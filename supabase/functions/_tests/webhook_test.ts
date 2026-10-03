import { assertEquals } from "@std/assert";
import { timingSafeEqual } from "../_shared/auth.ts";
import { rateLimited } from "../check-email/index.ts";

Deno.test("timingSafeEqual", () => {
  assertEquals(timingSafeEqual("abc", "abc"), true);
  assertEquals(timingSafeEqual("abc", "abd"), false);
  assertEquals(timingSafeEqual("abc", "abcd"), false);
});

Deno.test("check-email rate limit: 20 per minute per key", () => {
  const t0 = 1_000_000;
  for (let i = 0; i < 20; i++) assertEquals(rateLimited("ip-1", t0 + i), false);
  assertEquals(rateLimited("ip-1", t0 + 21), true);
  assertEquals(rateLimited("ip-2", t0 + 21), false);
  assertEquals(rateLimited("ip-1", t0 + 61_000), false);
});
