# 동기화 RPC (`docs/sync-rpc.md`) — S03 확정 · S13 접점

D2 의 서버 구현. 함수는 `supabase/migrations/0003_sync_rpc.sql`, 테스트는 `supabase/tests/02_sync_push.sql`(pgTAP 47건). 사용자 토큰으로 호출할 수 있는 RPC 는 **`sync_push` · `sync_pull` · `profile_set_onboarding_done`** 세 개뿐이다(D24).

## 1. 공통

| 항목 | 값 |
|---|---|
| 호출 | `supabase.rpc('sync_push', params: {p_epoch, rows})` · `supabase.rpc('sync_pull', params: {p_epoch, since_seq, p_limit})` |
| 인증 | `auth.uid()` 필수 + `profiles` 행 필수. 없으면 **예외**(`P0001`): `not_authenticated` · `no_profile` |
| epoch | `profiles.purge_epoch`. 요청 epoch ≠ 서버 epoch → push `{epoch, epoch_mismatch:true, accepted:[], rejected:[]}` / pull `{epoch_mismatch:true, epoch}`. 미래 값도 거부 |
| 시각 | 모든 시각 컬럼은 ISO 8601 UTC 문자열 `…Z`(로컬 DB 와 동일). 서버는 `iso_utc` 도메인으로 형식 검사 |
| JSON 컬럼 | `settings.value_json` · `reading_requests.result_json` · `marks_json` 은 서버에선 jsonb, **와이어에선 JSON 텍스트 문자열**(로컬 TEXT 와 동일). push 는 문자열·JSON 값 둘 다 받는다 |
| id | 소문자 uuid 문자열(`uuid_text` 도메인) |
| 순서 | 모든 서버 쓰기는 사용자 advisory lock 아래 `next_server_seq()` 로 seq 발급 → seq 순 = 커밋 순 → pull 겹침 없음 |

## 2. `sync_push(p_epoch int, rows jsonb) → jsonb`

입력 행(최대 500, 초과 시 예외 `batch_too_large`):

```json
{"table":"sessions","id":"<uuid>","mutation_id":"<uuid>","base_server_version":3,"purge_epoch":0,
 "data":{"kind":"study","mode":"camera", "...":"내용 컬럼", "created_at":"…Z","client_updated_at":"…Z","deleted_at":null,"device_id":"…","purge_epoch":0}}
```

응답:

```json
{"epoch":0,
 "accepted":[{"table":"sessions","id":"…","mutation_id":"…","server_version":4,"server_seq":120}],
 "rejected":[{"table":"sessions","id":"…","mutation_id":"…","reason":"version_conflict","server_row":{…}}]}
```

행 처리 순서(D2 · D24 §7):

1. `mutation_id` 가 `sync_mutations` 에 있으면 **영수증 그대로 반환**(재전송 멱등). 영수증은 승인 행만 기록(거부는 재평가).
2. `table` ∈ 12개 동기화 테이블(`sync_tables`), 아니면 `invalid_table`.
3. `data` 의 키 ⊆ `allowed_columns(table)`. **하나라도 벗어나면 `invalid_columns`**(서버 컬럼·`user_id`·로컬 전용 컬럼 포함). `user_id` 는 서버가 `auth.uid()` 로 채우고 `purge_epoch` 는 서버 epoch 로 덮어쓴다.
4. 기존 행의 `user_id ≠ auth.uid()` → `forbidden`(server_row 없음).
5. `base_server_version = null`: 서버에 없음 → insert(`server_version 1`) / 살아 있음 → `version_conflict` + `server_row` / tombstone → `deleted`.
6. `base ≠ null`: `existing.server_version = base` 일 때만 update(`+1`), 아니면 `version_conflict` + `server_row`. tombstone 은 base 와 무관하게 `deleted`. 서버에 없는 id + base ≠ null 은 insert 로 처리(수렴 우선).
7. CHECK·NOT NULL·UNIQUE 위반 → 그 행만 `constraint_violation`(배치의 다른 행은 계속).

### 허용 컬럼(`allowed_columns`)

- 공통(모든 테이블, `wrong_items` 제외): `created_at · client_updated_at · deleted_at · device_id · purge_epoch`
- 내용 컬럼 + 유지 키: data-model §2 각 표 그대로(`session_segments.session_id`, `review_entries.wrong_item_id`, `activity_days.date` 등 포함)
- `wrong_items`(§7 ②): `subject_id · status · resolved_at · client_updated_at · device_id · purge_epoch` 만. `created_at`·`deleted_at` 도 없음 → **wrong_items 는 push 로 생성·삭제 불가**(`insert_not_allowed`)
- `reading_requests`: `request_id · subject_id · range_text · session_id · planner_item_id · origin` + 공통. `status` 등 서버 컬럼은 목록에 없음

### tombstone(`deleted_at` 포함 push)

