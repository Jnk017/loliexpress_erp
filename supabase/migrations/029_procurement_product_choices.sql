CREATE OR REPLACE FUNCTION public.list_procurement_product_choices()
RETURNS TABLE (id uuid, name text)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
BEGIN
  IF coalesce(public.current_user_role(), '') NOT IN ('admin', 'acheteur') THEN
    RAISE EXCEPTION 'Procurement product choices denied' USING ERRCODE = '42501';
  END IF;
  RETURN QUERY
  SELECT p.id, p.name::text FROM public.products p
    WHERE p.is_active
    ORDER BY p.name, p.id;
END;
$function$;
REVOKE ALL ON FUNCTION public.list_procurement_product_choices() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.list_procurement_product_choices() TO authenticated;
