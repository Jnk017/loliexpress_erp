"""Readiness and mail delivery checks for the isolated PostgreSQL 17 stack."""

import json
import os
import subprocess
import sys
from urllib.parse import unquote, urlsplit
from urllib.request import ProxyHandler, Request, build_opener


TOOLS = "/workspace/work/tools/bin"
WORKDIR = "/workspace/work/loli-gate-local"
API = "http://127.0.0.1:54321"
MAIL = "http://127.0.0.1:54324"


def check():
    result = subprocess.run(
        [f"{TOOLS}/supabase", "--workdir", WORKDIR, "status", "-o", "json"],
        capture_output=True, text=True, timeout=15,
    )
    if result.returncode:
        raise RuntimeError("La CLI ne voit pas de pile locale démarrée")
    config = json.loads(result.stdout)
    if config.get("API_URL") != API:
        raise RuntimeError("L’URL retournée par la pile ne correspond pas à la cible locale")
    db = urlsplit(config["DB_URL"])
    if db.hostname != "127.0.0.1" or db.port != 54322:
        raise RuntimeError("Cible PostgreSQL hors boucle locale attendue")
    print("STACK_OK", flush=True)
    http = build_opener(ProxyHandler({}))
    with http.open(Request(f"{API}/auth/v1/health", headers={"apikey": config["ANON_KEY"]}), timeout=10) as response:
        if response.status != 200:
            raise RuntimeError("Sonde Auth non valide")
    print("AUTH_OK", flush=True)
    with http.open(f"{MAIL}/api/v1/messages", timeout=10) as response:
        if response.status != 200:
            raise RuntimeError("Boîte locale non disponible")
    print("INBUCKET_OK (API Mailpit locale)", flush=True)
    child_env = os.environ | {"PGPASSWORD": unquote(db.password or "")}
    output = subprocess.run(
        [f"{TOOLS}/psql", "-X", "-w", "-Atq", "-v", "ON_ERROR_STOP=1",
         "-h", db.hostname, "-p", str(db.port), "-U", unquote(db.username or ""),
         "-d", db.path.removeprefix("/"), "-c",
         "SELECT current_setting('server_version_num')::int/10000,"
         "(SELECT count(*) FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE');"],
        env=child_env, capture_output=True, text=True, timeout=15,
    )
    if output.returncode or not output.stdout.strip().startswith("17|"):
        raise RuntimeError("PostgreSQL 17 local non vérifié")
    print(f"DB_OK version_majeure=17 tables_publiques={int(output.stdout.strip().split('|')[1])}", flush=True)
    message = {
        "From": {"Email": "no-reply@loliexpress.test"},
        "To": [{"Email": "admin@loliexpress.test"}],
        "Subject": "LoliExpress bootstrap local probe",
        "Text": "ok",
    }
    with http.open(Request(f"{MAIL}/api/v1/send", data=json.dumps(message).encode(),
                           headers={"Content-Type": "application/json"}, method="POST"), timeout=10):
        pass
    with http.open(f"{MAIL}/api/v1/messages", timeout=10) as response:
        if not any(msg.get("Subject") == message["Subject"] for msg in json.load(response)["messages"]):
            raise RuntimeError("Sonde reçue non trouvée dans la boîte locale")
    print("INBUCKET_RX_OK", flush=True)


if __name__ == "__main__":
    try:
        check()
    except Exception as exc:
        # Ne jamais afficher une configuration, une réponse JSON, ou des secrets.
        print(f"Probe arrêtée ({type(exc).__name__})", file=sys.stderr)
        raise SystemExit(1)
