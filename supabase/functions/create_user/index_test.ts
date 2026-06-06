import { assertEquals } from "jsr:@std/assert";
import { validateCreateUserPayload } from "./index.ts";

Deno.test("create_user accepts canonical and custom role identifiers", () => {
  for (const role of ["commercial_staff", "warehouse_staff", "client_b2b", "comptable", "acheteur", "delivery_agent", "regional_sales_manager"]) {
    assertEquals(validateCreateUserPayload({ email: "user@example.com", role }), null);
  }
});
Deno.test("create_user rejects admin, malformed roles and passwords", () => {
  assertEquals(validateCreateUserPayload({ email: "user@example.com", role: "admin" }), "Invalid role");
  assertEquals(validateCreateUserPayload({ email: "user@example.com", role: "Bad Role" }), "Invalid role");
  assertEquals(validateCreateUserPayload({ email: "user@example.com", role: "commercial_staff", password: "secret" }), "Passwords must never be supplied by administrators");
});
Deno.test("create_user rejects invalid email", () => {
  assertEquals(validateCreateUserPayload({ email: "invalid", role: "commercial_staff" }), "Invalid email");
});
