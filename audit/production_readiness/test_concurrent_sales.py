"""Check that two sales cannot hand over more than the available stock."""
import argparse
import json
import subprocess
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from threading import Barrier
from uuid import uuid4

from collect_drift import PROJECTS, request
from run_release_gate import ROOT


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--evidence", required=True, type=Path)
    args = parser.parse_args()
    ref, name = PROJECTS["gate"]
    if request(ref)["name"] != name:
        raise RuntimeError("Unexpected Gate project")
    customer, product, warehouse, delivery, second_delivery = (str(uuid4()) for _ in range(5))
    marker = f"qa-sales-race-{delivery}"
    report = {"environment": name, "fixture": marker, "passed": False,
              "sha": subprocess.check_output(["git", "-C", str(ROOT), "rev-parse", "HEAD"], text=True).strip()}
    claims = """
      SELECT set_config('request.jwt.claim.sub',id::text,true)
      FROM public.user_profiles WHERE email='admin@loliexpress.test'
        AND role='admin' AND is_active AND NOT must_change_password;
    """

    def query(sql):
        return request(ref, "/database/query", {"query": sql})

    barrier = Barrier(2)

    def confirm(delivery_id):
        barrier.wait(timeout=10)
        return query(f"""
          BEGIN;
          CREATE TEMP TABLE handover_race(backend integer, started timestamptz, finished timestamptz, confirmed boolean);
          GRANT INSERT, SELECT ON handover_race TO authenticated;
          {claims}
          SET LOCAL ROLE authenticated;
          DO $$
          DECLARE started timestamptz := clock_timestamp(); response jsonb;
          BEGIN
              response := public.confirm_delivery('{delivery_id}');
              IF response->>'success'='true' THEN
                PERFORM pg_sleep(3);
              ELSIF response->>'error' IS DISTINCT FROM 'Insufficient stock in the assigned warehouse' THEN
                RAISE EXCEPTION 'Unexpected handover refusal';
              END IF;
              INSERT INTO handover_race VALUES
                (pg_backend_pid(),started,clock_timestamp(),response->>'success'='true');
          END $$;
          SELECT * FROM handover_race;
          COMMIT;
        """)[0]

    try:
        query(f"""
          BEGIN;
          {claims}
          INSERT INTO public.customers(id,company_name,contact_person,email,phone,is_active)
          VALUES ('{customer}','{marker}','Gate','{customer}@example.invalid','000',true);
          INSERT INTO public.products(id,sku,name,unit_price,currency,is_active)
          VALUES ('{product}','{marker}','{marker}',1,'CDF',true);
          INSERT INTO public.warehouse_locations(id,name,is_active)
          VALUES ('{warehouse}','{marker}',true);
          DO $$
          DECLARE order_row public.sales_orders%ROWTYPE; target uuid;
          BEGIN
            PERFORM public.adjust_stock('{product}','{warehouse}',10,'{marker}');
            FOREACH target IN ARRAY ARRAY['{delivery}'::uuid,'{second_delivery}'::uuid] LOOP
              order_row := public.create_order_with_items('{customer}',
                  jsonb_build_array(jsonb_build_object('product_id','{product}','quantity',6)));
              PERFORM public.transition_order_status(order_row.id,'confirmed');
              PERFORM public.transition_order_status(order_row.id,'processing');
              PERFORM public.transition_order_status(order_row.id,'shipped');
              INSERT INTO public.deliveries(id,order_id,delivery_address,status)
                VALUES (target,order_row.id,'{marker}','pending');
              PERFORM public.assign_delivery_warehouse(target,'{warehouse}');
            END LOOP;
          END $$;
          COMMIT;
        """)
        with ThreadPoolExecutor(max_workers=2) as pool:
            tasks = [pool.submit(confirm, target) for target in (delivery, second_delivery)]
            workers = [task.result() for task in tasks]
        ledger = query(f"""
          SELECT
            (SELECT count(*) FROM public.stock_handovers WHERE delivery_id IN ('{delivery}','{second_delivery}')) AS handovers,
            (SELECT count(*) FROM public.stock_movements WHERE reference_id IN ('{delivery}','{second_delivery}')
             AND reference_type='customer_handover' AND quantity=6) AS exits,
            (SELECT quantity FROM public.inventory_stock WHERE product_id='{product}'
               AND warehouse_id='{warehouse}') AS final_stock,
            (SELECT count(*) FROM public.sales_orders WHERE customer_id='{customer}' AND order_status='delivered') AS delivered,
            (SELECT count(*) FROM public.sales_orders WHERE customer_id='{customer}' AND order_status='shipped') AS shipped
        """)[0]
        overlap = max(row["started"] for row in workers) < min(row["finished"] for row in workers)
        report.update(workers=workers, ledger=ledger, overlap=overlap)
        report["passed"] = (
            overlap and len({row["backend"] for row in workers}) == 2
            and sorted(row["confirmed"] for row in workers) == [False, True]
            and ledger == {"handovers": 1, "exits": 1, "final_stock": 4, "delivered": 1, "shipped": 1}
        )
    finally:
        try:
            report["cleanup"] = query(f"""
              BEGIN;
              {claims}
              CREATE TEMP TABLE handover_order_ids AS
                SELECT id FROM public.sales_orders WHERE customer_id='{customer}';
              CREATE TEMP TABLE handover_stock_ids AS
                SELECT id FROM public.inventory_stock WHERE product_id='{product}';
              DELETE FROM public.stock_handovers WHERE delivery_id IN ('{delivery}','{second_delivery}');
              DELETE FROM public.stock_movements WHERE product_id='{product}';
              DELETE FROM public.inventory_stock WHERE product_id='{product}';
              DELETE FROM public.notification_queue WHERE related_entity_type='order'
                AND related_entity_id IN (SELECT id FROM handover_order_ids);
              DELETE FROM public.sales_orders WHERE id IN (SELECT id FROM handover_order_ids);
              DELETE FROM public.customers WHERE id='{customer}' AND company_name='{marker}';
              DELETE FROM public.products WHERE id='{product}' AND sku='{marker}';
              DELETE FROM public.warehouse_locations WHERE id='{warehouse}' AND name='{marker}';
              DELETE FROM public.audit_logs WHERE
                 (table_name='sales_orders' AND record_id IN (SELECT id FROM handover_order_ids))
                 OR (table_name='inventory_stock' AND record_id IN (SELECT id FROM handover_stock_ids))
                 OR (table_name='customers' AND record_id='{customer}')
                 OR (table_name='products' AND record_id='{product}')
                 OR (table_name='deliveries' AND record_id IN ('{delivery}','{second_delivery}'));
              SELECT NOT EXISTS (SELECT FROM public.customers WHERE id='{customer}')
                AND NOT EXISTS (SELECT FROM public.products WHERE id='{product}')
                AND NOT EXISTS (SELECT FROM public.deliveries WHERE id IN ('{delivery}','{second_delivery}'))
                AND NOT EXISTS (SELECT FROM public.warehouse_locations WHERE id='{warehouse}') AS complete;
              COMMIT;
            """) == [{"complete": True}]
        finally:
            args.evidence.write_text(json.dumps(report, indent=2) + "\n")
    return int(not report["passed"] or not report["cleanup"])


if __name__ == "__main__":
    raise SystemExit(main())
