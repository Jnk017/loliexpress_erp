-- P1.a — lancer avec psql sur la pile isolée après 000 à 015.
\set ON_ERROR_STOP on
\ir verify_p1a_invoice_delivery.sql
\ir verify_p1a_admin_delivery_credit.sql
\ir verify_p1a_handover.sql
\ir verify_p1a_drafts_and_purchases.sql
\ir verify_p1a_ra.sql
