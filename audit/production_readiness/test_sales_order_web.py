import argparse
import functools
import json
import re
import subprocess
import threading
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from uuid import uuid4

from playwright.sync_api import sync_playwright

from collect_drift import PROJECTS, request

parser = argparse.ArgumentParser(description="Create a sales order from Flutter Web on Gate")
parser.add_argument("--plan-delivery", action="store_true")
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
        def new_role_page():
            context = browser.new_context(
                ignore_https_errors=True, service_workers="block", viewport={"width": 920, "height": 950}
            )
            context.route("https://www.gstatic.com/flutter-canvaskit/**", lambda route: route.fulfill(
                path="build/web/canvaskit/chromium/" + route.request.url.rsplit("/", 1)[-1]))
            screen = context.new_page()
            screen.set_default_timeout(40000)
            return screen

        page = new_role_page()
        def login_as(page, email, password, path):
            page.goto(f"http://127.0.0.1:{server.server_port}/")
            page.locator("flt-semantics-placeholder").evaluate("(element) => element.click()", timeout=15000)
            page.get_by_role("textbox").first.click()
            page.keyboard.type(email)
            page.get_by_role("textbox").nth(1).click()
            page.keyboard.type(password)
            password_input = page.locator('input[type=password]:focus')
            if password_input.input_value() != password:
                password_input.fill(password)
            assert password_input.input_value() == password, "Password field did not receive the test input"
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
        if args.plan_delivery:
            def open_order(screen):
                step = result["phase"]
                result["phase"] = step + ":open_followup"
                screen.get_by_role("button", name="Suivre les commandes").or_(
                    screen.get_by_label("Suivre les commandes")
                ).first.click()
                result["phase"] = step + ":select_order"
                screen.get_by_role("button", name=order_number).or_(
                    screen.get_by_text(order_number, exact=True)
                ).or_(screen.locator(f'[aria-label*="{order_number}"]')).first.click()
                result["phase"] = step + ":order_detail"

            for action in ("Mettre en préparation", "Marquer expédiée"):
                result["phase"] = action
                open_order(page)
                with page.expect_response(lambda response: "/rpc/transition_order_status" in response.url) as updated:
                    page.get_by_role("alertdialog").get_by_role("button", name=action, exact=True).click()
                assert updated.value.ok

            result["phase"] = "admin_login"
            admin_page = new_role_page()
            login_as(admin_page, credentials["ADMIN_EMAIL"], credentials["ADMIN_PASSWORD"], "/admin-dashboard")
            result["phase"] = "admin_sales"
            admin_page.get_by_role("button",name="Ventes").or_(admin_page.get_by_text("Ventes",exact=True)).first.click()
            admin_page.wait_for_url("**/#/sales-order-processing")
            result["phase"] = "plan_form"
            open_order(admin_page)
            dialog = admin_page.get_by_role("alertdialog")
            driver = sql("SELECT full_name FROM public.user_profiles WHERE email='livreur@loliexpress.test'")[0]["full_name"]
            def dropdown(label, option):
                result["phase"] = "plan_dropdown_" + label
                trigger = dialog.get_by_role("button", name=label, exact=True)
                if trigger.count():
                    trigger.click()
                else:
                    dialog.get_by_text(label, exact=True).click()
                target = re.compile(r"^" + re.escape(option) + r"$", re.IGNORECASE)
                admin_page.get_by_role("menu").get_by_role("menuitem", name=target).click()

            dropdown("Livreur", driver)
            dropdown("Entrepôt", marker)
            result["phase"] = "plan_submit"
            dialog.get_by_role("textbox", name="Adresse de livraison").click()
            admin_page.keyboard.type(marker)
            with admin_page.expect_response(lambda response: "/rpc/plan_order_delivery" in response.url) as planned:
                dialog.get_by_role("button", name="Planifier la livraison").click()
            result["planning_http"] = planned.value.status
            assert planned.value.ok
            admin_page.get_by_text("Livraison planifiée.").first.wait_for()
            admin_page.screenshot(path=out / "delivery_planned.png")
            result["before_handover"] = sql(f"""
            SELECT s.quantity AS stock, d.status AS delivery_status
            FROM public.inventory_stock s JOIN public.deliveries d ON d.warehouse_id=s.warehouse_id
            JOIN public.sales_orders o ON o.id=d.order_id
            WHERE s.product_id='{product}' AND o.customer_id='{customer}'
            """)[0]
            assert result["before_handover"] == {"stock": 3, "delivery_status": "pending"}
            result["phase"] = "driver_login"
            driver_page = new_role_page()
            def track_deliveries(response):
                if "/rest/v1/deliveries?" in response.url:
                    result["driver_deliveries_http"] = response.status
                    if response.ok:
                        assigned = response.json()
                        result["driver_pending_count"] = sum(d["status"] != "delivered" for d in assigned)
                        result["driver_fixture_count"] = sum(
                            delivery["delivery_address"] == marker and delivery["status"] == "pending" for delivery in assigned
                        )

            driver_page.on("response", track_deliveries)
            login_as(driver_page, credentials["LIVREUR_EMAIL"], credentials["LIVREUR_PASSWORD"], "/delivery-tracking")
            result["phase"] = "driver_card"
            driver_page.get_by_role("heading", name=re.compile("Suivi des Livraisons")).wait_for()
            confirm_button = driver_page.get_by_role("button", name=re.compile(r"Confirmer la remise$"))
            confirm_button.first.wait_for()
            assert result.get("driver_fixture_count") == 1 and result.get("driver_pending_count") == 1
            confirm_button.click()
            result["phase"] = "driver_handover"
            with driver_page.expect_response(lambda response: "/rpc/confirm_delivery" in response.url) as handover:
                driver_page.get_by_role("alertdialog").get_by_role("button", name="Confirmer", exact=True).click()
            result["handover_http"] = handover.value.status
            assert handover.value.ok and handover.value.json()["success"] is True
            confirm_button.wait_for(state="hidden")
            driver_page.screenshot(path=out / "delivery_handed_over.png")

        browser.close()
    check = sql(f"""
    SELECT
      (SELECT quantity FROM public.inventory_stock WHERE product_id='{product}' AND warehouse_id='{warehouse}') AS stock,
      (SELECT count(*) FROM public.stock_movements WHERE product_id='{product}') AS movements,
      (SELECT o.total_amount FROM public.sales_orders o WHERE o.customer_id='{customer}') AS total,
      (SELECT o.order_status FROM public.sales_orders o WHERE o.customer_id='{customer}') AS order_status
    """)[0]
    result["database"] = check
    expected = ({"stock": 2, "movements": 2, "total": "6.00", "order_status": "delivered"}
                if args.plan_delivery else {"stock": 3, "movements": 1, "total": "6.00", "order_status": "confirmed"})
    result["passed"] = check == expected
    if args.plan_delivery:
        delivery = sql(f"""
        SELECT d.delivery_address, d.status, d.warehouse_id = '{warehouse}' AS correct_warehouse,
               p.email = 'livreur@loliexpress.test' AS correct_driver,
               (SELECT count(*) FROM public.stock_handovers h WHERE h.delivery_id=d.id AND h.handed_over_by=p.id) AS handovers,
               (SELECT count(*) FROM public.stock_movements m WHERE m.product_id='{product}'
                  AND m.reference_type='customer_handover') AS handover_movements
        FROM public.deliveries d
        JOIN public.sales_orders o ON o.id = d.order_id
        JOIN public.delivery_routes r ON r.id = d.route_id
        JOIN public.user_profiles p ON p.id = r.driver_id
        WHERE o.customer_id = '{customer}'
        """)
        result["delivery"] = delivery
        result["passed"] = result["passed"] and delivery == [
            {"delivery_address": marker, "status": "delivered", "correct_warehouse": True, "correct_driver": True,
             "handovers": 1, "handover_movements": 1}
        ]
