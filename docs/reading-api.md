# 판독 API (`docs/reading-api.md`) — S03 확정 · S10/S11/S16 접점

D16 · D17 의 서버 구현. SQL: `supabase/migrations/0005_reading.sql` + `0009_photo_residue_marks_validation.sql`, Edge: `supabase/functions/reading-*`, 테스트: `supabase/tests/03_ledger.sql`(pgTAP 76건) · `06_s03b.sql`(47건). 모든 Edge Function 은 `POST` + JSON, 사용자 JWT(`Authorization: Bearer`) + `x-device-id` 헤더. 서버 함수는 `service_role` 전용이라 앱이 직접 RPC 로 부를 수 없다(D24).

## 0. 공통 응답

- 성공: `200 {outcome: "...", ...}`.
- 비즈니스 거부도 JSON `outcome` 으로 돌려주되 HTTP 상태를 함께 쓴다: `400 invalid_payload` · `403 not_entitled | consent_required` · `404 not_found` · `409 payload_mismatch | invalid_state | active_exists | quota_exhausted | id_reused` · `410 request_deleted`.
- 인프라 오류: `{error: <code>, detail?}` — `401 not_authenticated` · `403 no_profile` · `405` · `500 internal`.
- `quota` 객체 = `{month, used, reserved, limit}`(JSON 키 `limit`, 로컬 컬럼 `quota_limit` [S02]).
- `request` 객체 = `{request_id, status, server_version, server_seq, submitted_at, completed_at, fail_reason, quota_month, quota_charged, payload_hash, subject_id, range_text, origin, session_id, planner_item_id, result_json, marks_json}` — `result_json` 은 `done_unsaved·saved` 에서만, `marks_json` 은 `saved` 에서만 값이 있다. Edge 응답의 JSON 컬럼은 **객체**(pull 에서는 문자열, `docs/sync-rpc.md`).

### 상태 전이(서버 소유)

```
selecting ──submit──▶ processing ──60s──▶ taking_long
                          │  worker/engine done        │
                          ├──────────────▶ done_unsaved ──save──▶ saved ──(sync_push 삭제 전용)──▶ tombstone
                          │                 │  discard ▶ discarded      │ update-marks (saved 유지)
                          │                 └─ +7일 cron ▶ expired
                          └── failed (engine · timeout) / cancelled (user · purge · account_deleted)
```

## 1. `reading-submit`

요청: `{request_id, subject_id, range_text(≤40), origin(planner|wrongs|home), session_id?, planner_item_id?, object_paths:[…], created_at?, client_updated_at?}`
`object_paths` = 앱이 먼저 Storage `reading-photos` 버킷에 올린 객체 경로. **반드시 `<user_id>/<request_id>/` 로 시작**(아니면 `400 invalid_payload`). `payload_hash` = `sha256(canonical json(subject_id, range_text, origin, session_id, planner_item_id, object_paths))`.

| outcome | HTTP | 뜻 | S10 |
|---|---|---|---|
| `accepted` | 200 | 접수. `idempotent:true` 면 같은 해시 재전송(기존 상태 반환). `request`·`quota` 동봉 | `SubmitAccepted` → `watch()` |
| `request_deleted` | 410 | 같은 request_id 가 tombstone(초안 삭제·저장 결과 삭제 뒤) | `SubmitRequestDeleted` · 폴링 없음 |
| `payload_mismatch` | 409 | 제출된 요청과 다른 payload | `SubmitPayloadMismatch` · 새 requestId |
| `invalid_state` | 409 | `status` 가 selecting 도 submitted 도 아님(이론상) | `SubmitInvalidState(status)` |
| `active_exists` | 409 | 다른 활성(processing·taking_long) 또는 미저장(done_unsaved) 요청 존재. `request_id` 동봉 | `SubmitActiveExists(id)` |
| `quota_exhausted` | 409 | `limit - used - reserved ≤ 0`. `quota` 동봉 | `SubmitQuotaExhausted` |
| `not_entitled` | 403 | D18 `entitled=false`(`entitlement` 상태명 동봉) | `SubmitNotEntitled` |
| `consent_required` | 403 | 동의 ② 없음/철회 | `SubmitConsentRequired` |

순서(D16): 인증·profiles → entitled → 동의 ② → payload 검증 → 삭제 여부 → 제출 여부(해시) → 활성/미저장 → 월 쿼터(KST, 제출 시각 고정) → `reserved+1` + `processing` + `reading_jobs(deadline=+10분)` + pg_net 워커 기동. 최초 제출은 동기화된 초안이 없어도 된다(서버가 행을 만든다).

