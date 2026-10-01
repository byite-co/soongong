# 데이터 모델 v1 (`docs/data-model.md`) — S02 확정판

로컬 drift 스키마(v1 = S02 테이블, v2 = S02c 부분 유일 인덱스 마이그레이션) = 서버 Postgres DDL(S03)의 출처. 컬럼 이름은 snake_case, 서버와 동일. 컬럼 추가는 새 마이그레이션 파일로만(D27).

## 0. 표기 규칙

| 항목 | 규칙 |
|---|---|
| 타입 | `TEXT` · `INT` · `REAL` · `BOOL`(SQLite `INTEGER 0/1`, Postgres `boolean`) · `JSON`(로컬 `TEXT`, 서버 `jsonb`) |
| 시각 | `TEXT` ISO 8601 **UTC**, 밀리초 포함, 접미 `Z` (`2026-09-30T14:03:00.000Z`). 로컬 시간대 변환은 읽는 쪽에서(CLAUDE.md §7) |
| 날짜 키 | `TEXT` `yyyy-MM-dd` **로컬 날짜**(`activity_days.date`, `planner_items.date·band_start·band_end`, `recurrences.ends_on`) |
| 하루 중 시각 | `TEXT` `HH:mm` 24시간(`planner_items.start_time·end_time`, `recurrences.start_time·end_time`) |
| enum | `TEXT`, 와이어 이름 = 아래 표의 값 그대로(다단어는 snake_case: `taking_long`·`done_unsaved`). 서버 CHECK 제약 목록과 동일 출처 |
| id | `TEXT` uuid v4(소문자). `activity_days.id` 만 uuid v5(D24) |
| 정렬 | `sort_order INT` 오름차순 |

## 1. 공통 컬럼

### 1.1 동기화 테이블 공통(D2) — `sync_columns`

| 컬럼 | 타입 | NULL | 관리 주체 | 비고 |
|---|---|---|---|---|
| `id` | TEXT PK | ✗ | 클라이언트 | uuid v4 |
| `user_id` | TEXT | ✗ | 서버(`auth.uid()`로 채움) · 로컬은 현재 사용자 | 로컬 DB는 단일 파일 + `user_id` 컬럼, 계정 전환·로그아웃 시 전체 초기화(D27) |
| `created_at` | TEXT | ✗ | 클라이언트 | UTC |
| `client_updated_at` | TEXT | ✗ | 클라이언트 | 사용자 쓰기마다 갱신. LWW 기준 |
| `deleted_at` | TEXT | ✓ | 클라이언트 | tombstone(§3) |
| `device_id` | TEXT | ✗ | 클라이언트 | `deviceIdProvider` |
| `client_rev` | INT | ✗ (기본 1) | **로컬 전용** | 사용자 쓰기마다 +1. push 대상 아님 |
| `base_server_version` | INT | ✓ | **로컬 전용** | 마지막으로 본 서버 버전. 미확인 신규 = null. `sync_push` 행 헤더에만 동봉 |
| `server_version` | INT | ✓ | 서버 | 승인된 쓰기마다 +1 |
| `server_seq` | INT | ✓ | 서버 | pull 커서 |
| `purge_epoch` | INT | ✗ (기본 0) | 클라이언트(서버 값 복사) | D2 epoch |
| `pending_delete_until` | TEXT | ✓ | **로컬 전용** | D22 대상 테이블만(`subjects·sessions·planner_items·recurrences`). 되돌리기 기한 |

- `dirty` = `sync_outbox`에 행이 있음(= `client_rev > sent_client_rev`). 별도 컬럼 없음.
- **push 컬럼**(`sync_push.data` 허용 키, D24) = 각 표의 "내용 컬럼" + `created_at·client_updated_at·deleted_at·device_id·purge_epoch`. `id·base_server_version·purge_epoch` 는 행 헤더. 로컬 전용 컬럼과 서버 관리 컬럼(`user_id·server_version·server_seq`)은 `data` 에 넣지 않는다(포함 시 `invalid_columns` 거부).
- 서버 응답·pull 은 `applyServer` 경로로만 반영(`client_rev` 유지, outbox 미등록, `base_server_version = server_version`).

