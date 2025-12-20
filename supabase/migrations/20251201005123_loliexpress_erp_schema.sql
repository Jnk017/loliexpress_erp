-- Location: supabase/migrations/20251201005123_loliexpress_erp_schema.sql
-- Schema Analysis: Empty database - fresh project
-- Integration Type: NEW_MODULE - Complete ERP schema creation
-- Module: LoliExpress ERP System (Authentication, Products, Orders, Inventory, Customers, Financial, Delivery)

-- ============================================================================
-- 1. ENUMS AND TYPES
-- ============================================================================

CREATE TYPE public.user_role AS ENUM ('admin', 'sales_rep', 'warehouse_staff', 'b2b_customer');
CREATE TYPE public.order_status AS ENUM ('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled');
CREATE TYPE public.payment_status AS ENUM ('pending', 'paid', 'partial', 'failed', 'refunded');
CREATE TYPE public.delivery_status AS ENUM ('pending', 'in_transit', 'delivered', 'failed');
CREATE TYPE public.stock_movement_type AS ENUM ('in', 'out', 'adjustment', 'return');

-- ============================================================================
-- 2. CORE TABLES
-- ============================================================================

-- User profiles table (intermediary between auth.users and app tables)
CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    role public.user_role DEFAULT 'b2b_customer'::public.user_role,
    phone TEXT,
    company_name TEXT,
    avatar_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Product categories
CREATE TABLE public.product_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Products
CREATE TABLE public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sku TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    description TEXT,
    category_id UUID REFERENCES public.product_categories(id) ON DELETE SET NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    cost_price DECIMAL(10,2),
    image_url TEXT,
    barcode TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Warehouse locations
