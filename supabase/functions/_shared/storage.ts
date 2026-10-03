// Storage helpers for the private `reading-photos` bucket (D14: delete right
// after the terminal transition; failures stay `pending` in photo_delete_queue).
import { serviceClient } from "./db.ts";

export const PHOTO_BUCKET = "reading-photos";

/** Deletes objects; returns the paths that were NOT confirmed deleted. */
export async function deleteObjects(paths: string[]): Promise<string[]> {
  if (paths.length === 0) return [];
  const { data, error } = await serviceClient().storage.from(PHOTO_BUCKET).remove(paths);
  if (error) return paths;
  const removed = new Set((data ?? []).map((o) => o.name));
  // A missing object is a success for our purpose (nothing left to delete):
  // Storage only lists the objects it actually removed, so re-check the rest.
  const unconfirmed = paths.filter((p) => !removed.has(p));
  if (unconfirmed.length === 0) return [];
  const stillThere: string[] = [];
  for (const p of unconfirmed) {
    const dir = p.substring(0, p.lastIndexOf("/"));
    const name = p.substring(p.lastIndexOf("/") + 1);
    const { data: listed, error: listErr } = await serviceClient().storage.from(PHOTO_BUCKET).list(dir, { search: name, limit: 10 });
    if (listErr) { stillThere.push(p); continue; }
    if ((listed ?? []).some((o) => o.name === name)) stillThere.push(p);
  }
  return stillThere;
}
