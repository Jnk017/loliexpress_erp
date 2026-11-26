CREATE OR REPLACE FUNCTION public.list_warehouse_purchase_receipts()
RETURNS TABLE (
  purchase_number text,
  purchase_item_id uuid,
  product_name text,
  remaining_quantity integer
)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
BEGIN
  IF public.current_user_role() IS DISTINCT FROM 'warehouse_staff' THEN
    RAISE EXCEPTION 'Warehouse receipt queue denied' USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT p.purchase_number::text, i.id, product.name::text,
         i.quantity - coalesce(i.received_quantity, 0)
    FROM public.purchases p
    JOIN public.purchase_items i ON i.purchase_id = p.id
    JOIN public.products product ON product.id = i.product_id
    WHERE p.status IN ('pending', 'partial')
      AND i.quantity > coalesce(i.received_quantity, 0)
    ORDER BY p.created_at, p.id, i.id;
END;
$function$;
REVOKE ALL ON FUNCTION public.list_warehouse_purchase_receipts() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.list_warehouse_purchase_receipts() TO authenticated;
