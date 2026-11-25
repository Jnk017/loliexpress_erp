-- ProductService selects named catalogue fields. Cost accounting remains server-side.
REVOKE SELECT, TRUNCATE, TRIGGER ON public.products FROM PUBLIC, anon, authenticated;
GRANT SELECT (id, sku, name, description, category_id, unit_price, image_url,
    barcode, is_active, created_at, updated_at, currency)
ON public.products TO authenticated;
