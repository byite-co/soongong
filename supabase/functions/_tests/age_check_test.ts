import { assertEquals } from "@std/assert";
import { handle } from "../age-check/index.ts";

Deno.env.set("AGE_TICKET_SECRET", "0123456789abcdef0123456789abcdef-test-secret");
const NOW = new Date("2026-10-01T03:00:00Z");

function post(body: unknown): Request {
  return new Request("http://local/age-check", { method: "POST", body: JSON.stringify(body), headers: { "content-type": "application/json" } });
}

Deno.test("age-check: allowed → ticket; blocked → allowed:false; malformed → 400", async () => {
  const ok = await handle(post({ birth_date: "2010-01-01" }), NOW);
  assertEquals(ok.status, 200);
  const okBody = await ok.json();
  assertEquals(okBody.allowed, true);
  assertEquals(typeof okBody.ticket, "string");

  const blocked = await handle(post({ birth_date: "2015-01-01" }), NOW);
  assertEquals((await blocked.json()).allowed, false);

  const bad = await handle(post({ birth_date: "nope" }), NOW);
  assertEquals(bad.status, 400);
});

Deno.test("age-check: logs never contain the birth date", async () => {
  const captured: string[] = [];
  const orig = console.log;
  console.log = (...a: unknown[]) => captured.push(a.join(" "));
  try {
    await handle(post({ birth_date: "2010-06-15" }), NOW);
    await handle(post({ birth_date: "2015-06-15" }), NOW);
  } finally {
    console.log = orig;
  }
  for (const l of captured) {
    assertEquals(l.includes("2010-06-15") || l.includes("2015-06-15"), false, l);
  }
});
