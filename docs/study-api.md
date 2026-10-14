# NEXT-01 · study API v2 (CONTRACT-CHANGE)

2026-10-13 사용자 승인. 구현/자동 실행 증거는 `handoff/NEXT-01.md`에서 관리한다.
S13 scheduler와 실제 엔진·사진 업로드 UI는 이 계약과 별도다. 현재 local-only 안내를 유지한다.

## 경계

- 기존 OCR/풀이 **결과** schema_version=1과 새 AI **요청 봉투** version=2를 구분한다.
- 요청 ID는 계정별 UUID, epoch 및 입력 digest에 고정한다. quote는 서버 정책 버전을 고정하며 포인트를 클라이언트가 정하지 않는다.
- 구형 요청·알 수 없는 필드는 거절한다. 응답은 job 상태/재조회 ID/내부 결과로 구성한다. 외부 호출의 실행 불명은 재호출 허가가 아니다.
- `study_metadata_v1`은 title(최대 80자), kind, revision, 존재 상태와 seq만 반환한다. 별도의 사용자별 seq 커서이며 D2 sync_tables에 본문을 등록하지 않는다.
- 모든 메타데이터 변경과 pull은 기존 `user_lock`을 공유하고 그 아래 `next_server_seq`를 발급한다. cursor는 반환한 마지막 행까지만 이동한다. 본문은 `study_body_v1`로 선택한 문서/revision 하나만 조회한다.
- `study_save_v1`은 사용자 확정 본문만 저장하며 expected revision CAS와 영구 tombstone으로 부활을 차단한다. AI 임시 결과는 별도 private job 결과이며 자동으로 확정 문서가 되지 않는다.
- 서버·로컬의 account/epoch/revision을 재검증한다. cache missing/loading/available/error는 빈 확정 원문과 다르다.
- 사진은 복원용 private bucket과 opaque object ID를 사용한다. 최초 서버 시각 +30일 후 새 접근 불가. 삭제 worker가 Storage API 성공을 확인해야 완료다. metadata SQL 삭제를 bytes 삭제로 세지 않는다.

## 현재 계약과의 관계

D2 12개 테이블의 push/pull/receipt/fullResync는 유지한다. D14 처리 임시 사진과 RC 공유 파일 수명도 그대로다. 로컬 v3 → v4 이전은 기존 기록/관계/내용을 보존하고 메타데이터만 있는 행을 표현한다. 본문 목록 선로딩은 없다.

## 공식 문서 대조