### 1.2 로컬 전용 테이블 공통
동기화 컬럼 없음. 계정 전환·로그아웃·`purge-all`·epoch 불일치 시 DB 전체 초기화에 함께 지워진다.

## 2. 테이블

각 표: **내용 컬럼** = tombstone 시 `NULL` 로 비워지는 컬럼(§3 `content_columns`). **필수 내용** = 살아 있는 행에서 NOT NULL 이어야 하는 내용 컬럼(서버 `CHECK (deleted_at IS NOT NULL OR <필수 내용> IS NOT NULL)`). **유지 키** = tombstone 에도 남는 컬럼(§3 `tombstone_keep`).

### 2.1 `subjects` — 동기화 · D22 되돌리기

| 컬럼 | 타입 | NULL(live) | 비고 |
|---|---|---|---|
| `name` | TEXT | ✗ | 1–20자 |
| `color_index` | INT | ✗ | 0–7, 과목색 토큰 인덱스. 색만으로 구분 금지 → 항상 이름 동반 |
| `sort_order` | INT | ✗ | |
| `is_default` | BOOL | ✗ | `true` = "기타"(삭제 불가, 사용자당 1개). 과목 삭제 시 기록은 이 과목으로 이동(`subjDelN`) |

유지 키: 없음. 인덱스: `(user_id, sort_order)`.

### 2.2 `sessions` — 동기화 · D22 되돌리기

| 컬럼 | 타입 | NULL(live) | 비고 |
|---|---|---|---|
| `subject_id` | TEXT | ✓ | → subjects.id. 과목 삭제 시 "기타"로 재지정 |
| `planner_item_id` | TEXT | ✓ | → planner_items.id (G2 연결 비율) |
| `kind` | TEXT | ✗ | `study` · `todo` · `self` |
| `mode` | TEXT | ✗ | `camera` · `manual` |
| `started_at` | TEXT | ✗ | UTC |
| `ended_at` | TEXT | ✓ | UTC. 종료 전 null |
| `status` | TEXT | ✗ | `active` · `paused` · `interrupted` · `finished` · `discarded` |
| `seated_seconds` | INT | ✗ | 순공 초(`SeatedTimeCalculator` 결과 캐시). 정정 시 재계산 |
| `sensitivity_level` | INT | ✗ | 0–2(세션 시작 시점 값) |
| `note` | TEXT | ✓ | 메모 |

유지 키: 없음. 인덱스: `(user_id, started_at)`, `(user_id, status)`. 3분 미만 저장 확인은 UI 규칙(DB는 저장). `discarded` 세션은 저장하지 않는다(버리기 = 행 미생성 · 스냅샷 삭제).

### 2.3 `session_segments` — 동기화

| 컬럼 | 타입 | NULL(live) | 비고 |
|---|---|---|---|
| `session_id` | TEXT | ✗ | **유지 키** → sessions.id |
| `kind` | TEXT | ✗ | `seated` · `away` · `manual` · `paused` |
| `start_at` | TEXT | ✗ | UTC |
| `end_at` | TEXT | ✗ | UTC. 저장된 세션의 세그먼트는 모두 닫혀 있음(열린 세그먼트는 `session_snapshot`에만) |
| `corrected` | BOOL | ✗ | 사용자 정정으로 kind 가 바뀐 구간 |

유지 키: `session_id`. 인덱스: `(session_id, start_at)`.

### 2.4 `corrections` — 동기화

| 컬럼 | 타입 | NULL(live) | 비고 |
|---|---|---|---|
| `session_id` | TEXT | ✗ | **유지 키** |
| `segment_id` | TEXT | ✗ | → session_segments.id |
| `from_kind` | TEXT | ✗ | segment kind |
| `to_kind` | TEXT | ✗ | segment kind |
| `at` | TEXT | ✗ | UTC 정정 시각 |
| `sensitivity_before` | INT | ✗ | 0–2 |
| `sensitivity_after` | INT | ✗ | 0–2(`SensitivityPolicy` 결과) |

유지 키: `session_id`. 인덱스: `(user_id, at)`(최근 2주 집계).

### 2.5 `planner_items` — 동기화 · D22 되돌리기

