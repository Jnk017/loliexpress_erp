# Roles and permissions

> **Current status — 2026-11-25:** Seven canonical DB roles. Web smoke covers admin, sales_rep (commercial), comptable, acheteur, delivery_agent (livreur), two b2b_customer identities; warehouse_staff remains untested in this smoke. Invitation and role enforcement are server-side; verify self-service signup behavior before relying on it. [Current audit](gate_audit_2026-11-25.md).


- `admin`: full application and database administration.
- `sales_rep`: customers, sales orders, assigned customer documents and delivery follow-up.
- `warehouse_staff`: stock, barcode scanning, stock alerts and delivery operations.
- `comptable`: expenses, payments, purchases read access, receivables and financial reports.
- `acheteur`: suppliers, purchases and purchase items management.
- `delivery_agent`: assigned delivery routes and delivery status updates only.
- `b2b_customer`: customer portal, own orders, own documents and support tickets.

Role changes must be performed by an admin. Self-service signup always creates a customer profile by default.
