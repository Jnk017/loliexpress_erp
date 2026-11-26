"""Collect two read-only Supabase catalogs and compare them without emitting secrets."""
import argparse
import json
import os
from collections import Counter
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import Request, urlopen

PROJECTS = {
    "gate": ("muzbwqxvamcbfiuehxro", "loliexpress-gate-test"),
    "production": ("lvzdlmojjoqrwxwluvih", "loliexpress_erp"),
}


def request(ref, suffix="", payload=None):
    if ref not in {project[0] for project in PROJECTS.values()}:
        raise ValueError("Unexpected project reference")
    req = Request(
        f"https://api.supabase.com/v1/projects/{ref}{suffix}",
        headers={
            "Authorization": "Bearer " + os.environ["SUPABASE_PAT"],
            "Content-Type": "application/json",
        },
        data=None if payload is None else json.dumps(payload).encode(),
    )
    try:
        with urlopen(req, timeout=40) as response:
            return json.load(response)
    except HTTPError as error:
        print(json.load(error).get("message", "").splitlines()[0])
        raise RuntimeError(f"{ref} {suffix or '/'} returned HTTP {error.code}") from None


def collect(ref, name, query):
    if request(ref)["name"] != name:
        raise ValueError("Project name does not match the authorised project")
    rows = request(ref, "/database/query", {"query": query})[0]["inventory"]
    for function in request(ref, "/functions"):
        rows.append({
            "kind": "edge",
            "object": function["slug"],
            "detail": {key: function.get(key) for key in ("status", "verify_jwt", "version")},
        })
    indexed = {}
    for row in rows:
        key = (row["kind"], row["object"])
        indexed.setdefault(key, []).append(row["detail"])
    return indexed


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path)
    parser.add_argument("--gate-only", action="store_true")
    args = parser.parse_args()
    query = Path(__file__).with_name("catalog.sql").read_text()
    if args.gate_only:
        gate = collect(*PROJECTS["gate"], query)
        counts = Counter(kind for kind, _ in gate)
        args.output.write_text(json.dumps({"counts": counts, "catalog": [
            {"kind": kind, "object": name, "detail": detail}
            for (kind, name), detail in sorted(gate.items())
        ]}, indent=2) + "\n")
        print(f"{len(gate)} Gate objects across {len(counts)} catalog categories")
        return
    catalogs = {side: collect(*project, query) for side, project in PROJECTS.items()}
    gate, production = catalogs["gate"], catalogs["production"]
    diffs = []
    for kind, name in sorted(gate.keys() | production.keys()):
        key = kind, name
        left, right = gate.get(key), production.get(key)
        if left != right:
            status = "gate_only" if right is None else "production_only" if left is None else "different"
            diffs.append({"kind": kind, "object": name, "status": status,
                          "gate": left, "production": right})
    counts = Counter(row["kind"] for row in diffs)
    args.output.write_text(json.dumps({"counts": counts, "diffs": diffs}, indent=2) + "\n")
    print(f"{len(diffs)} differences across {len(counts)} catalog categories")


if __name__ == "__main__":
    main()