- 서버는 내용 컬럼을 NULL 로 지우고 공통 필드 + 유지 키만 남긴다(`sync_null_content`).
- 서버에 없는 id 의 tombstone → tombstone 으로 insert(D2). `settings` 도 형식상 가능(앱은 삭제하지 않음).

### `reading_requests` 특례

| 서버 행 상태 | push 내용 | 결과 |
|---|---|---|
| 없음 | 클라이언트 컬럼 | insert, 서버가 `status='selecting'`·`quota_charged=false` 세팅 |
| `selecting`·`submitted_at null` | 클라이언트 컬럼 | CAS update |
| `selecting`·`submitted_at null` | `deleted_at` | tombstone(§7 ①) |
| 없음 | `deleted_at` | tombstone insert |
| **`submitted_at not null`**(processing·taking_long·done_unsaved·failed·…) | 무엇이든(tombstone 포함, **base 가 맞아도**) | `version_conflict` + `server_row` → 클라이언트는 LWW 재push 금지, `applyServer(server_row)` 후 S10 취소/완료 처리(인수 ①) |
| `saved` | `data` = `{deleted_at}` (+ `created_at·client_updated_at·device_id·purge_epoch` 만 허용) · base 일치 | **삭제 전용 mutation**(D16): 요청 tombstone(`result_json·marks_json` null, `request_id` 유지) + 연결 `wrong_items·review_entries·retry_records` tombstone, 각각 seq 발급, 영수증 1건 |
| `saved` | `deleted_at` + 내용 키 | `invalid_columns` |
| tombstone | 무엇이든 | `deleted` |

## 3. `sync_pull(p_epoch int, since_seq bigint, p_limit int = 1000) → jsonb`

```json
{"epoch":0,
 "rows":[{"table":"subjects","row":{"id":"…","user_id":"…","server_version":3,"server_seq":7,"deleted_at":null,"name":"수학", "…":"…"}}],
 "next_seq":7,"has_more":false,
 "ledger":{"subscription_state":{"status":"premium","entitled":true,"expires_at":"…Z","grace_expires_at":null,"period_type":"NORMAL","will_renew":true,"trial_used":false},
           "reading_quota":{"month":"2026-10","used":3,"reserved":0,"limit":20}}}
```

- 12개 테이블 UNION, `user_id = auth.uid() and server_seq > since_seq`, `server_seq` 오름차순, `limit ≤ 1000`.
- `row` = 서버 행 전체 − `server_received_at`. tombstone 은 내용 컬럼이 null 로 섞여 온다(클라이언트는 `deleted_at` 먼저 확인).
- `next_seq` = 페이지 마지막 seq(행이 없으면 `since_seq`). `has_more` = 다음 페이지 존재. **커서 만료 없음.**
- `ledger` 는 pull 마다 동봉: `subscription_state` 는 D18 판정표(`entitlement_status`)의 결과, `reading_quota` 는 **당월(KST)**. 행이 없으면 `free`/`0·0·20`.
- `reading_requests.result_json` 은 `expired`·`discarded` 전이 때 서버에서 null 이 되므로 pull 에 원문이 내려오지 않는다(D8).

## 4. 서버 발 tombstone(push 없이 생기는 삭제)

- `reading-update-marks` 가 O 로 바뀐 문항의 `wrong_items·review_entries·retry_records` 를 tombstone.
- `sync_push` 삭제 전용 mutation 의 cascade.
- 고아 초안: `client_updated_at + 30일` 지난 미제출 `selecting` 초안을 일 1회 cron 이 tombstone(`draft_orphan_tombstone_run`, 0011): 후보마다 `user_lock` 을 잡고 같은 트랜잭션에서 조건(`selecting`·미제출·미삭제·30일)을 재확인한 행만 tombstone — 잡이 잠금을 기다리는 동안 커밋된 `reading_submit`/`sync_push` 편집은 건너뛴다(`tests/08_s03b_orphan_lock.sql`).
- `purge-all`·`delete-account` 는 tombstone 이 아니라 **물리 삭제**(+ epoch 증가 / 계정 삭제).

## 5. 클라이언트(S13) 체크리스트

- push payload = data-model §1.1 push 컬럼. `reading_requests` 는 클라이언트 컬럼만(로컬 `status`·`payload_hash` 를 보내지 않는다), `wrong_items` 는 3개 컬럼 + 공통 3개.
- `version_conflict` 의 `server_row` 는 pull 행과 같은 모양 → `applyServer` 로 바로 적용 가능. `reading_requests` 의 `submitted_at not null` 충돌은 재push 금지(D2 예외).
- `deleted` → 로컬도 tombstone 유지, 재생성 금지. `insert_not_allowed`(wrong_items 신규) → 로컬 행은 `reading-save` 응답 미러이므로 pull 이 서버본으로 덮는다.
- `epoch_mismatch` → 서버 epoch 가 더 크면 `wipeAll()` 후 `pull(0)`.
- JSON 텍스트 컬럼(`value_json`)은 pull 행 그대로 TEXT 에 저장. push 때도 TEXT 그대로 보낸다.
