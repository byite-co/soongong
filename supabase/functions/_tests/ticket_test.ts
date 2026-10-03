import { assert, assertEquals, assertRejects } from "@std/assert";
import { isAtLeast14, signAgeTicket, verifyAgeTicket } from "../_shared/ticket.ts";

const SECRET = "0123456789abcdef0123456789abcdef-test-secret";
const NOW = new Date("2026-10-01T03:00:00Z"); // 12:00 KST

Deno.test("age gate: exactly 14 today (KST) passes, tomorrow's birthday fails", () => {
  assertEquals(isAtLeast14("2012-10-01", NOW), true);
  assertEquals(isAtLeast14("2012-10-02", NOW), false);
  assertEquals(isAtLeast14("2000-01-01", NOW), true);
});

Deno.test("age gate: KST day boundary — 15:30Z is already the next KST day", () => {
  const at = new Date("2026-09-30T15:30:00Z"); // 2026-10-01 00:30 KST
  assertEquals(isAtLeast14("2012-10-01", at), true);
  const before = new Date("2026-09-30T14:59:00Z"); // 2026-09-30 23:59 KST
  assertEquals(isAtLeast14("2012-10-01", before), false);
});

Deno.test("age gate: malformed / impossible / future dates → null", () => {
  assertEquals(isAtLeast14("2012", NOW), null);
  assertEquals(isAtLeast14("2012-13-01", NOW), null);
  assertEquals(isAtLeast14("2012-02-30", NOW), null);
  assertEquals(isAtLeast14("2030-01-01", NOW), null);
});

Deno.test("ticket: sign → verify; contains only age_ok + jti", async () => {
  const t = await signAgeTicket(SECRET, NOW);
  const payload = JSON.parse(atob(t.split(".")[1].replace(/-/g, "+").replace(/_/g, "/")));
  assertEquals(payload.age_ok, true);
  assert(typeof payload.jti === "string");
  assertEquals(Object.keys(payload).sort(), ["age_ok", "aud", "exp", "iat", "iss", "jti"]);
  const v = await verifyAgeTicket(SECRET, t, new Date(NOW.getTime() + 60_000));
  assertEquals(v.jti, payload.jti);
});

Deno.test("ticket: expired after 10 minutes, wrong secret rejected", async () => {
  const t = await signAgeTicket(SECRET, NOW);
  await assertRejects(() => verifyAgeTicket(SECRET, t, new Date(NOW.getTime() + 11 * 60_000)));
  await assertRejects(() => verifyAgeTicket("another-secret-another-secret-another", t, NOW));
});
