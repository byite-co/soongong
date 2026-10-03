import { assert, assertEquals } from "@std/assert";
import { logger, redact } from "../_shared/log.ts";

Deno.test("redact masks email, birth date, jwt and sub-like fields", () => {
  const line = redact('user a.b+c@example.com born 2012-04-05 sub=abc123xyz token eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjMifQ.sflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c');
  assert(!line.includes("example.com"));
  assert(!line.includes("2012-04-05"));
  assert(!line.includes("abc123xyz"));
  assert(!line.includes("eyJhbGciOiJIUzI1NiJ9"));
});

Deno.test("logger emits only request id + outcome codes", () => {
  const lines: string[] = [];
  const log = logger("req-1", (l) => lines.push(l));
  log.info("age-check outcome=blocked birth_date=2012-04-05 email=x@y.io");
  assertEquals(lines.length, 1);
  assert(lines[0].startsWith("[req-1] info age-check outcome=blocked"));
  assert(!lines[0].includes("2012-04-05"));
  assert(!lines[0].includes("x@y.io"));
});
