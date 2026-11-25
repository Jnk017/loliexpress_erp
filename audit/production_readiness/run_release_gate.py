"""Run available release checks locally and report missing coverage explicitly."""
import argparse
import base64
import json
import os
import shlex
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path

from collect_drift import PROJECTS, request

ROOT = Path(__file__).resolve().parents[2]
SQL_TESTS = {
    "verify_delivery_client_boundary.sql": ("delivery_client_boundary_pass",),
    "verify_treasury_rpc_boundary.sql": ("treasury_write_boundary_pass",),
    "../verify_operational_setup.sql": (
        "account_opening_pass", "warehouse_and_supplier_pass", "role_guards_pass"
    ),
    "../verify_operational_treasury.sql": ("reconciled",),
    "verify_notification_grants.sql": ("notification_grants_pass",),
    "../verify_notification_read.sql": ("notification_read_pass",),
    "../verify_notification_center_preferences.sql": ("notification_center_preferences_pass",),
    "verify_rpc_only_tables.sql": ("rpc_only_tables_pass",),
    "../verify_stock_transfer_and_count.sql": ("stock_workflows_pass",),
}


def is_public_key(key):
    if not isinstance(key, str):
        return False
    if key.startswith("sb_publishable_"):
        return True
    try:
        payload = key.split(".")[1]
        claims = json.loads(base64.urlsafe_b64decode(payload + "=" * (-len(payload) % 4)))
        return claims.get("role") == "anon"
    except (IndexError, ValueError, AttributeError):
        return False


def run_sql(filename, keys):
    ref, name = PROJECTS["gate"]
    if request(ref)["name"] != name:
        raise ValueError("Unexpected Gate project")
    sql = Path(__file__).parent.joinpath(filename).read_text()
    rows = request(ref, "/database/query", {"query": sql})
    print(json.dumps(rows, indent=2))
    return int(len(rows) != 1 or any(rows[0].get(key) is not True for key in keys))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--flutter", default="flutter")
    parser.add_argument("--deno", default="deno")
    parser.add_argument("--web-defines", type=Path)
    parser.add_argument("--expected-sha", required=True)
    parser.add_argument("--with-gate-fixtures", action="store_true",
                        help="Autorise la création temporaire de fixtures sur Gate")
    parser.add_argument("--sql", choices=SQL_TESTS, help=argparse.SUPPRESS)
    args = parser.parse_args()
    os.chdir(ROOT)
    sha = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
    if sha != args.expected_sha:
        raise SystemExit("Candidate does not match --expected-sha")
    if args.sql:
        return run_sql(args.sql, SQL_TESTS[args.sql])
    if subprocess.check_output(["git", "status", "--porcelain", "--untracked-files=no"], text=True):
        raise SystemExit("Candidate has uncommitted tracked changes")

    args.output.mkdir(mode=0o700, parents=True, exist_ok=True)
    env = {**os.environ, "CI": "true"}
    results = []

    def record(check, command=None, reason=None, environment="local"):
        started = time.monotonic()
        timestamp = datetime.now(timezone.utc).isoformat()
        code = None
        proof = None
        if command:
            proof = f"{check}.log"
            with (args.output / proof).open("w") as log:
                try:
                    code = subprocess.run(command, env=env, stdout=log,
                                          stderr=subprocess.STDOUT, timeout=900).returncode
                except FileNotFoundError:
                    reason = "Exécutable indisponible"
                except subprocess.TimeoutExpired:
                    code, reason = 124, "Délai d’exécution dépassé"
        results.append({
            "id": check, "command": shlex.join(command) if command else None,
            "environment": environment, "sha": sha, "date": timestamp,
            "exit_code": code, "result": "NOT_RUN" if code is None else "PASS" if code == 0 else "FAIL",
            "evidence": proof, "duration_seconds": round(time.monotonic() - started, 3),
            "blocker": reason,
        })
        (args.output / "release_gate_results.json").write_text(
            json.dumps(results, ensure_ascii=False, indent=2) + "\n"
        )
        print(check, results[-1]["result"], flush=True)
        return code

    flutter_ready = record("FLUTTER-SDK", [args.flutter, "--version"]) == 0
    deps_ready = flutter_ready and record("FLUTTER-DEPS", [args.flutter, "pub", "get"]) == 0
    if deps_ready:
        record("FLUTTER-ANALYZE", [args.flutter, "analyze", "--no-pub"])
        record("FLUTTER-TEST", [args.flutter, "test", "--no-pub", "--reporter", "expanded"])
    else:
        for check in ("FLUTTER-ANALYZE", "FLUTTER-TEST"):
            record(check, reason="Dépendances Flutter indisponibles")
    if deps_ready and args.web_defines:
        config = json.loads(args.web_defines.read_text())
        if (config.get("SUPABASE_URL") == f"https://{PROJECTS['gate'][0]}.supabase.co"
                and set(config) <= {"SUPABASE_URL", "SUPABASE_ANON_KEY", "ENV"}
                and is_public_key(config.get("SUPABASE_ANON_KEY"))):
            record("WEB-BUILD", [args.flutter, "build", "web", "--release", "--no-pub",
                                 "--no-wasm-dry-run", f"--dart-define-from-file={args.web_defines}"])
        else:
            record("WEB-BUILD", reason="Configuration Gate ou clé publique absente")
    else:
        record("WEB-BUILD", reason="Configuration Web Gate ou dépendances manquantes")

    for filename in SQL_TESTS:
        test_id = "SQL-" + Path(filename).stem
        sql_command = ["python3", __file__, "--sql", filename, "--output", str(args.output),
                       "--expected-sha", sha]
        if env.get("SUPABASE_PAT"):
            record(test_id, sql_command, environment=PROJECTS["gate"][1])
        else:
            record(test_id, reason="PAT absent de l’environnement", environment=PROJECTS["gate"][1])

    if args.with_gate_fixtures and env.get("SUPABASE_PAT"):
        record("DB-CONCURRENT-TRANSFER", [
            "python3", str(Path(__file__).with_name("test_concurrent_transfer.py")),
            "--evidence", str(args.output / "concurrent_transfer.json"),
        ], environment=PROJECTS["gate"][1])
    else:
        record("DB-CONCURRENT-TRANSFER", reason="Fixtures Gate non activées ou PAT absent")

    tests = sorted(str(path.relative_to(ROOT)) for path in (ROOT / "supabase/functions").rglob("*_test.ts"))
    record("EDGE-DENO", [args.deno, "test", "--cached-only", *tests] if tests else None,
           reason=None if tests else "Suite Deno absente")
    for check, reason in {
        "DB-BASELINE": "Rejeu sur une cible vierge autorisée à raccorder",
        "DB-CONCURRENCY-OTHER": "Autres scénarios multisession à raccorder",
        "EDGE-HTTP": "Rejeu HTTP lié au candidat à raccorder",
        "WEB-E2E": "Suite métier Playwright à raccorder",
        "ANDROID": "APK et preuves appareil du candidat requis",
        "ARTEFACTS": "Inventaire et contrôle des artefacts complets à raccorder",
        "RECOVERY": "Restauration isolée à raccorder",
    }.items():
        record(check, reason=reason)
    return int(any(row["result"] != "PASS" for row in results))


if __name__ == "__main__":
    raise SystemExit(main())
