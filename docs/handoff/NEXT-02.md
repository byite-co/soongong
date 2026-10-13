# NEXT-02 · OCR 개발 연결과 검증 인계

기준 `419e78e7c541a725435c8626933e27dfd56b2bcc`, 기존 PR #9 `feat/s14-oss-integration` 위에서 작업했다. 사용자 실행 지시가 이전 review-only/separate-PR 지침을 대체한다. 기존 변경을 보존했고 force push·병합·배포·공개 활성화·유료 API·결제를 하지 않았다. PR은 Draft다. 이 문서는 S13/공개 제품 완료 선언이 아니다.

## 구현 경로

- `RemoteReadingEngine` + `/reading/grading`: 과목/범위, 소유 사진 선택·촬영, 서버 quota, 처리용 업로드, submit/status/cancel, 사용자 문항·Mark 교정, save/updateMarks/discard/quota 계약. 기본 FakeReadingEngine을 닫힌 adapter로 바꾸었다. 성공 응답의 기존 wrong_items/review_entries를 소유권·epoch·server_version 검사 뒤 로컬에 반영하고 반복 저장으로 행을 추가 생성하지 않는다. 활성 요청이 서버에만 있으면 상태 snapshot으로 로컬 요청을 복구한다. 로컬 tombstone은 복구하지 않는다. 현재 화면 입력은 요청당 사진 1장, 서버 adapter는 최대20장이다. 전체 오답/복습 UI는 후속 범위다.
- 기존 `TranscriptionScreen` + `AiApprovalController`: text/math 분리, 원본 대조, 회전·영역 선택, 서버 quote의 작업/포인트/정책/terms 표시, 명시 승인, quote 재확인, 교정, 사용자 확정 저장. 수식은 안전한 LaTeX **원문 표시/편집**이며 typeset preview나 정답 판정을 제공하지 않는다. 20,000자 상한과 사용자 확인이 유지된다.
- 암호화 로컬 DB v5 `study_ai_requests`: HTTP 전에 request/quote/owner/epoch/generation/입력 SHA256/원본 hash와 순서 있는 회전·crop 이력을 기록한다. 이미지·credential은 넣지 않는다. 결과 수신과 확정 저장은 다르다. 교정문·문서 ID/revision을 트랜잭션으로 연결하여 반복 확정은 기존 문서를 열고 수정은 CAS로 보호한다. 문서 삭제 시 요청에 남은 본문도 지우고 늦은 결과 재저장을 거절한다.
- 복구는 동일 ID `study-job status/cancel`만 사용한다. unknown·timeout·없는 요청에서 새 ID나 공급자 자동 재시도를 만들지 않는다. 결과 만료는 빈 본문 성공으로 저장하지 않는다. 원본 사진 부재를 알린다. 서버 points_state를 표시하며 취소 호출만으로 반환 완료라 하지 않는다. 판독 전송 전 `sending`도 영속화해 앱 재개 목록에서 빠지지 않는다.
- provider/account/동의/epoch/로컬 purge generation 경계와 트랜잭션 끝의 소유권 검사를 적용했다. 같은 사용자 토큰 갱신은 다른 사용자 전환과 구분한다. 이전 작업의 finally가 새 승인 scope나 새 임시 task를 해제하지 않는다. 기존 picker lost-data 폐기·공유 소유권·계정 삭제 영수증 경로를 보존했다.
- `reading-worker`: canonical owner/request/page object만 읽고 private HTTPS worker에 1회/페이지 호출, claim attempt fencing, SQL 재검증, 원래 quota 정산, 삭제 큐를 연결했다. handler 전체55초·worker50초·CPU45초/프로세스 정리 한도를 늘리지 않았다. 각 run은 job1개다. 자동 모델 fallback/공급자 재시도는 없다.
- 버전1 worker receipt가 내부 OCR v1/reading v2를 감싼다. attempt/provider/model 및 실제 requests/images/pages/crops/elapsed_ms를 Edge가 검증한 후 서비스 전용 원장에 기록한다. malformed inner result라도 정상 receipt는 비용 증거로 남긴다. 미응답·부분 페이지·누락 usage는 unknown이다. 실제 API0원인 로컬 정책만 검증된 증거로0원 정산한다. 포인트 반환과 운영비 예약 해제는 별개다.
- `reading_ai_costs`는 기존 판독의 비용 전용 원장이다. 포인트를 지급·차감해 무료를 흉내 내지 않는다. 다른 사용자/신규 OCR과 같은 `ai_budgets` 잠금을 사용하며 기존 월 정산·정확한 numeric·RLS를 유지한다. 정책/지갑/권리의 운영 seed는 없다.

