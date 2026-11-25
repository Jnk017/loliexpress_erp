import argparse
import functools
import json
import secrets
import subprocess
import threading
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.request import Request, urlopen
from uuid import uuid4

from playwright.sync_api import sync_playwright

from collect_drift import PROJECTS, request

parser = argparse.ArgumentParser(description="Run warehouse receipt from Flutter Web on Gate")
parser.add_argument("--evidence-dir", required=True, type=Path)
args = parser.parse_args()
ref, name = PROJECTS["gate"]
assert request(ref)["name"] == name
base = f"https://{ref}.supabase.co"
env = dict(line.split("=", 1) for line in Path("cloud.env").read_text().splitlines() if "=" in line and not line.startswith("#"))
assert env["CLOUD_SUPABASE_URL"] == base
key = env["CLOUD_SUPABASE_SERVICE_ROLE_KEY"]
supplier, product, warehouse, marker_id = (str(uuid4()) for _ in range(4))
marker = "Réception-Web-" + marker_id[:8]
email = f"qa-{marker_id}@loliexpress.test"
password = secrets.token_urlsafe(24)
out = args.evidence_dir
out.mkdir(parents=True, exist_ok=True, mode=0o700)
result = {"role": "warehouse_staff", "passed": False, "cleanup": False,
          "sha": subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()}


def sql(query):
    return request(ref, "/database/query", {"query": query})


def auth(path="", method="POST", data=None):
    req = Request(base + "/auth/v1/admin/users" + path,
                  headers={"apikey": key, "Authorization": "Bearer " + key, "Content-Type": "application/json"},
                  data=json.dumps(data).encode() if data else None, method=method)
    with urlopen(req, timeout=16) as response:
        return json.load(response)


claims = """
SELECT set_config('request.jwt.claim.sub',id::text,true) FROM public.user_profiles
WHERE email='admin@loliexpress.test' AND role='admin' AND is_active;
"""
user_id = None
try:
    user_id = auth(data={"email": email, "password": password, "email_confirm": True})["id"]
    sql(f"""
    BEGIN;
    {claims}
    UPDATE public.user_profiles SET role='warehouse_staff',is_active=true,must_change_password=false WHERE id='{user_id}';
    INSERT INTO public.suppliers(id,company_name,is_active) VALUES ('{supplier}','{marker}',true);
    INSERT INTO public.products(id,sku,name,unit_price,currency,is_active) VALUES ('{product}','{marker}','{marker}',1,'CDF',true);
    INSERT INTO public.warehouse_locations(id,name,is_active) VALUES ('{warehouse}','{marker}',true);
    SELECT public.create_purchase_with_items('{supplier}',
      jsonb_build_array(jsonb_build_object('product_id','{product}','quantity',2,'unit_cost',1)),'CDF',1,NULL);
    COMMIT;
    """)
    handler = functools.partial(SimpleHTTPRequestHandler, directory="build/web")
    server = ThreadingHTTPServer(("127.0.0.1", 0), handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    with sync_playwright() as p:
        browser = p.chromium.launch(executable_path="/usr/bin/chromium", args=["--no-sandbox"])
        context = browser.new_context(ignore_https_errors=True, service_workers="block", viewport={"width": 920, "height": 950})
        context.route("https://www.gstatic.com/flutter-canvaskit/**", lambda route: route.fulfill(
            path="build/web/canvaskit/chromium/" + route.request.url.rsplit("/", 1)[-1]))
        page = context.new_page()
        page.set_default_timeout(22000)
        page.goto(f"http://127.0.0.1:{server.server_port}/")
        page.locator("flt-semantics-placeholder").evaluate("(element) => element.click()", timeout=15000)
        page.get_by_role("textbox").first.click()
        page.keyboard.type(email)
        page.get_by_role("textbox").nth(1).click()
        page.keyboard.type(password)
        assert page.locator('input[type=password]:focus').input_value() == password
        with page.expect_response(lambda response: "/auth/v1/token" in response.url) as login:
            page.get_by_role("button", name="Se connecter").click()
        result["login_http"] = login.value.status
        assert login.value.ok
        page.wait_for_url("**/#/inventory-management")
        result["login"] = True
        result["phase"] = "stock_actions"
        page.get_by_role("button", name="Actions").click()
        result["phase"] = "receive_link"
        page.get_by_role("button", name="Recevoir Marchandises").or_(page.get_by_text("Recevoir Marchandises")).first.click()
        page.wait_for_url("**/#/purchases")
        result["phase"] = "choose_purchase_line"
        line = page.locator(f'[aria-label*="{marker}"]').or_(page.get_by_text(marker))
        line.first.wait_for()
        line.first.click()
        result["phase"] = "choose_warehouse"
        page.get_by_role("dialog").get_by_text(marker).click()
        result["phase"] = "quantity"
        page.get_by_role("textbox", name="Quantité reçue").click()
        page.keyboard.type("2")
        result["phase"] = "submit"
        with page.expect_response(lambda response: "/rpc/receive_purchase_item" in response.url) as receipt:
            page.get_by_role("button", name="Enregistrer").click()
        result["receipt_http"] = receipt.value.status
        assert receipt.value.ok
        page.get_by_text("Aucun article à réceptionner.", exact=True).wait_for()
        page.screenshot(path=out / "warehouse_web.png")
        browser.close()
    check = sql(f"""
    SELECT
      (SELECT quantity FROM public.inventory_stock WHERE product_id='{product}' AND warehouse_id='{warehouse}') AS stock,
      (SELECT count(*) FROM public.stock_movements WHERE product_id='{product}' AND reference_type='purchase_receipt') AS movements,
      (SELECT status FROM public.purchases WHERE supplier_id='{supplier}') AS purchase_status
    """)[0]
    result["database"] = check
    result["passed"] = check == {"stock": 2, "movements": 1, "purchase_status": "received"}
except Exception as error:
    result["error"] = type(error).__name__
finally:
    try:
        result["cleanup"] = sql(f"""
        BEGIN;
        {claims}
        CREATE TEMP TABLE warehouse_web_receipts AS
          SELECT id FROM public.purchase_receipts
            WHERE purchase_item_id IN (SELECT id FROM public.purchase_items WHERE product_id='{product}');
        DELETE FROM public.purchase_receipts WHERE id IN (SELECT id FROM warehouse_web_receipts);
        DELETE FROM public.stock_movements WHERE product_id='{product}';
        DELETE FROM public.inventory_stock WHERE product_id='{product}';
        DELETE FROM public.purchases WHERE supplier_id='{supplier}';
        DELETE FROM public.suppliers WHERE id='{supplier}' AND company_name='{marker}';
        DELETE FROM public.products WHERE id='{product}' AND sku='{marker}';
        DELETE FROM public.warehouse_locations WHERE id='{warehouse}' AND name='{marker}';
        DELETE FROM public.audit_logs WHERE (table_name='products' AND record_id='{product}')
          OR (table_name='purchase_receipts' AND record_id IN (SELECT id FROM warehouse_web_receipts));
        SELECT NOT EXISTS (SELECT FROM public.products WHERE id='{product}') AS complete;
        COMMIT;
        """) == [{"complete": True}]
        if user_id:
            auth("/" + user_id, method="DELETE")
    finally:
        (out / "warehouse-web.json").write_text(json.dumps(result, indent=2) + "\n")
print(result)
raise SystemExit(int(not result["passed"] or not result["cleanup"]))
