-- P0.a — réconciliation de create_order_with_items et tarifs client.
BEGIN;

CREATE TABLE IF NOT EXISTS public.customer_product_prices (
    customer_id uuid NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
    product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    unit_price numeric(10,2) NOT NULL CHECK (unit_price >= 0 AND unit_price <> 'NaN'::numeric),
    currency text NOT NULL CHECK (currency IN ('CDF', 'USD')),
    updated_by uuid REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    updated_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (customer_id, product_id)
);
ALTER TABLE public.customer_product_prices ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.customer_product_prices FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.set_customer_product_price(
    p_customer_id uuid, p_product_id uuid, p_unit_price numeric, p_currency text
)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $fn$
BEGIN
    IF public.current_user_role() IS DISTINCT FROM 'admin' THEN
        RAISE EXCEPTION 'Only administrators can set customer prices' USING ERRCODE = '42501';
    END IF;
    IF p_unit_price IS NULL THEN
        DELETE FROM public.customer_product_prices
        WHERE customer_id = p_customer_id AND product_id = p_product_id;
    ELSE
        IF p_unit_price < 0 OR p_unit_price::text IN ('NaN', 'Infinity', '-Infinity') THEN
            RAISE EXCEPTION 'Invalid customer price' USING ERRCODE = '22023';
        END IF;
        INSERT INTO public.customer_product_prices
            (customer_id, product_id, unit_price, currency, updated_by)
        VALUES (p_customer_id, p_product_id, p_unit_price, p_currency, auth.uid())
        ON CONFLICT (customer_id, product_id) DO UPDATE SET
            unit_price = EXCLUDED.unit_price, currency = EXCLUDED.currency,
            updated_by = EXCLUDED.updated_by, updated_at = now();
    END IF;
    INSERT INTO public.audit_logs(table_name, record_id, action_type, new_values, user_id)
    VALUES ('customer_product_prices', p_customer_id, 'update',
        jsonb_build_object('product_id', p_product_id, 'unit_price', p_unit_price,
            'currency', p_currency), auth.uid());
END;
$fn$;

CREATE OR REPLACE FUNCTION public.order_unit_price(
    p_customer_id uuid, p_product_id uuid, p_currency text
)
RETURNS numeric
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $fn$
DECLARE
    actor_role text := public.current_user_role();
    price numeric;
    price_currency text;
    usd_cdf_rate numeric;
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.customers c WHERE c.id = p_customer_id AND c.is_active
          AND (actor_role = 'admin'
            OR (actor_role = 'sales_rep' AND c.commercial_id = auth.uid())
            OR (actor_role = 'b2b_customer' AND c.user_id = auth.uid()))
    ) THEN
        RAISE EXCEPTION 'Customer unavailable for this actor' USING ERRCODE = '42501';
    END IF;
    SELECT coalesce(cp.unit_price, p.unit_price), coalesce(cp.currency, p.currency)
    INTO price, price_currency
    FROM public.products p
    LEFT JOIN public.customer_product_prices cp
      ON cp.product_id = p.id AND cp.customer_id = p_customer_id
    WHERE p.id = p_product_id AND p.is_active;
    IF NOT FOUND OR price IS NULL OR price < 0 OR price::text = 'NaN'
        OR price_currency IS NULL OR price_currency NOT IN ('CDF', 'USD')
        OR p_currency IS NULL OR p_currency NOT IN ('CDF', 'USD') THEN
        RAISE EXCEPTION 'Product price unavailable' USING ERRCODE = '22023';
    END IF;
    IF price_currency = p_currency THEN
        RETURN price;
    END IF;
    SELECT rate INTO usd_cdf_rate FROM public.exchange_rates
    WHERE currency_pair = 'USD/CDF' AND effective_at <= now()
      AND rate > 0 AND rate::text NOT IN ('NaN', 'Infinity', '-Infinity');
    IF usd_cdf_rate IS NULL THEN
        RAISE EXCEPTION 'No configured USD/CDF rate' USING ERRCODE = '22023';
    END IF;
    RETURN round(CASE WHEN p_currency = 'USD'
        THEN price / usd_cdf_rate ELSE price * usd_cdf_rate END, 2);
