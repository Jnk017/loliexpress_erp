#!/usr/bin/env python3
"""Provision seven supplied QA accounts on the verified local gate stack."""

import argparse
import json
import os
import shlex
import subprocess
from pathlib import Path
from urllib.error import HTTPError
from urllib.parse import quote, urlsplit
from urllib.request import ProxyHandler, Request, build_opener


ROLES = {
    "commercial": "sales_rep",
    "comptable": "comptable",
    "acheteur": "acheteur",
    "admin": "admin",
    "livreur": "delivery_agent",
    "b2b_a": "b2b_customer",
    "b2b_b": "b2b_customer",
}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", required=True, type=Path)
    parser.add_argument("--accounts", required=True, type=Path)
    args = parser.parse_args()
    api = os.environ["LOLI_E2E_SUPABASE_URL"].rstrip("/")
    parsed = urlsplit(api)
    if (parsed.scheme != "http" or parsed.netloc != "127.0.0.1:54321"
            or parsed.path or parsed.query or parsed.fragment or parsed.username):
        raise ValueError("URL locale attendue : http://127.0.0.1:54321")
    key = os.environ["LOLI_E2E_SERVICE_KEY"]
    if not key:
        raise ValueError("Clé locale manquante")
    config = json.loads(args.accounts.read_text())
    accounts = config["accounts"]
    sender = config["sender_email"]
    if set(accounts) != set(ROLES) or not isinstance(sender, str) or "@" not in sender:
        raise ValueError("Fournir exactement les sept profils et un expéditeur de test")
    emails = set()
    for slot in ROLES:
        account = accounts[slot]
        email, password = account["email"], account["password"]
        if ("@" not in email or len(password) < 8 or email.lower() in emails
                or any(c in email + password for c in "\r\n\x00")):
            raise ValueError(f"Compte E2E invalide : {slot}")
        emails.add(email.lower())
    if "\r" in sender or "\n" in sender or "\x00" in sender:
        raise ValueError("Expéditeur de test invalide")

    if subprocess.run(["git", "-C", str(args.repo), "check-ignore", "-q", "--", ".env.test"],
                      check=False).returncode != 0:
        raise ValueError("Le clone de gate doit ignorer .env.test")
    target = args.repo / ".env.test"
    if target.exists():
        raise ValueError(".env.test existe déjà, vérifier les comptes avant de relancer")
    client = build_opener(ProxyHandler({}))

    def request(method, path, data=None):
        headers = {"apikey": key, "Authorization": f"Bearer {key}", "Content-Type": "application/json"}
        body = json.dumps(data).encode() if data is not None else None
        try:
            with client.open(Request(api + path, data=body, method=method, headers=headers), timeout=15) as response:
                raw = response.read()
                return json.loads(raw) if raw else None
        except HTTPError as error:
            raise RuntimeError(f"API locale : HTTP {error.code}, étape {method}") from None

    request("GET", "/rest/v1/user_profiles?select=id&limit=0")
    existing = request("GET", "/auth/v1/admin/users?page=1&per_page=100")["users"]
    by_email = {row.get("email", "").lower(): row for row in existing if row.get("email")}
    output = {"E2E_SUPABASE_URL": api, "E2E_SENDER_EMAIL": sender}
    for slot, role in ROLES.items():
        email = accounts[slot]["email"]
        password = accounts[slot]["password"]
        body = {"email": email, "password": password, "email_confirm": True}
        user = by_email.get(email.lower())
        if user:
            user_id = user["id"]
            request("PUT", f"/auth/v1/admin/users/{quote(user_id, safe='')}", body)
        else:
            user = request("POST", "/auth/v1/admin/users", body)
            user_id = user["id"]
        query = f"/rest/v1/user_profiles?id=eq.{quote(user_id, safe='')}"
        request("PATCH", query, {"role": role, "is_active": True, "must_change_password": False})
        profiles = request("GET", query + "&select=role,is_active,must_change_password")
        if profiles != [{"role": role, "is_active": True, "must_change_password": False}]:
            raise RuntimeError(f"Profil de test non vérifié : {slot}")
        output[f"E2E_{slot.upper()}_EMAIL"] = email
        output[f"E2E_{slot.upper()}_PASSWORD"] = password
        print(f"{slot} : profil local vérifié")
    fd = os.open(target, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
    with os.fdopen(fd, "w") as env_file:
        for name, value in output.items():
            env_file.write(f"{name}={shlex.quote(value)}\n")
    print("Fichier .env.test créé, mode 0600. Aucun secret affiché.")


if __name__ == "__main__":
    main()
