BEGIN;
CREATE TEMP TABLE order_scope_fixture AS
SELECT gen_random_uuid() AS admin, gen_random_uuid() AS rep, gen_random_uuid() AS accountant,
       gen_random_uuid() AS client_a, gen_random_uuid() AS client_b, gen_random_uuid() AS customer_a,
       gen_random_uuid() AS customer_b, gen_random_uuid() AS product;
GRANT SELECT ON order_scope_fixture TO authenticated;
INSERT INTO auth.users(id,email)
SELECT id,id || '@example.invalid' FROM order_scope_fixture f
CROSS JOIN LATERAL unnest(ARRAY[f.admin,f.rep,f.accountant,f.client_a,f.client_b]) AS id;
UPDATE public.user_profiles p SET role=x.role::public.user_role,is_active=true,must_change_password=false
FROM order_scope_fixture f CROSS JOIN LATERAL (
VALUES (f.admin,'admin'),(f.rep,'sales_rep'),(f.accountant,'comptable'),
       (f.client_a,'b2b_customer'),(f.client_b,'b2b_customer')
) AS x(id,role) WHERE p.id=x.id;
SELECT set_config('request.jwt.claim.sub',admin::text,true) FROM order_scope_fixture;
INSERT INTO public.customers(id,user_id,commercial_id,company_name,contact_person,email,phone,is_active)
SELECT f.customer_a,f.client_a,f.rep,'Gate A','Gate',f.customer_a || '@example.invalid','000',true FROM order_scope_fixture f
UNION ALL
SELECT f.customer_b,f.client_b,NULL,'Gate B','Gate',f.customer_b || '@example.invalid','000',true FROM order_scope_fixture f;
INSERT INTO public.products(id,sku,name,unit_price,currency,is_active)
SELECT product,product::text,'Gate produit',10,'CDF',true FROM order_scope_fixture;

SET LOCAL ROLE authenticated;
DO $$
DECLARE f order_scope_fixture; lines jsonb; order_id uuid; invoice_id uuid;
BEGIN
  SELECT * INTO STRICT f FROM order_scope_fixture;
  lines := jsonb_build_array(jsonb_build_object('product_id',f.product,'quantity',2));
  PERFORM set_config('request.jwt.claim.sub',f.admin::text,true);
  PERFORM public.set_customer_product_price(f.customer_a,f.product,6,'CDF');

  PERFORM set_config('request.jwt.claim.sub',f.rep::text,true);
  IF public.order_unit_price(f.customer_a,f.product,'CDF') IS DISTINCT FROM 6 THEN
    RAISE EXCEPTION 'Expected assigned price';
  END IF;
  BEGIN
    PERFORM public.create_order_with_items(f.customer_b,lines);
    RAISE EXCEPTION 'Unassigned customer accepted';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN
    PERFORM public.set_customer_product_price(f.customer_a,f.product,1,'CDF');
    RAISE EXCEPTION 'Commercial price change accepted';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;

  PERFORM set_config('request.jwt.claim.sub',f.client_b::text,true);
  IF public.order_unit_price(f.customer_b,f.product,'CDF') IS DISTINCT FROM 10 THEN
    RAISE EXCEPTION 'Expected own catalogue price';
  END IF;
  BEGIN
    PERFORM public.order_unit_price(f.customer_a,f.product,'CDF');
    RAISE EXCEPTION 'Another customer price visible';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;

  PERFORM set_config('request.jwt.claim.sub',f.client_a::text,true);
  order_id := (public.create_order_with_items(f.customer_a,lines)).id;
  BEGIN
    PERFORM public.issue_order_invoice(order_id,now()+interval '7 days');
    RAISE EXCEPTION 'Customer invoice issuance accepted';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;

  PERFORM set_config('request.jwt.claim.sub',f.rep::text,true);
  PERFORM public.transition_order_status(order_id,'confirmed');
  PERFORM set_config('request.jwt.claim.sub',f.accountant::text,true);
  invoice_id := (public.issue_order_invoice(order_id,now()+interval '7 days')).id;
  IF NOT EXISTS (SELECT FROM public.invoices WHERE id=invoice_id AND total_amount=12 AND currency='CDF') THEN
    RAISE EXCEPTION 'Expected invoice at assigned price';
  END IF;
END
$$;
SELECT true AS order_invoice_scope_pass;
ROLLBACK;
