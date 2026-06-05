-- Demo data for local development. This file intentionally does not create
-- Supabase Auth users; create users through Studio/Admin API, then assign roles.

INSERT INTO public.product_categories (name, description)
SELECT 'Boissons', 'Boissons et produits de distribution'
WHERE NOT EXISTS (
    SELECT 1 FROM public.product_categories WHERE name = 'Boissons'
);

INSERT INTO public.product_categories (name, description)
SELECT 'Épicerie', 'Produits alimentaires courants'
WHERE NOT EXISTS (
    SELECT 1 FROM public.product_categories WHERE name = 'Épicerie'
);

INSERT INTO public.warehouse_locations (name, address)
SELECT 'Entrepôt Principal', 'Kinshasa'
WHERE NOT EXISTS (
    SELECT 1 FROM public.warehouse_locations WHERE name = 'Entrepôt Principal'
);

INSERT INTO public.products (sku, name, description, category_id, unit_price, cost_price, barcode, currency)
SELECT
    'LEX-COCA-33',
    'Coca-Cola 33cl',
    'Canette Coca-Cola 33cl',
    pc.id,
    1500,
    1000,
    '3760074380213',
    'CDF'
FROM public.product_categories pc
WHERE pc.name = 'Boissons'
AND NOT EXISTS (
    SELECT 1 FROM public.products WHERE sku = 'LEX-COCA-33'
);

INSERT INTO public.products (sku, name, description, category_id, unit_price, cost_price, barcode, currency)
SELECT
    'LEX-WATER-1L',
    'Eau minérale 1L',
    'Bouteille eau minérale 1L',
    pc.id,
    1000,
    650,
    '8901234567890',
    'CDF'
FROM public.product_categories pc
WHERE pc.name = 'Boissons'
AND NOT EXISTS (
    SELECT 1 FROM public.products WHERE sku = 'LEX-WATER-1L'
);

INSERT INTO public.inventory_stock (product_id, warehouse_id, quantity, reorder_level)
SELECT p.id, w.id, 250, 50
FROM public.products p
CROSS JOIN public.warehouse_locations w
WHERE p.sku = 'LEX-COCA-33'
  AND w.name = 'Entrepôt Principal'
ON CONFLICT (product_id, warehouse_id) DO NOTHING;

INSERT INTO public.inventory_stock (product_id, warehouse_id, quantity, reorder_level)
SELECT p.id, w.id, 40, 50
FROM public.products p
CROSS JOIN public.warehouse_locations w
WHERE p.sku = 'LEX-WATER-1L'
  AND w.name = 'Entrepôt Principal'
ON CONFLICT (product_id, warehouse_id) DO NOTHING;

-- Keep seeded stock and the movement ledger consistent. Runtime stock changes are
-- derived exclusively from stock_movements by the synchronization trigger.
INSERT INTO public.stock_movements (
    product_id, warehouse_id, movement_type, quantity,
    reference_type, notes, created_by
)
SELECT
    inventory.product_id,
    inventory.warehouse_id,
    'adjustment'::public.stock_movement_type,
    inventory.quantity,
    'seed_baseline',
    'Local development seed baseline',
    NULL
FROM public.inventory_stock AS inventory
WHERE inventory.quantity <> 0
  AND NOT EXISTS (
      SELECT 1
      FROM public.stock_movements movement
      WHERE movement.product_id = inventory.product_id
        AND movement.warehouse_id = inventory.warehouse_id
  );
