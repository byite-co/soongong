// v2 durable jobs; v1 inference results remain unchanged. No reading-quota
// mutation. No result is automatically a user-confirmed restore document.
import { type Caller, requireUser } from "../_shared/auth.ts";
import { serviceClient } from "../_shared/db.ts";
import { env, envList, envOr } from "../_shared/env.ts";
import { HttpError, json, methodNotAllowed } from "../_shared/http.ts";
import {
  boundedJson,
  requireStudyProfile,
  solutionResponse,
  studyEnvelope,
  transcriptionResponse,
} from "../_shared/study.ts";
import { type DeadlineClock, STUDY_DEADLINE_MS, StudyDeadline } from "../_shared/study_deadline.ts";
import { AiJobs, inputDigest } from "../_shared/ai_jobs.ts";
import { receipt } from "../_shared/worker_receipt.ts";

interface StudyDependencies {
  user: (req: Request, signal: AbortSignal) => Promise<Caller>;
  profile: (userId: string, signal: AbortSignal) => Promise<Record<string, unknown> | null>;
  fetch: typeof fetch;
  deadlineMs: number;
  clock?: DeadlineClock;
  jobs: AiJobs;
}
const defaults: StudyDependencies = {
  user: requireUser,
  profile: async (userId, signal) => {
    const { data, error } = await serviceClient().from("profiles")
      .select("consent_account_at,consent_reading_at,consent_reading_revoked_at,purge_epoch")
      .eq("user_id", userId).abortSignal(signal).maybeSingle();
    if (error) throw new HttpError(503, "profile_unavailable");
    return data;
  },
  fetch: (input, init) => fetch(input, init),
  deadlineMs: STUDY_DEADLINE_MS,
  jobs: new AiJobs(),
};

/** Test seams replace I/O, never the handler's lifetime/validation logic. */
export async function handle(
  req: Request,
  overrides: Partial<StudyDependencies> = {},
): Promise<Response> {
  const deps = { ...defaults, ...overrides };
  const deadline = new StudyDeadline(req.signal, deps.deadlineMs, deps.clock);
  let currentJob: string | undefined;
  try {
    deadline.check();
    const mna = methodNotAllowed(req);
    if (mna) return mna;
    const caller = await deadline.run((signal) => deps.user(req, signal));
    if (
      envOr("STUDY_AI_ENABLED", "false") !== "true" ||
      !envList("STUDY_AI_USER_IDS").includes(caller.userId)
    ) {
      throw new HttpError(503, "engine_unavailable");
    }
    const parsed = studyEnvelope.safeParse(
      await deadline.run((signal) => boundedJson(req.body, 5600000, signal)),
    );
    if (!parsed.success) throw new HttpError(400, "invalid_payload");
    const envelope = parsed.data;
    const body = envelope.input;
    const profile = () => deadline.run((signal) => deps.profile(caller.userId, signal));
    requireStudyProfile(await profile(), body.purge_epoch);
    const endpoint = new URL(
      env(
        body.operation === "solve"
          ? "STUDY_SOLVER_WORKER_URL"
          : body.kind === "math"
          ? "STUDY_MATH_OCR_WORKER_URL"
          : "STUDY_WORKER_URL",
      ),
    );
    if (
      endpoint.protocol !== "https:" || endpoint.username || endpoint.password || endpoint.search ||
      endpoint.hash
    ) {
      throw new HttpError(503, "engine_unavailable");
    }
    // Validate configuration before reserving anything. No secret crosses the app.
    const secret = env("STUDY_WORKER_SECRET");
    if (secret.length < 32) throw new HttpError(503, "engine_unavailable");
    const digest = await deadline.run(() => inputDigest(body));
    const job = await deadline.run(signal => deps.jobs.reserve({
      p_user: caller.userId, p_epoch: body.purge_epoch, p_request: envelope.request_id,
      p_quote: envelope.quote_id, p_operation: body.operation === "solve" ? "solve" : `ocr_${body.kind}`,
      p_digest: digest, p_document: body.operation === "solve" ? body.document_id : null,
      p_revision: body.operation === "solve" ? body.revision : null,
    }, signal));
    if (job.state !== "reserved") return json(job, job.state === "succeeded" ? 200 : 202, { "cache-control": "no-store" });
    currentJob = job.job_id;
    const dispatch = await deadline.run(signal => deps.jobs.dispatch(caller.userId, body.purge_epoch, job.job_id, signal));
    if (!dispatch.claimed) return json(dispatch.job, 202, { "cache-control": "no-store" });
    const response = await deadline.run((signal) =>
      deps.fetch(endpoint, {
        method: "POST",
        redirect: "error",
        signal,
        headers: {
          "content-type": "application/json",
          "authorization": `Bearer ${secret}`,
        },
        body: JSON.stringify({ version: 2, attempt_id: dispatch.attempt_id, provider: dispatch.provider,
          model: dispatch.model, limits: dispatch.limits, input: body }),
      })
    );
    if (!response.ok) {
      throw new HttpError(response.status === 429 ? 429 : 503, "engine_unavailable");
    }
    const raw = await deadline.run((signal) => boundedJson(response.body, 256000, signal));
    const evidence = receipt(raw, dispatch.attempt_id, dispatch.provider, dispatch.model);
    // Cost evidence is independent of result validity, revocation and refunds.
    await deadline.run(signal => deps.jobs.rpc("ai_record_evidence", {
      p_job: job.job_id, p_reading_cost: null, p_attempt: evidence.attempt_id,
      p_provider: evidence.provider, p_model: evidence.model, p_usage: evidence.usage,
    }, signal));
    const parsedResult = body.operation === "ocr"
      ? transcriptionResponse.safeParse(evidence.result)
      : solutionResponse.safeParse(evidence.result);
    if (!parsedResult.success) throw new HttpError(502, "invalid_engine_result");
    const result = parsedResult.data;
    if (body.operation === "ocr" && (!("kind" in result) || result.kind !== body.kind)) {
      throw new HttpError(502, "invalid_engine_result");
    }
    if (
      body.operation === "solve" &&
      (!("document_id" in result) || result.document_id !== body.document_id ||
        result.revision !== body.revision ||
        result.reference_provided !== Boolean(body.reference_answer) ||
        (result.verification === "verified" && !body.reference_answer))
    ) {
      throw new HttpError(502, "invalid_engine_result");
    }
    // Deletion/revocation/account removal during inference invalidates it.
    await deadline.run((signal) => deps.user(req, signal));
    requireStudyProfile(await profile(), body.purge_epoch);
    deadline.check();
    const saved = await deadline.run(signal => deps.jobs.finish(job.job_id, "succeeded", result, signal));
    return json(saved, saved.state === "succeeded" ? 200 : 409, { "cache-control": "no-store" });
  } catch (error) {
    if (currentJob) {
      try {
        // Within the original budget only. If cancelled/expired, the durable
        // lease becomes reconciliation_required; never another HTTP allowance.
        deadline.check();
        await deadline.run(signal => deps.jobs.finish(currentJob!, "failed", null, signal));
      } catch { /* Reservation/unknown cost remains for the bounded maintenance job. */ }
    }
    if (error instanceof HttpError) throw error;
    throw new HttpError(503, "engine_unavailable");
  } finally {
    deadline.close();
  }
}

if (import.meta.main) {
  const { serve } = await import("../_shared/http.ts");
  serve(handle);
}