## 2. `reading-status`

요청 `{request_id}` → `200 {outcome:"ok", ...request, quota}` · `404 not_found` · `410 request_deleted`.
`processing` 이 60초를 넘기면 조회 시점에 `taking_long` 으로 전이된다(reaper 도 1분마다). S10 `watch()` 폴링: 2초 → 60초 후 5초, `410` 이면 종료 + 로컬 tombstone(`applyDeleted`). `failed` 의 `fail_reason`: `engine_unavailable`(S16 전) · `engine_<status>` · `engine_error` · `timeout` · `empty_result`.

## 3. `reading-cancel`

요청 `{request_id}` → `{outcome:"cancelled"}` / `{outcome:"already_done", result, status}` / `{outcome:"already_failed", status}`. 취소 성공 시 예약 해제 + 사진 즉시 삭제. 앱은 반환값으로만 분기한다("미차감" 단정 금지, D16).

## 4. `reading-save`

요청 `{request_id, marks:[{page_index, number, mark, wrong_item_id?}], items:[{id, page_index, number, mark, confidence, user_confirmed}]}`
- `marks` = 전체 확정 마크(`correct` 포함). 비O 마크는 `wrong_item_id`(클라이언트 uuid) 필수.
- `items` = 비O 문항(= `WrongItemDraft`). **비O 마크 집합과 `id·page_index·number·mark` 가 정확히 일치**해야 한다 — 누락·초과·값 불일치·`correct` 항목 전부 `400 invalid_payload(detail: marks_items_mismatch)` (0009). 검사를 전부 통과하기 전에는 어떤 행도 쓰지 않는다.
- 서버가 `wrong_items` 를 만들고 **`review_entries` 를 D9 초기값(1일, 0)으로 생성**(id 서버 발급). 응답에 둘 다 담긴다.

| outcome | HTTP | 응답 | S10 |
|---|---|---|---|
| `saved` | 200 | `{marks, items[], entries[]}` | `SaveSaved` → `WrongsRepository.applySaved(items, entries)` |
| `already_saved` | 200 | `{marks, items[], entries[]}`(서버본) | `SaveAlreadySaved(marks, serverItems)` |
| `not_unsaved` | 200 | `{status}` | `SaveNotUnsaved(status)` |
| `invalid_payload` | 400 | `detail`: marks_not_array·mark_invalid(`page_index`·`number` 정수 0–999999, `mark` enum 필수)·wrong_item_id_required·mark_duplicate·wrong_item_id_duplicate·items_not_array·item_invalid·item_id_duplicate·marks_items_mismatch | `SaveFailed` |
| `id_reused` | 409 | item id 가 이미 존재(tombstone 포함) | `SaveFailed` |
| `not_found` / `request_deleted` | 404 / 410 | | |

## 5. `reading-discard`

`{request_id}` → `{outcome:"discarded"}` · `{outcome:"not_unsaved", status}` · 404 · 410. `result_json` 은 서버에서 null(D8), 차감 유지.

## 6. `reading-update-marks` (saved 전용 · 온라인)

요청 `{request_id, marks:[…전체 확정 마크…], entries:[{id, wrong_item_id, due_at, interval_days, consecutive_correct, last_result?}]}`
- 새로 비O → `wrong_items` 생성(id = `marks[i].wrong_item_id`, **tombstone id 재사용 → `409 id_reused`**, 쓰기 전 검증). entry 를 보내지 않으면 서버가 1일 기본 엔트리 생성.
- O 로 바뀜 → `wrong_items·review_entries·retry_records` tombstone(각 seq).
- 마크만 바뀜 → `mark` 갱신(`user_confirmed=true`).
- `marks` 검증은 `reading-save` 와 같은 함수(`reading_validate_marks`, 0009): 요소마다 정수 `page_index`·`number` 와 enum `mark` 필수, 비O 는 `wrong_item_id` 필수, `(page_index, number)`·`wrong_item_id` 중복 거부. 거부 시 쓰기 없음(1차 검증 → 2차 적용).
- `entries` 검증(D9): `interval_days ∈ {1,2,4,8,16,30}`, `consecutive_correct ∈ {0,1}`, `due_at` ISO UTC, 대상은 이 요청의 살아 있는 wrong item. 같은 wrong_item 의 live 엔트리가 다른 id 면 기존 것을 tombstone 하고 교체(부분 유일 인덱스 유지).
- 응답 `{outcome:"updated", marks, items[], entries[]}` → `MarksUpdated(items)`. 거부: `{outcome:"not_saved", status}`(tombstone 이면 `status:null`) · `400 invalid_payload(detail: entry_invalid …)` · `409 id_reused`.