SCHEMA-CHANGE: 로컬 v5 및 `20261013070956_next02_ocr_execution.sql`, `20261013081141_next02_reading_recovery.sql`. 적용된 NEXT-01 이전 migration은 수정하지 않았다. 후자는 기존 콘솔 의존 reading-photos private bucket/자기 canonical 경로 insert policy와 소유 상태 snapshot을 선언한다. 기존 수동 Storage policy가 있는 환경은 정책 합집합을 배포 전 확인해야 한다. 개발 전용 fixture 외 운영 권리는 조작하지 않았다.

CONTRACT-CHANGE: reading 결과 v2의 `mark/confidence=null`, 항상 `needs_review=true`; worker receipt v1; owner-scoped reading status의 복구용 stamp 필드 추가. 누락 confidence를1.0으로 채우지 않는다. 내부 OCR v1, 외부 study v2, 기존 ReadingEngine 메서드와 월 판독 권리는 보존한다.

## 실제 모델·자료·결과

[재현 및 권리 명세](NEXT-02-MODELS.md), [비식별 측정값](../evidence/next02/metrics.json), [사전 평가 기준](../evidence/next02/protocol.json), [실제 절대경로·출처·해시](../evidence/next02/datasets.json)를 함께 사용한다. 원본 이미지/정답/예측 전문은 Git/CI artifact에 넣지 않았다. 데이터에 없는 필기자/문서 ID는 null이다. 평가 ID는 자료의 필기자 ID를 대체하지 않는다.

| 실제 실행 | 결과와 판정 범위 |
|---|---|
| PaddleOCR3.7 + Korean PP-OCRv3/v5 | 둘 다 실제 모델 실행. 인쇄 합성 문장 smoke에서 v5는 문자열 일치, v3는 공백/문장부호 차이. 이는 손글씨 품질이 아니다. 공개9개는 실제/합성 구분·정답·필기자 정보 없음. 원본 MPO는 양쪽 모두9/9 거절. 명시적 첫 frame PNG 파생본은 v3 7/9, v5 4/9 유효. 실패도 분모 포함. 실제 한국어 필기 CER/숫자·부호·단위 오류는 UNVERIFIED. |
| UniMERNet tiny0.2.3 | 실제 CPE 인쇄 수식60개. 유효60/60, 사전 선언한 NFC+공백 제거 exact match12/60=20% → 목표90% FAIL. 일부 표현상 차이도 포함되는 엄격한 문자열 지표이며 “80% 수학적 오류”로 해석하지 않는다. 추론 후 정규화를 바꿔 합격시키지 않았다. 손글씨/3명 조건은 UNVERIFIED. |
| 채점표시 | 실제 PaddleOCR+red-ink geometry를 synthetic page에 실행하고 실제 local HTTP receipt도 확인. 문항1~5, wrong/partial 후보와 null 확인 대상을 반환했다. 원형 표시도 null이 될 수 있고 guessed/unsolved는 자동 추정하지 않는다. 모든 후보는 확인 필요다. 실제5종100개 자료가 없어 precision/recall/macro-F1/문항 연결 품질은 UNVERIFIED. |