CREATE TABLE public.warehouse_locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    address TEXT,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Inventory stock
CREATE TABLE public.inventory_stock (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
    warehouse_id UUID REFERENCES public.warehouse_locations(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL DEFAULT 0,
    reorder_level INTEGER DEFAULT 10,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(product_id, warehouse_id)
);

-- ============================================================================
-- 3. DEPENDENT TABLES (Customer & Orders)
-- ============================================================================

-- Customers (B2B clients)
CREATE TABLE public.customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    company_name TEXT NOT NULL,
    contact_person TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT NOT NULL,
    address TEXT,
    city TEXT,
    postal_code TEXT,
    credit_limit DECIMAL(12,2) DEFAULT 0,
    current_balance DECIMAL(12,2) DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Sales orders
CREATE TABLE public.sales_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number TEXT NOT NULL UNIQUE,
    customer_id UUID REFERENCES public.customers(id) ON DELETE CASCADE,
    sales_rep_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    order_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    delivery_date TIMESTAMPTZ,
    subtotal DECIMAL(12,2) NOT NULL,
    tax_amount DECIMAL(12,2) DEFAULT 0,
    discount_amount DECIMAL(12,2) DEFAULT 0,
    total_amount DECIMAL(12,2) NOT NULL,
    order_status public.order_status DEFAULT 'pending'::public.order_status,
    payment_status public.payment_status DEFAULT 'pending'::public.payment_status,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Order items
CREATE TABLE public.order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES public.sales_orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    discount_percent DECIMAL(5,2) DEFAULT 0,
    line_total DECIMAL(12,2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 4. FINANCIAL TABLES
-- ============================================================================

-- Invoices
CREATE TABLE public.invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_number TEXT NOT NULL UNIQUE,
    order_id UUID REFERENCES public.sales_orders(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES public.customers(id) ON DELETE CASCADE,
    invoice_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    due_date TIMESTAMPTZ NOT NULL,
    subtotal DECIMAL(12,2) NOT NULL,
    tax_amount DECIMAL(12,2) DEFAULT 0,
    total_amount DECIMAL(12,2) NOT NULL,
    amount_paid DECIMAL(12,2) DEFAULT 0,
    payment_status public.payment_status DEFAULT 'pending'::public.payment_status,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Payments
CREATE TABLE public.payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID REFERENCES public.invoices(id) ON DELETE CASCADE,
    payment_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    amount DECIMAL(12,2) NOT NULL,
    payment_method TEXT,
    reference_number TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Expenses
CREATE TABLE public.expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category TEXT NOT NULL,
    description TEXT NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    expense_date DATE NOT NULL,
    created_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 5. DELIVERY & INVENTORY MOVEMENT TABLES
-- ============================================================================

-- Delivery routes
CREATE TABLE public.delivery_routes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_name TEXT NOT NULL,
    driver_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    route_date DATE NOT NULL,
    start_location TEXT,
    end_location TEXT,
    status public.delivery_status DEFAULT 'pending'::public.delivery_status,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Deliveries
CREATE TABLE public.deliveries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES public.sales_orders(id) ON DELETE CASCADE,
    route_id UUID REFERENCES public.delivery_routes(id) ON DELETE SET NULL,
    delivery_address TEXT NOT NULL,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    estimated_time TIMESTAMPTZ,
    actual_delivery_time TIMESTAMPTZ,
    status public.delivery_status DEFAULT 'pending'::public.delivery_status,
    signature_url TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Stock movements
CREATE TABLE public.stock_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
    warehouse_id UUID REFERENCES public.warehouse_locations(id) ON DELETE CASCADE,
    movement_type public.stock_movement_type NOT NULL,
    quantity INTEGER NOT NULL,
    reference_id UUID,
    reference_type TEXT,
    notes TEXT,
    created_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Barcode scans history
CREATE TABLE public.barcode_scans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
    scanned_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    scan_type TEXT,
    quantity INTEGER DEFAULT 1,
    location TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 6. INDEXES FOR PERFORMANCE
-- ============================================================================

CREATE INDEX idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX idx_user_profiles_role ON public.user_profiles(role);
CREATE INDEX idx_products_sku ON public.products(sku);
CREATE INDEX idx_products_category ON public.products(category_id);
CREATE INDEX idx_products_barcode ON public.products(barcode);
CREATE INDEX idx_inventory_stock_product ON public.inventory_stock(product_id);
CREATE INDEX idx_inventory_stock_warehouse ON public.inventory_stock(warehouse_id);
CREATE INDEX idx_customers_user_id ON public.customers(user_id);
CREATE INDEX idx_sales_orders_customer ON public.sales_orders(customer_id);
CREATE INDEX idx_sales_orders_sales_rep ON public.sales_orders(sales_rep_id);
CREATE INDEX idx_sales_orders_order_number ON public.sales_orders(order_number);
CREATE INDEX idx_sales_orders_status ON public.sales_orders(order_status);
CREATE INDEX idx_order_items_order ON public.order_items(order_id);
CREATE INDEX idx_order_items_product ON public.order_items(product_id);
CREATE INDEX idx_invoices_customer ON public.invoices(customer_id);
CREATE INDEX idx_invoices_order ON public.invoices(order_id);
CREATE INDEX idx_invoices_invoice_number ON public.invoices(invoice_number);
CREATE INDEX idx_payments_invoice ON public.payments(invoice_id);
CREATE INDEX idx_deliveries_order ON public.deliveries(order_id);
CREATE INDEX idx_deliveries_route ON public.deliveries(route_id);
CREATE INDEX idx_stock_movements_product ON public.stock_movements(product_id);
CREATE INDEX idx_barcode_scans_product ON public.barcode_scans(product_id);

-- ============================================================================
-- 7. FUNCTIONS (BEFORE RLS POLICIES)
-- ============================================================================

-- Function to check admin role
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.user_profiles up
    WHERE up.id = auth.uid() 
    AND up.role = 'admin'::public.user_role
    AND up.is_active = true
)
$$;

-- Function to check warehouse staff role
CREATE OR REPLACE FUNCTION public.is_warehouse_staff()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.user_profiles up
    WHERE up.id = auth.uid() 
    AND up.role = 'warehouse_staff'::public.user_role
    AND up.is_active = true
)
$$;

-- Function to check sales rep role
CREATE OR REPLACE FUNCTION public.is_sales_rep()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.user_profiles up
    WHERE up.id = auth.uid() 
    AND up.role = 'sales_rep'::public.user_role
    AND up.is_active = true
)
$$;

-- Trigger function for creating user profiles
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.user_profiles (id, email, full_name, role, phone, company_name, avatar_url)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE((NEW.raw_user_meta_data->>'role')::public.user_role, 'b2b_customer'::public.user_role),
        NEW.raw_user_meta_data->>'phone',
        NEW.raw_user_meta_data->>'company_name',
        NEW.raw_user_meta_data->>'avatar_url'
    );
    RETURN NEW;
END;
$$;

-- ============================================================================
-- 8. ENABLE RLS
-- ============================================================================

ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.warehouse_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_stock ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.deliveries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stock_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.barcode_scans ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 9. RLS POLICIES
-- ============================================================================

-- User Profiles Policies
CREATE POLICY "users_view_own_profile"
ON public.user_profiles
FOR SELECT
TO authenticated
USING (id = auth.uid() OR public.is_admin());

CREATE POLICY "users_update_own_profile"
ON public.user_profiles
FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

