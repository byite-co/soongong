import { HttpError } from "./http.ts";

export const STUDY_DEADLINE_MS = 55_000;

export interface DeadlineClock {
  now(): number;
  setTimeout(callback: () => void, ms: number): unknown;
  clearTimeout(timer: unknown): void;
}
const systemClock: DeadlineClock = {
  now: () => performance.now(),
  setTimeout: (callback, ms) => setTimeout(callback, ms),
  clearTimeout: (timer) => clearTimeout(timer as ReturnType<typeof setTimeout>),
};

export function studyUnavailable(): HttpError {
  return new HttpError(503, "engine_unavailable");
}

/** Bound the wait as well as passing the signal to the actual I/O owner. */
export function abortable<T>(pending: PromiseLike<T>, signal?: AbortSignal): Promise<T> {
  const promise = Promise.resolve(pending);
  if (!signal) return promise;
  return new Promise<T>((resolve, reject) => {
    const clean = () => signal.removeEventListener("abort", abort);
    const abort = () => {
      clean();
      reject(studyUnavailable());
    };
    signal.addEventListener("abort", abort, { once: true });
    promise.then((value) => {
      clean();
      resolve(value);
    }, (error) => {
      clean();
      reject(error);
    });
    if (signal.aborted) abort();
  });
}

/** One budget, starting at handler entry; no stage resets its deadline. */
export class StudyDeadline {
  private readonly controller = new AbortController();
  private readonly expires: number;
  private readonly timer: unknown;
  private readonly cancel = () => this.controller.abort();
  readonly signal = this.controller.signal;

  constructor(
    private readonly source: AbortSignal,
    ms = STUDY_DEADLINE_MS,
    private readonly clock: DeadlineClock = systemClock,
  ) {
    this.expires = clock.now() + ms;
    this.timer = clock.setTimeout(this.cancel, ms);
    source.addEventListener("abort", this.cancel, { once: true });
    if (source.aborted) this.cancel();
  }

  check(): void {
    if (this.clock.now() >= this.expires) this.cancel();
    if (this.signal.aborted) throw studyUnavailable();
  }

  async run<T>(operation: (signal: AbortSignal) => PromiseLike<T>): Promise<T> {
    this.check();
    const value = await abortable(operation(this.signal), this.signal);
    this.check();
    return value;
  }

  close(): void {
    this.clock.clearTimeout(this.timer);
    this.source.removeEventListener("abort", this.cancel);
    // Also stop any unread upstream error body or a still-settling SDK fetch.
    this.controller.abort();
  }
}