평가 장비: Ryzen7 7800X3D, Windows/WSL Ubuntu, WSL 약15.5GiB+4GiB swap, RTX5070 12227MiB, driver595.79. Python3.11.17, PaddleCPU4threads/MKLDNN OFF, Torch2.8.0+cu128. 공유 개발 host에서 측정했으며 기기 성능이 아니다. cold는 요청별 새 child로 측정했다. 수식 cold p50 15.862s/p95 19.883s, 관측 순차 약218회/hour, 최대 child RSS 약2.04GiB. 이는 이60개에서20초 목표 안이다. warm은 같은1개 입력5회 4.136~5.747s로 분리하며 제품은 warm worker 재사용을 하지 않는다. GPU peak/전력/부하 중 처리량은 측정하지 못했다. 한국어 파생본은 v3 p95 12.823s, v5 p95 15.110s이나 유효율77.8%/44.4%는98% 목표 미달이다. 일부 child EOF의 OS 종료 원인은 단정하지 않는다(CPU45초 제한 유지).

KaTeX0.16.22의 사후 호환성 검사: 예측3/60, 제공 정답2/60 렌더 거절. `throwOnError`, trust=false, 입력별 새 macros, 확장 상한 사용. 이 값은 KaTeX 지원 범위 내 호환성으로, LaTeX 전반의 문법 정확도나 의미 검증이 아니다. 검토한 짧은 불일치6개에서 매크로·괄호·레이아웃 표현 차이를 확인했다. 전체60개 부호/지수/분모/정의역의 전문가 의미 오류율은 UNVERIFIED다. 교정률/사람 소요시간도 실측하지 않았다.

## 비용 구분

외부 AI API 호출/과금은0건/0원이다. 실제 로컬 모델 실행은 GPU/CPU/전력을 소비했으나 인프라 실청구·전력 배분은 unknown이다. “전체 건당0원”으로 보고하지 않는다. 품질 평가의96회 시도(원본 MPO 거절18 포함)와 smoke/warm 실행은 report 파일 hash/모델 ID로 구분한다. 설치 실패와 별도 개발 probe도 있었으므로 이를 완전한 인프라 실측 원장으로 보지 않는다. 제품 비용 원장과 오프라인 평가 보고는 구분하며 실제 매출/지갑에 평가 비용을 넣지 않았다.

가정 시나리오(관측 수요/판매 정책 아님): 로컬 API0원, 월 인프라 예산10/20/30만원, 월 시도1천/5천/1만, 유효율98%, 유효 결과의 사용자 확정50%를 가정하면 시도당100/40/30원, 유효당102.04/40.82/30.61원, 확정문서당204.08/81.63/61.22원이다. 실패/유휴를 포함하는 **가정한 월 인프라 총액**을 나눈 값이다. 실제 한국어 유효율이나 사용자 확정률과 다르며 인프라 견적/실측 없이는30만원 내 실제 공급량을 확정할 수 없다. 사용량 증가시 전력·호스팅·Storage 비용을 새로 평가해야 한다.