| 컬럼 | 타입 | NULL(live) | 비고 |
|---|---|---|---|
| `kind` | TEXT | ✗ | `study` · `todo` · `self` · `event` |
| `title` | TEXT | ✗ | 1–60자 |
| `subject_id` | TEXT | ✓ | |
| `range_text` | TEXT | ✓ | 판독 이어받기 원천(D27). 없으면 제목 사용 |
| `target_minutes` | INT | ✓ | 목표 시간(사용자 입력, D25) |
| `date` | TEXT | ✗ | 로컬 `yyyy-MM-dd`. 기간 띠는 `band_start` 와 같은 값 |
| `start_time` | TEXT | ✓ | `HH:mm` |
| `end_time` | TEXT | ✓ | `HH:mm` |
| `is_done` | BOOL | ✗ | |
| `done_at` | TEXT | ✓ | UTC |
| `recurrence_id` | TEXT | ✓ | **유지 키** → recurrences.id (반복 전개 인스턴스의 원본. v1 은 전개를 저장하지 않으므로 보통 null) |
| `band_start` | TEXT | ✓ | 로컬 날짜. `kind=event` + band = 기간 띠 |
| `band_end` | TEXT | ✓ | 로컬 날짜(포함) |
| `sort_order` | INT | ✗ | 같은 날짜 안 순서 |

유지 키: `recurrence_id`. 인덱스: `(user_id, date)`, `(user_id, band_start, band_end)`.

### 2.6 `recurrences` — 동기화 · D22 되돌리기

| 컬럼 | 타입 | NULL(live) | 비고 |
|---|---|---|---|
| `title` | TEXT | ✗ | |
| `subject_id` | TEXT | ✓ | |
| `weekday_mask` | INT | ✗ | 7비트. **bit 0 = 월요일 … bit 6 = 일요일**(`DateTime.weekday − 1`). 0 은 허용 안 함 |
| `start_time` | TEXT | ✗ | `HH:mm` |
| `end_time` | TEXT | ✗ | `HH:mm`(start 보다 뒤) |
| `ends_on` | TEXT | ✓ | 로컬 날짜(포함). null = 무기한 |
| `active` | BOOL | ✗ | |

유지 키: 없음. 첫 출시는 전체 수정/삭제만(부분 예외 없음).

### 2.7 `reading_requests` — 동기화(혼합, D24)

| 컬럼 | 타입 | NULL(live) | 소유 | 비고 |
|---|---|---|---|---|
| `request_id` | TEXT | ✗ | 클라이언트 | **유지 키**. 멱등키, `UNIQUE (user_id, request_id)`. 클라이언트는 `id` 와 같은 uuid 를 넣는다 |
| `subject_id` | TEXT | ✗ | 클라이언트(`selecting`만) | |
| `range_text` | TEXT | ✗ | 클라이언트(`selecting`만) | 자유 텍스트 ≤ 40자(D7) |
| `session_id` | TEXT | ✓ | 클라이언트(`selecting`만) | |
| `planner_item_id` | TEXT | ✓ | 클라이언트(`selecting`만) | |
| `origin` | TEXT | ✗ | 클라이언트(`selecting`만) | `planner` · `wrongs` · `home` |
| `payload_hash` | TEXT | ✓ | 서버(제출 시 고정) · 로컬은 계산값 캐시 | |
| `status` | TEXT | ✗ | 서버(`selecting` 초안만 로컬 생성) | `selecting` · `sending` · `processing` · `taking_long` · `failed` · `cancelled` · `done_unsaved` · `saved` · `discarded` · `expired` |
| `submitted_at` | TEXT | ✓ | 서버 | 이후 상태는 pull·서버 응답으로만 |
| `completed_at` | TEXT | ✓ | 서버 | |
| `quota_month` | TEXT | ✓ | 서버 | `yyyy-MM`(KST 월) |
| `quota_charged` | BOOL | ✗ (기본 false) | 서버 | |
| `result_json` | JSON | ✓ | 서버 | 만료·버리기 시 null(D8) |
| `marks_json` | JSON | ✓ | 서버 | 저장 시 확정, 수정 시 교체. 결과 화면의 정답 |
| `fail_reason` | TEXT | ✓ | 서버 | |
| `confirmed_marks_json` | JSON | ✓ | **로컬 전용** | 저장 전 임시 보존, 저장 성공 시 null |