CREATE POLICY "admin_manage_all_profiles"
ON public.user_profiles
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- Product Categories Policies
CREATE POLICY "all_users_view_categories"
ON public.product_categories
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "admin_manage_categories"
ON public.product_categories
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- Products Policies
CREATE POLICY "all_users_view_products"
ON public.products
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "admin_manage_products"
ON public.products
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- Warehouse Locations Policies
CREATE POLICY "all_users_view_warehouses"
ON public.warehouse_locations
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "admin_manage_warehouses"
ON public.warehouse_locations
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- Inventory Stock Policies
CREATE POLICY "all_users_view_inventory"
ON public.inventory_stock
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "warehouse_staff_manage_inventory"
ON public.inventory_stock
FOR ALL
TO authenticated
USING (public.is_warehouse_staff() OR public.is_admin())
WITH CHECK (public.is_warehouse_staff() OR public.is_admin());

-- Customers Policies
CREATE POLICY "users_view_own_customer_record"
ON public.customers
FOR SELECT
TO authenticated
USING (user_id = auth.uid() OR public.is_sales_rep() OR public.is_admin());

CREATE POLICY "sales_admin_manage_customers"
ON public.customers
FOR ALL
TO authenticated
USING (public.is_sales_rep() OR public.is_admin())
WITH CHECK (public.is_sales_rep() OR public.is_admin());

-- Sales Orders Policies
CREATE POLICY "users_view_relevant_orders"
ON public.sales_orders
FOR SELECT
TO authenticated
USING (
    sales_rep_id = auth.uid() OR
    customer_id IN (SELECT id FROM public.customers WHERE user_id = auth.uid()) OR
    public.is_admin()
);

CREATE POLICY "sales_admin_manage_orders"
ON public.sales_orders
FOR ALL
TO authenticated
USING (public.is_sales_rep() OR public.is_admin())
WITH CHECK (public.is_sales_rep() OR public.is_admin());

-- Order Items Policies
CREATE POLICY "users_view_order_items"
ON public.order_items
FOR SELECT
TO authenticated
USING (
    order_id IN (
        SELECT id FROM public.sales_orders 
        WHERE sales_rep_id = auth.uid() 
        OR customer_id IN (SELECT id FROM public.customers WHERE user_id = auth.uid())
    ) OR public.is_admin()
);

CREATE POLICY "sales_admin_manage_order_items"
ON public.order_items
FOR ALL
TO authenticated
USING (public.is_sales_rep() OR public.is_admin())
WITH CHECK (public.is_sales_rep() OR public.is_admin());

-- Invoices Policies
CREATE POLICY "users_view_relevant_invoices"
ON public.invoices
FOR SELECT
TO authenticated
USING (
    customer_id IN (SELECT id FROM public.customers WHERE user_id = auth.uid()) OR
    public.is_admin()
);

CREATE POLICY "admin_manage_invoices"
ON public.invoices
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- Payments Policies
CREATE POLICY "users_view_payments"
ON public.payments
FOR SELECT
TO authenticated
USING (
    invoice_id IN (
        SELECT id FROM public.invoices 
        WHERE customer_id IN (SELECT id FROM public.customers WHERE user_id = auth.uid())
    ) OR public.is_admin()
);

CREATE POLICY "admin_manage_payments"
ON public.payments
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- Expenses Policies
CREATE POLICY "admin_manage_expenses"
ON public.expenses
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- Delivery Routes Policies
CREATE POLICY "drivers_view_own_routes"
ON public.delivery_routes
FOR SELECT
TO authenticated
USING (driver_id = auth.uid() OR public.is_admin());

CREATE POLICY "admin_manage_routes"
ON public.delivery_routes
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- Deliveries Policies
CREATE POLICY "users_view_relevant_deliveries"
ON public.deliveries
FOR SELECT
TO authenticated
USING (
    order_id IN (
        SELECT id FROM public.sales_orders 
        WHERE customer_id IN (SELECT id FROM public.customers WHERE user_id = auth.uid())
    ) OR 
    route_id IN (SELECT id FROM public.delivery_routes WHERE driver_id = auth.uid()) OR
    public.is_admin()
);

CREATE POLICY "admin_manage_deliveries"
ON public.deliveries
FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- Stock Movements Policies
CREATE POLICY "all_staff_view_movements"
ON public.stock_movements
FOR SELECT
TO authenticated
USING (public.is_warehouse_staff() OR public.is_admin());

CREATE POLICY "warehouse_staff_create_movements"
ON public.stock_movements
FOR INSERT
TO authenticated
WITH CHECK (public.is_warehouse_staff() OR public.is_admin());

-- Barcode Scans Policies
CREATE POLICY "warehouse_staff_manage_scans"
ON public.barcode_scans
FOR ALL
TO authenticated
USING (public.is_warehouse_staff() OR public.is_admin())
WITH CHECK (public.is_warehouse_staff() OR public.is_admin());

