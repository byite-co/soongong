import { serviceClient } from "./db.ts";
import { HttpError, statusForSqlError } from "./http.ts";

export type JobView = { version: 2; job_id: string; request_id: string; state: string; result: unknown; result_expired?: boolean };
export type Dispatch = { claimed: boolean; job: JobView; attempt_id?: string; provider?: string; model?: string; limits?: { max_input_tokens: number; max_output_tokens: number; max_attempts: number } };
export type JobRpc = <T>(name: string, args: Record<string, unknown>, signal: AbortSignal) => Promise<T>;
const call: JobRpc = async <T>(name: string, args: Record<string, unknown>, signal: AbortSignal) => {
  const { data, error } = await serviceClient().rpc(name, args).abortSignal(signal);
  if (error) {
    const code = /^[a-z_]+$/.test(error.message) ? error.message : "ledger_unavailable";
    throw new HttpError(statusForSqlError(code), code);
  }
  return data as T;
};

/** Real DB RPC repository. Tests may change transport, never accounting logic. */
export class AiJobs {
  constructor(readonly rpc: JobRpc = call) {}
  reserve(args: Record<string, unknown>, signal: AbortSignal) { return this.rpc<JobView>("ai_reserve", args, signal); }
  dispatch(user: string, epoch: number, job: string, signal: AbortSignal) {
    return this.rpc<Dispatch>("ai_dispatch", { p_user: user, p_epoch: epoch, p_job: job }, signal);
  }
  finish(job: string, outcome: string, result: unknown, signal: AbortSignal) {
    return this.rpc<JobView>("ai_finish", { p_job: job, p_outcome: outcome, p_result: result }, signal);
  }
}

export async function inputDigest(value: unknown): Promise<string> {
  const bytes = new TextEncoder().encode(JSON.stringify(value));
  return Array.from(new Uint8Array(await crypto.subtle.digest("SHA-256", bytes)), b => b.toString(16).padStart(2, "0")).join("");
}
