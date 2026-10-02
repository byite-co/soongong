// Account boundary (D16, 0010): every ledger call made by the Edge layer carries
// the owner next to the request_id, and the owner is the one from the claimed job /
// the authenticated caller — never derived from the request_id alone.
import { assertEquals, assertRejects } from "@std/assert";
import { runOnce } from "../reading-worker/index.ts";
import { cancel } from "../reading-cancel/index.ts";
import { runQueue } from "../photo-delete-runner/index.ts";
import { HttpError } from "../_shared/http.ts";

type Call = { name: string; args: Record<string, unknown> };

function recorder(handlers: Record<string, (args: Record<string, unknown>) => unknown>) {
  const calls: Call[] = [];
  const call = <T = unknown>(name: string, args: Record<string, unknown>): Promise<T> => {
    calls.push({ name, args });
    const h = handlers[name];
    if (!h) throw new Error(`unexpected rpc ${name}`);
    return Promise.resolve(h(args) as T);
  };
  return { calls, call };
}

const A = "aaaaaaaa-0000-4000-8000-000000000001";
const B = "bbbbbbbb-0000-4000-8000-000000000002";
const X = "60000000-0000-4000-8000-000000000001"; // same request_id for both accounts

Deno.test("worker: reading_finish and photo_delete_done carry the claimed job's user_id", async () => {
  let claimed = 0;
  const jobs = [
    { request_id: X, user_id: A, attempts: 1, object_paths: [`${A}/${X}/p0.jpg`], subject_id: null, range_text: null },
    { request_id: X, user_id: B, attempts: 1, object_paths: [`${B}/${X}/p0.jpg`], subject_id: null, range_text: null },
  ];
  const rec = recorder({
    reading_claim_job: () => jobs[claimed++] ?? null,
    reading_finish: (a) => ({ outcome: "failed", status: "failed", user_id: a.p_user, request_id: a.p_request_id, object_paths: [`${a.p_user}/${a.p_request_id}/p0.jpg`] }),
    photo_delete_done: () => 1,
  });
  const out = await runOnce(undefined, 20, rec.call, (paths) => Promise.resolve(paths.filter(() => false)));
  assertEquals(out.processed, [{ user_id: A, request_id: X }, { user_id: B, request_id: X }]);
  const finishes = rec.calls.filter((c) => c.name === "reading_finish").map((c) => [c.args.p_user, c.args.p_request_id]);
  assertEquals(finishes, [[A, X], [B, X]]);
  const dones = rec.calls.filter((c) => c.name === "photo_delete_done").map((c) => [c.args.p_user, c.args.p_request_id, c.args.p_paths]);
  assertEquals(dones, [[A, X, [`${A}/${X}/p0.jpg`]], [B, X, [`${B}/${X}/p0.jpg`]]]);
});

Deno.test("cancel: B cancelling request_id X only touches (B, X); an id B does not own is not_found", async () => {
  const rec = recorder({
    reading_status: (a) => (a.p_user === B ? { outcome: "ok", status: "processing" } : { outcome: "not_found" }),
    reading_finish: (a) => ({ outcome: "cancelled", status: "cancelled", user_id: a.p_user, request_id: a.p_request_id, object_paths: [] }),
  });
  const out = await cancel(B, X, rec.call);
  assertEquals(out, { outcome: "cancelled" });
  for (const c of rec.calls) assertEquals(c.args.p_user, B);
  assertEquals(rec.calls.map((c) => c.name), ["reading_status", "reading_finish"]);

  const other = recorder({ reading_status: () => ({ outcome: "not_found" }) });
  await assertRejects(() => cancel(A, X, other.call), HttpError, "not_found");
  assertEquals(other.calls.map((c) => c.name), ["reading_status"]); // no finish for a request A does not own
});

Deno.test("photo-delete-runner: repeats full batches in one run, stops at a short batch or 10 rounds", async () => {
  let served = 0;
  const total = 1200;
  const rec = recorder({
    photo_delete_claim: (a) => {
      const n = Math.min(a.p_limit as number, total - served);
      const rows = Array.from({ length: n }, (_, i) => ({ id: served + i + 1, user_id: A, request_id: X, bucket_path: `${A}/${X}/p${served + i}.jpg`, attempts: 1 }));
      served += n;
      return rows;
    },
    photo_delete_mark: (a) => (a.p_ids as number[]).length,
  });
  const out = await runQueue(500, 10, rec.call, () => Promise.resolve([]));
  assertEquals(out, { done: 1200, failed: 0, rounds: 3 });
  assertEquals(rec.calls.filter((c) => c.name === "photo_delete_claim").length, 3);
});
