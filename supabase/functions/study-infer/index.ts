// Bounded, stateless pilot. Images never enter Storage/SQL or logs. No
// reading-quota mutation and no unconfigured/Fake success. Broader release
// requires a durable usage policy and the held-out model evaluation.
import { type Caller, requireUser } from "../_shared/auth.ts";
import { serviceClient } from "../_shared/db.ts";
import { env, envList, envOr } from "../_shared/env.ts";
import { HttpError, json, methodNotAllowed } from "../_shared/http.ts";
import {
  boundedJson,
  requireStudyProfile,
  solutionResponse,
  studyRequest,
  transcriptionResponse,
} from "../_shared/study.ts";
import { type DeadlineClock, STUDY_DEADLINE_MS, StudyDeadline } from "../_shared/study_deadline.ts";

interface StudyDependencies {
  user: (req: Request, signal: AbortSignal) => Promise<Caller>;
  profile: (userId: string, signal: AbortSignal) => Promise<Record<string, unknown> | null>;
  fetch: typeof fetch;
  deadlineMs: number;
  clock?: DeadlineClock;
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
};

/** Test seams replace I/O, never the handler's lifetime/validation logic. */
export async function handle(
  req: Request,
  overrides: Partial<StudyDependencies> = {},
): Promise<Response> {
  const deps = { ...defaults, ...overrides };
  const deadline = new StudyDeadline(req.signal, deps.deadlineMs, deps.clock);
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
    const parsed = studyRequest.safeParse(
      await deadline.run((signal) => boundedJson(req.body, 5600000, signal)),
    );
    if (!parsed.success) throw new HttpError(400, "invalid_payload");
    const body = parsed.data;
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
    const response = await deadline.run((signal) =>
      deps.fetch(endpoint, {
        method: "POST",
        redirect: "error",
        signal,
        headers: {
          "content-type": "application/json",
          "authorization": `Bearer ${env("STUDY_WORKER_SECRET")}`,
        },
        body: JSON.stringify(body),
      })
    );
    if (!response.ok) {
      throw new HttpError(response.status === 429 ? 429 : 503, "engine_unavailable");
    }
    const raw = await deadline.run((signal) => boundedJson(response.body, 256000, signal));
    const parsedResult = body.operation === "ocr"
      ? transcriptionResponse.safeParse(raw)
      : solutionResponse.safeParse(raw);
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
    return json(result, 200, { "cache-control": "no-store" });
  } catch (error) {
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
