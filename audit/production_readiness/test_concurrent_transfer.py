"""Exercise concurrent stock transfers across two Gate PostgreSQL sessions."""
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
    product, source, destination = (str(uuid4()) for _ in range(3))
    marker = f"qa-concurrency-{product}"
    result = {
        "scenario": "two_transfers_on_limited_stock",
        "sha": subprocess.check_output(["git", "-C", str(ROOT), "rev-parse", "HEAD"], text=True).strip(),
        "environment": name,
        "passed": False,
        "fixture": {"product": product, "source": source, "destination": destination},
    }

    def sql(query):
        return request(ref, "/database/query", {"query": query})

    claims = """
      SELECT set_config('request.jwt.claim.sub',id::text,true) FROM public.user_profiles
        WHERE email='admin@loliexpress.test' AND role='admin' AND is_active
          AND NOT must_change_password;
    """
    barrier = Barrier(2)

    def transfer():
        barrier.wait(timeout=10)
        return sql(f"""
          BEGIN;
          CREATE TEMP TABLE gate_transfer_result
            (backend integer, started timestamptz, finished timestamptz, status text);
          GRANT SELECT, INSERT ON gate_transfer_result TO authenticated;
          {claims}
          SET LOCAL ROLE authenticated;
          DO $$
          DECLARE started timestamptz := clock_timestamp(); result text;
          BEGIN
            BEGIN
              PERFORM public.transfer_stock('{product}','{source}','{destination}',6,'{marker}');
              result := 'committed';
              PERFORM pg_sleep(3);
            EXCEPTION WHEN numeric_value_out_of_range THEN
              result := 'insufficient_stock';
            END;
            INSERT INTO gate_transfer_result VALUES
              (pg_backend_pid(), started, clock_timestamp(), result);
          END $$;
          SELECT * FROM gate_transfer_result;
          COMMIT;
        """)[0]

    try:
        sql(f"""
          BEGIN;
          {claims}
          INSERT INTO public.products(id,sku,name,unit_price,currency,is_active)
          VALUES ('{product}','{marker}','{marker}',1,'CDF',true);
          INSERT INTO public.warehouse_locations(id,name,is_active) VALUES
            ('{source}','{marker}-source',true), ('{destination}','{marker}-destination',true);
          SET LOCAL ROLE authenticated;
          SELECT public.adjust_stock('{product}','{source}',10,'{marker}');
          COMMIT;
        """)
        with ThreadPoolExecutor(max_workers=2) as pool:
            futures = [pool.submit(transfer) for _ in range(2)]
            workers = [future.result() for future in futures]
        ledger = sql(f"""
          SELECT
            (SELECT quantity FROM public.inventory_stock WHERE product_id='{product}' AND warehouse_id='{source}') AS source,
            (SELECT quantity FROM public.inventory_stock WHERE product_id='{product}' AND warehouse_id='{destination}') AS destination,
            (SELECT count(*) FROM public.stock_movements WHERE product_id='{product}') AS movements,
            (SELECT sum(quantity) FROM public.stock_movements WHERE product_id='{product}') AS ledger_total
        """)[0]
        overlap = max(worker["started"] for worker in workers) < min(worker["finished"] for worker in workers)
        result.update(workers=workers, overlap=overlap, ledger=ledger)
        result["passed"] = (
            overlap and len({worker["backend"] for worker in workers}) == 2
            and sorted(worker["status"] for worker in workers) == ["committed", "insufficient_stock"]
            and ledger == {"source": 4, "destination": 6, "movements": 3, "ledger_total": 10}
        )
    finally:
        try:
            result["cleanup"] = sql(f"""
              BEGIN;
              {claims}
              CREATE TEMP TABLE gate_stock_audit_ids AS SELECT id FROM public.inventory_stock WHERE product_id='{product}';
              DELETE FROM public.stock_movements WHERE product_id='{product}';
              DELETE FROM public.inventory_stock WHERE product_id='{product}';
              DELETE FROM public.products WHERE id='{product}' AND sku='{marker}';
              DELETE FROM public.warehouse_locations WHERE id IN ('{source}','{destination}')
                AND name IN ('{marker}-source','{marker}-destination');
              DELETE FROM public.audit_logs WHERE
                (table_name='products' AND record_id='{product}') OR
                (table_name='inventory_stock' AND record_id IN (SELECT id FROM gate_stock_audit_ids)
                  AND new_values->>'reason'='{marker}');
              SELECT NOT EXISTS (SELECT FROM public.products WHERE id='{product}')
                AND NOT EXISTS (SELECT FROM public.warehouse_locations WHERE id IN ('{source}','{destination}'))
                AND NOT EXISTS (SELECT FROM public.stock_movements WHERE product_id='{product}') AS complete;
              COMMIT;
            """) == [{"complete": True}]
        finally:
            args.evidence.write_text(json.dumps(result, indent=2) + "\n")
    return int(not result["passed"] or not result["cleanup"])


if __name__ == "__main__":
    raise SystemExit(main())
