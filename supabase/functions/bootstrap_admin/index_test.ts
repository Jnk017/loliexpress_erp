import { assertEquals } from "jsr:@std/assert";
import { validateBootstrapPayload } from "./index.ts";

Deno.test("bootstrap_admin refuses passwords", () => {
  assertEquals(
    validateBootstrapPayload({
      email: "admin@example.com",
      password: "secret",
    }),
    "Bootstrap does not accept passwords",
  );
});

Deno.test("bootstrap_admin requires an explicit valid email", () => {
  assertEquals(
    validateBootstrapPayload({ email: "" }),
    "A valid email is required",
  );
  assertEquals(
    validateBootstrapPayload({ email: "invalid" }),
    "A valid email is required",
  );
});

Deno.test("bootstrap_admin accepts an invitation-only payload", () => {
  assertEquals(
    validateBootstrapPayload({ email: "admin@example.com" }),
    null,
  );
});
