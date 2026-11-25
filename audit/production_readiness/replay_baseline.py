"""Rehearse the migration history on an explicitly authorised empty Supabase project."""
import argparse
import hashlib
import json
import os
import re
from pathlib import Path
from urllib.request import Request, urlopen

from collect_drift import PROJECTS
from run_release_gate import ROOT, SQL_TESTS

HISTORICAL_SUITES = (
    "verify_p0a", "verify_p0b", "verify_p0b_settings",
    "verify_p1a_invoice_delivery", "verify_p1a_admin_delivery_credit",
    "verify_p1a_handover", "verify_p1a_drafts_and_purchases", "verify_p1a_ra", "verify_p1b",
)


def authorise_target(ref, name, confirmation):
    if not re.fullmatch(r"[a-z0-9]{20}", ref) or confirmation != ref:
        raise ValueError("La référence exacte et sa confirmation sont requises")
    if ref in {project[0] for project in PROJECTS.values()}:
        raise ValueError("Gate et Production sont exclus du rejeu de baseline")
    if not name.startswith("loliexpress-baseline-"):
        raise ValueError("Un projet réservé au rejeu loliexpress-baseline-* est requis")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project-ref", required=True)
    parser.add_argument("--project-name", required=True)
    parser.add_argument("--confirm-isolated-ref", required=True)
    parser.add_argument("--evidence", required=True, type=Path)
    args = parser.parse_args()
    ref, name = args.project_ref, args.project_name
    authorise_target(ref, name, args.confirm_isolated_ref)
    token = os.environ["SUPABASE_PAT"]

    def request(path="", payload=None):
        authorise_target(ref, name, args.confirm_isolated_ref)
        req = Request(
            f"https://api.supabase.com/v1/projects/{ref}{path}",
            headers={"Authorization": "Bearer " + token, "Content-Type": "application/json"},
            data=None if payload is None else json.dumps(payload).encode(),
        )
        with urlopen(req, timeout=90) as response:
            return json.load(response)

    def query(sql):
        return request("/database/query", {"query": sql})

    if request()["name"] != name:
        raise SystemExit("Identité du projet non confirmée")
    initial = query("""
        SELECT NOT EXISTS (SELECT FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
          WHERE n.nspname='public' AND c.relkind IN ('r','p','v','m','S')) AS public_empty,
          NOT EXISTS (SELECT FROM auth.users) AS auth_empty,
          NOT EXISTS (SELECT FROM storage.buckets) AS storage_empty,
          CASE WHEN to_regclass('supabase_migrations.schema_migrations') IS NULL THEN true
               ELSE NULL END AS register_absent
    """)[0]
    register_empty = initial["register_absent"] is True or query(
        "SELECT NOT EXISTS (SELECT FROM supabase_migrations.schema_migrations) AS empty"
    ) == [{"empty": True}]
    if not register_empty or not all(initial[key] for key in ("public_empty", "auth_empty", "storage_empty")):
        raise SystemExit("Projet déjà initialisé, rejeu refusé")

    args.evidence.mkdir(mode=0o700, parents=True, exist_ok=False)

    def save(label, value):
        (args.evidence / f"{label}.json").write_text(json.dumps(value, indent=2) + "\n")

    save("initial", {"project_ref": ref, "project_name": name, **initial,
                     "register_empty": register_empty})
    migrations = sorted((ROOT / "supabase/migrations").glob("*.sql"))
    migrations = [path for path in migrations if re.match(r"^\d{3}_", path.name)]
    versions = [int(path.name[:3]) for path in migrations]
    if not versions or versions != list(range(versions[-1] + 1)) or versions[-1] < 25:
        raise SystemExit("Historique local incomplet ou ambigu")

    def apply(path):
        content = path.read_bytes()
        result = request("/database/migrations", {"name": path.stem, "query": content.decode()})
        save(path.stem, {"sha256": hashlib.sha256(content).hexdigest(), "response": result})

    def assert_rows(label, sql, expected_count=None):
        rows = query(sql)
        save(label, rows)
        if (not rows or (expected_count is not None and len(rows) != expected_count)
                or any(row.get("passed") is not True for row in rows)):
            raise SystemExit(f"Contrôle bloquant en échec, voir {label}.json")
        return len(rows)

    apply(migrations[0])
    audit = ROOT / "audit"
    total = assert_rows("verify_p0a_baseline", (audit / "verify_p0a_baseline.sql").read_text(), 9)
    for path in migrations[1:]:
        apply(path)
    for label in HISTORICAL_SUITES:
        sql = (audit / f"{label}.sql").read_text()
        if label == "verify_p0b":
            # Keep the setup and assertions in the same transaction. The API
            # returns the last result set and does not parse psql includes.
            sql = sql.split(chr(92) + "ir", 1)[0]
            sql = sql.replace("BEGIN;", """BEGIN;
CREATE TEMP TABLE baseline_assertions(scenario text, passed bool);
GRANT INSERT, SELECT ON baseline_assertions TO authenticated;""", 1)
            sql = re.sub(r"(?m)^SELECT ('.*?' AS scenario,)",
                         r"INSERT INTO baseline_assertions SELECT \1", sql)
            sql = sql.replace("ROLLBACK;", "SELECT * FROM baseline_assertions;\nROLLBACK;")
        total += assert_rows(label, sql)
    if total != 66:
        raise SystemExit(f"Nombre d’assertions inattendu : {total}")
    save("historical_status", {"passed": total, "expected": 66})
    # Profiles have no password; these disposable identities are only for
    # database role simulation after the historical empty-state assertion.
    query("""
        BEGIN;
        INSERT INTO auth.users(id, email)
        VALUES (gen_random_uuid(), 'admin@loliexpress.test'),
               (gen_random_uuid(), 'comptable@loliexpress.test'),
               (gen_random_uuid(), 'acheteur@loliexpress.test'),
               (gen_random_uuid(), 'client-a@loliexpress.test');
        UPDATE public.user_profiles AS p SET role = f.role::public.user_role,
            is_active = true, must_change_password = false
        FROM (VALUES ('admin@loliexpress.test','admin'),
                     ('comptable@loliexpress.test','comptable'),
                     ('acheteur@loliexpress.test','acheteur'),
                     ('client-a@loliexpress.test','b2b_customer')) AS f(email, role)
        WHERE p.email = f.email;
        COMMIT;
    """)
    for filename, keys in SQL_TESTS.items():
        file = Path(__file__).parent / filename
        rows = query(file.read_text())
        save(file.stem, rows)
        if len(rows) != 1 or any(rows[0].get(key) is not True for key in keys):
            raise SystemExit(f"Suite supplémentaire en échec, voir {file.stem}.json")
    save("supplemental_status", {"passed": len(SQL_TESTS), "expected": len(SQL_TESTS)})
    print("66/66 contrôles historiques et toutes les suites supplémentaires configurées réussis.")


if __name__ == "__main__":
    main()