END;
$fn$;

CREATE OR REPLACE FUNCTION public.notify_new_order()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
DECLARE
    depot_users UUID[];
    depot_user UUID;
BEGIN
    -- Get all depot/warehouse staff users
    SELECT COALESCE(ARRAY_AGG(id), ARRAY[]::uuid[]) INTO depot_users
    FROM public.user_profiles
    WHERE role = 'warehouse_staff' AND is_active;
    
    -- Create notification for each depot user
    FOREACH depot_user IN ARRAY depot_users
    LOOP
        INSERT INTO public.notification_queue (
            notification_type,
            recipient_id,
            recipient_email,
            channel,
            subject,
            message,
            related_entity_type,
            related_entity_id
        )
        SELECT
            'new_order'::public.notification_type,
            depot_user,
            up.email,
            'both'::public.notification_channel,
            'Nouvelle commande à préparer',
            'Nouvelle commande #' || NEW.id::TEXT || ' reçue. À préparer.',
            'sales_order',
            NEW.id
        FROM public.user_profiles up
        WHERE up.id = depot_user;
    END LOOP;
    
    RETURN NEW;
END;
$function$;

-- Remove the legacy overload so PostgREST resolves the intended contract.
DROP FUNCTION IF EXISTS public.create_order_with_items(uuid, jsonb, text);
CREATE OR REPLACE FUNCTION public.create_order_with_items(
    p_customer_id uuid, p_items jsonb, p_notes text DEFAULT NULL,
    p_currency text DEFAULT 'CDF', p_exchange_rate numeric DEFAULT NULL,
    p_payment_type text DEFAULT 'cash', p_discount numeric DEFAULT 0
)
RETURNS public.sales_orders
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $fn$
DECLARE
    actor uuid := auth.uid();
    actor_role text := public.current_user_role();
    order_row public.sales_orders%ROWTYPE;
    item jsonb;
    priced_items jsonb := '[]'::jsonb;
    product_id uuid;
    quantity integer;
    unit_price numeric;
    subtotal numeric := 0;
    discount numeric := round(coalesce(p_discount, 0), 2);
    usd_cdf_rate numeric;
