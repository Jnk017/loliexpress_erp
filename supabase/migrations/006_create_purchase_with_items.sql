-- P1.a — création atomique d'un achat et de ses lignes.
BEGIN;
CREATE OR REPLACE FUNCTION public.create_purchase_with_items(
    p_supplier_id uuid, p_items jsonb, p_currency text, p_exchange_rate numeric, p_notes text DEFAULT NULL
)
RETURNS public.purchases
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $purchase$
DECLARE
    purchase_row public.purchases%ROWTYPE;
    item record;
    total numeric := 0;
    rate numeric := 1;
BEGIN
    IF coalesce(public.current_user_role(), '') NOT IN ('admin', 'acheteur') THEN
        RAISE EXCEPTION 'Purchase creation denied' USING ERRCODE = '42501';
    END IF;
    IF jsonb_typeof(p_items) IS DISTINCT FROM 'array' OR p_currency IS NULL
       OR p_currency NOT IN ('CDF', 'USD') THEN
        RAISE EXCEPTION 'Invalid purchase data' USING ERRCODE = '22023';
    END IF;
    IF jsonb_array_length(p_items) NOT BETWEEN 1 AND 500 THEN
        RAISE EXCEPTION 'Invalid purchase item count' USING ERRCODE = '22023';
    END IF;
    IF p_currency = 'USD' THEN
        SELECT e.rate INTO rate FROM public.exchange_rates e
        WHERE e.currency_pair = 'USD/CDF' AND e.effective_at <= now() AND e.rate > 0
          AND e.rate::text NOT IN ('NaN', 'Infinity', '-Infinity');
        IF rate IS NULL OR (p_exchange_rate IS NOT NULL AND
            (p_exchange_rate::text IN ('NaN', 'Infinity', '-Infinity')
             OR abs(rate - p_exchange_rate) > greatest(0.0001, rate * 0.001))) THEN
            RAISE EXCEPTION 'Missing or stale USD/CDF rate' USING ERRCODE = '22023';
        END IF;
    END IF;
    FOR item IN SELECT * FROM jsonb_to_recordset(p_items)
        AS x(product_id uuid, quantity integer, unit_cost numeric)
    LOOP
        IF item.product_id IS NULL OR item.quantity IS NULL OR item.quantity < 1
            OR item.unit_cost IS NULL OR item.unit_cost < 0
            OR item.unit_cost::text IN ('NaN', 'Infinity', '-Infinity') THEN
            RAISE EXCEPTION 'Invalid purchase item' USING ERRCODE = '22023';
        END IF;
        total := total + round(round(item.unit_cost, 2) * item.quantity, 2);
    END LOOP;
    INSERT INTO public.purchases(supplier_id, total_amount, currency, exchange_rate, status,
        payment_status, created_by, notes)
    VALUES (p_supplier_id, total, p_currency, rate, 'pending', 'pending', auth.uid(), p_notes)
    RETURNING * INTO purchase_row;
    INSERT INTO public.purchase_items(purchase_id, product_id, quantity, unit_cost, total_cost)
    SELECT purchase_row.id, x.product_id, x.quantity, round(x.unit_cost, 2),
        round(round(x.unit_cost, 2) * x.quantity, 2)
    FROM jsonb_to_recordset(p_items) AS x(product_id uuid, quantity integer, unit_cost numeric);
    RETURN purchase_row;
END;
$purchase$;
REVOKE ALL ON FUNCTION public.create_purchase_with_items(uuid, jsonb, text, numeric, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_purchase_with_items(uuid, jsonb, text, numeric, text) TO authenticated;
REVOKE INSERT ON public.purchases, public.purchase_items FROM PUBLIC, anon, authenticated;
COMMIT;