필수 내용: `request_id·subject_id·range_text·origin·status`. 유지 키: `request_id`. 인덱스: `UNIQUE (user_id, request_id)`, `(user_id, status)`.
- `sync_push` 허용: `selecting` 상태의 클라이언트 컬럼 + `saved` 상태의 **삭제 전용 mutation**(`data = {deleted_at}`)(D16) + **`selecting` 초안(`submitted_at IS NULL`)의 `deleted_at`**(S02b 계약 ①: 초안 삭제. 서버는 내용 컬럼을 NULL 로 지우고 `request_id` 를 남긴다. 서버에 없는 id 로 온 tombstone 은 D2 규칙대로 tombstone 으로 insert). 서버 컬럼이 `data` 에 있으면 행 거부.
- 클라이언트 삭제 규칙(S02c): `selecting` 초안 삭제는 **항상** tombstone mutation(로컬 물리 삭제 없음, 전송 이력 무관). `sending`(제출 호출 중) 상태는 삭제하지 않는다 — `reading-status` 로 `processing` 이면 취소 경로, 404 면 `selecting` 으로 되돌린 뒤 삭제.
- 클라이언트 `sending` 표시는 로컬 상태값(제출 호출 중). 서버 응답 후 `applyServer` 로 서버 상태로 덮인다.
- 서버가 삭제를 확정한 요청(`410 request_deleted`, pull tombstone)과 `expired`·`discarded` 수신 시 로컬도 `result_json·marks_json·confirmed_marks_json` 을 지운다(D8, S02b).

### 2.8 `photos` — 로컬 전용(서버 미동기화)

| 컬럼 | 타입 | NULL | 비고 |
|---|---|---|---|
| `id` | TEXT PK | ✗ | uuid v4 |
| `user_id` | TEXT | ✗ | |
| `request_id` | TEXT | ✓ | → reading_requests.request_id. 촬영 직후에는 null 가능 |
| `local_path` | TEXT | ✗ | `ApplicationSupport/photos/` 기준 **상대 경로**. 로그 금지 |
| `taken_at` | TEXT | ✗ | UTC |
| `expires_at` | TEXT | ✗ | `taken_at + 30일`(D14). 재시도로 연장 없음 |
| `width` | INT | ✗ | px |
| `height` | INT | ✗ | px |
| `page_index` | INT | ✗ | 0-base |
| `created_at` | TEXT | ✗ | |
| `deleted_at` | TEXT | ✓ | 파일 삭제 완료 후 세팅("삭제됨" 표시용, `photoDel`) |

인덱스: `(request_id, page_index)`, `(expires_at)`.

### 2.9 `wrong_items` — 동기화(최초 생성은 `reading-save`, 이후 `status` 만 `sync_push`)

| 컬럼 | 타입 | NULL(live) | 비고 |
|---|---|---|---|
| `request_id` | TEXT | ✗ | **유지 키** |
| `subject_id` | TEXT | ✗ | |
| `range_text` | TEXT | ✗ | |
| `page_index` | INT | ✗ | |
| `number` | INT | ✗ | 문항 번호 |
| `mark` | TEXT | ✗ | `wrong` · `partial` · `unsolved` · `guessed`(`correct` 는 오답이 아니므로 없음) |
| `confidence` | REAL | ✗ | 0–1 |
| `user_confirmed` | BOOL | ✗ | 확정 없이 저장 = false(목표 0, D15) |
| `status` | TEXT | ✗ | `open` · `resolved` |
| `resolved_at` | TEXT | ✓ | UTC |

유지 키: `request_id`. 인덱스: `(user_id, status)`, `(request_id)`, `(user_id, subject_id)`.
- **push 컬럼(S02b 계약 ②)**: 최초 생성은 `reading-save` 가 하고, 이후 `sync_push` 가 받는 `data` 는 **`subject_id · status · resolved_at`**(+ 공통 `client_updated_at·device_id·purge_epoch`) 뿐. `subject_id` 는 과목 삭제 시 "기타" 재지정(subjDelN)용. 그 외 내용 컬럼(`request_id·range_text·page_index·number·mark·confidence·user_confirmed`)이 `data` 에 있으면 `invalid_columns` 거부(§1.1 의 일반 규칙 "내용 컬럼 전부" 에 대한 예외).

