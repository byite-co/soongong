import { assertEquals, assertRejects } from "@std/assert";
import { AiJobs } from "../_shared/ai_jobs.ts";
import { handle } from "../study-infer/index.ts";
import { requireUser } from "../_shared/auth.ts";
import { boundedJson } from "../_shared/study.ts";
import { DeadlineClock, STUDY_DEADLINE_MS } from "../_shared/study_deadline.ts";
import { HttpError } from "../_shared/http.ts";

class Clock implements DeadlineClock {
  time = 0;
  next = 0;
  timers = new Map<number, { at: number; callback: () => void }>();
  now = () => this.time;
  setTimeout = (callback: () => void, ms: number) => {
    const id = ++this.next;
    this.timers.set(id, { at: this.time + ms, callback });
    return id;
  };
  clearTimeout = (id: unknown) => {
    this.timers.delete(id as number);
  };
  advance(ms: number) {
    this.time += ms;
    for (const [id, timer] of this.timers) {
      if (timer.at <= this.time) {
        this.timers.delete(id);
        timer.callback();
      }
    }
  }
}
function deferred<T = void>() {
  let resolve!: (value: T) => void;
  const promise = new Promise<T>((r) => {
    resolve = r;
  });
  return { promise, resolve };
}
const payload = {
  schema_version: 1,
  operation: "ocr",
  kind: "text",
  image: "YQ==",
  purge_epoch: 0,
  consent_version: "study-2026-10-13",
};
const result = { schema_version: 1, kind: "text", engine: "fixture", blocks: [] };
const profile = {
  consent_account_at: "yes",
  consent_reading_at: "yes",
  consent_reading_revoked_at: null,
  purge_epoch: 0,
};

function fixture() {
  const clock = new Clock();
  const calls = { user: 0, profile: 0, worker: 0 };
  const io = {
    clock,
    jobs: new AiJobs(<T>(name: string) => Promise.resolve((name === "ai_dispatch"
      ? {claimed:true,attempt_id:"33333333-3333-4333-8333-333333333333",provider:"local",model:"fixture",limits:{max_input_tokens:100,max_output_tokens:100,max_attempts:1}}
      : {version:2,job_id:"44444444-4444-4444-8444-444444444444",request_id:"11111111-1111-4111-8111-111111111111",state:name === "ai_finish" ? "succeeded" : "reserved",result}) as T)),
    user: async (_req: Request, _signal: AbortSignal) => {
      calls.user++;
      return { userId: "fixture", deviceId: null };
    },
    profile: async (_id: string, _signal: AbortSignal): Promise<Record<string, unknown> | null> => {
      calls.profile++;
      return profile;
    },
    fetch: ((_input: RequestInfo | URL, _init?: RequestInit) => {
      calls.worker++;
      return Promise.resolve(Response.json({worker_version:1,attempt_id:"33333333-3333-4333-8333-333333333333",provider:"local",model:"fixture",result,usage:{requests:1,images:1,pages:1,crops:0,elapsed_ms:1},billing:"local_no_external_api"}));
    }) as typeof fetch,
  };
  return { clock, calls, io };
}
function request(signal?: AbortSignal, body?: BodyInit) {
  return new Request("https://fixture.invalid/study-infer", {
    method: "POST",
    body: body ?? JSON.stringify({version:2,request_id:"11111111-1111-4111-8111-111111111111",quote_id:"22222222-2222-4222-8222-222222222222",input:payload}),
    signal,
  });
}
async function unavailable(promise: Promise<unknown>) {
  const error = await assertRejects(() => promise, HttpError, "engine_unavailable");
  assertEquals(error.status, 503);
}
async function configured(run: () => Promise<void>) {
  const values: Record<string, string> = {
    STUDY_AI_ENABLED: "true",
    STUDY_AI_USER_IDS: "fixture",
    STUDY_WORKER_URL: "https://fixture.invalid/infer",
    STUDY_WORKER_SECRET: "synthetic-test-only-0000000000000000",
  };
  const before = Object.fromEntries(Object.keys(values).map((key) => [key, Deno.env.get(key)]));
  try {
    for (const [key, value] of Object.entries(values)) Deno.env.set(key, value);
    await run();
  } finally {
    for (const [key, value] of Object.entries(before)) {
      if (value === undefined) Deno.env.delete(key);
      else Deno.env.set(key, value);
    }
  }
}

