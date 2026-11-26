-- P0.b — configuration persistante de la société et de ses documents.
BEGIN;
CREATE TABLE IF NOT EXISTS public.company_settings (
    singleton boolean PRIMARY KEY DEFAULT true CHECK (singleton),
    company_name text,
    company_address text,
    company_phone text,
    tax_identifier text,
    default_currency text NOT NULL DEFAULT 'CDF' CHECK (default_currency IN ('CDF','USD')),
    tax_rate numeric(5,2) NOT NULL DEFAULT 0 CHECK (tax_rate = 0),
    pdf_title text NOT NULL DEFAULT 'FACTURE' CHECK (length(btrim(pdf_title)) BETWEEN 1 AND 100),
    pdf_footer text,
    sender_name text,
    sender_email text CHECK (sender_email IS NULL OR sender_email ~ '^[^ @<>]+@[^ @<>]+\.[^ @<>]+$'),
    updated_at timestamptz NOT NULL DEFAULT now(),
    updated_by uuid REFERENCES public.user_profiles(id)
);
INSERT INTO public.company_settings(singleton) VALUES (true) ON CONFLICT DO NOTHING;
ALTER TABLE public.company_settings ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.company_settings FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.get_company_settings()
RETURNS public.company_settings LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $settings$
DECLARE
    settings public.company_settings%ROWTYPE;
BEGIN
    IF coalesce(public.current_user_role(),'') NOT IN
        ('admin','sales_rep','warehouse_staff','comptable','acheteur','delivery_agent') THEN
        RAISE EXCEPTION 'Company settings unavailable' USING ERRCODE = '42501';
    END IF;
    SELECT * INTO STRICT settings FROM public.company_settings WHERE singleton;
    RETURN settings;
END;
$settings$;

CREATE OR REPLACE FUNCTION public.update_company_settings(p_patch jsonb)
RETURNS public.company_settings LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $settings$
DECLARE
    settings public.company_settings%ROWTYPE;
BEGIN
    IF NOT public.is_admin() THEN
        RAISE EXCEPTION 'Company settings modification denied' USING ERRCODE = '42501';
    END IF;
    IF jsonb_typeof(p_patch) IS DISTINCT FROM 'object' OR p_patch = '{}'::jsonb
        OR octet_length(p_patch::text) > 12000 THEN
        RAISE EXCEPTION 'Invalid settings patch' USING ERRCODE = '22023';
    END IF;
    IF EXISTS (
        SELECT 1 FROM jsonb_each(p_patch) e
        WHERE e.key NOT IN ('company_name','company_address','company_phone','tax_identifier',
            'default_currency','tax_rate','pdf_title','pdf_footer','sender_name','sender_email')
            OR (e.key = 'tax_rate' AND e.value IS DISTINCT FROM '0'::jsonb)
            OR (e.key <> 'tax_rate' AND jsonb_typeof(e.value) NOT IN ('string','null'))
            OR length(e.value::text) > 2000
    ) THEN
        RAISE EXCEPTION 'Unsupported settings value' USING ERRCODE = '22023';
    END IF;
    UPDATE public.company_settings s SET
        company_name = CASE WHEN p_patch ? 'company_name' THEN nullif(btrim(p_patch->>'company_name'),'') ELSE s.company_name END,
        company_address = CASE WHEN p_patch ? 'company_address' THEN nullif(btrim(p_patch->>'company_address'),'') ELSE s.company_address END,
        company_phone = CASE WHEN p_patch ? 'company_phone' THEN nullif(btrim(p_patch->>'company_phone'),'') ELSE s.company_phone END,
        tax_identifier = CASE WHEN p_patch ? 'tax_identifier' THEN nullif(btrim(p_patch->>'tax_identifier'),'') ELSE s.tax_identifier END,
        default_currency = CASE WHEN p_patch ? 'default_currency' THEN p_patch->>'default_currency' ELSE s.default_currency END,
        tax_rate = 0,
        pdf_title = CASE WHEN p_patch ? 'pdf_title' THEN btrim(p_patch->>'pdf_title') ELSE s.pdf_title END,
        pdf_footer = CASE WHEN p_patch ? 'pdf_footer' THEN nullif(btrim(p_patch->>'pdf_footer'),'') ELSE s.pdf_footer END,
        sender_name = CASE WHEN p_patch ? 'sender_name' THEN nullif(btrim(p_patch->>'sender_name'),'') ELSE s.sender_name END,
        sender_email = CASE WHEN p_patch ? 'sender_email' THEN nullif(btrim(p_patch->>'sender_email'),'') ELSE s.sender_email END,
        updated_at = now(),
        updated_by = auth.uid()
    WHERE singleton RETURNING * INTO STRICT settings;
    RETURN settings;
END;
$settings$;
REVOKE ALL ON FUNCTION public.get_company_settings(),public.update_company_settings(jsonb) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_company_settings(),public.update_company_settings(jsonb) TO authenticated;

ALTER TABLE public.invoices ADD COLUMN IF NOT EXISTS company_presentation jsonb;
CREATE OR REPLACE FUNCTION public.snapshot_invoice_company_presentation()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $presentation$
BEGIN
    SELECT jsonb_build_object('company_name',company_name,'company_address',company_address,
        'company_phone',company_phone,'tax_identifier',tax_identifier,'pdf_title',pdf_title,'pdf_footer',pdf_footer)
    INTO NEW.company_presentation FROM public.company_settings WHERE singleton;
    RETURN NEW;
END;
$presentation$;
DROP TRIGGER IF EXISTS snapshot_invoice_company_presentation ON public.invoices;
CREATE TRIGGER snapshot_invoice_company_presentation BEFORE INSERT ON public.invoices
FOR EACH ROW EXECUTE FUNCTION public.snapshot_invoice_company_presentation();
REVOKE ALL ON FUNCTION public.snapshot_invoice_company_presentation() FROM PUBLIC, anon, authenticated;
COMMIT;
