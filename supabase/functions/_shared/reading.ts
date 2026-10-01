// Shared bits of the reading functions: outcome → HTTP mapping, immediate
// photo deletion after a terminal transition (queue row → done on success).
import { rpc } from "./db.ts";
import { deleteObjects } from "./storage.ts";

export interface FinishResult {
  outcome: string;
  status: string | null;
  user_id?: string;
  object_paths?: string[];
  request?: Record<string, unknown>;
}

/** Try to delete the request's objects now; whatever fails stays `pending` for the runner. */
export async function deletePhotosNow(requestId: string, paths: string[] | undefined): Promise<{ deleted: number; pending: number }> {
  const list = paths ?? [];
  if (list.length === 0) return { deleted: 0, pending: 0 };
  const stillThere = await deleteObjects(list);
  const done = list.filter((p) => !stillThere.includes(p));
  if (done.length > 0) await rpc("photo_delete_done", { p_request_id: requestId, p_paths: done });
  return { deleted: done.length, pending: stillThere.length };
}

export function requestIdFrom(body: Record<string, unknown>): string {
  const v = body.request_id;
  if (typeof v !== "string" || !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/.test(v)) {
    throw new (class extends Error {})("invalid request_id");
  }
  return v;
}
