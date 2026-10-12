// purge-all ([S09d]): the client request id goes to purge_all as p_request_id,
// a replay answer is passed through without deleting objects twice, a missing
// id is the legacy call, and a malformed id is rejected before any RPC.
import { assertEquals, assertThrows } from "@std/assert";
import { purgeAll, requestIdOf } from "../purge-all/index.ts";
import { HttpError } from "../_shared/http.ts";

const A = "aaaaaaaa-0000-4000-8000-000000000001";
const R = "90000000-0000-4000-8000-000000000001";

type Call = { name: string; args: Record<string, unknown> };

function recorder(handler: (args: Record<string, unknown>) => unknown) {
  const calls: Call[] = [];
  const deleted: string[][] = [];
  const call = <T = unknown>(name: string, args: Record<string, unknown>): Promise<T> => {
    calls.push({ name, args });
    return Promise.resolve(handler(args) as T);
  };
  const del = (paths: string[]): Promise<string[]> => {
    deleted.push(paths);
    return Promise.resolve([]);
  };
  return { calls, deleted, call, del };
}

Deno.test("purge-all: the request id reaches purge_all and the epoch comes back", async () => {
  const rec = recorder(() => ({ epoch: 9, object_paths: [`${A}/x/p0.jpg`], replayed: false }));
  const out = await purgeAll(A, R, rec.call, rec.del);
  assertEquals(out, { epoch: 9, replayed: false });
  assertEquals(rec.calls, [{ name: "purge_all", args: { p_user: A, p_request_id: R } }]);
  assertEquals(rec.deleted, [[`${A}/x/p0.jpg`]]);
});

Deno.test("purge-all: a replayed request deletes nothing and says so", async () => {
  const rec = recorder(() => ({ epoch: 9, object_paths: [], replayed: true }));
  const out = await purgeAll(A, R, rec.call, rec.del);
  assertEquals(out, { epoch: 9, replayed: true });
  assertEquals(rec.deleted, []);
});

Deno.test("purge-all: no request id → legacy call with null", async () => {
  const rec = recorder(() => ({ epoch: 1, object_paths: [] }));
  const out = await purgeAll(A, null, rec.call, rec.del);
  assertEquals(out, { epoch: 1, replayed: false });
  assertEquals(rec.calls[0].args, { p_user: A, p_request_id: null });
});

Deno.test("requestIdOf: absent → null, uuid → lower-cased, anything else → 400 invalid_field", () => {
  assertEquals(requestIdOf({}), null);
  assertEquals(requestIdOf({ request_id: null }), null);
  assertEquals(requestIdOf({ request_id: R.toUpperCase() }), R);
  const err = assertThrows(() => requestIdOf({ request_id: "not-a-uuid" }), HttpError);
  assertEquals([err.status, err.code, err.detail], [400, "invalid_field", "request_id"]);
  assertThrows(() => requestIdOf({ request_id: 42 }), HttpError);
});