### 2.10 `review_entries` — 동기화(D9)

| 컬럼 | 타입 | NULL(live) | 비고 |
|---|---|---|---|
| `wrong_item_id` | TEXT | ✗ | **유지 키**. wrong_item 당 살아 있는 행 1개 — **부분 유일 인덱스** `review_entries_live_wrong_item ON review_entries (wrong_item_id) WHERE deleted_at IS NULL`(S02b 계약 ③, 로컬은 `AppDatabase.partialUniqueIndexes` 의 `customStatement`, 서버 DDL 동일 문장) |
| `due_at` | TEXT | ✗ | UTC |
| `interval_days` | INT | ✗ | 1 → ×2 … ≤ 30 |
| `consecutive_correct` | INT | ✗ | 2 도달 시 큐 이탈(행 soft delete) |
| `last_result` | TEXT | ✓ | `correct` · `partial` · `wrong` |

유지 키: `wrong_item_id`. 인덱스: `(user_id, due_at)`.

### 2.11 `retry_records` — 동기화

| 컬럼 | 타입 | NULL(live) | 비고 |
|---|---|---|---|
| `wrong_item_id` | TEXT | ✗ | **유지 키** |
| `result` | TEXT | ✗ | `correct` · `partial` · `wrong` |
| `at` | TEXT | ✗ | UTC |
| `voided` | BOOL | ✗ | 기록 취소(`rtVoid`). 취소된 기록은 큐 재계산·집계에서 제외 |
| `voided_at` | TEXT | ✓ | UTC |

유지 키: `wrong_item_id`. 인덱스: `(wrong_item_id, at)`.

### 2.12 `settings` — 동기화

| 컬럼 | 타입 | NULL(live) | 비고 |
|---|---|---|---|
| `key` | TEXT | ✗ | `UNIQUE (user_id, key)`. 삭제 없음(값 갱신만) |
| `value_json` | JSON | ✗ | 스칼라 JSON(`120` · `"system"` · `true` · `"08:00"` · `null`) |

`id = uuid_v5(namespace = 7a1c6d2b-0e4f-4c3a-8b5d-9e2f1a3c4d5e, name = "<user_id>|<key>")` 결정적(두 기기가 같은 키를 만들어도 pull 에서 `UNIQUE (user_id, key)` 와 충돌하지 않고 CAS 로 병합, D24 `activity_days` 와 같은 방식). 키 목록과 기본값: `daily_goal_minutes` INT 120 · `week_start` INT 1(1=월 … 7=일) · `notif_review_time` `"HH:mm"`\|null (null = 꺼짐) · `notif_event_10min` BOOL false · `theme` `"system"`\|`"light"`\|`"dark"` · `seat_detection_enabled` BOOL true · `sensitivity_level` INT 0 · `sensitivity_auto` BOOL true. 유지 키: 없음(tombstone 없음).

### 2.13 `subscription_state` — 서버 원장 **캐시**(사용자당 1행, push 금지)

| 컬럼 | 타입 | NULL | 비고 |
|---|---|---|---|
| `user_id` | TEXT PK | ✗ | |
| `status` | TEXT | ✗ | `free` · `trial` · `premium` · `cancelPending` · `grace` · `expired` · `pendingApproval`(D18, `EntitlementStatus.name`) |
| `entitled` | BOOL | ✗ | |
| `expires_at` | TEXT | ✓ | UTC |
| `grace_expires_at` | TEXT | ✓ | **서버 ledger 에서만**(SDK 에 없음, D18) |
| `period_type` | TEXT | ✓ | SDK/웹훅 값 그대로(`TRIAL` · `NORMAL` · `INTRO` …) |
| `will_renew` | BOOL | ✗ | |
| `trial_used` | BOOL | ✗ | |
| `source` | TEXT | ✗ | `sdk` · `ledger`(마지막으로 쓴 쪽) |
| `last_checked_at` | TEXT | ✗ | UTC |

갱신 경로: `SubscriptionRepository.applySdk(Entitlement)` · `applyLedger(json)` 만. 사용자 쓰기 메서드 없음(D24).

### 2.14 `reading_quota` — 서버 원장 **캐시**(D16, push 금지)