비교 참고로 [Cloud Vision 공식 가격](https://cloud.google.com/vision/pricing)은 Document Text Detection 첫월1000단위 무료 이후1000단위USD1.50(이미지/페이지/기능별)로 확인했다. 이 계정의 공유 무료량/SKU/FX/부대비용이나 대상 연령 계약을 승인한 것이 아니며 호출·채택하지 않았다. Gemini Developer API는14세 이상 앱에 자동 연결하지 않는다. 운영 가격/포인트 양/이월/환불 값은 미확정 상태다.

## 자동 시나리오 증거 색인

24는 테스트 수가 아니다. 아래 실파일 테스트명을 최종 실행 SHA의 CI 로그와 연결해 판정한다. 실행 결과·최종 SHA·run ID·suite별 개수는 동봉 `soongong-pr9-next02-checklist.json` 및 `soongong-pr9-next02-report.md`가 정본이다. 오래된 CI 수치를 최종 SHA에 재사용하지 않는다.

| 항목 | 코드/테스트 증거 |
|---|---|
| A01 | providers/study_providers; `A01 default closed engine`, widget `A01/A04 actual approval injection` |
| A02 | strict receipt/worker transport; `worker_receipt_test.ts`, Python transport/bounds, grading wire limits regression |
| A03 | models/*.json, checked_models, `test_manifest_detects_unlisted_and_modified_weights`, transport model ID tests |
| A04 | AiApprovalController cancel/changed quote; widget cancel zero/repeated taps one durable request |
| A05 | stale scope controller test; study_action_race purge/account overlap; transaction before/after guard |
| A06 | AiRequestRepository `A06 encrypted request identity commits before HTTP`; duplicate INSERT and record failure zero-dispatch |
| A07 | `A07 file close/reopen retains request correction and document link`; OS process test와 구분 |
| A08 | `A08 pending recovery`, actual PG `FD-17/18 dispatch interruption` |
| A09 | expired-success test, RemoteAiJobs pending/cancel, actual PG result expiry |
| A10 | revoked consent/deleted-body/purge tests; actual PG deleted-account callback; same-user refresh test |
| A11 | request confirmation/CAS test, study_action_race save errors, approval widget no automatic document |
| A12 | `A12 long malformed LaTeX stays editable and never auto saves` |
| A13 | `study_crop_test.dart`, owned temp and picker RC suites, adapter unowned upload zero |
| A14 | RemoteReadingEngine submit8 outcomes,2/5s polling,404/410 terminal,cancel,active_exists snapshot recovery; existing save/update/discard/quota SQL suites |
| A15 | `13_ocr_execution.sql` stale attempt/malformed page/unknown/null checks; receipt output tests |
| A16 | `A16 save replay mirrors real server rows once`, existing marks/reading-save SQL duplicate/mismatch cases |
| A17 | pgTAP original quota/no point lots; adapter denial mapping, actual shared-budget refusal |
| A18 | receipt/idempotent settlement/SQL permissions; invalid inner result receipt recording |
| A19 | units negative/fractional/missing zero refusal; original numeric/price/FX tests; local0 and unknown distinctions |
| A20 | actual PostgreSQL `A20 actual reading versus OCR lock race` observes real Lock waiter; existing different-user budget race |
| A21 | worker test_lifetime.py actual child timeout/socket/cleanup/semaphore, real model cold/warm above |
| A22 | full Flutter DB/encryption/purge/export/temp regressions and native host contracts |
| A23 | test_evaluate.py5 tests, split/identity/hash/full denominator, per-Mark unknown/timeout metrics, real reports |
| A24 | final analyze/codegen/test, server PG/Edge/static diagnostics, worker and Android/iOS native/build CI; data/key artifact audit |

## 실제 판정과 기존 검토

R01 PASS: 고정된 실제 text/math/grading 실행, 입력 hash와 normalized result 로컬 보존. R02 UNVERIFIED(실제 필기/정답/필기자 부족). R03 FAIL(인쇄 exact match20%; 손글씨 미검증). R04 UNVERIFIED(실제5종 자료 없음). R05 FAIL(관측 한국어 유효율 목표 미달; 수식 지연은 해당60개에서 통과). R06 UNVERIFIED(인프라 배분/실청구/확정문서 원가 없음). R07 UNVERIFIED(실제 앱+실제 엔진 전체 흐름 미실행). R08 UNVERIFIED(진행 중 앱 프로세스 강제 종료/재개 미실행). 합계 PASS1/FAIL2/UNVERIFIED5.

FD-21/22는 **로컬 실제 Auth/Storage/Edge 통합 범위 PASS**로 변경했다. `tool/next02_storage_check.py`는 임시14세 승인 pass를 가진 A/B 실제 Auth 세션을 만들고 합성 bytes를 업로드한다. A 서명 GET/B 거절, exp≤asset/60s, 실제 대기 후 GET 거절, 보관 시작/만료 비연장, B 삭제 시 bytes 잔존, pending/5분 backoff/즉시 재claim 거절, fixture due 재시도 후 실bytes/metadata 부재, 문서·계정 삭제의 잔여 의무/늦은 URL 거절을 확인했다. 운영 clock은 바꾸지 않았고 격리된 자산 TTL/삭제 due만 fixture로 조절했다. 시험 계정 제거와 local stack stop 완료. 발급된 URL은 즉시 철회 보장이 없으며 최대 잔여60초 제한은 유지된다. 공개 Supabase/기기 결과가 아니다.

기존58개는 기존 판정 PASS13/UNVERIFIED45를 보존한다. 이번 모델 실행으로 모든 OCR/수능/기기 복합 항목을 승격하지 않는다. RC40은 기존 자동 범위 회귀 결과와 연결하고 DEVICE12는 모두 UNVERIFIED다. NEXT-01 FD01~28 중 기존26개와 신규 Storage2개를 구분하고 FD21/22의 로컬 통합 근거를 추가한다.

## 재현·남은 범위·NEXT-03 입력

- 자동 검증: GitHub Actions analyze-test/server-tests/study-worker/native-check. Flutter3.47.5 코드 생성·lint·전체 unit/widget, PG16 pgTAP+PL/pgSQL+실제DB Edge, Python3.11 worker. Android Debug 빌드/native unit과 iPhone ARM64 release/no-codesign 및 Foundation assertions는 실기기 설치가 아니다. 로컬 Flutter/pub에 대한 이전 자동 승인 거절을 우회하지 않고 허용된 CI를 사용했다.
- 실제 Storage: Supabase CLI2.120.0, isolated project_id `soongong-next02-local`, Postgres17.11.0.004/Edge1.77.4. `tool/next02_storage_check.py` 상단의 /var/tmp CLI/stack 경로, Docker 이름, localhost만 허용한다. 임시 서비스 키는 CLI status에서 메모리로 읽고 출력하지 않는다. 로그 공유 시 startup/status 원문은 제외한다. 운영 프로젝트를 가리키게 고치지 않는다.
- 필요한 자료: 실제 한국어60영역/5명+정답/문서·필기자 구분, 손글씨 수식60영역/3명, 실제5종표시 각각20개 및 문항 연결 정답. AIHub 등 권한/신청이 필요한 자료는 [모델 명세](NEXT-02-MODELS.md)에 구체화했다. 원문/비밀키를 채팅에 요구하지 않는다.
- DEVICE12에 승인 중 계정/동의 변경, 크롭 회전·원본 보존, 카메라 측정 중 점유, 연결 단절 후 동일ID조회, 실제 OS 강제종료 복구, 교정 입력/삭제 경합을 추가한다. Android/iPhone 물리 기기와 승인된 dev Auth/worker endpoint가 필요하다. 현재 연결된 기기는 없다.
- NEXT-03 재사용: `AiApprovalController`/`RemoteAiJobs`, `AiRequestRepository.confirm`, `StudyDocument{id,text,kind,revision}`. text/math 확정 fixture는 study repository/ai request tests, 잘못된 긴 LaTeX fixture는 widget test를 사용한다. solver는 document_id/revision/epoch와 사용자 확인 원문을 받고 기준답 없는 verified 금지·CAS/계산 한도·source revision 변경 보호를 유지한다. 이번 모델 출력에 수학적 정답 보증을 부여하지 않는다.
- 미구현: 전체S13/핵심기록 원격 복원/사진 업로드 UI(NEXT-05), 실제 결제/추가권/환불(NEXT-06), 풀이 엔진 공개(NEXT-03), 시선 정정(NEXT-04), 실기기·전체 병합 판단(NEXT-07), 공개서비스 ingress/운영모니터링/정산/성능 검증. 별도미완료이며 PR은 계속 Draft다.

공유파일24시간은 변경 가능한 제품 기본값이며 플랫폼의 보관/정확한 삭제 보장이 아니다. 처리 임시 사진·복원30일·공유24시간·공급자 보관은 별개로 유지한다.
