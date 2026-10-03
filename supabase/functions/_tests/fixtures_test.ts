// RevenueCat fixture sanity (the 8 JSON files are the inputs of 05_billing.sql):
// every fixture has the fields revenuecat_apply_event() reads.
import { assert, assertEquals } from "@std/assert";

const dir = new URL("../../tests/fixtures/revenuecat/", import.meta.url);
Deno.test("8 RevenueCat fixtures are well-formed", async () => {
  const files: string[] = [];
  for await (const e of Deno.readDir(dir)) if (e.name.endsWith(".json")) files.push(e.name);
  assertEquals(files.length, 8);
  for (const f of files) {
    const j = JSON.parse(await Deno.readTextFile(new URL(f, dir)));
    assert(typeof j.event?.id === "string", f);
    assert(typeof j.event?.type === "string", f);
    assert(typeof j.event?.event_timestamp_ms === "number", f);
    assert(typeof j.event?.app_user_id === "string", f);
  }
});