Deno.test("study deadline: defaults and normal handler preserve validation and no-store", () =>
  configured(async () => {
    assertEquals(STUDY_DEADLINE_MS, 55_000);
    const f = fixture();
    const response = await handle(request(), f.io);
    assertEquals(response.status, 200);
    assertEquals(response.headers.get("cache-control"), "no-store");
    assertEquals(f.calls, { user: 2, profile: 2, worker: 1 });
    assertEquals(f.clock.timers.size, 0);
  }));

Deno.test("study deadline: pre-aborted request starts no external operation", () =>
  configured(async () => {
    const f = fixture();
    const abort = new AbortController();
    abort.abort();
    await unavailable(handle(request(abort.signal), f.io));
    assertEquals(f.calls, { user: 0, profile: 0, worker: 0 });
    assertEquals(f.clock.timers.size, 0);
  }));

Deno.test("study deadline: stuck body and stuck cancel release reader without another budget", () =>
  configured(async () => {
    const f = fixture();
    const reading = deferred();
    let cancels = 0;
    const stream = new ReadableStream<Uint8Array>({
      pull() {
        reading.resolve();
      },
      cancel() {
        cancels++;
        return new Promise(() => {});
      },
    });
    f.io.user = async () => {
      f.calls.user++;
      f.clock.advance(40_000);
      return { userId: "fixture", deviceId: null };
    };
    const pending = handle(request(undefined, stream), f.io);
    await reading.promise;
    // Wait for the actual body reader, rather than relying on elapsed wall time.
    while (!stream.locked) await Promise.resolve();
    f.clock.advance(15_000);
    await unavailable(pending);
    assertEquals(cancels, 1);
    assertEquals(stream.locked, false);
    assertEquals(f.calls, { user: 1, profile: 0, worker: 0 });
    assertEquals(f.clock.timers.size, 0);
  }));

for (
  const stage of ["auth", "body", "worker", "response", "final-auth", "final-profile"] as const
) {
  Deno.test(`study deadline: cancellation during ${stage} aborts I/O and starts no next stage`, () =>
    configured(async () => {
      const f = fixture();
      const abort = new AbortController();
      const entered = deferred();
      let ioSignal: AbortSignal | undefined;
      let streamCancels = 0;
      let responseStream: ReadableStream<Uint8Array> | undefined;
      const stalled = (signal: AbortSignal) => {
        ioSignal = signal;
        entered.resolve();
        return new Promise<never>((_resolve, reject) =>
          signal.addEventListener("abort", () => reject(new Error("cancelled")), { once: true })
        );
      };
      let body: BodyInit | undefined;
      const stream = () =>
        new ReadableStream<Uint8Array>({
          pull() {
            entered.resolve();
          },
          cancel() {
            streamCancels++;
          },
        });
      if (stage === "auth" || stage === "final-auth") {
        f.io.user = async (_req, signal) => {
          f.calls.user++;
          if (stage === "auth" || f.calls.user === 2) return await stalled(signal);
          return { userId: "fixture", deviceId: null };
        };
      }
      if (stage === "body") body = stream();
      if (stage === "worker") {
        f.io.fetch = ((_input, init) => {
          f.calls.worker++;
          return stalled(init!.signal!);
        }) as typeof fetch;
      }
      if (stage === "response") {
        f.io.fetch = (() => {
          f.calls.worker++;
          responseStream = stream();
          return Promise.resolve(new Response(responseStream));
        }) as typeof fetch;
      }
      if (stage === "final-profile") {
        f.io.profile = async (_id, signal) => {
          f.calls.profile++;
          if (f.calls.profile === 2) return await stalled(signal);
          return profile;
        };
      }
      const pending = handle(request(abort.signal, body), f.io);
      await entered.promise;
      // A source pull may run when its stream is created; wait for handler entry.
      if (stage === "body") {
        while (f.calls.user === 0 || !(body as ReadableStream).locked) await Promise.resolve();
      }
      if (stage === "response") { while (!responseStream?.locked) await Promise.resolve(); }
      abort.abort();
      await unavailable(pending);
      if (ioSignal) assertEquals(ioSignal.aborted, true);
      if (stage === "body" || stage === "response") assertEquals(streamCancels, 1);
      const expected = {
        auth: [1, 0, 0],
        body: [1, 0, 0],
        worker: [1, 1, 1],
        response: [1, 1, 1],
        "final-auth": [2, 1, 1],
        "final-profile": [2, 2, 1],
      }[stage];
      assertEquals([f.calls.user, f.calls.profile, f.calls.worker], expected);
      assertEquals(f.clock.timers.size, 0);
    }));
}

