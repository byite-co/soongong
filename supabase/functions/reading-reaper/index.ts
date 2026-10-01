// reading-reaper — job function (x-job-secret). reading_reaper_run() (deadline /
// attempts exhausted → failed/timeout, photo queue rows) + immediate deletion.
// The SQL part also runs directly from the 1-minute pg_cron job, so this
// function is the "delete now" path and a manual trigger.
import { requireJobSecret } from "../_shared/auth.ts";
import { rpc } from "../_shared/db.ts";
import { json } from "../_shared/http.ts";
import { deletePhotosNow } from "../_shared/reading.ts";

export async function handle(req: Request): Promise<Response> {
  requireJobSecret(req);
  const out = await rpc<{ finished: { request_id: string; object_paths: string[] }[] }>("reading_reaper_run", {});
  let deleted = 0;
  for (const f of out.finished) deleted += (await deletePhotosNow(f.request_id, f.object_paths)).deleted;
  return json({ finished: out.finished.map((f) => f.request_id), deleted });
}

if (import.meta.main) {
  const { serve } = await import("../_shared/http.ts");
  serve(handle);
}