BEGIN
    IF actor_role IS NULL OR actor_role NOT IN ('admin', 'sales_rep', 'b2b_customer') THEN
        RAISE EXCEPTION 'Order creation denied' USING ERRCODE = '42501';
    END IF;
    IF discount < 0 OR discount::text IN ('NaN', 'Infinity', '-Infinity') THEN
        RAISE EXCEPTION 'Invalid discount' USING ERRCODE = '22023';
    END IF;
    IF actor_role <> 'admin' AND coalesce(p_discount, 0) <> 0 THEN
        RAISE EXCEPTION 'Only administrators can grant discounts' USING ERRCODE = '42501';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM public.customers c
        WHERE c.id = p_customer_id AND c.is_active
          AND (actor_role = 'admin'
            OR (actor_role = 'sales_rep' AND c.commercial_id = actor)
            OR (actor_role = 'b2b_customer' AND c.user_id = actor))
    ) THEN
        RAISE EXCEPTION 'Customer unavailable for this actor' USING ERRCODE = '42501';
    END IF;
    IF p_currency IS NULL OR p_currency NOT IN ('CDF', 'USD')
        OR p_payment_type IS NULL OR p_payment_type NOT IN ('cash', 'credit') THEN
        RAISE EXCEPTION 'Invalid currency or payment type' USING ERRCODE = '22023';
    END IF;
    IF jsonb_typeof(p_items) IS DISTINCT FROM 'array' THEN
        RAISE EXCEPTION 'Expected an array of order items' USING ERRCODE = '22023';
    END IF;
    IF jsonb_array_length(p_items) NOT BETWEEN 1 AND 500 THEN
        RAISE EXCEPTION 'Expected 1 to 500 order items' USING ERRCODE = '22023';
    END IF;
    SELECT rate INTO usd_cdf_rate FROM public.exchange_rates
    WHERE currency_pair = 'USD/CDF' AND effective_at <= now()
      AND rate > 0 AND rate::text NOT IN ('NaN', 'Infinity', '-Infinity');
    IF p_currency = 'USD' AND
        (usd_cdf_rate IS NULL OR (p_exchange_rate IS NOT NULL AND
           (p_exchange_rate::text IN ('NaN', 'Infinity', '-Infinity')
           OR abs(p_exchange_rate - usd_cdf_rate) > greatest(0.0001, usd_cdf_rate * 0.001)))) THEN
        RAISE EXCEPTION 'Missing or stale USD/CDF rate' USING ERRCODE = '22023';
    END IF;
    FOR item IN SELECT value FROM jsonb_array_elements(p_items)
    LOOP
        product_id := (item->>'product_id')::uuid;
        quantity := (item->>'quantity')::integer;
        IF quantity IS NULL OR quantity NOT BETWEEN 1 AND 100000 THEN
            RAISE EXCEPTION 'Invalid item quantity' USING ERRCODE = '22023';
        END IF;
        unit_price := public.order_unit_price(p_customer_id, product_id, p_currency);
        IF item ? 'unit_price'
            AND (item->>'unit_price')::numeric IS DISTINCT FROM unit_price THEN
            RAISE EXCEPTION 'Quoted price has changed' USING ERRCODE = '22023';
        END IF;
        subtotal := subtotal + round(unit_price * quantity, 2);
        priced_items := priced_items || jsonb_build_array(jsonb_build_object(
            'product_id', product_id, 'quantity', quantity, 'unit_price', unit_price));
    END LOOP;
    IF discount > subtotal THEN
        RAISE EXCEPTION 'Discount exceeds subtotal' USING ERRCODE = '22023';
    END IF;
    INSERT INTO public.sales_orders (
        order_number, customer_id, sales_rep_id, subtotal, tax_amount, discount_amount,
        total_amount, order_status, payment_status, notes, currency, exchange_rate, payment_type
    ) VALUES (
        public.generate_order_number(), p_customer_id,
        CASE WHEN actor_role = 'b2b_customer' THEN NULL ELSE actor END,
        subtotal, 0, discount, subtotal - discount, 'pending', 'pending', p_notes,
        p_currency, CASE WHEN p_currency = 'USD' THEN usd_cdf_rate ELSE 1 END, p_payment_type
    ) RETURNING * INTO order_row;
    INSERT INTO public.order_items(order_id, product_id, quantity, unit_price, discount_percent, line_total)
    SELECT order_row.id, line.product_id, line.quantity, line.unit_price, 0,
        round(line.quantity * line.unit_price, 2)
    FROM jsonb_to_recordset(priced_items) AS line(product_id uuid, quantity integer, unit_price numeric);
    SELECT * INTO STRICT order_row FROM public.sales_orders WHERE id = order_row.id;
    RETURN order_row;
END;
$fn$;

REVOKE INSERT, UPDATE, DELETE ON public.sales_orders, public.order_items FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.set_customer_product_price(uuid, uuid, numeric, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.set_customer_product_price(uuid, uuid, numeric, text) TO authenticated;
REVOKE ALL ON FUNCTION public.order_unit_price(uuid, uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.order_unit_price(uuid, uuid, text) TO authenticated;
REVOKE ALL ON FUNCTION public.create_order_with_items(uuid, jsonb, text, text, numeric, text, numeric) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_order_with_items(uuid, jsonb, text, text, numeric, text, numeric) TO authenticated;
COMMIT;