| 컬럼 | 타입 | NULL | 비고 |
|---|---|---|---|
| `user_id` | TEXT | ✗ | PK (user_id, month) |
| `month` | TEXT | ✗ | `yyyy-MM`(KST 월) |
| `used` | INT | ✗ | |
| `reserved` | INT | ✗ | |
| `quota_limit` | INT | ✗ | 서버 JSON 키는 `limit`(20). **로컬·DDL 컬럼명은 `quota_limit`**(`limit` 은 SQL 예약어 — [S02] 결정). `applyLedger` 가 `limit`↔`quota_limit` 를 매핑 |

갱신 경로: `QuotaRepository.applyLedger(json)` 만. 차감·예약 계산 코드는 클라이언트에 없다(`ReadingQuotaPolicy` 는 잔여 표시만).

### 2.15 `activity_days` — 동기화(D15·D24)

| 컬럼 | 타입 | NULL(live) | 비고 |
|---|---|---|---|
| `date` | TEXT | ✗ | **유지 키**. 로컬 날짜 `yyyy-MM-dd`. `UNIQUE (user_id, date)` |

`id = uuid_v5(namespace = 6f0b3a2e-3c5b-4b7e-9a1d-2f4a8c1e5d70, name = "<user_id>|<date>")` — 두 기기가 같은 id 를 만들어 CAS 로 병합. 앱 포그라운드 진입 시 오늘 행 upsert(이미 있으면 쓰기 없음).

### 2.16 `sync_outbox` — 로컬 전용

| 컬럼 | 타입 | NULL | 비고 |
|---|---|---|---|
| `table_name` | TEXT | ✗ | PK (table_name, row_id). 행당 1건 |
| `row_id` | TEXT | ✗ | |
| `mutation_id` | TEXT | ✗ | uuid v4. 재전송(응답 유실)은 같은 값, **편집 후 재전송은 새 값**: enqueue 시 `sent_client_rev` 가 null 이 아니면(전송된 적 있음) 새 mutation_id 발급 |
| `sent_client_rev` | INT | ✓ | 마지막으로 전송한 `client_rev`. null = 미전송 |
| `queued_at` | TEXT | ✗ | UTC |
| `attempts` | INT | ✗ (기본 0) | |
| `last_error` | TEXT | ✓ | |

payload 는 전송 시 현재 행을 읽어 만든다(§1.1 push 컬럼). 승인 응답 시 `sent_client_rev == 행.client_rev` 면 행 삭제, 아니면(전송 중 편집) 새 mutation_id 로 유지 — S13.

### 2.17 `sync_meta` — 로컬 전용

| 컬럼 | 타입 | 비고 |
|---|---|---|
| `key` | TEXT PK | `cursor_next_seq`(단조 증가만) · `last_synced_at` · `purge_epoch` |
| `value` | TEXT | |

### 2.18 `sync_conflicts` — 로컬 전용(dev 메뉴 열람)

| 컬럼 | 타입 | 비고 |
|---|---|---|
| `id` | INT PK autoincrement | |
| `table_name` | TEXT | |
| `row_id` | TEXT | |
| `local_json` | JSON | |
| `server_json` | JSON | |
| `resolved_as` | TEXT | `local` · `server` · `deleted` |
| `at` | TEXT | UTC |

### 2.19 `session_snapshot` — 로컬 전용 · 단일 행 덮어쓰기(D23)

| 컬럼 | 타입 | NULL | 비고 |
|---|---|---|---|
| `session_id` | TEXT PK | ✗ | 진행 중 세션 id (행은 최대 1개) |
| `mode` | TEXT | ✗ | `camera` · `manual` |
| `segments_json` | JSON | ✗ | 확정 세그먼트 배열 `[{id, kind, start_at, end_at, corrected}]` |
| `open_kind` | TEXT | ✗ | `seated` · `manual` · `away` · `paused` |
| `open_start` | TEXT | ✗ | UTC |
| `last_seated_at` | TEXT | ✓ | camera 만 |
| `away_candidate_since` | TEXT | ✓ | camera 만, 미확정 이탈 후보 |
| `sensitivity` | INT | ✗ | 0–2 |
| `saved_at` | TEXT | ✗ | 벽시계 UTC. 단조 시계 기준점은 저장하지 않음 |
| `subject_id` | TEXT | ✓ | 복구 화면 표시용(세션 행은 종료 시점에 만들어지므로 여기 보관) |
| `planner_item_id` | TEXT | ✓ | 〃 |
| `kind` | TEXT | ✗ | `study` · `todo` · `self` |
| `started_at` | TEXT | ✗ | 세션 시작 UTC |

