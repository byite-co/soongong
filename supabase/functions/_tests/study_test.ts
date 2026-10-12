import { assertEquals, assertRejects, assertThrows } from "@std/assert";
import { boundedJson, requireStudyProfile, studyRequest, transcriptionResponse } from "../_shared/study.ts";
import { HttpError } from "../_shared/http.ts";

Deno.test("study ownership generation and consent fail closed", () => {
  const profile = { consent_account_at: "yes", consent_reading_at: "yes", consent_reading_revoked_at: null, purge_epoch: 4 };
  requireStudyProfile(profile, 4);
  assertThrows(() => requireStudyProfile(profile, 3), HttpError);
  assertThrows(() => requireStudyProfile({ ...profile, consent_reading_revoked_at: "now" }, 4), HttpError);
  assertThrows(() => requireStudyProfile(null, 4), HttpError);
});
Deno.test("study rejects overlarge chunked body and malformed input", async () => {
  await assertRejects(() => boundedJson(new Response("123456").body, 5), HttpError);
  await assertRejects(() => boundedJson(new Response("{").body, 5), HttpError);
  assertEquals(studyRequest.safeParse({ schema_version: 1, operation: "ocr", kind: "text", image: "YQ==", purge_epoch: 0, consent_version: "study-2026-10-13", user_id: "other" }).success, false);
});
Deno.test("transcription coordinates, score, and total text are bounded", () => {
  const value = { schema_version: 1, kind: "text", engine: "fixture", blocks: [{ text: "손글씨", box: [0, 0, 1, 1], confidence: 0.6 }] };
  assertEquals(transcriptionResponse.safeParse(value).success, true);
  assertEquals(transcriptionResponse.safeParse({ ...value, blocks: [{ ...value.blocks[0], box: [1, 0, 0, 1] }] }).success, false);
});
