# NEXT-01 · 복원 계약 / 로컬 v4 / AI 포인트·비용 기반 인계

CONTRACT-CHANGE · SCHEMA-CHANGE. 2026-10-13 사용자 승인에 따른 실제 구현이다. 시작점 `20542197c785476c252ab4e416630518313269d5`의 RC 변경을 보존하고 기존 `feat/s14-oss-integration` / [Draft PR #9](https://github.com/byite-co/soongong/pull/9)에 후속 commit을 누적했다. 강제 초기화·force push·main 병합·배포·공개 플래그 활성화·유료 모델 호출·실결제는 하지 않는다. CLAUDE의 과거 역할 분담/세션별 PR 규칙은 이번 명시적 사용자 실행 지시가 우선한다.

## 실행 결과의 기준

**이 파일은 마지막 검증 커밋에도 포함되는 인계와 테스트 연결표다. 그 커밋 자체의 SHA·CI 실행 결과·FD별 최종 PASS/FAIL/UNVERIFIED 표는 실행이 끝난 뒤 [PR #9 본문](https://github.com/byite-co/soongong/pull/9)에 기록한다.** 전달 산출물 `soongong-pr9-next01-report.md` / `soongong-pr9-next01-checklist.json`도 같은 최종 SHA를 사용한다. 이전 CI 숫자를 마지막 커밋의 결과로 승격하지 않는다.

중간에 실제 확인한 코드 기준 `61dd403470d11031a51886a5e501f5504813fec8`: [Flutter949](https://github.com/byite-co/soongong/actions/runs/38356084297), [pgTAP477 / Deno48 / 실제 DB 연결13](https://github.com/byite-co/soongong/actions/runs/38356084286), [Python30](https://github.com/byite-co/soongong/actions/runs/38356084359) 통과. 이 뒤 추가한 cached-generation 2개와 machine-secret 1개, 최종 설정/문서 커밋의 전체 재검증은 위 최종 기록으로 구분한다. host native 결과는 Android/iPhone 설치·실행 결과가 아니다.

## 정책·구현·연결 상태

| 정책 | 정책 확정 | 이번 코드 / 실제 연결 | 자동·실기기 경계 |
|---|---|---|---|
| P01/P02 | 비용 기준·월 최대30만원 확정, provider 미확정 | numeric 포인트/비용 예약 및 KST 월 budget·서버비 배정 구현. 모든 운영 정책·grant seed 없음. paid worker adapter 미설정은 거절 | synthetic DB 경쟁/정산 테스트. 실제 비용·provider 약관/품질 미검증 |
| P03 | 순차 완성 | A~E 기반 구현, NEXT-02~07 입력 준비 | 이번 완료는 전체 제품 완성 아님 |
| P04 | 시선 단독 시간 차감 금지 | 측정·시선 판정 코드 변경 없음, 기존 회귀 유지 | 실제 관측 품질은 미검증 |
| P05/P06/P07 | 핵심 기록 우선·선택 본문/사진 | metadata/body/photo RPC와 앱 adapter/repository, 로컬 v4/cache 상태 구현. 자동 S13/원격 저장 UI·사진 업로드 UI는 미연결. 현재 화면 local-only 안내 유지 | 실제 SQLite/PG·race 테스트. 새 기기 전체 복원 미검증 |
| P08/P09 | 구독 기본량+추가권, 차등 integer points | 지급 근거·예약·정산·반환·멱등/불명 상태 구현. 가격·이월·만료·순서·구독 종료 후 사용·환불/결제 연동 미결. `ApproveAi` 미주입은 사용 불가 | 테스트 포인트 OCR3/풀이7은 운영값 아님. store webhook/실결제 미실행 |
| P10 | 최초 복원 사진 기준30일 | private 자산 등록·서버 시각·접근 만료·독립 삭제 의무·재시도·짧은 URL 계약 구현 | SQL 만료 및 삭제 obligation 검증. 실제 Storage 객체/URL 통합은 FD-21/22 UNVERIFIED |
| P11 | 첫 출시14세 이상 | 기존 age gate 유지 | 기존 경계 테스트, 공급자별 연령 허용은 후속 확인 |
| P12/P13 | 즉시 정정/최근 자동 차감 선택 복원 | NEXT-04 범위로 미구현 | 이번 구현/검증 완료로 세지 않음 |

## 코드와 정합성 검토

- 서버: CLI2.120.0 `migration new`가 생성한 `20261013053432_next01_foundation.sql`. 기존0001~0013 불변. 공개 스키마의 새11개 테이블 RLS/직접 client 권한 차단,6개 owner RPC만 authenticated 허용. service 함수는 검증된 caller 또는 job secret 경계 뒤에서 호출한다. public EXECUTE를 명시적으로 회수했다.
- 계약: 기존 OCR/풀이 결과 v1은 유지, 외부 요청은 v2 request ID/quote/epoch/입력 digest. 앱·Edge·worker와 fixture가 함께 바뀌었다. HTTPS/redirect 금지/크기/CAS/전체 deadline/동의/계정 검증을 유지한다.
- 로컬: v3 body DDL을 덮어쓰지 않고 v4 metadata를 추가했다. exact 구조 검증과 atomic backfill/user_version, 암호화 승격/복구, raw table wipe/export를 함께 검토했다. 목록은 본문을 읽지 않는다. 캐시·오프라인 경로도 generation을 검사하고 늦은 owner/epoch/revision/seq의 응답을 저장하지 않는다.
- 비용: user lock→global budget lock→row lock. maintenance는 transaction당 한 owner. 외부 HTTP 대기 중 DB lock 없음. 두 실제 연결이 Postgres lock에서 기다리는 것까지 확인한 동시성 시험을 추가했다. 결과 저장/정산 양쪽에 실패를 주입한다. 월 경계·정밀도·unknown 비용을 별도 검증한다.
- 삭제: 원문 수정/문서 삭제/purge/계정 삭제 시 AI 결과·content 참조 무효화. purge는 구매 잔액/지급·사용 이력/운영비를 리셋하지 않는다. account delete 후 직접 식별자를 제거한 비용·정리 의무만 유지한다. 기존 RC receipt/revocation/lost-data/share 경계를 대체하지 않는다.
- 사진: 복원 bucket과 기존 D14 처리 bucket을 분리했다. metadata DELETE는 bytes 삭제 완료가 아니다. `study-maintenance`는 service RPC→Storage remove/list 확인→done 순서, 실패 시 pending/backoff. `supabase/config.toml`은 machine endpoint만 gateway JWT 대신 x-job-secret을 사용하고 user endpoint는 JWT를 요구한다. 실제 배포하지 않았다.
- 패키지: 새 앱/모델 라이브러리 없음. 기존 lock·고정 native 패치 유지. CI의 기존 Deno 도구를 PostgreSQL job에도 사용했다.

상세 계약은 [study-api](../study-api.md), 원장 상태/가격 단위/조정 절차는 [ai-usage](../ai-usage.md), 정책 충돌 근거는 [decisions NEXT-01](../decisions.md)다.

## FD-01~28 기대값·실제 검사 연결

아래는 실제 실행 함수/테스트의 연결표다. 최종 판정은 위 PR 본문의 **같은 SHA** 실행 표를 따른다. FD-21/22는 일부 자동 계약 검사가 성공해도 실제 Storage 통합 전체를 PASS로 표시하지 않는다. `12_foundation.sql`은 실제 PostgreSQL, `_db_tests`는 실제 SQL transaction에 연결한 Edge repository다. SQLite 테스트는 실제 암호화 파일/Drift를 사용한다. Auth caller는 테스트 identity, 모델·Storage IO는 synthetic fixture이므로 hosted Auth/Storage/모델 완료로 읽지 않는다.

| ID | 기대값 | 실제 검사·관측 범위 | 구현 / 테스트 식별자 |
|---|---|---|---|
| FD-01 | P01~P13 범위 구별; 공개 OFF 외부 호출·차감0 | 승인 정책 기록. OFF/allowlist/키/동의/예산 미설정에서 DB job·예약·공급자 호출0 | docs/decisions.md; supabase/functions/study-infer/index.ts; lib/data/engines/transcription/remote_ai_jobs.dart / _db_tests/foundation_test.ts: FD-01/02/12, FD-01 no key; remote_ai_jobs_test.dart: FD-01 |
| FD-02 | Dart/Edge/worker 버전 일치; 구형·변조·큰 입력 거절 | 외부 v2/내부 결과v1, 구형 HTTP 거절. 요청ID/quote/session/result 검증. 기존 deadline 유지 | remote_ai_jobs.dart; _shared/study.ts; services/study_worker/worker.py / remote_ai_jobs_test.dart: FD-02; foundation_contract_test.ts: FD-02; test_lifetime.py: test_v2_rejects_legacy_unknown_fields_and_paid_unbounded_adapter |
| FD-03 | anon/B/삭제계정 접근 불가; A만 허용 | 실제 PG authenticated/anon role로 실행/직접 테이블/지급 권한 검사; B 본문·사진 grant 차단, 삭제 JWT no_profile | NEXT-01 migration RLS/grants; study_require_user; study_photo_access / 12_foundation.sql: FD-03; 01_rls.sql; _db_tests/foundation_test.ts: FD-25 |
| FD-04 | 목록에 본문·사진 없음; 페이지 누락·중복 없음 | metadata projection만 반환; 실제 PG 두 페이지와 commit 대기 확인; 목록 조회는 body/remote 선로딩0 | study_metadata_v1; StudyRepository.list; RemoteStudyRestore.metadata / _db_tests/foundation_test.ts: FD-04/08; study_restore_test.dart: FD-04/05; 12_foundation.sql: FD-04 |
| FD-05 | 선택 본문만 조회; offline miss는 빈 확정 원문이 아님 | missing/loading/available/error 구별. 선택 a만1회 수신, b 미수신. 재시작 loading→missing | StudyRepository.loadBody; study_metadata; problem_solver_screen.dart / study_restore_test.dart: FD-04/05, FD-05 invalid body; encrypted_schema_migration_test.dart: FD-05 reopen |
| FD-06 | revision CAS·삭제 우선, 늦은 저장 부활0 | 서버·로컬 CAS, tombstone, 같은 revision의 새 solution seq 캐시 무효화. 원문 수정 시 pending AI 취소·결과 제거 | study_save_v1/study_solution_v1/study_document_boundary; StudyRepository / 12_foundation.sql: FD-06; _db_tests/foundation_test.ts: FD-06/15; study_restore_test.dart: FD-06; 기존 study_repository_race_test.dart |
| FD-07 | 계정/epoch 변경 중 늦은 결과 저장·표시0; 비용 분리 | owner 생명주기/세대/revision/seq 재검증. purge 중 결과 폐기·사용자 예약 반환, 공급자 unknown 유지 | study_account_boundary; ai_finish; StudyRepository.loadBody; RemoteAiJobs.execute / study_restore_test.dart: FD-06/07 delete/revision/purge/owner; remote_ai_jobs_test.dart: FD-07; _db_tests/foundation_test.ts: FD-07/24; study_restore_test.dart: FD-07 cached return online=true/false |
| FD-08 | D2 12개 기존 계약·새 커서 commit 순서 유지 | sync_tables12 유지. 실제 PG metadata 조회가 사용자 잠금에서 대기 후 커밋된 두 행 확인 | study_metadata_v1; 기존 user_lock/next_server_seq 및 sync_push/pull / 02_sync_push.sql 및 기존 서버 회귀; _db_tests/foundation_test.ts: FD-04/08 |
| FD-09 | 실제 v3 이전 후 모든 필드 보존·재실행 중복0 | 암호화 SQLite v3 fixture의 id/owner/epoch/revision/text/JSON/planner 링크 원형 보존, 두 번 열기와 metadata 단일 backfill | app_database.dart; study_schema.dart / encrypted_schema_migration_test.dart: FD-09/10 real encrypted v3 |
| FD-10 | 이전 실패·재시작 원본/키 보존; 손상/0byte 초기화0 | DDL/버전쓰기/query_only/commit/정책 후 실패 주입 및 새 executor 재개. 기존 codec/0byte/키/WAL 회귀 유지 | app_database.dart; database_protection.dart; encrypted_database.dart / encrypted_schema_migration_test.dart: FD-09/10 및 MIG; database_creation_protection_test.dart; database_protection_test.dart |
| FD-11 | 새 raw 테이블 wipe/export/owner 검사 포함 | metadata+body 전체삭제, 타 계정 metadata export 제외, 미캐시 body 행0. pending purge 목록은 기존행도 표시하지 않음 | AppDatabase.wipeAll; LocalPurge; ExportService; StudyRepository.list / study_restore_test.dart: FD-11 metadata export, FD-11 pending purge; 기존 export/share 소유권 회귀 |
| FD-12 | 동일 ID 동일 작업/한 번 실행, 입력변경conflict, 타 계정 독립 | 실제 DB Edge 재전송 및 동시 두 요청에서 공급자 fixture1회, 동일 job. 입력 변경 거절·B 같은 request ID 별도 job | AiJobs; ai_reserve/ai_dispatch; study-infer / _db_tests/foundation_test.ts: FD-01/02/12, FD-12 two concurrent; 12_foundation.sql: FD-12 |
| FD-13 | 잔액으로 한 건만 가능하면 병렬 예약 최대1 | 두 실제 PG 연결을 겹쳐 pg_stat_activity Lock 대기 관측. 한 건만3포인트 예약, 두 번째 points_insufficient | ai_reserve; ai_point_lots CHECK/allocations / _db_tests/foundation_test.ts: FD-13 real parallel requests |
| FD-14 | 중복 지급1회·클라이언트 지급/원장 직접 변경 불가 | subscription/purchase 근거 멱등; 다른 양/만료값 conflict; 실제 authenticated ai_grant EXECUTE 거절 | ai_grant; ai_point_lots unique; grants / 12_foundation.sql: FD-14; _db_tests/foundation_test.ts: FD-07/24 |
| FD-15 | OCR/풀이 차등 차감; quote 가격 몰래 증가0 | synthetic OCR3/풀이7 예약 및 성공 정산. 정책값 변경 trigger 거절·변조 quote 차단. 운영값 seed0 | ai_policies immutable; ai_quote/reserve/finish / 12_foundation.sql: FD-15; _db_tests/foundation_test.ts: FD-06/15 |
| FD-16 | 성공 결과·정산 하나의 transaction; 중복 완료1회 | 원장 insert와 결과 UPDATE 각각 trigger 예외 주입 후 잔액/예약/result 롤백; 재시도 성공1회 | ai_finish; ai_points_finish / _db_tests/foundation_test.ts: FD-16 injected settlement failure; 12_foundation.sql: FD-16 |
| FD-17 | 실패/취소 사용자 반환1회; 사용 비용 유지; missing usage≠0 | 중복 실패에 예약만 반환. unknown/actual=null 및 비용 예약200 유지 후 실제 fixture 금액170 정산 | ai_finish; ai_reconcile; ai_costs / _db_tests/foundation_test.ts: FD-17/18; 12_foundation.sql: FD-17 |
| FD-18 | dispatch 불명 상태 보존, 자동 재호출/비용해제0 | lease 만료→reconciliation_required. 재dispatch claimed=false. never-dispatched만0원, 임시 result 만료 재실행0 | ai_dispatch/maintenance; study-maintenance; ai_job_view / _db_tests/foundation_test.ts: FD-17/18, FD-18 never-dispatched; study_deadline_test.ts |
| FD-19 | 다른 사용자 병렬 월 상한·서버비 포함; 30만원 초과 거절 | 다른 사용자 DB 연결들이 global lock에서 실제 대기. 서버비100+예약200=한도300 한 건만;300001 설정 거절 | ai_budget_set; ai_reserve; ai_lock / _db_tests/foundation_test.ts: FD-19 different users; 12_foundation.sql: FD-19 |
| FD-20 | 원래 KST월 정산; exact 금액/가격/FX 구별 | 통제 시각 월경계 이후 원래월120정산, 다음월 이동0. 중복정산/비정상 금액/초과 정밀도 거절 | ai_reserve/ai_reconcile; ai_costs/ai_budgets / 12_foundation.sql: FD-20; _db_tests/foundation_test.ts: FD-17/18 |
| FD-21 | 최초+30일, 재시도 연장0, 만료 후 발급0, 텍스트 보존 | SQL의 직전/정각, 반복 등록, 만료 후 접근 거절·본문 보존 PASS. token exp decoder unit PASS. 실제 Storage 서명 URL 통합은 미실행 **UNVERIFIED 범위: UNVERIFIED: disposable Supabase Auth/Storage, 합성 object, 통제 시각/서명 token 만료/삭제 중 URL 검증 필요** | study_photo_register_v1/access/expire; study-photo / 12_foundation.sql: FD-21; foundation_contract_test.ts: FD-21 |
| FD-22 | Storage 실패 재시도, bytes 삭제 확인 후 done, 삭제계정 의무 유지 | 실제 PG 의무/claim/backoff 및 Storage fixture 실패→성공 ACK 전이 PASS. 실제 Storage bytes 생성/삭제는 미실행 **UNVERIFIED 범위: UNVERIFIED: 격리 Storage API·합성 object·강제 실패/재시도·삭제 후 다운로드 부재 증거 필요** | study_queue_asset_delete; study_object_claim/done; study-maintenance; storage.ts / 12_foundation.sql: FD-22; _db_tests/foundation_test.ts: FD-22 real deletion obligations |
| FD-23 | 복원30일/처리임시/공유24h 독립; 하나 변경이 다른 정책 연장0 | D14 residue는 reading bucket만 정리하고 restore bucket/30일 anchor 보존. 실제 임시 파일에서 shareGrace2일로 늘려도 완료 picker 정리·외부 restore 파일 불변 | study_photo_assets; photo_residue_run; TempRetentionPolicy/OwnedTempStore / 12_foundation.sql: FD-23; owned_temp_store_test.dart: FD-23 및 EXP-05/06, EXP-10 |
| FD-24 | purge는 content/late result 제거, paid balance·receipt·cost 유지 | 진행 중 job 취소+원문/digest 제거. 예약 포인트 반환·구매10 유지·동일근거 재지급0·unknown 비용200 유지 | study_account_boundary; purge_all; LocalPurge / 12_foundation.sql: FD-24; _db_tests/foundation_test.ts: FD-07/24; study_restore_test.dart: purge |
| FD-25 | 삭제계정 JWT/callback 부활0; 익명 정리/비용 지속 | no_profile/late grant 거절. job owner/request/content 제거, late result cancelled, wallet/profile0 상태에서 비용100 정산 | delete_account_data; study_account_boundary; ai_reconcile / 12_foundation.sql: FD-25; _db_tests/foundation_test.ts: FD-25 |
| FD-26 | 기존 quota 이중 차감0·측정/조회 유지·시선 단독 차감0 | 신규 job pipeline 후 reading_quota 변화0. 기존 판독/측정/카메라/시선 회귀 유지. 예산 검사는 AI 경로에 한정 | study-infer; ai_* 별도 tables; 기존 measurement code 변경0 / _db_tests/foundation_test.ts: FD-01/02/12; 03_ledger.sql; 기존 Flutter measurement/camera/gaze suites |
| FD-27 | 민감 내용 로그/원장 불필요 복사0·기존 보호/검증 유지 | cost usage에 source_text 거절, private result/digest purge. 기존 공유/DB/CAS/deadline/picker/camera regressions 및 정적 진단 실행 | _shared/ai_jobs.ts; ai_costs/reconcile; 기존 RC 보호경로 / 12_foundation.sql: FD-27; log_test.ts; study_deadline_test.ts; 전체 Flutter/worker/native suite |
| FD-28 | 새 HEAD에서 unit/계약/actual PG와 필수 CI 성공; 실행·스킵 공개 | 최종 보고의 SHA/run/checkout/tree 및 전체 suite 실제 로그로 판정; 중간 실패/취소는 최종 성공과 분리 | server-tests.yml actual PG + Deno; analyze-test; study-worker; native-check / 최종 CI4 workflow 및 산출물 실행 manifest |

## 실행 방법과 환경

- `.github/workflows/analyze-test.yml`: Flutter3.47.5, 모델 hash 확인, build_runner clean-tree, `flutter analyze --fatal-infos`, 금지 문구, `flutter test --reporter expanded`.
- `server-tests.yml`: disposable PostgreSQL16 + pgTAP/pg_cron, `supabase/tests/local/run.sh`로 모든 migration 실제 적용. plpgsql_check는 기존 sync_pull의 dynamic record 진단2개만 기존 baseline으로 남기고 새 오류를 거절한다. 대상 Supabase 설정의 PG17/실제 hosted stack 검증과 구별한다.
- 같은 실제 DB에서 `PGDATABASE=soongong_test deno test -A --config supabase/functions/deno.json supabase/functions/_db_tests/`. 테스트는 GITHUB_ACTIONS=true 및 정확한 test DB 이름이 아니면 거절한다. 두 psql 연결·transaction·실제 lock waiter·trigger rollback을 검사하며 원장 로직을 fake로 바꾸지 않는다.
- Edge: `deno test -A _tests/`, `deno check */index.ts ../dev/functions/e2e-runner/index.ts`. 로컬 새 경계 테스트도 실행했지만 최종 숫자는 전체 CI 기준이다.
- Worker: Python3.11 + 기존 lock, `python -m unittest discover -s services/study_worker -v`. 실제 Linux process/CAS/HTTP 경계, 모델 다운로드/유료 API 없음.
- Native: Android dev Debug와 iPhone ARM64 dev Release/no-codesign. 별도 Android16 tests/iOS Foundation54 assertions는 최종 native 로그/보고서로 재확인한다. signed install·실기기 카메라·공유 동작으로 세지 않는다.

로컬 Docker daemon이 연결되지 않았고 psql 환경이 없어 실제 PG는 허용된 CI에서 실행했다. 로컬 Flutter/pub metadata 접근에 대한 기존 자동 승인 거절을 우회하지 않고 Flutter도 CI에서 실행했다. CLI 생성/직접 Dart 구문 formatter/Deno 검사는 로컬에서 수행했다. 필수 gate를 낮추거나 테스트를 삭제/skip해서 실패를 숨기지 않았다.

중간 실패는 최종 PASS와 분리한다: SQL NULL 검증 누락·authenticated 정확 허용 목록, 초기 테스트 DB transport의 set-returning/배열 변환 및 테이블명, Flutter lint/버전 기대값과 purge 목록·ID 충돌 예외 호환을 수정했다. 같은-revision 캐시 무효화, cached-generation 검사, original-currency 정밀도는 코드 검토에서 보강했다. 취소된 과거 CI를 완료로 세지 않는다.

## 기존 검토 판정 유지

기준2054219의 기존58개는 PASS13/FAIL0/UNVERIFIED45/N/A0, RC40개는 당시 자동 검증 범위 PASS40, DEVICE12개는 UNVERIFIED12다. 이번 원장·metadata 테스트로 실제 OCR/수능 정확도/기기 항목을 승격하지 않는다. 전체 회귀 통과와 개별 실검증 판정은 별개다. 과거 판정·근거를 보존한 최종 checklist 산출물과 [RC 인계](EXT-FIX-02.md), [12개 기기 절차](EXT-FIX-02-DEVICE.md)를 함께 전달한다.

## 미구현·미검증 및 다음 입력

1. FD-21/22: 별도의 disposable Supabase Auth/Storage(PG17)·Edge 실행 환경, 합성 object와 A/B 시험 계정, 키/자격증명을 안전하게 주입할 수단이 필요하다. 실제 bytes upload/download/hash, API 실패 뒤 pending/backoff, 재시도 뒤 object 부재, doc/account 삭제 후 정리 완료를 확인한다. 실제 환경이 없었으므로 UNVERIFIED다.
2. 서명 URL 시험: 실제 server clock에 맞춘 만료 직전 fixture에서 URL exp≤asset expiry 및 최대60초를 확인한다. A/B/삭제 JWT, 서명 대기 중 삭제, 만료 정각 이후 신규 발급 거절, 이미 발급된 URL의 최대 잔여 수명을 실제 GET으로 확인한다. test DB의 통제 clock/fixture만 쓰고 운영 시각·원본 first_stored_at을 갱신하지 않는다. SQL bucket metadata 삭제만으로 bytes 삭제 완료를 판정하지 않는다.
3. 실기기12개 절차는 그대로 UNVERIFIED다. DEVICE07~09에는 새 v3→v4 암호화 fixture, body가 없는 목록, pending 다운로드 중 계정/전체삭제, 실제 재시작을 추가한다. 서버 ACK와 최초 로컬 receipt 사이 강제 종료는 기존 미검증 경계다.
4. NEXT-02/03: 실제 OCR/수학 모델, 라이선스·가중치 hash·배포 lock/container, provider 약관/연령/데이터 보관/지역/가격, 권리 있는 평가셋과 정확도/실패율/지연/재시도 포함 단가 기준. `RemoteAiJobs`의 approved quote/request ID와 worker v2 transport에 연결한다. 가격/토큰/검증 호출/usage 상한을 증명하기 전 remote paid solver는 닫혀 있다. 앱 quote 승인 UI·종료 후 pending ID 복구 UX도 이 연결 작업에 포함한다.
5. NEXT-04 시선 보조·정정 UI, NEXT-05 핵심 기록 우선 S13/원격 confirmed 저장·photo upload UI/선택 다운로드 스케줄러, NEXT-06 실제 구독·추가권·환불 권리. 현재 FakeSyncEngine을 완성했다고 표시하지 않는다.
6. 운영 상품·provider pricing/FX/point 양/차감 정책·임시결과 TTL·장기 비용/정리 의무 보관 근거는 명시적 설정과 검토가 필요하다. 새 정책/기능을 자동 활성화하는 기본값은 없다. 공개 서비스의 ingress/로그/성능/가용성/원가·보안 검토도 남았다.

기본 공유24시간은 변경 가능한 제품 정책이며 OS가 수신 완료나 정확한 삭제 시간을 보장하는 수치가 아니다. 복원30일·처리 임시 파일·공유 파일·공급자 측 보관은 네 종류로 유지한다. SQLite 보호를 서버/Storage/외부 수신 사본까지 확장해 주장하지 않는다. NEXT-07 실제 통합 검토 전 Draft 유지, 병합 판단도 후속 범위다.
