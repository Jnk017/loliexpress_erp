-- Clean bootstrap 001: core ERP schema, extensible roles, no business/demo data.
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

CREATE TABLE IF NOT EXISTS public.roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE CHECK (name ~ '^[a-z][a-z0-9_]{1,63}$'),
  display_name text NOT NULL,
  description text,
  sector text NOT NULL CHECK (sector IN ('all','sales','warehouse','delivery','accounting','purchasing','client')),
  permissions jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(permissions) = 'object'),
  is_system boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL
);
INSERT INTO public.roles(name,display_name,sector,is_system,permissions) VALUES
 ('admin','Administrateur','all',true,'{"all":true}'),
 ('commercial_staff','Commercial','sales',true,'{"customers":"manage","orders":"manage"}'),
 ('warehouse_staff','Magasinier','warehouse',true,'{"inventory":"manage","deliveries":"read"}'),
 ('client_b2b','Client B2B','client',true,'{"portal":"self"}')
ON CONFLICT (name) DO UPDATE SET display_name=EXCLUDED.display_name,sector=EXCLUDED.sector,is_system=true;

CREATE OR REPLACE FUNCTION public.protect_system_roles() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
BEGIN
  IF TG_OP='DELETE' AND OLD.is_system THEN
    RAISE EXCEPTION 'System roles cannot be deleted';
  END IF;
  IF TG_OP='UPDATE' AND OLD.is_system AND (NEW.name IS DISTINCT FROM OLD.name OR NEW.sector IS DISTINCT FROM OLD.sector OR NOT NEW.is_system) THEN
    RAISE EXCEPTION 'System role identity cannot be changed';
  END IF;
  RETURN COALESCE(NEW,OLD);
END $$;
DROP TRIGGER IF EXISTS protect_system_roles_trigger ON public.roles;
CREATE TRIGGER protect_system_roles_trigger BEFORE UPDATE OR DELETE ON public.roles FOR EACH ROW EXECUTE FUNCTION public.protect_system_roles();

