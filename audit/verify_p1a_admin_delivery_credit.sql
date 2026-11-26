-- P1.a — exécuter après 009 sur une pile isolée. Cinq lignes passed = true.
BEGIN;
CREATE TEMP TABLE credit_results (scenario text PRIMARY KEY, passed boolean NOT NULL);
DO $verify$
DECLARE
    admin_id uuid := gen_random_uuid();
    accountant_id uuid := gen_random_uuid();
    invoice_id uuid := gen_random_uuid();
    paid_invoice_id uuid := gen_random_uuid();
    request_id uuid := gen_random_uuid();
    denied boolean := false;
    rejected boolean := false;
    credit public.invoice_delivery_fee_credits%ROWTYPE;
    payment jsonb;
BEGIN
    INSERT INTO auth.users(id,email) VALUES
        (admin_id,admin_id::text || '@example.invalid'),
        (accountant_id,accountant_id::text || '@example.invalid');
    UPDATE public.user_profiles SET role = 'admin', is_active = true WHERE id = admin_id;
    UPDATE public.user_profiles SET role = 'comptable', is_active = true WHERE id = accountant_id;
    PERFORM set_config('request.jwt.claim.sub', admin_id::text, true);
    INSERT INTO public.invoices(id,due_date,subtotal,tax_amount,total_amount,amount_paid,
        payment_status,currency,home_delivery,delivery_fee)
    VALUES (invoice_id, now(), 3850,0,4350,0,'pending','CDF',true,500),
           (paid_invoice_id, now(), 3850,0,4350,0,'pending','CDF',true,500);
    PERFORM set_config('request.jwt.claim.sub', accountant_id::text, true);
    BEGIN
        PERFORM public.record_delivery_fee_credit(invoice_id,200,'Test',request_id);
    EXCEPTION WHEN insufficient_privilege THEN denied := true;
    END;
    INSERT INTO credit_results VALUES ('accountant_denied',denied);
    PERFORM set_config('request.jwt.claim.sub', admin_id::text, true);
    credit := public.record_delivery_fee_credit(invoice_id,200,'Retour accepté',request_id);
    INSERT INTO credit_results VALUES ('admin_credit_and_retry',
        credit.approved_by = admin_id
        AND (public.record_delivery_fee_credit(invoice_id,200,'Retour accepté',request_id)).id = credit.id
        AND (SELECT outstanding_amount FROM public.invoice_open_balances b WHERE b.invoice_id = credit.invoice_id) = 4150);
    BEGIN
        PERFORM public.record_delivery_fee_credit(invoice_id,301,'Dépassement',gen_random_uuid());
    EXCEPTION WHEN invalid_parameter_value THEN rejected := true;
    END;
    INSERT INTO credit_results VALUES ('fee_cap',rejected);
    payment := public.record_payment(invoice_id,4350,'CDF','cash');
    rejected := payment->>'success' = 'false';
    payment := public.record_payment(invoice_id,4150,'CDF','cash');
    INSERT INTO credit_results VALUES ('payment_uses_net_amount',
        rejected AND payment->>'success' = 'true'
        AND NOT EXISTS (SELECT 1 FROM public.invoice_open_balances b WHERE b.invoice_id = credit.invoice_id));
    payment := public.record_payment(paid_invoice_id,4350,'CDF','cash');
    credit := public.record_delivery_fee_credit(paid_invoice_id,500,'Retour accepté',gen_random_uuid());
    INSERT INTO credit_results VALUES ('paid_invoice_refund_due',
        payment->>'success' = 'true'
        AND (SELECT refund_due FROM public.invoice_delivery_refunds_due r WHERE r.invoice_id = credit.invoice_id) = 500
        AND (SELECT amount_paid FROM public.invoices i WHERE i.id = credit.invoice_id) = 4350);
END;
$verify$;
SELECT scenario, passed FROM credit_results ORDER BY scenario;
ROLLBACK;