-- ============================================================================
-- 10. TRIGGERS
-- ============================================================================

-- Trigger for new user profile creation
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- 11. MOCK DATA
-- ============================================================================

DO $$
DECLARE
    admin_id UUID := gen_random_uuid();
    sales_id UUID := gen_random_uuid();
    warehouse_id UUID := gen_random_uuid();
    customer_id UUID := gen_random_uuid();
    
    cat1_id UUID := gen_random_uuid();
    cat2_id UUID := gen_random_uuid();
    
    prod1_id UUID := gen_random_uuid();
    prod2_id UUID := gen_random_uuid();
    prod3_id UUID := gen_random_uuid();
    
    warehouse1_id UUID := gen_random_uuid();
    
    cust1_id UUID := gen_random_uuid();
    
    order1_id UUID := gen_random_uuid();
    
    invoice1_id UUID := gen_random_uuid();
BEGIN
    -- Create auth users
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES
        (admin_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'admin@loliexpress.com', crypt('Admin@2024', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Admin User", "role": "admin"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (sales_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'sales@loliexpress.com', crypt('Sales@2024', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Sales Representative", "role": "sales_rep"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (warehouse_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'warehouse@loliexpress.com', crypt('Warehouse@2024', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Warehouse Staff", "role": "warehouse_staff"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (customer_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'customer@loliexpress.com', crypt('Customer@2024', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "B2B Customer", "role": "b2b_customer", "company_name": "ABC Corp"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null);
    
    -- Insert categories
    INSERT INTO public.product_categories (id, name, description) VALUES
        (cat1_id, 'Electronics', 'Electronic products and accessories'),
        (cat2_id, 'Office Supplies', 'Office and stationery products');
    
    -- Insert products
    INSERT INTO public.products (id, sku, name, description, category_id, unit_price, cost_price, barcode, image_url) VALUES
        (prod1_id, 'LAPTOP-001', 'Business Laptop', 'High-performance business laptop', cat1_id, 1200.00, 900.00, '1234567890123', 'https://images.unsplash.com/photo-1496181133206-80ce9b88a853'),
        (prod2_id, 'MOUSE-001', 'Wireless Mouse', 'Ergonomic wireless mouse', cat1_id, 35.00, 20.00, '1234567890124', 'https://images.unsplash.com/photo-1527864550417-7fd91fc51a46'),
        (prod3_id, 'PAPER-001', 'A4 Paper Pack', 'Premium A4 paper 500 sheets', cat2_id, 15.00, 10.00, '1234567890125', 'https://images.unsplash.com/photo-1586075010923-2dd4570fb338');
    
    -- Insert warehouse
    INSERT INTO public.warehouse_locations (id, name, address, latitude, longitude) VALUES
        (warehouse1_id, 'Main Warehouse', '123 Storage Street, City', 40.7128, -74.0060);
    
    -- Insert inventory
    INSERT INTO public.inventory_stock (product_id, warehouse_id, quantity, reorder_level) VALUES
        (prod1_id, warehouse1_id, 50, 10),
        (prod2_id, warehouse1_id, 200, 50),
        (prod3_id, warehouse1_id, 500, 100);
    
    -- Insert customer
    INSERT INTO public.customers (id, user_id, company_name, contact_person, email, phone, address, city, postal_code, credit_limit) VALUES
        (cust1_id, customer_id, 'ABC Corporation', 'John Smith', 'customer@loliexpress.com', '+1234567890', '456 Business Ave', 'New York', '10001', 50000.00);
    
    -- Insert sales order
    INSERT INTO public.sales_orders (id, order_number, customer_id, sales_rep_id, subtotal, tax_amount, total_amount) VALUES
        (order1_id, 'SO-2024-001', cust1_id, sales_id, 1235.00, 123.50, 1358.50);
    
    -- Insert order items
    INSERT INTO public.order_items (order_id, product_id, quantity, unit_price, line_total) VALUES
        (order1_id, prod1_id, 1, 1200.00, 1200.00),
        (order1_id, prod2_id, 1, 35.00, 35.00);
    
    -- Insert invoice
    INSERT INTO public.invoices (id, invoice_number, order_id, customer_id, due_date, subtotal, tax_amount, total_amount) VALUES
        (invoice1_id, 'INV-2024-001', order1_id, cust1_id, now() + interval '30 days', 1235.00, 123.50, 1358.50);
    
    -- Insert stock movements
    INSERT INTO public.stock_movements (product_id, warehouse_id, movement_type, quantity, reference_type, created_by) VALUES
        (prod1_id, warehouse1_id, 'out', 1, 'sales_order', sales_id),
        (prod2_id, warehouse1_id, 'out', 1, 'sales_order', sales_id);
END $$;