except Exception as error:
    result["error"] = type(error).__name__
    (out / "diagnostic.txt").write_text(str(error))
finally:
    try:
        result["cleanup"] = sql(f"""
        BEGIN;
        {claims}
        CREATE TEMP TABLE sales_web_orders AS SELECT id FROM public.sales_orders WHERE customer_id='{customer}';
        CREATE TEMP TABLE sales_web_inventory AS SELECT id FROM public.inventory_stock WHERE product_id='{product}';
        DELETE FROM public.notification_queue WHERE related_entity_type='order'
          AND related_entity_id IN (SELECT id FROM sales_web_orders);
        CREATE TEMP TABLE sales_web_deliveries AS
          SELECT id,route_id FROM public.deliveries WHERE order_id IN (SELECT id FROM sales_web_orders);
        DELETE FROM public.stock_handovers WHERE order_id IN (SELECT id FROM sales_web_orders);
        DELETE FROM public.deliveries WHERE id IN (SELECT id FROM sales_web_deliveries);
        DELETE FROM public.delivery_routes WHERE id IN (SELECT route_id FROM sales_web_deliveries);
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
          OR (table_name='deliveries' AND record_id IN (SELECT id FROM sales_web_deliveries))
          OR (table_name='sales_orders' AND record_id IN (SELECT id FROM sales_web_orders));
        SELECT NOT EXISTS (SELECT FROM public.products WHERE id='{product}')
          AND NOT EXISTS (SELECT FROM public.customers WHERE id='{customer}') AS complete;
        COMMIT;
        """) == [{"complete": True}]
    finally:
        (out / "sales-web.json").write_text(json.dumps(result, indent=2) + "\n")
print(result)
raise SystemExit(int(not result["passed"] or not result["cleanup"]))