세션 저장·버리기 어느 경로든 행 삭제. 복구 정산은 `SessionTimeline.recover(snapshot)`(D23 kind 별 규칙).

## 3. tombstone 표 (D2 · `content_columns` / `tombstone_keep`)

서버 `sync_push` 가 `deleted_at` 을 받아들일 때 `content_columns` 를 NULL 로 지운다. 클라이언트 저장소는 행을 엔티티로 만들기 전에 `deleted_at` 을 보고 `Tombstone(table, id, keepKeys)` 로 분기한다. DDL: 내용 컬럼은 nullable + `CHECK (deleted_at IS NOT NULL OR <필수 내용> IS NOT NULL)`.

| 테이블 | `content_columns`(tombstone 시 NULL) | 필수 내용(CHECK) | `tombstone_keep` |
|---|---|---|---|
| `subjects` | name, color_index, sort_order, is_default | name, color_index, sort_order, is_default | — |
| `sessions` | subject_id, planner_item_id, kind, mode, started_at, ended_at, status, seated_seconds, sensitivity_level, note | kind, mode, started_at, status, seated_seconds, sensitivity_level | — |
| `session_segments` | kind, start_at, end_at, corrected | kind, start_at, end_at, corrected | `session_id` |
| `corrections` | segment_id, from_kind, to_kind, at, sensitivity_before, sensitivity_after | 전부 | `session_id` |
| `planner_items` | kind, title, subject_id, range_text, target_minutes, date, start_time, end_time, is_done, done_at, band_start, band_end, sort_order | kind, title, date, is_done, sort_order | `recurrence_id` |
| `recurrences` | title, subject_id, weekday_mask, start_time, end_time, ends_on, active | title, weekday_mask, start_time, end_time, active | — |
| `reading_requests` | subject_id, range_text, session_id, planner_item_id, origin, payload_hash, status, submitted_at, completed_at, quota_month, quota_charged, result_json, marks_json, fail_reason, confirmed_marks_json | subject_id, range_text, origin, status | `request_id` |
| `wrong_items` | subject_id, range_text, page_index, number, mark, confidence, user_confirmed, status, resolved_at | subject_id, range_text, page_index, number, mark, confidence, user_confirmed, status | `request_id` |
| `review_entries` | due_at, interval_days, consecutive_correct, last_result | due_at, interval_days, consecutive_correct | `wrong_item_id` |
| `retry_records` | result, at, voided, voided_at | result, at, voided | `wrong_item_id` |
| `settings` | key, value_json | key, value_json | — (삭제 없음) |
| `activity_days` | — | — | `date` |

공통 필드(`id·user_id·deleted_at·server_version·server_seq·purge_epoch·created_at·client_updated_at·device_id`)는 항상 남는다. 로컬 전용 테이블(`photos·sync_*·session_snapshot`)과 원장 캐시(`subscription_state·reading_quota`)는 tombstone 개념이 없다.

## 4. 인덱스 요약(로컬)

| 테이블 | 인덱스 |
|---|---|
| subjects | `(user_id, sort_order)` |
| sessions | `(user_id, started_at)` · `(user_id, status)` |
| session_segments | `(session_id, start_at)` |
| corrections | `(user_id, at)` · `(session_id)` |
| planner_items | `(user_id, date)` · `(user_id, band_start)` · `(recurrence_id)` |
| reading_requests | `UNIQUE (user_id, request_id)` · `(user_id, status)` |
| photos | `(request_id, page_index)` · `(expires_at)` |
| wrong_items | `(user_id, status)` · `(request_id)` · `(user_id, subject_id)` |
| review_entries | `(user_id, due_at)` · **`UNIQUE (wrong_item_id) WHERE deleted_at IS NULL`**(`review_entries_live_wrong_item`, 부분 유일 — 로컬 스키마 v2 `onUpgrade` 에서 중복 정리 후 생성, 신규 DB 는 `onCreate`) |
| retry_records | `(wrong_item_id, at)` |
| settings | `UNIQUE (user_id, key)` |
| activity_days | `UNIQUE (user_id, date)` |

