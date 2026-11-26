"""Check that overlapping payments cannot exceed the invoice net balance."""
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
    customer, invoice, account = (str(uuid4()) for _ in range(3))
    marker = f"qa-payment-{invoice}"
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

    def pay():
        barrier.wait(timeout=10)
        return query(f"""
          BEGIN;
          CREATE TEMP TABLE payment_race(backend integer, started timestamptz, finished timestamptz, confirmed boolean);
          GRANT INSERT, SELECT ON payment_race TO authenticated;
          {claims}
          SET LOCAL ROLE authenticated;
          DO $$
          DECLARE started timestamptz := clock_timestamp(); accepted boolean := false;
          BEGIN
              BEGIN
                PERFORM public.receive_invoice_payment('{invoice}',7,'CDF','{marker}',
                    'cash','{account}','{uuid4()}','cash');
                accepted := true;
                PERFORM pg_sleep(3);
              EXCEPTION WHEN invalid_parameter_value THEN
                IF SQLERRM <> 'Amount exceeds net invoice balance or currency differs' THEN RAISE; END IF;
              END;
              INSERT INTO payment_race VALUES
                (pg_backend_pid(),started,clock_timestamp(),accepted);
          END $$;
          SELECT * FROM payment_race;
          COMMIT;
        """)[0]

    try:
        query(f"""
          BEGIN;
          {claims}
          INSERT INTO public.customers(id,company_name,contact_person,email,phone,is_active)
          VALUES ('{customer}','{marker}','Gate','{customer}@example.invalid','000',true);
          INSERT INTO public.invoices(id,customer_id,due_date,subtotal,tax_amount,total_amount,
              amount_paid,payment_status,currency,exchange_rate)
          VALUES ('{invoice}','{customer}',now()+interval '7 days',10,0,10,0,'pending','CDF',1);
          SELECT public.open_treasury_account('{account}','cash','{marker}',NULL,'CDF',0);
          COMMIT;
        """)
        with ThreadPoolExecutor(max_workers=2) as pool:
            tasks = [pool.submit(pay) for _ in range(2)]
            workers = [task.result() for task in tasks]
        ledger = query(f"""
          SELECT
            (SELECT amount_paid FROM public.invoices WHERE id='{invoice}') AS paid,
            (SELECT count(*) FROM public.payments WHERE invoice_id='{invoice}') AS payments,
            (SELECT count(*) FROM public.operational_treasury_postings WHERE account_id='{account}') AS postings,
            (SELECT current_balance FROM public.cash_registers WHERE id='{account}') AS balance
        """)[0]
        overlap = max(row["started"] for row in workers) < min(row["finished"] for row in workers)
        report.update(workers=workers, ledger=ledger, overlap=overlap)
        report["passed"] = (
            overlap and len({row["backend"] for row in workers}) == 2
            and sorted(row["confirmed"] for row in workers) == [False, True]
            and ledger == {"paid": "7.00", "payments": 1, "postings": 1, "balance": "7.00"}
        )
    finally:
        try:
            report["cleanup"] = query(f"""
              BEGIN;
              {claims}
              CREATE TEMP TABLE gate_payment_ids AS SELECT id FROM public.payments WHERE invoice_id='{invoice}';
              DELETE FROM public.notification_queue WHERE related_entity_type='payment'
                AND related_entity_id IN (SELECT id FROM gate_payment_ids);
              DELETE FROM public.operational_treasury_postings WHERE account_id='{account}';
              DELETE FROM public.cash_movements WHERE cash_register_id='{account}';
              DELETE FROM public.payments WHERE invoice_id='{invoice}';
              DELETE FROM public.invoices WHERE id='{invoice}' AND customer_id='{customer}';
              DELETE FROM public.cash_registers WHERE id='{account}' AND name='{marker}';
              DELETE FROM public.customers WHERE id='{customer}' AND company_name='{marker}';
              DELETE FROM public.audit_logs WHERE
                 (table_name='payments' AND record_id IN (SELECT id FROM gate_payment_ids))
                 OR (table_name='invoices' AND record_id='{invoice}')
                 OR (table_name='cash_registers' AND record_id='{account}')
                 OR (table_name='customers' AND record_id='{customer}');
              SELECT NOT EXISTS (SELECT FROM public.invoices WHERE id='{invoice}')
                AND NOT EXISTS (SELECT FROM public.cash_registers WHERE id='{account}')
                AND NOT EXISTS (SELECT FROM public.customers WHERE id='{customer}') AS complete;
              COMMIT;
            """) == [{"complete": True}]
        finally:
            args.evidence.write_text(json.dumps(report, indent=2) + "\n")
    return int(not report["passed"] or not report["cleanup"])


if __name__ == "__main__":
    raise SystemExit(main())