CREATE TABLE IF NOT EXISTS public.user_profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL UNIQUE,
  full_name text NOT NULL,
  role_id uuid NOT NULL REFERENCES public.roles(id) ON DELETE RESTRICT,
  role text NOT NULL,
  sector text NOT NULL,
  warehouse_id uuid,
  phone text,
  company_name text,
  avatar_url text,
  display_currency text NOT NULL DEFAULT 'CDF' CHECK (display_currency IN ('CDF','USD')),
  is_active boolean NOT NULL DEFAULT true,
  must_change_password boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_user_profiles_role_id ON public.user_profiles(role_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_sector ON public.user_profiles(sector);

CREATE OR REPLACE FUNCTION public.sync_profile_role_cache() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE r public.roles%ROWTYPE;
BEGIN
  SELECT * INTO STRICT r FROM public.roles WHERE id=NEW.role_id;
  NEW.role:=r.name; NEW.sector:=r.sector; NEW.updated_at:=now();
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS sync_profile_role_cache_trigger ON public.user_profiles;
CREATE TRIGGER sync_profile_role_cache_trigger BEFORE INSERT OR UPDATE OF role_id ON public.user_profiles
FOR EACH ROW EXECUTE FUNCTION public.sync_profile_role_cache();

DO $bootstrap$
BEGIN
  IF to_regprocedure('public.current_user_role()') IS NULL THEN
    EXECUTE 'CREATE FUNCTION public.current_user_role() RETURNS text
      LANGUAGE sql STABLE SECURITY DEFINER SET search_path=public AS $body$
      SELECT role FROM public.user_profiles WHERE id=auth.uid() AND is_active AND NOT must_change_password
      $body$';
  END IF;
END $bootstrap$;
CREATE OR REPLACE FUNCTION public.current_user_sector() RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER SET search_path=public AS $$
 SELECT sector FROM public.user_profiles WHERE id=auth.uid() AND is_active AND NOT must_change_password
$$;
CREATE OR REPLACE FUNCTION public.has_role(VARIADIC names text[]) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path=public AS $$
 SELECT COALESCE(public.current_user_role()=ANY(names),false)
$$;
CREATE OR REPLACE FUNCTION public.is_admin() RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=public AS $$ SELECT public.has_role('admin') $$;

CREATE OR REPLACE FUNCTION public.handle_new_user() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE default_role uuid;
BEGIN
  SELECT id INTO STRICT default_role FROM public.roles WHERE name='client_b2b';
  INSERT INTO public.user_profiles(id,email,full_name,role_id,role,sector,phone,company_name,avatar_url,must_change_password)
  VALUES(NEW.id,NEW.email,COALESCE(NULLIF(NEW.raw_user_meta_data->>'full_name',''),split_part(NEW.email,'@',1)),default_role,'client_b2b','client',NEW.raw_user_meta_data->>'phone',NEW.raw_user_meta_data->>'company_name',NEW.raw_user_meta_data->>'avatar_url',true)
  ON CONFLICT(id) DO NOTHING;
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE TABLE IF NOT EXISTS public.product_categories(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),name text NOT NULL UNIQUE,description text,created_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS public.products(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),sku text NOT NULL UNIQUE,name text NOT NULL,description text,category_id uuid REFERENCES public.product_categories(id) ON DELETE SET NULL,unit_price numeric(18,2) NOT NULL CHECK(unit_price>=0),cost_price numeric(18,2) CHECK(cost_price>=0),currency text NOT NULL DEFAULT 'CDF' CHECK(currency IN('CDF','USD')),image_url text,barcode text UNIQUE,is_active boolean NOT NULL DEFAULT true,created_at timestamptz NOT NULL DEFAULT now(),updated_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS public.warehouse_locations(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),name text NOT NULL UNIQUE,address text,latitude numeric(10,8),longitude numeric(11,8),is_active boolean NOT NULL DEFAULT true,created_at timestamptz NOT NULL DEFAULT now());
ALTER TABLE public.user_profiles DROP CONSTRAINT IF EXISTS user_profiles_warehouse_id_fkey;
ALTER TABLE public.user_profiles ADD CONSTRAINT user_profiles_warehouse_id_fkey FOREIGN KEY(warehouse_id) REFERENCES public.warehouse_locations(id) ON DELETE SET NULL;
CREATE TABLE IF NOT EXISTS public.customers(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),user_id uuid UNIQUE REFERENCES auth.users(id) ON DELETE SET NULL,commercial_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,company_name text NOT NULL,contact_person text,email text,phone text,address text,city text,postal_code text,credit_limit numeric(18,2) NOT NULL DEFAULT 0,is_active boolean NOT NULL DEFAULT true,created_at timestamptz NOT NULL DEFAULT now(),updated_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS public.sales_orders(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),order_number text NOT NULL UNIQUE,customer_id uuid NOT NULL REFERENCES public.customers(id) ON DELETE RESTRICT,sales_rep_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,order_date timestamptz NOT NULL DEFAULT now(),delivery_date timestamptz,subtotal numeric(18,2) NOT NULL DEFAULT 0,tax_amount numeric(18,2) NOT NULL DEFAULT 0,discount_amount numeric(18,2) NOT NULL DEFAULT 0,total_amount numeric(18,2) NOT NULL DEFAULT 0,currency text NOT NULL DEFAULT 'CDF' CHECK(currency IN('CDF','USD')),exchange_rate numeric(18,6) NOT NULL DEFAULT 1 CHECK(exchange_rate>0),payment_type text NOT NULL DEFAULT 'cash' CHECK(payment_type IN('cash','credit')),due_date timestamptz,order_status text NOT NULL DEFAULT 'pending' CHECK(order_status IN('pending','confirmed','processing','shipped','delivered','cancelled')),payment_status text NOT NULL DEFAULT 'pending' CHECK(payment_status IN('pending','paid','partial','failed','refunded')),notes text,created_at timestamptz NOT NULL DEFAULT now(),updated_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS public.order_items(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),order_id uuid NOT NULL REFERENCES public.sales_orders(id) ON DELETE CASCADE,product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,quantity integer NOT NULL CHECK(quantity>0),unit_price numeric(18,2) NOT NULL CHECK(unit_price>=0),discount_percent numeric(5,2) NOT NULL DEFAULT 0 CHECK(discount_percent BETWEEN 0 AND 100),line_total numeric(18,2) NOT NULL CHECK(line_total>=0),created_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS public.inventory_stock(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,warehouse_id uuid NOT NULL REFERENCES public.warehouse_locations(id) ON DELETE CASCADE,quantity integer NOT NULL DEFAULT 0 CHECK(quantity>=0),reorder_level integer NOT NULL DEFAULT 10 CHECK(reorder_level>=0),updated_at timestamptz NOT NULL DEFAULT now(),UNIQUE(product_id,warehouse_id));
CREATE TABLE IF NOT EXISTS public.stock_movements(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,warehouse_id uuid NOT NULL REFERENCES public.warehouse_locations(id) ON DELETE RESTRICT,movement_type text NOT NULL CHECK(movement_type IN('in','out','adjustment','return')),quantity integer NOT NULL,reference_type text,reference_id uuid,notes text,created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,created_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS public.invoices(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),invoice_number text NOT NULL UNIQUE,order_id uuid NOT NULL REFERENCES public.sales_orders(id) ON DELETE RESTRICT,customer_id uuid NOT NULL REFERENCES public.customers(id) ON DELETE RESTRICT,invoice_date timestamptz NOT NULL DEFAULT now(),due_date timestamptz NOT NULL,subtotal numeric(18,2) NOT NULL,total_amount numeric(18,2) NOT NULL,amount_paid numeric(18,2) NOT NULL DEFAULT 0,currency text NOT NULL DEFAULT 'CDF' CHECK(currency IN('CDF','USD')),exchange_rate numeric(18,6) NOT NULL DEFAULT 1,payment_status text NOT NULL DEFAULT 'pending',notes text,created_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS public.payments(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),invoice_id uuid NOT NULL REFERENCES public.invoices(id) ON DELETE RESTRICT,amount numeric(18,2) NOT NULL CHECK(amount>0),payment_method text NOT NULL,reference_number text,notes text,currency text NOT NULL DEFAULT 'CDF' CHECK(currency IN('CDF','USD')),created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,payment_date timestamptz NOT NULL DEFAULT now(),created_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS public.expenses(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),category text NOT NULL,description text NOT NULL,amount numeric(18,2) NOT NULL CHECK(amount>=0),currency text NOT NULL DEFAULT 'CDF' CHECK(currency IN('CDF','USD')),expense_date date NOT NULL,status text NOT NULL DEFAULT 'draft',created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,created_at timestamptz NOT NULL DEFAULT now(),updated_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS public.delivery_routes(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),route_name text NOT NULL,delivery_agent_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,warehouse_id uuid REFERENCES public.warehouse_locations(id) ON DELETE SET NULL,route_date date NOT NULL,status text NOT NULL DEFAULT 'pending' CHECK(status IN('pending','in_transit','delivered','failed')),created_at timestamptz NOT NULL DEFAULT now(),updated_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS public.deliveries(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),order_id uuid NOT NULL REFERENCES public.sales_orders(id) ON DELETE RESTRICT,route_id uuid REFERENCES public.delivery_routes(id) ON DELETE SET NULL,warehouse_id uuid REFERENCES public.warehouse_locations(id) ON DELETE SET NULL,delivery_agent_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,delivery_address text NOT NULL,estimated_time timestamptz,actual_delivery_time timestamptz,status text NOT NULL DEFAULT 'pending' CHECK(status IN('pending','in_transit','delivered','failed')),signature_url text,notes text,created_at timestamptz NOT NULL DEFAULT now(),updated_at timestamptz NOT NULL DEFAULT now());

DO $$ DECLARE t text; BEGIN FOREACH t IN ARRAY ARRAY['roles','user_profiles','product_categories','products','warehouse_locations','customers','sales_orders','order_items','inventory_stock','stock_movements','invoices','payments','expenses','delivery_routes','deliveries'] LOOP EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY',t); END LOOP; END $$;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon;
