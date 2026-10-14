// purge-all ([S09d] · [S09e]): the client request id and expected epoch reach
// purge_all, a replayed / superseded answer is passed through without deleting
// objects, a missing id or epoch is the legacy call, and a malformed field is
// rejected before any RPC.
import { assertEquals, assertThrows } from "@std/assert";
import { expectedEpochOf, purgeAll, requestIdOf } from "../purge-all/index.ts";
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

Deno.test("purge-all: the request id and the expected epoch reach purge_all and the epoch comes back", async () => {
  const rec = recorder(() => ({ epoch: 9, object_paths: [`${A}/x/p0.jpg`], replayed: false, superseded: false }));
  const out = await purgeAll(A, R, 8, rec.call, rec.del);
  assertEquals(out, { epoch: 9, replayed: false, superseded: false });
  assertEquals(rec.calls, [{ name: "purge_all", args: { p_user: A, p_request_id: R, p_expected_epoch: 8 } }]);
  assertEquals(rec.deleted, [[`${A}/x/p0.jpg`]]);
});

Deno.test("purge-all: a replayed request deletes nothing and says so", async () => {
  const rec = recorder(() => ({ epoch: 9, object_paths: [], replayed: true, superseded: false }));
  const out = await purgeAll(A, R, 8, rec.call, rec.del);
  assertEquals(out, { epoch: 9, replayed: true, superseded: false });
  assertEquals(rec.deleted, []);
});

Deno.test("purge-all: a superseded request deletes nothing and carries the current epoch", async () => {
  const rec = recorder(() => ({ epoch: 9, object_paths: [], replayed: false, superseded: true }));
  const out = await purgeAll(A, R, 7, rec.call, rec.del);
  assertEquals(out, { epoch: 9, replayed: false, superseded: true });
  assertEquals(rec.deleted, []);
});

Deno.test("purge-all: no request id / no expected epoch → legacy call with nulls", async () => {
  const rec = recorder(() => ({ epoch: 1, object_paths: [] }));
  const out = await purgeAll(A, null, null, rec.call, rec.del);
  assertEquals(out, { epoch: 1, replayed: false, superseded: false });
  assertEquals(rec.calls[0].args, { p_user: A, p_request_id: null, p_expected_epoch: null });
});

Deno.test("requestIdOf: absent → null, uuid → lower-cased, anything else → 400 invalid_field", () => {
  assertEquals(requestIdOf({}), null);
  assertEquals(requestIdOf({ request_id: null }), null);
  assertEquals(requestIdOf({ request_id: R.toUpperCase() }), R);
  const err = assertThrows(() => requestIdOf({ request_id: "not-a-uuid" }), HttpError);
  assertEquals([err.status, err.code, err.detail], [400, "invalid_field", "request_id"]);
  assertThrows(() => requestIdOf({ request_id: 42 }), HttpError);
});

Deno.test("expectedEpochOf: absent → null, non-negative integer → itself, anything else → 400 invalid_field", () => {
  assertEquals(expectedEpochOf({}), null);
  assertEquals(expectedEpochOf({ expected_epoch: null }), null);
  assertEquals(expectedEpochOf({ expected_epoch: 0 }), 0);
  assertEquals(expectedEpochOf({ expected_epoch: 12 }), 12);
  const err = assertThrows(() => expectedEpochOf({ expected_epoch: -1 }), HttpError);
  assertEquals([err.status, err.code, err.detail], [400, "invalid_field", "expected_epoch"]);
  assertThrows(() => expectedEpochOf({ expected_epoch: 1.5 }), HttpError);
  assertThrows(() => expectedEpochOf({ expected_epoch: "3" }), HttpError);
});
