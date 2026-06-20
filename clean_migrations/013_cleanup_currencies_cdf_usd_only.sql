-- Clean bootstrap 013: enforce CDF/USD without touching business data.
INSERT INTO public.system_configuration(config_key,config_value,description) VALUES('default_currency','"CDF"','Default accounting currency'),('supported_currencies','["CDF","USD"]','Allowed currencies') ON CONFLICT(config_key) DO UPDATE SET config_value=EXCLUDED.config_value,updated_at=now();
