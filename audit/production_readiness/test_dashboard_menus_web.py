"""Exercise visible Flutter dashboard menu entries with real Gate accounts."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import functools
import json
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import re
import subprocess
import threading
from urllib.parse import urlsplit

from playwright.sync_api import sync_playwright

GATE = "muzbwqxvamcbfiuehxro.supabase.co"
SETTINGS = ("Paramètres", "/settings-configuration")
CASES = {
    "admin": ("ADMIN", "/admin-dashboard", [
        ("Ventes", "/sales-order-processing"), ("Factures et encaissements", "/invoice-generation"),
        ("Achats", "/purchases"), ("Stock", "/inventory-management"), SETTINGS,
    ], [("Dépenses", "/expenses"), ("Rapports", "/reports-analytics")]),
    "commercial": ("COMMERCIAL", "/main-dashboard", [
        ("Nouvelle commande", "/sales-order-processing"), ("Clients", "/customer-management"),
        ("Catalogue", "/product-catalog"), ("Scanner", "/barcode-scanner"), SETTINGS,
    ], [("Livraisons", "/delivery-tracking")]),
    "comptable": ("COMPTABLE", "/main-dashboard", [
        ("Factures et encaissements", "/invoice-generation"), ("Dépenses", "/expenses"),
        ("Rapports", "/reports-analytics"), ("Achats", "/purchases"), SETTINGS,
    ], [("Stock", "/inventory-management")]),
    "acheteur": ("ACHETEUR", "/purchases", [
        ("Catalogue", "/product-catalog"), ("Stock", "/inventory-management"),
        SETTINGS, ("Nouvel achat", "dialog"),
    ], []),
    "magasinier": ("MAGASINIER", "/inventory-management", [], [("Scanner", "/barcode-scanner")]),
    "livreur": ("LIVREUR", "/delivery-tracking", [], [("Alertes", "/notifications-center")]),
    "b2b_a": ("CLIENT_A", "/customer-portal", [], []),
    "b2b_b": ("CLIENT_B", "/customer-portal", [], []),
}
B2B_TABS = ("Commandes", "Documents", "Compte", "Support")
ERROR_TEXT = re.compile(r"Accès refusé|Une erreur est survenue|Erreur de chargement|PostgrestException", re.I)


def test_account(role, env, base, fixtures, support_marker, scanner_code):
    slot, home, menu, shortcuts = CASES[role]
    result = {"role": role, "home": home, "checks": []}
    if not env.get(slot + "_EMAIL") or not env.get(slot + "_PASSWORD"):
        return {**result, "login": "NOT_RUN", "reason": "test account unavailable"}
    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(executable_path="/usr/bin/chromium", args=["--no-sandbox"])
        context = browser.new_context(ignore_https_errors=True, service_workers="block", viewport={"width": 920, "height": 950})
        context.route("https://www.gstatic.com/flutter-canvaskit/**", lambda route: route.fulfill(
            path="build/web/canvaskit/chromium/" + route.request.url.rsplit("/", 1)[-1]))
        page = context.new_page()
        page.set_default_timeout(12000)
        requests = []

        def track(response):
            url = urlsplit(response.url)
            if url.hostname == GATE and url.path.startswith(("/rest/v1/", "/functions/v1/")):
                requests.append({"path": url.path, "method": response.request.method, "http": response.status})

        page.on("response", track)

        def enable_semantics():
            placeholder = page.locator("flt-semantics-placeholder")
            if not page.locator("flt-semantics").count():
                placeholder.evaluate("(element) => element.click()", timeout=25000)

        def action(label):
            regex = re.compile(r"(?:^|\s)" + re.escape(label) + r"$", re.I)
            return page.get_by_role("button", name=regex).or_(page.get_by_text(label, exact=True)).last

        try:
            page.goto(base)
            enable_semantics()
            page.get_by_role("textbox").first.click()
            page.keyboard.type(env[slot + "_EMAIL"])
            page.get_by_role("textbox").nth(1).click()
            password = env[slot + "_PASSWORD"]
            page.keyboard.type(password)
            field = page.locator('input[type=password]:focus')
            if field.input_value() != password:
                field.fill(password)
            with page.expect_response(lambda response: urlsplit(response.url).hostname == GATE
                                      and "/auth/v1/token" in response.url, timeout=20000) as auth:
                page.get_by_role("button", name="Se connecter").click()
            result["auth_http"] = auth.value.status
            assert auth.value.ok
            page.wait_for_url("**/#" + home, timeout=18000)
            result["login"] = "PASS"
        except Exception as error:
            return {**result, "login": "FAIL", "reason": type(error).__name__}

        entries = [("menu", *item) for item in menu] + [("shortcut", *item) for item in shortcuts]
        if role.startswith("b2b"):
            entries += [("tab", label, "tab") for label in B2B_TABS]
            entries.extend([("shortcut", "Catalogue", "/product-catalog"),
                            ("notification", "Notifications", "/notifications-screen")])
        for surface, label, target in entries:
            check = {"surface": surface, "label": label, "target": target}
            start = len(requests)
            try:
                if urlsplit(page.url).fragment != home or surface == "notification":
                    page.goto(base + "#" + home)
                    enable_semantics()
                if surface == "menu":
                    check["phase"] = "open_menu"
                    action("Navigation par métier").click()
                    check["phase"] = "select_menu_item"
                    page.get_by_role("menuitem", name=label, exact=True).or_(
                        page.get_by_role("menu").get_by_text(label, exact=True)).first.click()
                elif surface == "tab":
                    tab = page.get_by_role("tab", name=re.compile(re.escape(label), re.I))
                    tab.click()
                    tab.locator("xpath=self::*[@aria-selected='true']").wait_for()
                else:
                    action(label).click()
                check["phase"] = "assert_destination"
                if target == "dialog":
                    dialog = page.get_by_role("alertdialog").or_(page.get_by_role("dialog")).first
                    dialog.wait_for()
                    page.keyboard.press("Escape")
                    dialog.wait_for(state="hidden")
                elif target.startswith("/"):
                    page.wait_for_url("**/#" + target)
                if label == "Scanner" and scanner_code:
                    action("Saisie manuelle").click()
                    search = page.get_by_role("alertdialog")
                    search.get_by_role("textbox").click()
                    page.keyboard.type(scanner_code)
                    with page.expect_response(lambda response: "/rest/v1/barcode_scans" in response.url
                                              and response.request.method == "POST") as scan:
                        search.get_by_role("button", name="Rechercher").click()
                    check["barcode_scan_http"] = scan.value.status
                    assert scan.value.ok
                    page.get_by_text("Article QA scanner 6f82").or_(
                        page.locator('[aria-label*="Article QA scanner 6f82"]')
                    ).first.wait_for()
                if label == "Support" and surface == "tab" and support_marker:
                    message = f"{support_marker} {role}"
                    field = page.get_by_role("textbox", name=re.compile("Tapez votre message"))
                    field.click()
                    page.keyboard.type(message)
                    with page.expect_response(lambda response: "/rest/v1/support_tickets" in response.url
                                              and response.request.method == "POST") as created:
                        action("send").click()
                    assert created.value.ok
                    page.get_by_text(message).or_(page.locator(f'[aria-label*="{message}"]')).first.wait_for()
                    check["support_ticket_http"] = created.value.status
                if surface == "notification" and fixtures:
                    own, other = fixtures if role == "b2b_a" else fixtures[::-1]
                    page.get_by_text(own).or_(page.locator(f'[aria-label*="{own}"]')).first.wait_for()
                    assert not page.get_by_text(other).or_(page.locator(f'[aria-label*="{other}"]')).count()
                    mark_read = action("Marquer comme lu")
                    assert mark_read.count() and page.get_by_role(
                        "button", name=re.compile("Marquer comme lu")
                    ).count() == 1, "A single unread fixture is required"
                    with page.expect_response(lambda response: "/rest/v1/notification_queue" in response.url
                                              and response.request.method == "PATCH") as updated:
                        mark_read.click()
                    assert updated.value.ok
                    check["own_fixture_visible"] = True
                    check["foreign_fixture_hidden"] = True
                    check["mark_read_http"] = updated.value.status
                page.wait_for_timeout(650)
                if page.get_by_text(ERROR_TEXT).count():
                    check["finding"] = "Erreur visible après ouverture"
                check["status"] = "FAIL" if check.get("finding") else "PASS"
                check.pop("phase", None)
            except Exception as error:
                check.update(status="FAIL", reason=type(error).__name__, observed_route=urlsplit(page.url).fragment)
                page.keyboard.press("Escape")
            check["gate_requests"] = requests[start:]
            check["http_errors"] = [request for request in check["gate_requests"] if request["http"] >= 400]

            if check["http_errors"]:
                check["status"] = "FAIL"
            result["checks"].append(check)
        browser.close()
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--accounts", type=Path, default=Path(".env.test"))
    parser.add_argument("--evidence", required=True, type=Path)
    parser.add_argument("--roles", choices=CASES, nargs="+", default=list(CASES))
    parser.add_argument("--notification-fixtures", nargs=2, metavar=("CLIENT_A", "CLIENT_B"))
    parser.add_argument("--support-marker")
    parser.add_argument("--scanner-code")
    args = parser.parse_args()
    env = dict(line.split("=", 1) for line in args.accounts.read_text().splitlines()
               if "=" in line and not line.startswith("#"))
    if urlsplit(env["SUPABASE_URL"]).hostname != GATE:
        raise SystemExit("Gate accounts required")
    handler = functools.partial(SimpleHTTPRequestHandler, directory="build/web")
    with ThreadingHTTPServer(("127.0.0.1", 0), handler) as server:
        threading.Thread(target=server.serve_forever, daemon=True).start()
        base = f"http://127.0.0.1:{server.server_port}/"
        with ThreadPoolExecutor(max_workers=2) as pool:
            results = list(pool.map(lambda role: test_account(role, env, base, args.notification_fixtures, args.support_marker, args.scanner_code), args.roles))
    evidence = {"sha": subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip(),
                "scope": "navigation and HTTP observations; optional Gate B2B notifications and support actions",
                "results": results}
    args.evidence.write_text(json.dumps(evidence, indent=2, ensure_ascii=False) + "\n")
    return int(any(r["login"] != "PASS" or any(c["status"] != "PASS" for c in r["checks"]) for r in results))


if __name__ == "__main__":
    raise SystemExit(main())
