-- P1.a — mémoriser un brouillon sans créer une créance ni numéro fiscal.
BEGIN;
CREATE TABLE IF NOT EXISTS public.invoice_drafts (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id uuid NOT NULL REFERENCES public.customers(id),
    created_by uuid NOT NULL REFERENCES public.user_profiles(id),
    currency text NOT NULL CHECK (currency IN ('CDF','USD')),
    payload jsonb NOT NULL CHECK (jsonb_typeof(payload) = 'object'),
    updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.invoice_drafts ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.invoice_drafts FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.invoice_drafts TO authenticated;
DROP POLICY IF EXISTS invoice_drafts_read ON public.invoice_drafts;
CREATE POLICY invoice_drafts_read ON public.invoice_drafts FOR SELECT TO authenticated
USING (public.is_admin() OR public.is_comptable() OR
    (public.is_sales_rep() AND created_by = auth.uid() AND EXISTS (
        SELECT 1 FROM public.customers c
        WHERE c.id = invoice_drafts.customer_id AND c.commercial_id = auth.uid()
    )));

CREATE OR REPLACE FUNCTION public.save_invoice_draft(
    p_draft_id uuid, p_customer_id uuid, p_currency text, p_payload jsonb
)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $draft$
DECLARE
    actor_role text := public.current_user_role();
    draft_id uuid;
BEGIN
    IF actor_role IS NULL OR NOT EXISTS (
        SELECT 1 FROM public.customers c WHERE c.id = p_customer_id AND c.is_active
          AND (actor_role IN ('admin','comptable') OR (actor_role = 'sales_rep' AND c.commercial_id = auth.uid()))
    ) THEN
        RAISE EXCEPTION 'Invoice draft denied' USING ERRCODE = '42501';
    END IF;
    IF p_currency IS NULL OR p_currency NOT IN ('CDF','USD')
        OR jsonb_typeof(p_payload) IS DISTINCT FROM 'object'
        OR jsonb_typeof(p_payload->'items') IS DISTINCT FROM 'array'
        OR octet_length(p_payload::text) > 262144 THEN
        RAISE EXCEPTION 'Invalid invoice draft' USING ERRCODE = '22023';
    END IF;
    IF jsonb_array_length(p_payload->'items') NOT BETWEEN 1 AND 500 THEN
        RAISE EXCEPTION 'Invalid draft item count' USING ERRCODE = '22023';
    END IF;
    IF (p_payload ? 'home_delivery' AND jsonb_typeof(p_payload->'home_delivery') <> 'boolean')
        OR (p_payload ? 'delivery_fee' AND jsonb_typeof(p_payload->'delivery_fee') <> 'number') THEN
        RAISE EXCEPTION 'Invalid draft delivery fields' USING ERRCODE = '22023';
    END IF;
    IF coalesce((p_payload->>'delivery_fee')::numeric,0) NOT BETWEEN 0 AND 9999999999.99
        OR (NOT coalesce((p_payload->>'home_delivery')::boolean,false)
            AND coalesce((p_payload->>'delivery_fee')::numeric,0) <> 0) THEN
        RAISE EXCEPTION 'Invalid draft delivery fee' USING ERRCODE = '22023';
    END IF;
    IF p_draft_id IS NULL THEN
        INSERT INTO public.invoice_drafts(customer_id, created_by, currency, payload)
        VALUES (p_customer_id, auth.uid(), p_currency, p_payload) RETURNING id INTO draft_id;
    ELSE
        UPDATE public.invoice_drafts d
        SET customer_id = p_customer_id, currency = p_currency, payload = p_payload, updated_at = now()
        WHERE d.id = p_draft_id AND (actor_role IN ('admin','comptable') OR
            (d.created_by = auth.uid() AND EXISTS (
                SELECT 1 FROM public.customers c WHERE c.id = d.customer_id AND c.commercial_id = auth.uid()
            )))
        RETURNING id INTO draft_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Invoice draft unavailable' USING ERRCODE = '42501';
        END IF;
    END IF;
    RETURN draft_id;
END;
$draft$;
REVOKE ALL ON FUNCTION public.save_invoice_draft(uuid, uuid, text, jsonb) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.save_invoice_draft(uuid, uuid, text, jsonb) TO authenticated;
COMMIT;
