import { assert, assertEquals, assertRejects, assertThrows } from "@std/assert";
import fc from "fast-check";
import { HttpError, optionalString, readJson, requireString } from "../_shared/http.ts";
import { jsonObjectSchema, photoPathsSchema } from "../_shared/validation.ts";

Deno.test("JSON boundary keeps unknown keys and rejects non-object JSON", async () => {
  const body = { future_field: { value: 3 }, nullable: null, items: ["a"] };
  const request = (value: unknown) =>
    new Request("https://test.invalid", {
      method: "POST",
      body: JSON.stringify(value),
    });
  assertEquals(await readJson(request(body)), body);
  const unusual = JSON.parse('{"__proto__":{"value":3},"constructor":"kept"}');
  assertEquals(await readJson(request(unusual)), unusual);
  for (const value of [null, [], "x", 1, false]) {
    const error = await assertRejects(() => readJson(request(value)), HttpError);
    assertEquals([error.status, error.code, error.detail], [400, "invalid_json", undefined]);
  }
});

Deno.test("string boundary preserves null, empty, spaces and UTF-16 length behavior", () => {
  assertEquals(optionalString({}, "v"), null);
  assertEquals(optionalString({ v: null }, "v"), null);
  assertEquals(optionalString({ v: "" }, "v"), "");
  assertEquals(requireString({ v: " " }, "v"), " ");
  assertEquals(requireString({ v: "한글" }, "v", 2), "한글");
  assertThrows(() => requireString({ v: "😀" }, "v", 1), HttpError);
  const error = assertThrows(() => requireString({ v: "sensitive-value" }, "v", 2), HttpError);
  assertEquals([error.code, error.detail, error.message], ["invalid_field", "v", "invalid_field"]);
});

Deno.test("property: Zod boundaries preserve the pre-integration JSON contracts", () => {
  fc.assert(
    fc.property(fc.jsonValue(), fc.integer({ min: 1, max: 100 }), (v, max) => {
      const objectBefore = v !== null && typeof v === "object" && !Array.isArray(v);
      assertEquals(jsonObjectSchema.safeParse(v).success, objectBefore);
      const requiredBefore = typeof v === "string" && v.length > 0 && v.length <= max;
      if (requiredBefore) assertEquals(requireString({ v }, "v", max), v);
      else assertThrows(() => requireString({ v }, "v", max), HttpError);
      const optionalBefore = v === null || (typeof v === "string" && v.length <= max);
      if (optionalBefore) assertEquals(optionalString({ v }, "v", max), v);
      else assertThrows(() => optionalString({ v }, "v", max), HttpError);
    }),
    { seed: 20261012, numRuns: 1500 },
  );
});

Deno.test("photo path schema retains the existing Edge boundary (SQL validates ownership)", () => {
  for (const paths of [[""], ["x".repeat(512)], Array(20).fill("user/request/p.jpg")]) {
    assert(photoPathsSchema.safeParse(paths).success);
  }
  for (const paths of [[], null, {}, [12], ["x".repeat(513)], Array(21).fill("p")]) {
    assert(!photoPathsSchema.safeParse(paths).success);
  }
  fc.assert(
    fc.property(fc.jsonValue(), (paths) => {
      const before = Array.isArray(paths) && paths.length > 0 && paths.length <= 20 &&
        paths.every((p) => typeof p === "string" && p.length <= 512);
      assertEquals(photoPathsSchema.safeParse(paths).success, before);
    }),
    { seed: 20261012, numRuns: 500 },
  );
});
