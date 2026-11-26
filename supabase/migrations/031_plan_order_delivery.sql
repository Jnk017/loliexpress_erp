CREATE OR REPLACE FUNCTION public.plan_order_delivery(
  p_order_id uuid, p_driver_id uuid, p_warehouse_id uuid, p_address text, p_route_date date
)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  locked_order public.sales_orders;
  existing_delivery public.deliveries;
  created_route_id uuid;
  created_delivery_id uuid;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Delivery planning denied' USING ERRCODE = '42501';
  END IF;
  IF p_route_date IS NULL OR coalesce(length(btrim(p_address)), 0) NOT BETWEEN 1 AND 500 THEN
    RAISE EXCEPTION 'Address and route date required' USING ERRCODE = '22023';
  END IF;

  SELECT * INTO locked_order FROM public.sales_orders WHERE id=p_order_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Order unavailable' USING ERRCODE = '22023';
  END IF;
  SELECT * INTO existing_delivery FROM public.deliveries WHERE order_id=p_order_id ORDER BY id LIMIT 1;
  IF FOUND THEN
    IF existing_delivery.warehouse_id = p_warehouse_id
       AND existing_delivery.delivery_address = btrim(p_address)
       AND (SELECT count(*) FROM public.deliveries WHERE order_id=p_order_id) = 1
       AND EXISTS (
         SELECT FROM public.delivery_routes WHERE id=existing_delivery.route_id
           AND driver_id=p_driver_id AND route_date=p_route_date
       ) THEN
      RETURN existing_delivery.id;
    END IF;
    RAISE EXCEPTION 'Order already has a delivery plan' USING ERRCODE = '22023';
  END IF;
  IF locked_order.order_status IS DISTINCT FROM 'shipped'
     OR NOT EXISTS (
       SELECT FROM public.user_profiles WHERE id=p_driver_id
         AND role='delivery_agent' AND is_active AND NOT must_change_password
     )
     OR NOT EXISTS (SELECT FROM public.warehouse_locations WHERE id=p_warehouse_id AND is_active) THEN
    RAISE EXCEPTION 'Shipped order, active driver and active warehouse required' USING ERRCODE = '22023';
  END IF;
  INSERT INTO public.delivery_routes(route_name,driver_id,route_date,status)
    VALUES ('Commande ' || locked_order.order_number,p_driver_id,p_route_date,'pending')
    RETURNING id INTO created_route_id;
  INSERT INTO public.deliveries(order_id,route_id,warehouse_id,delivery_address,status)
    VALUES (p_order_id,created_route_id,p_warehouse_id,btrim(p_address),'pending')
    RETURNING id INTO created_delivery_id;
  INSERT INTO public.audit_logs(table_name,record_id,action_type,user_id,new_values)
    VALUES ('deliveries',created_delivery_id,'insert',auth.uid(),jsonb_build_object(
      'operation','plan_order_delivery','order_id',p_order_id,'route_id',created_route_id,
      'warehouse_id',p_warehouse_id,'driver_id',p_driver_id));
  RETURN created_delivery_id;
END;
$function$;
REVOKE ALL ON FUNCTION public.plan_order_delivery(uuid,uuid,uuid,text,date) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.plan_order_delivery(uuid,uuid,uuid,text,date) TO authenticated;