## 5. 쓰기 경로 요약(머지 전 체크 §8 근거)

| 경로 | `client_rev` | outbox | 대상 |
|---|---|---|---|
| 사용자 쓰기(`create/update/commitDelete/setStatus …`) | +1 | enqueue | 동기화 테이블(사진·원장·로컬 전용 제외) |
| `softDelete / undoDelete`(D22) | 변경 없음 | 없음(`pending_delete_until` 만) | subjects · sessions · planner_items · recurrences |
| `applyServer(rows)` | 유지 | 없음 | 모든 동기화 테이블(pull) · reading_requests(`reading-*` 응답) |
| `applyLedger / applySdk` | — | 없음 | subscription_state · reading_quota |
| 로컬 전용 컬럼 쓰기(`confirmed_marks_json`, `pending_delete_until`) | 변경 없음 | 없음 | reading_requests · D22 테이블 |
| `deleteSavedResult(requestId)` | +1 | enqueue(삭제 전용) | reading_requests(`saved`). 자식은 로컬 낙관적 숨김(`deleted_at` 세팅, outbox 없음) → pull 의 서버 tombstone 이 덮어씀 |
| `deleteDraft(requestId)` | +1 | enqueue(tombstone) | reading_requests(`selecting` 만, `DraftDeleteOutcome`). `sending` 은 불변(§2.7 삭제 규칙) |
| `applyDeleted(requestId)` · pull tombstone | 유지 | 없음 | 내용·`result_json·marks_json·confirmed_marks_json` NULL, `request_id` 유지 |

모든 사용자 쓰기는 **행 변경과 outbox 등록이 한 트랜잭션**(S02b, `SyncWriter`). 여러 행을 바꾸는 작업(세션 삭제 cascade · 과목 삭제 재지정 · 복습 기록)은 `SyncWriter.runInTransaction` 안에서 전부 커밋되거나 전부 롤백된다.

## 6. 내보내기(§4.4)

- JSON: `{ "schema_version": 1, "exported_at": "<UTC>", "app_version": "<pubspec version>", "tables": { "<table>": [ <row(§2 컬럼명)>, … ] } }` — 동기화 테이블 + `photos`(경로 제외) 의 **살아 있는 행만**(tombstone·pending delete 제외). 로컬 전용 컬럼·원장 캐시·sync_* 제외.
- CSV zip: `sessions.csv`(세션 + 순공 초·과목명) · `planner.csv` · `wrongs.csv`(오답 + 복습·재풀이 요약). UTF-8 BOM, 헤더 1행.
- 가져오기는 만들지 않는다(D1).

## 7. S03 addendum — S02b 에서 확정한 서버 계약 3건

S03 은 아래 3건을 DDL·`sync_push` 검증에 그대로 반영한다(출처는 이 문서뿐).

| # | 계약 | 서버 반영 |
|---|---|---|
| ① | `reading_requests` 초안 삭제: `status = selecting AND submitted_at IS NULL` 인 행에 `data = {deleted_at}` mutation 허용(§2.7). 서버에 없는 id 의 tombstone 은 D2 규칙대로 insert | `sync_push` 허용 컬럼: `selecting` → 클라이언트 컬럼 + `deleted_at`; `saved` → `deleted_at` 만(D16). tombstone 처리 시 내용 컬럼 NULL, `request_id` 유지 |
| ② | `wrong_items` push 컬럼 = `subject_id · status · resolved_at`(§2.9). 최초 생성은 `reading-save` | `sync_push` 허용 컬럼 목록을 이 3개(+ 공통)로 제한, 그 외 `invalid_columns` |
| ③ | `review_entries` 부분 유일 인덱스 `review_entries_live_wrong_item (wrong_item_id) WHERE deleted_at IS NULL`(§2.10·§4) | 같은 문장의 `CREATE UNIQUE INDEX`. `reading-save`·`reading-update-marks`·`sync_push` 는 wrong_item 당 살아 있는 엔트리 1개를 전제 |
