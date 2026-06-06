-- Idempotent operational configuration; no users, customers, products or stock.
INSERT INTO public.roles(name,display_name,description,sector,permissions,is_system) VALUES
('admin','Administrateur','Accès complet','all','{"all":true}',true),
('commercial_staff','Commercial','Ventes et portefeuille clients','sales','{"customers":"manage","orders":"manage"}',true),
('warehouse_staff','Magasinier','Stock de son entrepôt','warehouse','{"inventory":"manage"}',true),
('delivery_agent','Livreur','Tournées assignées','delivery','{"deliveries":"assigned"}',true),
('comptable','Comptable','Finance et comptabilité','accounting','{"finance":"manage"}',true),
('acheteur','Acheteur','Fournisseurs et achats','purchasing','{"purchases":"manage"}',true),
('client_b2b','Client B2B','Portail de sa société','client','{"portal":"self"}',true)
ON CONFLICT(name) DO UPDATE SET display_name=EXCLUDED.display_name,description=EXCLUDED.description,sector=EXCLUDED.sector,permissions=EXCLUDED.permissions,is_system=true;
INSERT INTO public.exchange_rates(base_currency,quote_currency,rate,is_active)
SELECT 'USD','CDF',2500,true WHERE NOT EXISTS(SELECT 1 FROM public.exchange_rates WHERE base_currency='USD' AND quote_currency='CDF' AND is_active);
INSERT INTO public.security_thresholds(name,category,value,description) VALUES
('failed_login_threshold','authentication',5,'Failed logins before alert'),
('high_value_transaction_cdf','transaction',10000000,'High value CDF transaction'),
('inventory_variance_percent','inventory',20,'Inventory variance alert threshold')
ON CONFLICT(name) DO UPDATE SET value=EXCLUDED.value,description=EXCLUDED.description,updated_at=now();
INSERT INTO public.automation_rules(name,description,trigger_type,priority,is_active) VALUES
('Repeated login failures','Create a security alert after the configured failed-login threshold','failed_login_threshold',100,true),
('Low stock alert','Queue an alert when stock reaches its reorder level','low_stock',80,true),
('High value transaction review','Flag high-value transactions for review','high_value_transaction',90,true)
ON CONFLICT(name) DO NOTHING;
