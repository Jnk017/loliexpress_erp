import argparse
import functools
import json
import subprocess
import threading
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from uuid import uuid4

from playwright.sync_api import sync_playwright

from collect_drift import PROJECTS, request

parser = argparse.ArgumentParser(description="Create a sales order from Flutter Web on Gate")
parser.add_argument("--evidence-dir", required=True, type=Path)
args = parser.parse_args()
ref, name = PROJECTS["gate"]
assert request(ref)["name"] == name
customer, product, warehouse = (str(uuid4()) for _ in range(3))
marker = f"Gate vente {product[:8]}"
out = args.evidence_dir
out.mkdir(parents=True, exist_ok=True, mode=0o700)
result = {"role": "sales_rep", "passed": False, "cleanup": False,
          "sha": subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()}

def sql(query):
    return request(ref, "/database/query", {"query": query})


claims = """
SELECT set_config('request.jwt.claim.sub',id::text,true) FROM public.user_profiles
WHERE email='admin@loliexpress.test' AND role='admin' AND is_active;
"""
try:
    sql(f"""
    BEGIN;
    {claims}
    INSERT INTO public.customers(id,company_name,contact_person,email,phone,is_active,commercial_id)
    SELECT '{customer}','{marker}','Gate','{customer}@example.invalid','000',true,id
    FROM public.user_profiles WHERE email='commercial@loliexpress.test' AND role='sales_rep' AND is_active;
    INSERT INTO public.products(id,sku,name,unit_price,currency,is_active) VALUES ('{product}','{product}','{marker}',10,'CDF',true);
    INSERT INTO public.warehouse_locations(id,name,is_active) VALUES ('{warehouse}','{marker}',true);
    SELECT public.adjust_stock('{product}','{warehouse}',3,'{marker}');
    SELECT public.set_customer_product_price('{customer}','{product}',6,'CDF');
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
        def login_as(page, email, password, path):
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
            page.wait_for_url("**/#" + path)
        credentials = dict(line.split("=",1) for line in Path(".env.test").read_text().splitlines()
                           if "=" in line and not line.startswith("#"))
        login_as(page, credentials["COMMERCIAL_EMAIL"], credentials["COMMERCIAL_PASSWORD"], "/main-dashboard")
        result["phase"] = "sales_navigation"
        page.get_by_role("button",name="Ventes").or_(page.get_by_text("Ventes",exact=True)).first.click()
        page.wait_for_url("**/#/sales-order-processing")
        result["phase"] = "customer"
        page.get_by_text("Nouvelle commande", exact=True).first.wait_for()
        choose = page.get_by_role("button",name="Changer de client")
        if choose.count() and choose.first.is_enabled():
            choose.first.click()
            page.get_by_role("button",name=marker).or_(page.get_by_text(marker)).last.click()
        result["phase"] = "stock"
        page.get_by_role("textbox",name="Sélection de produits").wait_for()
        page.get_by_text("3 en stock").or_(page.locator('[aria-label*="3 en stock"]')).first.wait_for()
        result["phase"] = "select_product"
        product_row = page.get_by_role("group", name=marker)
        product_row.get_by_role("button", name="add_circle").click()
        result["phase"] = "submit"
        page.get_by_role("button", name="Créer la commande").wait_for()
        page.screenshot(path=out / "sales_quote.png")
        with page.expect_response(lambda response: "/rpc/create_order_with_items" in response.url) as created:
            page.get_by_role("button", name="Créer la commande").click()
        result["order_http"] = created.value.status
        result["order_response_shape"] = type(created.value.json()).__name__
        assert created.value.ok
        page.get_by_role("alertdialog").get_by_role("button",name="Suivre les commandes").wait_for()
        result["phase"] = "confirm"
        order_number = sql(f"SELECT order_number FROM public.sales_orders WHERE customer_id='{customer}'")[0]["order_number"]
        page.get_by_role("alertdialog").get_by_role("button",name="Suivre les commandes").click()
        page.get_by_role("button",name=order_number).or_(page.get_by_text(order_number)).or_(page.locator(f'[aria-label*="{order_number}"]')).first.click()
        with page.expect_response(lambda response: "/rpc/transition_order_status" in response.url) as transition:
            page.get_by_role("alertdialog").get_by_role("button",name="Confirmer",exact=True).click()
        result["transition_http"] = transition.value.status
        assert transition.value.ok
        page.screenshot(path=out / "sales_confirmed.png")
        browser.close()
    check = sql(f"""
    SELECT
      (SELECT quantity FROM public.inventory_stock WHERE product_id='{product}' AND warehouse_id='{warehouse}') AS stock,
      (SELECT count(*) FROM public.stock_movements WHERE product_id='{product}') AS movements,
      (SELECT o.total_amount FROM public.sales_orders o WHERE o.customer_id='{customer}') AS total,
      (SELECT o.order_status FROM public.sales_orders o WHERE o.customer_id='{customer}') AS order_status
    """)[0]
    result["database"] = check
    result["passed"] = check == {"stock": 3, "movements": 1, "total": "6.00", "order_status": "confirmed"}
except Exception as error:
    result["error"] = type(error).__name__
finally:
    try:
        result["cleanup"] = sql(f"""
        BEGIN;
        {claims}
        CREATE TEMP TABLE sales_web_orders AS SELECT id FROM public.sales_orders WHERE customer_id='{customer}';
        CREATE TEMP TABLE sales_web_inventory AS SELECT id FROM public.inventory_stock WHERE product_id='{product}';
        DELETE FROM public.notification_queue WHERE related_entity_type='order'
          AND related_entity_id IN (SELECT id FROM sales_web_orders);
        DELETE FROM public.sales_orders WHERE id IN (SELECT id FROM sales_web_orders);
        DELETE FROM public.customer_product_prices WHERE customer_id='{customer}' AND product_id='{product}';
        DELETE FROM public.stock_movements WHERE product_id='{product}';
        DELETE FROM public.inventory_stock WHERE product_id='{product}';
        DELETE FROM public.products WHERE id='{product}' AND name='{marker}';
        DELETE FROM public.warehouse_locations WHERE id='{warehouse}' AND name='{marker}';
        DELETE FROM public.customers WHERE id='{customer}' AND company_name='{marker}';
        DELETE FROM public.audit_logs WHERE (table_name='products' AND record_id='{product}')
          OR (table_name IN ('customers','customer_product_prices') AND record_id='{customer}')
          OR (table_name='inventory_stock' AND record_id IN (SELECT id FROM sales_web_inventory))
          OR (table_name='sales_orders' AND record_id IN (SELECT id FROM sales_web_orders));
        SELECT NOT EXISTS (SELECT FROM public.products WHERE id='{product}')
          AND NOT EXISTS (SELECT FROM public.customers WHERE id='{customer}') AS complete;
        COMMIT;
        """) == [{"complete": True}]
    finally:
        (out / "sales-web.json").write_text(json.dumps(result, indent=2) + "\n")
print(result)
raise SystemExit(int(not result["passed"] or not result["cleanup"]))
