"""Check that overlapping retries of one purchase receipt post stock once."""
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
    supplier, product, warehouse, receipt = (str(uuid4()) for _ in range(4))
    marker = f"qa-receipt-{receipt}"
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

    def receive():
        barrier.wait(timeout=10)
        return query(f"""
          BEGIN;
          CREATE TEMP TABLE receipt_race(backend integer, started timestamptz, finished timestamptz, confirmed boolean);
          GRANT INSERT, SELECT ON receipt_race TO authenticated;
          {claims}
          SET LOCAL ROLE authenticated;
          DO $$
          DECLARE started timestamptz := clock_timestamp(); entry public.purchase_receipts;
          BEGIN
              entry := public.receive_purchase_item('{item_id}','{warehouse}',2,'{receipt}');
              PERFORM pg_sleep(3);
              INSERT INTO receipt_race VALUES
                (pg_backend_pid(),started,clock_timestamp(),entry.id='{receipt}');
          END $$;
          SELECT * FROM receipt_race;
          COMMIT;
        """)[0]

    try:
        item_id = query(f"""
          BEGIN;
          {claims}
          INSERT INTO public.suppliers(id,company_name,is_active)
          VALUES ('{supplier}','{marker}',true);
          INSERT INTO public.products(id,sku,name,unit_price,currency,is_active)
          VALUES ('{product}','{marker}','{marker}',1,'CDF',true);
          INSERT INTO public.warehouse_locations(id,name,is_active)
          VALUES ('{warehouse}','{marker}',true);
          SELECT public.create_purchase_with_items('{supplier}',
            jsonb_build_array(jsonb_build_object('product_id','{product}','quantity',2,'unit_cost',1)),
            'CDF',1,NULL);
          SELECT id FROM public.purchase_items WHERE product_id='{product}';
          COMMIT;
        """)[0]["id"]
        with ThreadPoolExecutor(max_workers=2) as pool:
            tasks = [pool.submit(receive) for _ in range(2)]
            workers = [task.result() for task in tasks]
        ledger = query(f"""
          SELECT
            (SELECT count(*) FROM public.purchase_receipts WHERE id='{receipt}') AS receipts,
            (SELECT count(*) FROM public.stock_movements WHERE reference_id='{receipt}'
             AND reference_type='purchase_receipt' AND quantity=2) AS entries,
            (SELECT quantity FROM public.inventory_stock WHERE product_id='{product}'
               AND warehouse_id='{warehouse}') AS final_stock,
            (SELECT status FROM public.purchases WHERE supplier_id='{supplier}') AS purchase_status
        """)[0]
        overlap = max(row["started"] for row in workers) < min(row["finished"] for row in workers)
        report.update(workers=workers, ledger=ledger, overlap=overlap)
        report["passed"] = (
            overlap and len({row["backend"] for row in workers}) == 2
            and all(row["confirmed"] for row in workers)
            and ledger == {"receipts": 1, "entries": 1, "final_stock": 2, "purchase_status": "received"}
        )
    finally:
        try:
            report["cleanup"] = query(f"""
              BEGIN;
              {claims}
              DELETE FROM public.purchase_receipts WHERE id='{receipt}';
              DELETE FROM public.stock_movements WHERE product_id='{product}';
              DELETE FROM public.inventory_stock WHERE product_id='{product}';
              DELETE FROM public.purchases WHERE supplier_id='{supplier}';
              DELETE FROM public.suppliers WHERE id='{supplier}' AND company_name='{marker}';
              DELETE FROM public.products WHERE id='{product}' AND sku='{marker}';
              DELETE FROM public.warehouse_locations WHERE id='{warehouse}' AND name='{marker}';
              DELETE FROM public.audit_logs WHERE
                 (table_name='products' AND record_id='{product}')
                 OR (table_name='purchase_receipts' AND record_id='{receipt}');
              SELECT NOT EXISTS (SELECT FROM public.suppliers WHERE id='{supplier}')
                AND NOT EXISTS (SELECT FROM public.products WHERE id='{product}')
                AND NOT EXISTS (SELECT FROM public.purchase_receipts WHERE id='{receipt}')
                AND NOT EXISTS (SELECT FROM public.warehouse_locations WHERE id='{warehouse}') AS complete;
              COMMIT;
            """) == [{"complete": True}]
        finally:
            args.evidence.write_text(json.dumps(report, indent=2) + "\n")
    return int(not report["passed"] or not report["cleanup"])


if __name__ == "__main__":
    raise SystemExit(main())