## 7. 삭제 전용 mutation (S11 `wdDelRes`, 오프라인 허용)

Edge 가 아니라 `sync_push` 다. `docs/sync-rpc.md` §2 특례 표 참고:

```json
{"table":"reading_requests","id":"<request_id>","mutation_id":"<uuid>","base_server_version":<saved 시점 server_version>,"purge_epoch":0,
 "data":{"deleted_at":"…Z","client_updated_at":"…Z","device_id":"…","purge_epoch":0}}
```

승인 시 서버가 요청 + 자식(wrong_items·review_entries·retry_records) 을 한 트랜잭션에서 tombstone. 자식은 pull 로 내려와 `hideLocally` 된 행을 덮는다. 사진·세션 유지.

## 8. 워커 · 회수 · 사진 삭제

- 워커 선택 SQL(`reading_claim_job`, D16):
  ```sql
  update reading_jobs set lease_until = now() + interval '3 minutes', attempts = attempts + 1
  where request_id = (select request_id from reading_jobs
                      where (lease_until is null or lease_until <= now()) and deadline > now() and attempts < 2
                      order by created_at for update skip locked limit 1)
  returning *;
  ```
  기동: `reading_submit` 트랜잭션 안의 `net.http_post(reading-worker)`(커밋 후 전송) + pg_cron 1분 sweep. 엔진 호출부 `callEngine()` 은 **501 스텁**(S16) → `reading_finish(failed,'engine_unavailable')` → 사진 즉시 삭제.
- `reading_finish(request_id, outcome, result?, reason?)`: `processing|taking_long` 에서 최초 1회. `done` → `used+1·reserved−1·result_json·done_unsaved·completed_at·quota_charged`; `failed|cancelled` → `reserved−1`. 요청 epoch ≠ 현재 → `cancelled/purge`. `result` 없는 `done` → `failed/empty_result`. 같은 트랜잭션에서 `reading_jobs` 삭제 + `photo_delete_queue(pending)` 등록. 늦은 전이는 `noop`.
- reaper(1분 cron, `reading_reaper_run`): 60초 경과 processing → taking_long, `deadline` 경과 또는 attempts ≥ 2(리스 만료) → `failed/timeout`.
- `photo-delete-runner`(5분 cron, 큐에 기한 도래 행이 있을 때만 기동): `pending` 큐를 `next_at` 백오프(5분 × attempts, 상한 1시간)로 처리. 큐 밖의 Storage 목록 스캔은 하지 않는다.
- `photo_residue_run`(일 1회 cron `soongong-photo-residue`, 00:45 KST, 0009): 큐와 독립된 24시간 안전망. `storage.objects` 의 `reading-photos` 객체 중 `created_at < now()−24h` 이고 경로의 request 가 `processing/taking_long` 이 아닌(또는 request 행이 없는) 것을 `(created_at, id)` 커서로 500개씩 끝까지 순회해 `photo_delete_queue` 에 `pending` 으로 넣는다(이미 pending 인 경로는 건너뜀). 큐 유무와 무관하게 실행. 제출 전 업로드만 하고 중단한 객체, 500개 초과 백로그 모두 다음 실행에서 큐에 들어간다(`tests/06_s03b.sql`).
- `reading_expire_run`(일 1회): `done_unsaved` + 7일 → `expired`, `result_json=null`.

## 9. Storage

버킷 `reading-photos`(private). 경로 `<user_id>/<request_id>/p<N>.jpg`. 업로드는 사용자(S10, 아래 정책), 읽기·삭제는 서버. 버킷·정책 생성은 콘솔 작업(handoff §콘솔).

```sql
-- storage.objects 정책(콘솔에서 1회): 자기 prefix 에만 insert, select/update/delete 없음
create policy "reading photos upload own prefix" on storage.objects for insert to authenticated
  with check (bucket_id = 'reading-photos' and (storage.foldername(name))[1] = auth.uid()::text);
```

## 10. S16 (엔진) 연결 지점

`supabase/functions/reading-worker/index.ts` 의 `callEngine(job)` — 입력 `{request_id, user_id, object_paths, subject_id, range_text, attempts}`, 반환 `{ok:true, result:{pages:[{index, items:[{number, mark, confidence, box?}]}], completed_at}}` 또는 `{ok:false, status, reason}`. `result` 가 그대로 `result_json` 이 된다(형식 확정은 S06/S16).