Supabase CLI 2.120.0의 `migration new`로 새 파일 생성(기존 0001~0013 불변). 실제 Postgres 테스트는 일회용 CI DB에서 실행한다. 운영 프로젝트 접근 없음.
[함수 권한](https://supabase.com/docs/guides/database/functions), [RLS](https://supabase.com/docs/guides/database/postgres/row-level-security), [Storage 권한](https://supabase.com/docs/guides/storage/security/access-control)을 대조했다.
2026-10-13 changelog 확인: [TLS CBC 제거 예정](https://supabase.com/changelog/cbc-tls-ciphers-deprecated)은 후속 최소 OS/TLS 실기기 확인 대상. [PG 보안 업데이트](https://supabase.com/changelog/postgres-15-19-17-11-breaking-changes)의 ltree/legacy PGP/btree_gist/custom operator는 이번 새 스키마에 도입하지 않는다.


## 실행 가능한 요청 및 응답

`RemoteTranscriptionEngine` / `RemoteProblemSolver` → `RemoteAiJobs.execute` → `study-infer` → `AiJobs`(PostgREST RPC) → private worker 순서다. 기본 앱 바인딩에는 `ApproveAi`가 없으므로 `ai_policy_unconfigured`로 끝난다. 다음 세션에서 서버 quote를 표시하고 사용자가 승인한 뒤 `{requestId, quoteId, operation, epoch}`를 제공한다. 요청 ID를 생성한 호출자가 재시도에도 보존해야 한다. 불명 상태에서 새 ID 자동 생성·자동 재시도는 없다. 포인트 승인 UI·앱 종료 후 요청 ID 보관 UI는 아직 연결하지 않았다.

```json
{"version":2,"request_id":"UUID","quote_id":"SERVER_POLICY_UUID","input":{"schema_version":1,"operation":"ocr","kind":"text","image":"BASE64","purge_epoch":0,"consent_version":"study-2026-10-13"}}
```

`solve`의 내부 input은 기존 v1: `operation, document_id, revision, text(1..20000), reference_answer(null 또는 최대100자), purge_epoch, consent_version, schema_version`. OCR은 text/math, 원본 최대4MiB, 요청 전체5,600,000 bytes다. 알 수 없는 필드는 세 경계에서 거절한다. worker v2는 `version, attempt_id, provider, model, limits, input`만 받고 사용자 지갑 자격증명은 받지 않는다.

반환: `{version:2, job_id, request_id, state, result, result_expired, retryable, points_state}`. result만 기존 v1이다. 결과는 HTTP200의 succeeded일 때도 만료되어 null일 수 있다. 같은 ID 재조회가 공급자를 재실행하지 않는다. pending/불명/만료는 가짜 성공으로 바꾸지 않는다. `study-job`은 v2 `action:quote` + operation/epoch 또는 `action:status|cancel` + request_id/epoch를 받는다. owner는 검증된 JWT에서만 얻는다. `quote`는 `{version:2,quote_id,operation,points,terms_version}`이며 정책은 비활성화만 가능하고 금액 변경은 새 UUID가 필요하다.

오류: 입력/버전400, 동의·계정403, request/revision/quote 충돌409, 예산초과429, 미설정503, 잘못된 엔진 결과502. 예약 전 플래그/allowlist/HTTPS/키/프로필을 확인한다. 서버의 정책·잔액·예산 검사에서 실패하면 원장 트랜잭션 전체가 롤백된다. 전체55초 deadline은 인증·수신·원장·worker·최종검증을 공유하며 실패 처리에 새 시간을 부여하지 않는다. SQL 자체는 외부 HTTP를 기다리지 않는다.

## 복원 RPC / 실제 바인딩

| API | 입력 / 응답의 핵심 |
|---|---|
| study_save_v1 | epoch, id, expected_revision(null=create), kind, title, text, transcription → version/id/서버 revision |
| study_solution_v1 | epoch/id/revision/기존 v1 풀이 → 같은 revision에만 저장 |
| study_metadata_v1 | epoch/since/limit1..100 → version/epoch/rows/next_seq; 삭제 행 포함 |
| study_body_v1 | epoch/id/revision → version/id/revision/epoch/text/transcription/solution |
| study_delete_v1 | epoch/id → 영구 tombstone, 본문·사진 삭제 의무, AI 결과 무효화 |
| study_photo_register_v1 | epoch/document/asset UUID → id/first_stored_at/expires_at/available |
| study-photo Edge | version1/epoch/asset_id → 짧은 private URL; owner 직접 입력 불가 |

사진의 `available`/`has_photo`는 등록한 자산의 접근 가능 상태이며 bytes 업로드 성공 증명이 아니다. 이번 세션에는 업로드 경로가 없다. 최초 자산 등록을 서버의 보수적 보관 기준시각으로 고정하며, 나중에 업로드/재시도를 연결해도 같은 자산의 기준시각을 재설정하지 않는다. 기존 자산의 최초 시각을 모르면 오늘로 채우지 말고 별도 미이전 상태로 남긴다.

등록/만료/삭제에도 metadata seq를 발행한다. 동시 수정은 새 seq의 변경으로 다시 받으며 클라이언트는 ID별 적용한다. 안정된 페이지는 중복/누락 없이 이동한다. D2 커서와 문서 커서는 별도로 저장해야 한다(NEXT-05). 본문·AI job은 기존12개 sync_tables에 넣지 않았다.

서버 RPC/`RemoteStudyRestore`/`studyRestoreProvider`/`StudyRepository.applyMetadata, loadBody`는 구현했다. 자동 원격 호출은 없다. 현재 목록은 로컬 metadata만, 문제 화면은 선택한 로컬 본문만 읽고 미캐시 문구를 표시한다. 원격 복원은 후속 scheduler가 명시적으로 호출해야 한다. 원격 저장/본문/사진 UI·핵심 기록 우선 S13 전체 흐름은 미연결이다.

## 로컬 v4 (SCHEMA-CHANGE)

v3 `study_documents`의 정확한 DDL과 내용은 그대로 보존한다. v4 `study_metadata`가 title/존재 상태/cache/epoch/revision/seq를 맡고, 본문 없는 항목은 body 행을 만들지 않는다. 제목은 CR/LF/TAB→공백, 앞뒤 공백 제거, 최대80 Unicode codepoint로 결정한다. 외부 AI를 사용하지 않는다.

DDL·backfill·user_version4는 한 트랜잭션이다. 이전 실패는 새 executor로 재시도한다. 이전 exact-v3 recovery 및 v4 두 테이블 검증, 암호화 승격·저널 정책을 유지한다. 재시작 시 loading→missing. 새 seq는 같은 revision의 풀이 변경도 포함하므로 캐시를 무효화한다. 로컬 수정의 seq는 null(미전송)이며 원격 페이지로 덮지 않는다. 로컬 tombstone은 재생성하지 않는다. 전체 동기화 충돌 조정/업로드 완료 표시 구조는 NEXT-05 범위다.

본문 네트워크 대기 중 DB transaction을 유지하지 않는다. 전후 owner/생명주기/epoch/revision/seq를 검사한다. body·metadata를 로컬 purge/wipe에 포함했고 export는 현재 owner의 명시적 필드만 읽는다. JSON export v1의 tables에 metadata를 가산했으며 import 기능은 없다. 로컬 SQLite 암호화와 서버/Storage/export 암호화를 같은 보호로 표시하지 않는다.

## 사진 URL 및 삭제

bucket `study-restore`는 private이고 클라이언트 Storage policy를 추가하지 않았다. `study_photo_access`는 사용자 잠금을 기다린 **이후** 서버 시각으로 만료를 검사한다. 서명 TTL은 최대60초이고 자산 만료보다 짧게 제한한다. Storage가 반환한 token의 exp도 검사하며 서명 후 소유권/epoch/만료를 다시 확인한다. 이미 발급된 URL의 즉시 철회를 보장하지 않는다(최대 잔여60초 이내). NEXT-02에서 격리된 로컬 Auth/Storage/Edge와 실제 bytes/만료/삭제 재시도를 검증했다. 공개환경/기기 검증은 별개다.

삭제 의무는 owner FK가 없는 opaque object path로 남는다. 문서/계정을 먼저 지워도 유지한다. `study-maintenance`는 x-job-secret, 최대50개의 단일 사용자 lease 처리, 자산 만료 최대100개, 객체 삭제 최대100개/실행, 50초 대기를 사용한다. 실제 Storage remove/list 확인 후에만 done, 실패·중단은 pending 및5분 후 재시도다. 기존 server_config가 없으면 cron의 외부 호출도 닫혀 있다. 이번에는 운영에 등록/배포하지 않았다.

## NEXT-02 로컬 v5와 승인 복구 (SCHEMA-CHANGE)

`study_ai_requests`는 암호화된 같은 파일에 요청 UUID/quote ID/operation/owner/epoch/generation/input SHA256/원본 hash·회전·crop 순서/명시 승인/created_at을 HTTP **전에** INSERT한다. 입력 사진/credential은 저장하지 않는다. INSERT 실패·ID충돌은 dispatch0회다. JSON export는 명시적인 요청 metadata만 포함하고 wipe/purge가 이 테이블도 제거한다. 기존 v3→v4 metadata 이전 뒤 v5를 같은 migration transaction에서 생성하며 실패/잘못된 키/0byte 초기화 보호는 유지한다.

개발 provider는 AiApprovalController를 실제 RemoteAiJobs에 주입한다. quote는 operation/points/terms/정책 ID를 표시하고 직전 재조회에서 변경되면 다시 확인한다. scope ticket와 계정/동의/epoch/generation 검사는 await 전후와 저장 transaction 끝에 적용한다. 실제 사용자 전환과 같은 사용자 토큰 갱신을 구분한다. 이전 operation의 finally는 새 scope를 해제하지 않는다.

서버 status/cancel만으로 복구하며 자동 infer/새 UUID를 만들지 않는다. `result_expired`, missing, unknown은 빈 성공 본문으로 저장하지 않는다. `points_state`는 서버 사실 그대로 표시한다. 임시 원본 부재 안내와 local correction을 보존한다. 명시 confirm은 request→document ID/revision을 같은 transaction에 저장한다. 반복 confirm은 같은 문서, 수정은 revision CAS, 문서 삭제는 중복 cached body 제거 및 late replay 차단이다. 원격 확정본 업로드/다른기기 복원 UI는 여전히 NEXT-05다.

수식 입력은 한 영역/한 모드다. crop 좌표는 회전한 이미지의 normalized 좌표이고 원본 hash 및 변환 순서를 요청에 남긴다. 안전한 LaTeX 원문 편집만 제공하고 자동 실행·verified 판정을 하지 않는다. 실제 엔진·자료·검증은 [NEXT-02](handoff/NEXT-02.md)를 참조한다.