Deno.test("study deadline: final profile cannot return success after total expiry", () =>
  configured(async () => {
    const f = fixture();
    f.io.profile = async () => {
      f.calls.profile++;
      if (f.calls.profile === 2) f.clock.advance(55_000);
      return profile;
    };
    await unavailable(handle(request(), f.io));
    assertEquals(f.calls, { user: 2, profile: 2, worker: 1 });
    assertEquals(f.clock.timers.size, 0);
  }));

Deno.test("study bounded bodies: exact byte limits, malformed UTF8/JSON and lying lengths", async () => {
  for (const limit of [5_600_000, 256_000]) {
    for (const delta of [-1, 0, 1]) {
      const stream = new Response('"' + "a".repeat(limit + delta - 2) + '"').body;
      if (delta > 0) {
        const error = await assertRejects(() => boundedJson(stream, limit), HttpError);
        assertEquals(error.status, 413);
      } else assertEquals((await boundedJson(stream, limit) as string).length, limit + delta - 2);
    }
  }
  for (const body of [new Uint8Array([0xff]), new TextEncoder().encode("{")]) {
    const error = await assertRejects(() => boundedJson(new Response(body).body, 20), HttpError);
    assertEquals(error.status, 400);
  }
  // No trust in Content-Length: boundedJson counts chunks actually received.
  const response = new Response("123456", { headers: { "content-length": "1" } });
  assertEquals((await assertRejects(() => boundedJson(response.body, 5), HttpError)).status, 413);
});

Deno.test("study auth option forwards cancellation into the pinned SDK fetch", async () => {
  const oldFetch = globalThis.fetch;
  const oldUrl = Deno.env.get("SUPABASE_URL"), oldKey = Deno.env.get("SUPABASE_ANON_KEY");
  Deno.env.set("SUPABASE_URL", "https://fixture.invalid");
  Deno.env.set("SUPABASE_ANON_KEY", "synthetic");
  const entered = deferred();
  const abort = new AbortController();
  let passed: AbortSignal | null | undefined;
  try {
    globalThis.fetch = ((_input, init) => {
      passed = init?.signal;
      entered.resolve();
      return new Promise((_resolve, reject) =>
        passed!.addEventListener("abort", () => reject(new DOMException("aborted", "AbortError")), {
          once: true,
        })
      );
    }) as typeof fetch;
    const pending = requireUser(
      new Request("https://fixture.invalid", { headers: { authorization: "Bearer synthetic" } }),
      abort.signal,
    );
    await entered.promise;
    abort.abort();
    await assertRejects(() => pending);
    assertEquals(passed, abort.signal);
    assertEquals(passed!.aborted, true);
  } finally {
    globalThis.fetch = oldFetch;
    for (const [key, value] of [["SUPABASE_URL", oldUrl], ["SUPABASE_ANON_KEY", oldKey]]) {
      if (value === undefined) Deno.env.delete(key!);
      else Deno.env.set(key!, value);
    }
  }
});
