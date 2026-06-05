import { assertEquals } from "jsr:@std/assert";
import { validateCreateUserPayload } from "./index.ts";

Deno.test("create_user refuses administrator-supplied passwords", () => {
  assertEquals(
    validateCreateUserPayload({
      email: "user@example.com",
      role: "sales_rep",
      password: "secret",
    }),
    "Passwords must never be supplied by administrators",
  );
});

Deno.test("create_user refuses unknown and admin roles", () => {
  assertEquals(
    validateCreateUserPayload({ email: "user@example.com", role: "admin" }),
    "Invalid role",
  );
  assertEquals(
    validateCreateUserPayload({ email: "user@example.com", role: "unknown" }),
    "Invalid role",
  );
});

Deno.test("create_user rejects malformed email addresses", () => {
  assertEquals(
    validateCreateUserPayload({ email: "invalid", role: "sales_rep" }),
    "Invalid email",
  );
});

Deno.test("create_user accepts every delegated application role", () => {
  for (
    const role of [
      "sales_rep",
      "warehouse_staff",
      "b2b_customer",
      "comptable",
      "acheteur",
      "delivery_agent",
    ]
  ) {
    assertEquals(
      validateCreateUserPayload({ email: "user@example.com", role }),
      null,
    );
  }
});
