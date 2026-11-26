-- DoD P0.b : vérifier la persistance avant et après changement de session.
BEGIN;
CREATE TEMP TABLE settings_checks(scenario text PRIMARY KEY, passed boolean NOT NULL);
DO $verify$
DECLARE
    admin_id uuid := gen_random_uuid();
    reader_id uuid := gen_random_uuid();
    b2b_id uuid := gen_random_uuid();
    persisted public.company_settings%ROWTYPE;
    denied boolean := false;
    invoice_row public.invoices%ROWTYPE;
BEGIN
    INSERT INTO auth.users(id,email) VALUES
        (admin_id,admin_id::text||'@example.invalid'),
        (reader_id,reader_id::text||'@example.invalid'),
        (b2b_id,b2b_id::text||'@example.invalid');
    UPDATE public.user_profiles SET role = 'admin', is_active = true WHERE id = admin_id;
    UPDATE public.user_profiles SET role = 'comptable', is_active = true WHERE id = reader_id;
    PERFORM set_config('request.jwt.claim.sub',admin_id::text,true);
    PERFORM public.update_company_settings('{
        "company_name":"Société fixture","company_address":"Adresse fixture","company_phone":"000",
        "default_currency":"USD","tax_rate":0,"tax_identifier":"ID-FIXTURE",
        "pdf_title":"Facture fixture","pdf_footer":"Pied fixture",
        "sender_name":"Facturation fixture","sender_email":"facturation@example.invalid"
    }'::jsonb);
    PERFORM set_config('request.jwt.claim.sub','',true);
    PERFORM set_config('request.jwt.claim.sub',reader_id::text,true);
    persisted := public.get_company_settings();
    INSERT INTO settings_checks VALUES ('reload_company_settings_after_session_change',
        persisted.company_name = 'Société fixture' AND persisted.company_address = 'Adresse fixture'
        AND persisted.company_phone = '000' AND persisted.updated_by = admin_id
        AND persisted.default_currency = 'USD' AND persisted.tax_rate = 0
        AND persisted.tax_identifier = 'ID-FIXTURE' AND persisted.pdf_title = 'Facture fixture'
        AND persisted.pdf_footer = 'Pied fixture' AND persisted.sender_name = 'Facturation fixture'
        AND persisted.sender_email = 'facturation@example.invalid');
    BEGIN
        PERFORM public.update_company_settings('{"default_currency":"CDF"}');
    EXCEPTION WHEN insufficient_privilege THEN denied := true;
    END;
    INSERT INTO settings_checks VALUES ('reader_cannot_change_settings',denied);
    denied := false;
    PERFORM set_config('request.jwt.claim.sub',b2b_id::text,true);
    BEGIN
        PERFORM public.get_company_settings();
    EXCEPTION WHEN insufficient_privilege THEN denied := true;
    END;
    INSERT INTO settings_checks VALUES ('client_cannot_read_internal_settings',denied);
    denied := false;
    PERFORM set_config('request.jwt.claim.sub',admin_id::text,true);
    BEGIN
        PERFORM public.update_company_settings('{"tax_rate":20}');
    EXCEPTION WHEN invalid_parameter_value THEN denied := true;
    END;
    INSERT INTO settings_checks VALUES ('nonzero_tax_refused',denied);
    INSERT INTO public.invoices(due_date,subtotal,total_amount,currency)
    VALUES (now(),100,100,'CDF') RETURNING * INTO invoice_row;
    PERFORM public.update_company_settings('{"pdf_title":"Nouveau modèle"}');
    INSERT INTO settings_checks VALUES ('issued_pdf_keeps_persisted_template',
        (SELECT company_presentation->>'pdf_title' FROM public.invoices WHERE id = invoice_row.id) = 'Facture fixture'
        AND (public.get_company_settings()).pdf_title = 'Nouveau modèle');
END;
$verify$;
SELECT scenario,passed FROM settings_checks ORDER BY scenario;
ROLLBACK;
