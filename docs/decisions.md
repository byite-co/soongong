# S00 v2.7 · 결정 문서 (`docs/decisions.md`)

작성 2026-09-29 · 사람이 확정 · CC 세션 아님
상태 표기: **확정** = 그대로 구현 / **미결** = 구현하지 않고 해당 경로를 막거나 빈칸으로 둠 / **확인 필요** = 요섭님 답변 대기
v2.6 → v2.7 변경: D21 확정(신규 레포, 기존 sungong 레포 미재사용) → D19 행·S01·S03 전제 갱신, 착수 보류 해제
v2.5 → v2.6 변경(v5 검토 V5-01 + 잔여 반영): D16(제출 분기에 삭제 여부 선검사·`request_deleted`·`invalid_state`, status의 tombstone 응답) · D14(tombstone 필드 목록은 D2 참조로 통일)
v2.4 → v2.5 변경(v4 검토 V4-01~05 반영): D2(tombstone 표현·유지 키·서버 응답 적용 경로) · D16(상태 조회 API·저장된 결과 삭제 mutation·retry 삭제 범위·ID 규칙·사진 삭제 작업 영속 등록) · D24(전역 default privileges·트리거/훅 실행 역할과 테이블 권한)
v2.3 → v2.4 변경(v3 재검토 V3-01~07 반영): D6(트리거 분기 순서·패스 즉시 삭제·시험 조건) · D8/D14(만료·버리기 시 결과 원문 삭제, 사진 즉시 삭제, tombstone 필드 최소화) · D16(초안 최초 제출 분리·워커 조회 조건·기동 경로·저장 후 마크 수정 명령) · D18(SDK `isActive` 기준·판정표 단일화) · D24(EXECUTE 회수 범위·입력 거부)
v2.2 → v2.3 변경(v2 검토 V2-01~11 반영): D2(pull 계약 단일화·tombstone 영구 보존·mutation_id·epoch 전파) · D6(훅=확인만, 소비·승인은 auth.identities 트리거, 연령 티켓→패스 2단계) · D15(전환·완료율 산식) · D16~D17(멱등 순서·작업 큐·회수·저장/버리기/만료 서버 전이·취소 결과) · D18(grace 판정) · D23(모드·열린 세그먼트) · D24(RPC 검증·동의 검사·문의·온보딩·activity_days 키)

## D0. 자료 우선순위 — 확정
1. PRD v1.4 (2026-09-19)
2. 유저플로우 다이어그램 · 프로토타입 v2
3. AI판독파일럿 인수인계 (2026-09-05) — D19에서 승계 표시된 항목만
4. 8월 결정기록·PRD 8/27~8/28 — 참고만
충돌 시 위 순서. PRD 안에서 충돌하면 4.3c(v1.4 신설)가 5장·7장보다 우선.

## D1. 계정 모델 — 확정
- 로그인 필수, 기록은 계정 동기화, 판독 사진은 기기만(D14).
- 파일 가져오기 삭제 → 유저플로우 `imp impFile impConflict impRunning impBad impVer impDupe impSave impN` 9개 폐기. 내보내기(CSV/JSON) 유지.
- PRD 5장 "서버 계정"·7장 표는 폐기, D14가 대체.

## D2. 동기화 규칙 — 확정
- 행 공통 필드
  - 서버 관리: `server_version`(승인된 쓰기마다 서버가 +1) · `server_received_at` · `server_seq`
  - 클라이언트 관리: `client_updated_at` · `deleted_at` · `purge_epoch`
  - 로컬 전용: `client_rev`(편집마다 +1) · `base_server_version`(마지막으로 본 서버 버전, 미확인 신규는 null) · outbox의 `mutation_id`(uuid, 전송 단위마다 고정)
- **push** = `sync_push(rows[])` RPC 하나. 행마다 `{table, id, mutation_id, base_server_version, purge_epoch, data}`. 서버는 사용자 advisory lock 아래 행마다:
  1. `sync_mutations(user_id, mutation_id)`에 영수증이 있으면 그 결과를 그대로 반환(응답 유실 재전송 멱등)
  2. `base=null`(신규): 같은 `id`가 서버에 있으면 — 살아 있으면 `version_conflict`+서버 사본, tombstone이면 `deleted` — 반환. 없으면 insert
  3. `base≠null`: `existing.server_version == base`일 때만 update(CAS), 아니면 `version_conflict`+서버 사본
  4. 승인 행은 `server_version+1`·`server_received_at`·`server_seq` 발급 + 영수증 기록
  - 거부 행은 클라이언트가 LWW로 해소(`client_updated_at` 늦은 쪽 승 · `deleted_at` 우선 · 동률 서버 승) 후 서버 사본의 `server_version`을 base로 새 `mutation_id`로 재push. `deleted` 응답은 로컬도 삭제(재생성 금지).
  - **예외(S02 문서 마감)**: `reading_requests` tombstone mutation 이 서버 행(`submitted_at not null`)과 충돌하면 `deleted_at` 우선 규칙으로 자동 재push 하지 않는다. `version_conflict` 와 함께 온 `server_row` 상태(`processing`/`taking_long`/`done_unsaved`/…)를 `applyServer` 로 적용하고 S10 의 취소·완료 처리로 넘긴다.
- **pull** = `sync_pull(since_seq, limit)` 하나. 응답 `{rows(server_seq 오름차순), next_seq, purge_epoch, ledger{subscription_state, reading_quota(당월)}}`. 모든 사용자 쓰기가 같은 advisory lock 아래 `next_server_seq()`를 거치므로 seq 순 = 커밋 순 → **겹침 조회 없음**, 커서는 `next_seq`로만 전진(단조). `ledger`는 읽기 전용 캐시 갱신용이며 push 대상이 아니다.
- **tombstone(`deleted_at`)은 계정 삭제 전까지 영구 보존**(물리 삭제 없음). 영수증 `sync_mutations`도 동일. 따라서 장기 오프라인 기기의 오래된 미확인 신규 create는 서버에서 `deleted`로 거부되어 부활하지 않는다. 커서 만료 개념 없음 — 60일 이상 오프라인이면 클라이언트가 `fullResync`(아래).
- **tombstone 표현(서버·로컬 동일 테이블)**: 삭제 행은 `id·user_id·deleted_at·server_version·server_seq·purge_epoch·created_at·client_updated_at·device_id` + 테이블별 **유지 키**(`reading_requests.request_id`, `wrong_items.request_id`, `review_entries.wrong_item_id`, `retry_records.wrong_item_id`, `session_segments.session_id`, `corrections.session_id`, `planner_items.recurrence_id`, `activity_days.date`)만 남기고 내용 컬럼(이름·제목·범위·마크·메모·시간값·결과 JSON 등)은 null. DDL: 내용 컬럼은 nullable + `CHECK (deleted_at IS NOT NULL OR <필수 내용 컬럼> IS NOT NULL)`. 클라이언트는 행을 엔티티로 디코딩하기 전에 `deleted_at`을 먼저 보고 `Tombstone`으로 처리(첫 pull·fullResync에 내용 없는 삭제 행이 섞여도 실패하지 않음). 서버 `sync_push`가 `deleted_at`을 받아들일 때 내용 컬럼을 null로 지운다.
- **서버 응답·pull 적용은 outbox를 거치지 않는다**: 저장소에 `applyServer(rows)` 경로를 두고 `sync_pull` 결과·`reading-*` 응답(`saved·marks_json·result_json null` 등)은 이 경로로만 로컬에 반영. 이 반영은 `client_rev`를 올리지 않고 outbox에 넣지 않는다(서버 컬럼 거부 규칙과 충돌 방지).
- **epoch**: `profiles.purge_epoch`. 모든 push/pull 요청에 클라이언트 epoch 동봉, 모든 pull 응답에 서버 epoch 포함. 요청 epoch ≠ 서버 epoch이면 `epoch_mismatch`(미래 값도 거부). 클라이언트는 서버 epoch가 더 크면 로컬 데이터 초기화 후 `pull(sinceSeq: 0)`, 같지 않은 다른 경우는 오류로 기록하고 재시도 안 함.
- **`fullResync`**: ① outbox 전부를 그대로 `sync_push`(영수증·tombstone·CAS가 부활·중복을 막는다) ② `pull(sinceSeq: 0)` ③ 로컬에만 있고 `server_version != null`이며 서버 응답에 없는 행 삭제.
- **모든 기록 삭제(`purge-all`)**: 사용자 lock 아래 ① 활성 판독 요청을 `reading_finish(cancelled, reason=purge)`로 종료(예약 해제) ② 데이터 테이블 행 삭제(tombstone 아님, 물리 삭제) + `sync_mutations` 삭제 ③ `purge_epoch+1`. `reading_quota`·`subscription_*`·`signup_approvals`·`profiles`는 유지(전체 삭제가 월 횟수 초기화 우회가 되지 않음). 이전 epoch 요청의 늦은 완료는 `reading_finish`가 요청의 `purge_epoch`와 현재 값을 비교해 폐기.
- 사진(`photos`)·outbox·sync_meta·session_snapshot 등 로컬 전용은 동기화 대상 아님.

## D3. 착석 감지 엔진 — 확정 (A: 앱 내 신규 구현)
- 출력은 착석 불리언 + 카메라 상태만.
- 실기기 검증 케이스는 8월 관문 승계: 양성 4(정면·고개 숙임·측면·저조도) + 음성 10(빈 자리·의자에 옷·벽 포스터·사진 속 얼굴·반려동물·조명 변화·카메라 가림·화면 끄기·전화 수신·다른 앱 카메라 점유). S04 프로토콜에 반영.
- [S04b] focus-engine 선별 참조(세대·종료·시각 분리), 엔진 출처는 A 유지. 7상태 판정·30초 확정 버퍼·백그라운드 서비스·MediaPipe 경로는 미도입(`docs/seat-engine.md` §3.6).

## D4. 스트릭 — 확정
하루에 저장된 세션 1회 이상. 3분 미만도 저장됐으면 포함.

## D5. 계정 삭제 — 확정
즉시 삭제. 서버 기록 전체 + 로컬 DB 초기화 + 기기 사진 삭제. 구독은 스토어에서 별도 해지 안내.

## D6. 연령·동의 — v1 정책 확정 · 절차 미결
- **v1 출시 정책: 만 14세 이상만 가입 허용.** 현재 준비 범위에서 선택한 정책. 보호자 확인 절차 구현·검증 완료 시 지원 범위를 넓힌다.
- 연령 입력: 생년월일(연도만 불가). 분기는 서버 계산.
- 생성 전 차단 구조(소셜 포함) — Before User Created Hook + `auth.identities` 트리거 2단계. **훅과 사용자 생성은 같은 트랜잭션이 아니다**(Supabase Auth 공개 소스 기준, 훅 호출 후 별도 트랜잭션에서 생성). 그래서 소비·승인은 훅이 아니라 트리거에서 한다.
  1. 연령 판정(제공자 호출 전): `ageGate`에서 생년월일 → `age-check` Edge Function → 만 14세 이상이면 **연령 티켓**(서명 JWT, 10분, 내용은 `age_ok:true·jti`뿐) 발급, 생년월일은 응답 후 폐기(DB·로그·계측 기록 없음). 미달 → `ageBlocked`에서 끝, 제공자 호출 없음.
  2. 패스 발급(티켓을 가입 요청에 연결): 제공자 선택 후 네이티브 SDK로 idToken 획득(Apple은 nonce) → `issue-pass(ticket, provider, id_token | email, nonce?)`. 서버는 티켓 검증 + idToken 검증(서명·`iss`·허용 `aud` 목록·`exp`, Apple `nonce` 해시 일치) 후 패스 `signup_passes(provider, subject_hash, expires_at=+10분)` 저장. 키: 소셜 `(provider, sha256(sub))`, 이메일 `('email', sha256(lower(email)))`. 같은 키 미소비 패스가 있으면 만료 연장만. 카카오는 `signInWithIdToken(provider:'kakao')` 공식 경로(OIDC 활성화·`openid` 스코프).
  3. `before_user_created` 훅(Postgres 함수): payload의 `user.app_metadata.provider`·`user.email`·`user.user_metadata`(제공자 `sub`는 훅 시점에 `identities`가 비어 있으므로 경로별 fixture로 추출 위치를 S03에서 확정)로 **미소비·미만료 패스 존재만 확인**. 없으면 `{"error":{"http_code":400,"message":"가입 확인이 필요합니다"}}`로 거부. **훅은 아무것도 쓰지 않는다.**
  4. `AFTER INSERT ON auth.identities` 트리거(사용자 생성과 같은 트랜잭션). **분기 순서**: ① `signup_approvals`에 `NEW.user_id`가 이미 있으면 계정 연결(같은 이메일 OAuth 자동 연결 포함)로 보고 패스 조회·소비 없이 통과 ② 없으면 신규 가입: `NEW.provider`·`NEW.provider_id`(소셜 sub) / 이메일은 `NEW.identity_data->>'email'`로 미만료 패스를 `DELETE ... RETURNING`(소비 = 즉시 삭제, 보관 없음) → 1행이면 `signup_approvals(user_id=NEW.user_id, provider, age_verified=true, approved_at)` insert `ON CONFLICT (user_id) DO NOTHING` → 0행이면 `RAISE EXCEPTION` → 사용자·identity insert 전체 롤백. 소비된 패스는 남지 않으므로 계정 삭제 후 같은 제공자 재가입은 새 패스로 정상 진행.
  5. `complete-signup`: 인증된 `auth.uid()`의 `signup_approvals`만 확인(패스 TTL과 무관) → `profiles` 생성(없으면) + 동의 ① 기록. 멱등.
  6. 백스톱: `profiles` 없는 사용자는 RLS로 전면 차단. 훅이 꺼져 있어도 패스 없는 신규 가입은 트리거가 막고, 트리거까지 꺼진 환경(있어선 안 됨)에서 생긴 계정은 승인 기록이 없어 프로필 불가.
  - 클라이언트가 보낸 provider/sub는 신뢰하지 않는다 — 트리거는 `auth.identities` 실제 값만 본다.
  - 인수 기준(S03, 실제 Auth API 경유): 패스 없이 가입 → 훅 거부 / **훅 통과 후 트리거 단계 실패 유도**(dev 전용 설정 `app.test_trigger_fail`로 트리거가 RAISE, prod 마이그레이션에는 없음) → 사용자·identity·승인 전부 미생성, 패스는 삭제되지 않음 / **훅 비활성 + 패스 없음 → 트리거가 차단**(백스톱) / 기존 승인 사용자에 새 identity 연결(패스 있음·없음 둘 다) → 통과, 승인 1건 유지 / 동시 가입 2건 → 1건 / 승인 `user_id` = 실제 사용자 / 가입 10분 후 `complete-signup` 성공 / 탈퇴 후 같은 제공자 재가입 / 잘못된 aud·iss·nonce·티켓 없음 → `issue-pass` 거부. 훅 함수 단독 pgTAP은 보조.
- 동의 2종 분리, 각각 `consent_version·consented_at` 기록:
  ① 계정·학습기록 처리 — 가입 완료 시 (`complete-signup` 입력)
  ② 외부 판독 전송 — 온보딩 2단계 / 페이월 동의 단계 (`update-consent`)
- 미결: 법정대리인 확인 절차. 절차 없이 만 14세 미만 경로를 여는 기본값은 두지 않는다. 동의 화면만 추가한 상태로는 해제하지 않는다.
- 유저플로우 신규 노드: `ageGate`(생년월일 → 티켓) · `ageBlocked`.

## D7. 판독 요청 — 확정
사진 최대 10장, 범위는 자유 텍스트 40자 필수.

## D8. 미저장 판독 결과 — 확정
결과 데이터(이미지 분리)만 7일 유지. 만료·버리기 시 서버 `result_json`을 **실제로 삭제(null)**하고 상태만 남긴다(`expired`/`discarded`). 이후 status 조회·pull에 원문이 내려오지 않으며 로컬 캐시도 pull 시 정리. 횟수는 차감 유지.

## D9. 복습 큐 — 확정
초기 1일 → 맞음 ×2(최대 30일) · 부분 유지 · 또 틀림 1일 리셋 · 맞음 2회 연속 이탈.

## D10. 판독 요청 처리 — 확정
앱 포그라운드에서만 폴링. 재실행 시 `reading_requests.status`로 복원. OS 백그라운드 작업은 로드맵.

## D11. 같은 과목·범위 재등록 — 확정
사용자 선택(새 회차 / 기존 결과 수정). 자동 병합 없음.

## D12. 스택·버전 — 확정
- Flutter stable / Riverpod codegen / go_router / drift / supabase_flutter / RevenueCat / ML Kit.
- S01 시점 stable 버전을 `pubspec.yaml environment`·`.fvmrc`에 고정, `pubspec.lock` 커밋, CI 도구 버전 고정. 업데이트는 별도 작업.
- 클라이언트 설정(`env/app.dev.json`, anon key)과 서버 비밀(`supabase/.env`, service role)은 파일·주입 경로 분리. 서버 비밀은 앱 빌드에 절대 포함하지 않는다.

## D13. 식별자 — 확정
순공 / SoonGong · `co.byite.soongong` · `byite-co/soongong`(S01b 정정: 실제 레포명) · `soongong_premium_monthly`.

## D14. 데이터 처리표 — 벤더 행 제외 확정

| 데이터 | 위치 | 보관·삭제 |
|---|---|---|
| 착석 감지 프레임 | 기기 메모리 | 처리 즉시 해제. 파일 저장·외부 전송 없음 |
| 착석 샘플(불리언·시각) | 기기 → 계정 동기화 | 세션 세그먼트로만 저장. 사용자 삭제까지 |
| 판독 사진·파생 이미지(압축본·크롭) | 기기 | 최초 보관일 +30일. 즉시 삭제·로그아웃 삭제 지원. 재시도로 기간 연장 없음. 앱 시작·포그라운드·접근 시 만료분 삭제 |
| 판독 사진·파생 이미지 | 자사 서버 | 서버 처리 종료(완료·실패·취소) **직후 즉시 삭제 시도**. 실패분만 재시도 큐(5분), 잔여물은 최초 업로드 +24시간 내 purge. 클라이언트 수신과 무관 |
| 판독 사진 | 외부 AI(Vertex AI, D19 승계) | 전송 사실 명시. **미결:** 보관·학습 사용·로그 정책. 남용 모니터링 opt-out 신청 전에는 최대 90일 보관 가능성 → S16 게이트에서 확정 |
| 미저장 판독 결과(`result_json`) | 서버 → 기기 캐시 | 7일 후 또는 버리기 시 서버 원문 삭제(D8). 저장된 확정 마크(`marks_json`)는 오답 기록의 일부로 사용자 삭제까지 |
| 판독 결과·오답·복습·재풀이 | 기기 → 계정 동기화 | 사용자 삭제까지. 구독 종료 시 읽기 전용 |
| 세션·플래너·과목·설정 | 기기 → 계정 동기화 | 사용자 삭제까지 |
| 계정(이메일·로그인 방식·동의 이력) | 서버 | 계정 삭제까지. **생년월일은 어디에도 저장하지 않음** — `profiles`에 생년월일 컬럼 없음, 판정 결과는 `signup_approvals.age_verified`만 |
| 가입 패스(`signup_passes`) | 서버 | 소비 시 즉시 삭제, 미소비는 발급 +10분 만료 후 cron 삭제. 생년월일 미포함 |
| 가입 승인 기록(`signup_approvals`) | 서버 | 계정 삭제 시 삭제. `age_verified·approved_at·provider`만 |
| 구독 상태(`subscription_state`) | 서버(웹훅) → 기기 | 계정 삭제 시 삭제 |
| 구독 전환 이력(`subscription_events`, 웹훅 원본) | 서버 | 계정 삭제 시 삭제(계측 집계본 `metrics_weekly`는 익명 합산이라 유지) |
| 계측 `activity_days` · `review_due_snapshots` · `metrics_weekly` | 기기 → 서버 / 서버 / 서버(익명 합산) | 1년(cron 삭제) |
| 동기화 영수증 `sync_mutations` · tombstone 행 | 서버 | 계정 삭제까지(D2 부활 방지). tombstone에 남는 필드는 **D2의 tombstone 표현 규칙과 `docs/data-model.md`의 `tombstone_keep` 표**를 따르고 내용 컬럼은 null(여기에 목록을 중복 기재하지 않음). 영수증은 `mutation_id·table·row_id·server_version·result`만 — 학습 원문 미보존 |
| 판독 작업 `reading_jobs` · 사진 삭제 큐 | 서버 | 종료 후 7일 |
| 문의 내용·답장 이메일 | 서버 | `resolved_at` 기준 90일(미처리 건은 생성 후 180일 상한) |

- 앱 내 "저장 데이터 표"(S09), 개인정보처리방침, 스토어 신고(S15)는 이 표만 참조. 스토어 신고에는 외부 전송·일시 처리를 모두 포함한다.

## D15. 계측 — 확정
- 원칙: 기존 기록 재사용. 새 저장은 G3용 `activity_days(user_id, date)`와 구독 전환 이력 `subscription_events(event_id, user_id, type, event_at)`(웹훅 원본, 불변) 두 개.
- 산출: 서버 주 1회 배치 → `metrics_weekly`, 1년 보관. 주 경계 = 월요일 00:00 KST.
- 지표 정의
  - G1 착석 감지 비율 = `mode=camera` 세션 수 / 전체 세션 수(3분 미만 제외). 정정율 = 정정 건수 / camera 세션 수. 4주차 = 각 사용자 가입 후 22~28일 세션 기준
  - G2 연결 비율 = `planner_item_id` 있는 세션 / 전체 세션. 주간 등록 = 사용자당 그 주 생성된 planner_items 수(반복 전개 제외)
  - G3 D30 = 분모: 해당 주 가입(`profiles.created_at`) 코호트 / 분자: 가입 30~36일째 `activity_days` 1일 이상. 주 4일 = 그 주 `activity_days` ≥ 4. 스트릭 복귀 = 끊김(하루 공백) 후 7일 내 세션 저장
  - G4 전환(`subscription_events` 필드 기준): 체험 시작 = `INITIAL_PURCHASE` & `period_type=TRIAL` / 직접 유료 = `INITIAL_PURCHASE` & `period_type=NORMAL` / 체험→유료 전환 = `RENEWAL` & `is_trial_conversion=true`. 전환율 분모 = 그 주 체험 시작 코호트, 분자 = 같은 코호트의 체험→유료 전환. 일반 갱신·재구독은 전환에 넣지 않음. 확정 없이 저장 = `wrong_items.user_confirmed=false` 건수(목표 0). 재풀이 완료율 = 주 시작 시점에 `review_due_snapshots(week, wrong_item_id)`로 **그 주 due 집합을 고정**하고, 분자는 그 집합 안에서 그 주 `retry_records`(voided 제외)가 있는 고유 `wrong_item_id`. 선행 재풀이는 분자에 넣지 않으므로 100%를 넘지 않음. `review_entries.due_at` 현재값으로 과거 집합을 복원하지 않는다
  - 표시명: D30은 "D30(30~36일 창)", 관측 완료는 가입 37일째 이후 배치에서
- 사진·문항 본문·자유 입력·생년월일은 계측에 넣지 않는다. 외부 분석 SDK 없음.
- 구현·배포 담당: 집계 SQL 함수·`review_due_snapshots` 주간 잡·`metrics_weekly` 주간 잡은 S03(마이그레이션 + pg_cron), prod 등록은 S15 cutover 체크리스트. `metrics_weekly`는 익명 합산이라 사용자 RLS 없이 service role 전용. 배치는 `(week)` 키 upsert로 재실행 멱등.
- 보관 정책 잡(S03 pg_cron): 미소비 패스 삭제(10분 경과) · 문의 90일 · `activity_days`·`metrics_weekly` 1년 · 사진 잔여물 24시간 · 판독 미종료 회수(D16).

## D16. 판독 횟수 원장·작업·종료 전이 — 확정
- 서버 `reading_quota(user_id, month) PK, used, reserved, limit`. 사용자는 읽기만.
- **제출(`reading-submit`) 순서(트랜잭션)**: ① 사용자 advisory lock ② 인증·`profiles`·`entitled`(D18)·판독 전송 동의 ② 재검사(D24) ③ 같은 `(user_id, request_id)` 조회 후 **삭제 여부를 먼저, 그다음 제출 여부로 분기** — (0) 행이 있고 `deleted_at not null` → `410 request_deleted`, 예약·작업 없음(tombstone은 `request_id`를 유지하고 `submitted_at`이 비워지므로 초안으로 오인 금지) / (a) 행 없음 → 최초 제출 / (b) `status = selecting AND submitted_at null` → 최초 제출: 초안을 잠그고 최종 payload로 `payload_hash` 고정 / (c) `submitted_at not null` → 해시 같으면 기존 상태·예약 반환(재전송 멱등), 다르면 `409 payload_mismatch`(사진 교체는 새 requestId) / (d) 그 밖의 상태 → `409 invalid_state`. ④ (a)(b)만 계속: 다른 활성·미저장 요청 존재 → `409 active_exists` ⑤ `quota_month` 고정(제출 시각 KST 월), `limit-used-reserved > 0` 아니면 `409 quota_exhausted` ⑥ `reserved+1` + 요청 `processing·submitted_at` + **`reading_jobs` 행 생성(같은 트랜잭션, `lease_until=null, attempts=0, deadline=submitted_at+10분`)**. DB 제약: `unique(user_id) where status in ('processing','taking_long')`, `unique(user_id) where status='done_unsaved'`.
- 재촬영·사진 교체는 **새 requestId**(기존 요청은 먼저 취소). 같은 requestId에 다른 payload를 붙이지 않는다.
- **워커**: 선택 조건 `(lease_until IS NULL OR lease_until <= now()) AND deadline > now() AND attempts < 2`, `SELECT ... FOR UPDATE SKIP LOCKED LIMIT 1` + 같은 문장에서 `lease_until=now+3분, attempts+1` 갱신(원자적, 두 워커가 같은 작업을 잡지 않음) → 벤더 호출 → `reading_finish`. **기동 경로**: `reading_submit` 트랜잭션 안에서 `net.http_post`로 `reading-worker` 호출을 등록(pg_net은 커밋 후 전송, 실패 무시) + pg_cron 1분 sweep이 신규·lease 만료 작업을 소비(중단 후 재기동 경로). 워커 1회 실행은 큐가 빌 때까지 반복 소비.
- **회수(`reading-reaper`, 1분 cron)**: `deadline` 경과 또는 attempts 초과인 미종료 요청을 `reading_finish(failed, 'timeout')`로 단 한 번 종료. 앱이 실행되지 않아도 예약·활성 상태가 자동 해제된다.
- **종료 전이 `reading_finish(request_id, outcome)`**(service role 전용, 최초 1회만: `UPDATE ... WHERE status IN ('processing','taking_long')`): `done` → `used+1·reserved−1·result_json·status=done_unsaved`. `failed|cancelled` → `reserved−1`. 늦은 전이는 no-op. 요청의 `purge_epoch` ≠ 현재 epoch면 결과 폐기(D2). **같은 트랜잭션에서 `photo_delete_queue`에 해당 요청의 객체 경로를 `pending`으로 영속 등록**. 커밋 직후 호출한 Edge Function이 즉시 Storage 삭제를 시도하고 성공 시 `done` 처리, 실패·프로세스 중단 시 남은 `pending`을 `photo-delete-runner`(5분)가 처리. 24시간 잔여물 purge는 지속 장애 대비 최종 안전망. `purge-all`도 요청을 물리 삭제하기 전에 객체 경로를 큐에 보존.
- **상태 조회 `reading-status(request_id)`**(인증·profiles·소유 확인): `{status, server_version, completed_at, result_json(done_unsaved·saved에서만), marks_json(saved에서만), fail_reason, quota}` 반환. 행 없음 → `404 not_found`, tombstone → `410 request_deleted`(정상 status enum으로 내보내지 않음) → 클라이언트는 폴링 종료 + 로컬 tombstone 반영. S10 `watch()`는 이 함수 폴링(2초 → 60초 후 5초)으로 구현하고, 응답은 `applyServer`로 반영. `request_deleted`를 받은 requestId로는 자동 재시도하지 않는다.
- **취소**: `reading-cancel`은 최종 상태를 반환 — `cancelled` / `already_done`(결과 유지·차감 유지·결과 화면으로) / `already_failed`. 앱은 반환값으로 분기하고 "미차감"을 단정하지 않는다.
- **저장·버리기·만료(서버 소유 전이, D17 해제 지점)**:
  - `reading-save(request_id, items[])`: 트랜잭션 — 소유·`status=done_unsaved` 확인 → 클라이언트가 생성한 `wrong_items`·`review_entries` 행(id 포함) insert(server_version 발급) → `status=saved` → 영수증. 두 번째 저장(다른 기기·재전송)은 `already_saved` + 서버 항목 반환, 중복 생성 없음. 저장은 온라인 필수(오프라인이면 버튼 비활성 + 마크는 로컬 `confirmed_marks_json` 보존).
  - `reading-discard(request_id)`: `status=discarded` + `result_json=null`(D8), 차감 유지, 사진 로컬 보관.
  - 만료 cron(일 1회): `done_unsaved`가 `completed_at+7일` 경과 → `status=expired` + `result_json=null`(차감 유지). 클라이언트는 pull로 상태·원문 삭제 반영.
  - **저장 후 마크 수정 `reading-update-marks(request_id, marks[], entries[])`**(온라인 필수, `saved` 상태만): 전체 확정 마크를 서버 `marks_json`으로 교체하고 같은 트랜잭션에서 `wrong_items` 차이 반영 — 새로 비O가 된 문항은 생성(**클라이언트가 `ConfirmedMark.wrongItemId`에 새 uuid를 넣어 보냄**; X→O→X처럼 다시 생기는 항목도 매번 새 uuid, tombstone id 재사용 금지), O가 된 문항은 `wrong_items·review_entries·retry_records` soft delete(tombstone, 내용 null) — 후 클라이언트가 `ReviewScheduler`로 계산한 `review_entries`를 받아 D9 규칙 검증 후 반영. 삭제된 요청(tombstone)에 대한 늦은 수정은 `not_saved`로 거부. 다른 기기는 pull로 수신, 결과 화면은 항상 `marks_json`이 정답. 오프라인에서는 마크 수정 불가(해결 처리 토글은 `wrong_items.status` sync_push로 계속 가능).
  - **저장된 결과 삭제(S11 `wdDelRes`, 오프라인 허용)**: `sync_push`에 `reading_requests`의 **삭제 전용 mutation**만 좁게 허용 — `data`는 `{deleted_at}` 하나, 대상은 `saved` 상태, 소유·CAS·epoch 검사 후 서버가 한 트랜잭션에서 요청 tombstone(`result_json·marks_json null`, `request_id` 유지) + 연결된 `wrong_items·review_entries·retry_records` tombstone(각각 seq 발급). 사진·세션은 유지. 응답 유실 재전송은 영수증으로 멱등. `status·marks_json` 등 다른 컬럼 수정은 계속 거부.
  - 새 요청 허용 판정은 **서버 상태**(`saved/discarded/expired`)로만. 로컬 저장 성공만으로 잠금을 풀지 않는다.

## D17. 판독 동시 실행 — 확정
- 활성 요청(processing/taking_long) 계정당 1건, 미저장 결과(done_unsaved) 계정당 1건. 둘 다 D16의 DB partial unique index로 강제, UI 잠금은 안내용.
- 미저장 결과가 있으면 새 요청 버튼 잠금 + "확인 대기 중인 판독 결과가 있습니다 · 먼저 확인" → 결과 화면. 홈 카드 1건과 일치. 다른 기기에서 저장·버리기 되면 pull 후 해제.

## D18. 이용 권한·읽기 전용 — 확정
- 판정표 하나로 통일(서버·앱 동일 결과):

| 조건(우선순위 순) | status | entitled |
|---|---|---|
| 승인 대기 중(RevenueCat pending) | `pendingApproval` | false |
| `expires_at > now` & 해지 예약 없음 & `period_type=TRIAL` | `trial` | true |
| `expires_at > now` & 해지 예약 없음 | `premium` | true |
| `expires_at > now` & 해지 예약 | `cancelPending` | true |
| `expires_at ≤ now` & `grace_expires_at > now` | `grace` | true |
| 위 모두 아님 & 구독 이력 있음 | `expired` | false |
| 구독 이력 없음 | `free` | false |

  - `BILLING_ISSUE` 이벤트는 상태가 아니라 `grace_expires_at`(웹훅 `grace_period_expiration_at_ms`, null 가능)을 갱신하는 입력이다. grace가 null이어도 `expires_at`이 남아 있으면 그때까지 entitled.
  - **앱(S12)**: `purchases_flutter` `EntitlementInfo`에는 grace 만료 시각이 없으므로 앱은 `isActive`를 `entitled`로, `expirationDate`·`billingIssueDetectedAt`·`periodType`·`willRenew`로 status를 계산한다. `grace_expires_at`은 서버 ledger(`subscription_state.grace_expires_at`, S02·S03 컬럼)에서만 받아 화면 문구에 쓴다. SDK에 없는 필드를 읽는 코드 금지.
  - **서버**: 유료 판독 권한(`reading-submit`)은 서버 ledger로만 판정. 상태 enum: `free·trial·premium·cancelPending·grace·expired·pendingApproval`(S01).
- 읽기 전용 = `!entitled && 기존 오답 존재`. 체험 사용 여부와 무관.
- 웹훅: `event_id` 중복 무시, `event_timestamp`가 저장값보다 오래된 이벤트 무시. 원본은 `subscription_events`에 보존(D15). 계정 전환 시 SDK 사용자 ID·캐시 권한 함께 전환.
- 승인 대기: 관측 가능한 상태(RevenueCat pending)만 표시. 앱 타이머로 확정 금지.

## D19. 9/5 인수인계 결정 승계표 — 확정

| 8월 결정 | 처리 | 근거 |
|---|---|---|
| Gemini Developer API 사용 불가, Vertex AI 전환 | **승계** | D14 벤더 행. 계약·opt-out은 미결 |
| 사진·크롭 서버 보관 없음(기기 저장) | **승계** | D14. 서버는 처리 중 일시 보유만 |
| 판독 정확도 게이트 UX별 3종 · 비정답 마크 recall 핵심 · 사진당 1회 측정 · AI가 라벨 만들지 않음 | **승계 → S16 게이트 조건** | 엔진 트랙 산출물을 게이트로 사용 |
| 감지기 실기기 테스트 양성 4 + 음성 10 | **승계** | D3 |
| A′ 서버 checkpoint 측정 구조 | **변경** | v1.4 오프라인 우선. 손실 상한은 로컬 15초 스냅샷으로 충족(D23) |
| 직접 입력 채점 본안 + AI는 유료 초안 | **v1 범위 제외 · 재도입 보류** | v1.4 PRD·유저플로우·프로토타입에 경로 없음. 과거 결정의 영구 폐기는 아님. 재도입 시 화면 설계 필요 |
| "엔진 미달이면 AI 기능만 끄고 출시" 방침 | **효력 종료** | 직접 입력 제외 시 엔진 없이는 오답·복습이 빈 기능 → D20 S16 게이트가 출시 필수 조건 |
| 기존 sungong 레포(백엔드 스키마·RPC·화면·CI) | **미재사용 확정**(2026-10-01) | D21. 보존 여부는 사람 판단, 새 레포에서 참조하지 않음 |
| 가격 미확정 | **변경** | PRD v1.4 4,900원/월 채택 |
| 노출된 Gemini API 키 폐기·재발급 미확인 | **사람 확인** | 새 레포와 무관하나 미완료면 처리 |

## D20. 출시 범위·심사 게이트 — 확정
- S15 완료 = Play 내부 테스트 AAB 업로드 + TestFlight 빌드 업로드 + 스토어 입력 문서. 이 빌드는 판독 미연결(준비 중 안내) 허용.
- **심사 제출 게이트 = S16 실엔진 연결·검증 통과. 출시 필수 조건.** 실제 판독 · 횟수 예약/확정/해제 · 취소 · 서버 사진 삭제 · 재실행 복구 관통, p90 8초·실패율 5% 이하(PRD 8장), 판독 트랙 정확도 게이트 3종 통과, D14 벤더 행 확정, 개인정보 문서 갱신.
- 엔진 서버 구현 자체는 이 묶음 밖(별도 트랙).

## D21. 기존 sungong 레포 — 확정 (2026-10-01: 신규 레포, 미재사용)
- `byite-co/soongong`(S01b 정정)을 새로 만들고 기존 sungong 레포의 코드·스키마·마이그레이션·CI를 가져오지 않는다. D24 default privileges 변경 범위 확인(다른 서비스 공유 역할 여부)도 불필요 — 새 Supabase 프로젝트 기준.
- 9/5 문서에서 승계한 항목은 D19 표의 결정·기준값뿐(코드 아님).
- S01~S03 실행 범위는 지시문 그대로.

## D22. 삭제 되돌리기 — 확정
- soft delete 시 `pending_delete_until = now+5s`, outbox enqueue는 `commitDelete`(기한 경과)에서만.
- 앱 재시작 시: 기한 지난 건 commit, 안 지난 건 복원(삭제 취소). 토스트 재표시 없음.
- 대상: 플래너 항목·기간 띠·반복 일정·과목·세션. 확인창을 거친 삭제(계정·모든 기록·판독 결과)는 즉시 commit.

## D23. 측정 시간 규칙 — 확정
- 세션 타임라인은 메모리 원본, 15초마다 `session_snapshot` 단일 행 덮어쓰기(append 아님). 스냅샷 필드: `mode(camera|manual)` · 확정 세그먼트 목록 · **열린 세그먼트 `open_kind(seated|manual|away|paused)`·`open_start`** · `last_seated_at`(camera만) · `away_candidate_since`(camera만, 미확정 후보) · `saved_at`(벽시계) · 감도. 단조 시계 기준점은 저장하지 않는다 — 재부팅 후 이어 쓰지 않음.
- 이탈 확정(임계 초과) 시 away 세그먼트 시작 = `last_seated_at`(최대 90초 소급). 확인 대기 구간은 순공 제외. 세션 종료 전까지 모든 세그먼트는 소급 수정 대상.
- 강제 종료 복구는 **열린 세그먼트 kind별**로 마지막 스냅샷에서 닫는다:
  - `seated` + 후보 없음 → `saved_at`에 닫고 착석 인정 / `seated` + `away_candidate_since` 있음 → `last_seated_at`에 닫고 이후는 away로 정산
  - `manual` → `saved_at`에 닫고 순공 인정
  - `away`·`paused` → `saved_at`에 닫고 순공 제외
  - 스냅샷 없음 → 세션 시작 시각에 닫고 0분
  - 스냅샷 이후 시간은 어떤 경우에도 추가하지 않음(status=interrupted, 손실 상한 15초)
- 카메라 장애(`cameraLost`)·화면 꺼짐·다른 앱 점유는 이탈이 아니라 `paused`. 이탈 판정은 카메라가 정상 동작 중 미검출일 때만.
- 저장·버리기 어느 경로든 `session_snapshot` 삭제.
- **감도(S02b 보완, 사람 확정)**: `sensitivity_level` 0·1·2 = 이탈 임계 **60·75·90초**. 최근 2주 정정 **3건마다 1레벨 상향**(상한 2, 건수가 줄면 하향, 변동 시 토스트). S02 지시문의 "+10초씩" 문구는 폐기. S06 은 `AwayPolicy.thresholdFor(level)`·`SensitivityPolicy.levelFor(count)` 의 이 값을 그대로 쓴다.

## D24. 서버 권한 경계 — 확정
| 구분 | 테이블 | 사용자 권한 |
|---|---|---|
| 사용자 편집 | subjects · sessions · session_segments · corrections · planner_items · recurrences · wrong_items · review_entries · retry_records · settings · activity_days | `sync_push` RPC 경유 CAS 쓰기(허용 컬럼 목록 내), select. `wrong_items·review_entries`의 최초 생성은 `reading-save`가 한다 |
| 서버 원장 | subscription_state · subscription_events · reading_quota · reading_jobs · photo_delete_queue · sync_mutations · signup_passes · signup_approvals · review_due_snapshots · metrics_weekly | `subscription_state·reading_quota`만 pull `ledger`로 수신. 나머지는 사용자 접근 없음(service role·트리거만). `metrics_weekly`는 익명 합산이라 사용자 정책 없음 |
| 혼합 | reading_requests | 클라이언트 컬럼(subject_id·range_text·origin·session_id·planner_item_id, `selecting` 상태에서만)은 `sync_push`로, `saved` 상태의 **삭제 전용 mutation**(`data={deleted_at}`)만 추가 허용(D16). `submitted` 이후 그 외 모든 전이는 서버 함수(`reading-submit/status/cancel/save/discard/update-marks`·`reading_finish`·만료 cron)로만. 서버 컬럼(status·submitted_at·payload_hash·result_json·marks_json·quota_month·quota_charged·fail_reason)은 허용 컬럼 목록에 없음(포함 시 행 거부) |
| 계정 | profiles (생년월일 컬럼 없음) | 자기 행 select, 갱신은 `complete-signup`·`update-consent`·`profile_set_onboarding_done()`·`purge-all` |
| 문의 | inquiries | `submit-inquiry` Edge Function만 insert, 사용자 select 없음 |
- **함수 실행 권한(Supabase 기본값은 `authenticated`에도 EXECUTE가 있음)**: 앱 소유 함수는 시그니처별로 `REVOKE EXECUTE ... FROM PUBLIC, anon, authenticated`를 먼저 실행한 뒤 사용자 RPC(`sync_push·sync_pull·profile_set_onboarding_done`)만 `authenticated`에, Edge에서 호출하는 서비스 함수(`reading_submit·reading_status·reading_finish·reading_save·reading_update_marks·집계·회수`)는 `service_role`에 명시 grant. 내부 보조 함수(`next_server_seq` 등)는 grant 없이 소유자·상위 함수에서만. **새 함수 기본값은 실제 마이그레이션 역할(Supabase CLI = `postgres`)에 대해 `IN SCHEMA` 없는 전역 기본 권한과 스키마별 기본 권한을 둘 다 회수**(스키마별만으로는 전역 PUBLIC EXECUTE가 남음): `ALTER DEFAULT PRIVILEGES FOR ROLE postgres REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC, anon, authenticated;` + `... IN SCHEMA public ...`. 검증: 시험 함수를 새로 만들어 개별 REVOKE 전에도 anon/authenticated EXECUTE가 없는지 확인. 새 프로젝트이므로(D21) 공유 역할 확인 불필요. 모든 `security definer` 함수는 `set search_path = public, pg_temp`.
- **가입 훅·트리거 실행 역할**: `before_user_created` 훅 함수와 `auth.identities` 트리거 함수는 **`postgres` 소유 `security definer`**(테이블 소유자이므로 `signup_passes·signup_approvals` 접근·RLS 우회 가능), EXECUTE는 `supabase_auth_admin`에만 grant(PUBLIC·anon·authenticated 회수), `supabase_auth_admin`에 `public` 스키마 USAGE. 두 테이블은 RLS 활성 + 사용자 정책 없음. 검증은 SQL Editor 관리자 호출이 아니라 **깨끗한 dev 프로젝트에서 실제 Auth API로** 이메일·소셜 가입·기존 계정 연결이 성공하는지로.
- **RPC 내부 검증**: `sync_push`는 행마다 ① `auth.uid()` 존재 + `profiles` 존재 ② `table`이 사용자 편집 허용 목록에 있음 ③ `data`의 키가 테이블별 허용 컬럼 목록에 있음 — **허용 목록 밖 키(서버 관리 컬럼·`user_id` 포함)가 하나라도 있으면 그 행을 `invalid_columns`로 거부**(무시하지 않음), `user_id`는 서버가 `auth.uid()`로 채움 ④ 기존 행은 `user_id = auth.uid()` 확인. `reading-submit`은 ① 인증·profiles ② `entitled`(D18) ③ 동의 ② 현재 유효 ④ 원장. 무료·만료·미동의 사용자는 예약·외부 전송 없이 거부.
- 온보딩 완료: `profile_set_onboarding_done()` RPC(authenticated). 문의: `submit-inquiry` Edge Function(인증 필수, 본문 2000자, 하루 10건 제한). `sync_push` 허용 목록에 `inquiries` 없음.
- `activity_days`: 동기화 행이지만 `id = uuid_v5(namespace, user_id||date)`로 결정적 생성 → 두 기기가 같은 id를 만들어 CAS로 병합. 서버 `unique(user_id, date)`.
- 원장(`subscription_state·reading_quota`)은 **push 금지, pull 응답의 `ledger`로만 수신**하는 읽기 전용 캐시.
- 사용자 쓰기 경로는 다음으로 한정: `sync_push`(saved `reading_requests`의 삭제 전용 mutation 포함)·`sync_pull`·`profile_set_onboarding_done()`·Edge(`complete-signup·update-consent·submit-inquiry·purge-all·delete-account·reading-submit/status/cancel/save/discard/update-marks·age-check·issue-pass·check-email`). 그 외 직접 쓰기·함수 호출 없음.
- 검증(S03): 일반 사용자 JWT로 `reading_finish` 등 서비스 함수 호출 거부·service_role 호출 성공, premium 변경·횟수 초기화·타인 행 select/update·판독 상태 변경·패스 없는 가입·원장 테이블명 `sync_push`·서버 컬럼 포함 `sync_push`(`invalid_columns`)·profiles 없는 토큰 RPC·무료/만료/미동의 `reading-submit` 이 전부 거부되는 테스트.

## D25. 하루 목표 시간 — 확정
무료도 편집 가능. 프리미엄은 기록 기반 기본값 제안("최근 4주 평균")이 추가될 뿐. 플래너 등록 시트의 예상 시간(무료 30분 기본 + 잠금 힌트)과 별개.

## D26. 플래너 제스처 — 확정
3D 시간 보기 전환 = 좌우 스와이프(PRD). 월 이동 = 상단 이전/다음 버튼(프로토타입 `calPrev/calNext`). 세로 드래그 = 접힘.

## D27. 스키마 변경 절차 — 확정
기존 마이그레이션 수정 금지 + 새 마이그레이션 추가 + PR `SCHEMA-CHANGE`. S02 스키마에 처음부터 포함: `reading_requests.session_id·planner_item_id·quota_month`, `planner_items.range_text`(플래너 → 판독 이어받기 원천, 없으면 제목 사용), 로컬 DB는 `user_id` 컬럼 방식(계정 전환 시 초기화).

---

## 남은 미결
- D6 법정대리인 확인 절차 (경로 차단 상태로 진행)
- D14 외부 AI 벤더 조건 (S16 게이트에서 확정)

## v3 zip 반영 목록
`01-common-rules`(라우터 소유 예외·검사 목록) · S01(enum grace·ReadingJob 필드·cancel/save/discard 계약·PremiumLockHint 공용 위젯·pull 시그니처) · S02(activity_days 결정적 id·snapshot 필드·confirmed_marks·mutation_id) · S03(전면: 훅/트리거/티켓, RPC 검증, pull 계약, 저장/버리기/만료, 작업 큐·회수, 온보딩 RPC, 문의, 집계 배치, 보관 잡) · S04(가용성 장애 분리) · S05(티켓→패스 순서, 온보딩 RPC) · S06(D23 모드별 복구) · S08(입력·문구) · S09(문의 Edge) · S10(저장/버리기/취소 결과·동의 게이트·새 requestId) · S12(grace 판정·planF·동의 게이트) · S13(pull 계약·epoch·영수증·fullResync) · S15(cutover에 배치·cron) · S16(마크 매핑·시나리오 4종 추가) · README(의존표)

## [S01] 세션 결정 — 지시문에 없던 사항 (2026-09-30)

- **[S01] 프로젝트 생성 범위**: `flutter create --org co.byite --project-name soongong --platforms android,ios`. 웹·데스크톱 폴더는 만들지 않는다(출시 범위 D20).
- **[S01] Outcome 변형 클래스 이름**: 지시문이 주석으로만 적은 sealed 변형(`SubmitOutcome`·`CancelOutcome`·`SaveOutcome`·`UpdateMarksOutcome`·`PurchaseOutcome`·`RestoreOutcome`·`SyncState`·`SeatEngineEvent`)은 네 계약을 한 파일에서 함께 import 할 수 있도록 접두어를 붙인다: `SubmitAccepted`·`CancelAlreadyDone`·`SaveAlreadySaved`·`MarksUpdated`·`PurchaseSuccess`·`RestoreRestored`·`SyncSyncing`·`SeatCameraLost` 등. 지시문에 시그니처가 명시된 `ReadingStatus` 변형(`Deleted`·`NotFound`·`Sending`·`Processing`·`TakingLong`·`Failed`·`Done`)과 모든 메서드 시그니처는 그대로. 이후 변경은 `CONTRACT-CHANGE`.
- **[S01] 서버 상태 문자열**: `SubmitInvalidState(status)`·`SaveNotUnsaved(status)`·`MarksNotSaved(status)` 의 `status` 는 서버 상태 이름 `String`. `QuotaSnapshot { used · reserved · limit · fetchedAt }`.
- **[S01] 계약 프로바이더**: `core/contracts/providers.dart` 의 `seatEngineProvider`·`readingEngineProvider`·`billingGatewayProvider`·`syncEngineProvider`·`deviceIdProvider` 가 고정 접점. S01은 Fake 를 반환하며, 실제 구현 세션(S04·S06·S12·S13)은 프로바이더 본문을 교체하거나 `bootstrap()` 에서 override 한다. Fake 시나리오는 `devFakeSettingsControllerProvider`(freezed) 로 바뀐다.
- **[S01] 코드 생성 산출물 커밋**: `*.g.dart`·`*.freezed.dart` 를 커밋한다(병렬 세션·IDE 편의). CI 가 `build_runner` 를 다시 돌린 뒤 `git diff --exit-code` 로 드리프트를 막는다.
- **[S01] riverpod_lint 설치 방식**: riverpod_lint 3.1.x 는 `custom_lint` 가 아니라 Dart 네이티브 analyzer 플러그인이다. `analysis_options.yaml` 최상위 `plugins:` 로 설치하고 `flutter analyze --fatal-infos` 한 번으로 검사한다. `custom_lint` 는 쓰지 않는다(버전 충돌).
- **[S01] 로컬 DB 패키지**: `sqlite3_flutter_libs` 는 EOL. `drift` + `drift_flutter`(sqlite3 native assets) 조합으로 설치. 초기화는 S02(`data/db/app_database.dart`).
- **[S01] 새 패키지 3개**: `flutter_secure_storage`(deviceId 보관) · `lucide_icons_flutter`(Lucide 아이콘, 기존 `lucide_icons` 는 2023년 이후 미유지) · `sensors_plus`(dev 메뉴 셰이크). `flutter_localizations`(SDK 내장)는 한국어 Material 문자열용.
- **[S01] 과목색 다크 변형**: 프로토타입에 없어 파생(색상·채도 유지, 다크 배경 대비 ≥ 4.5:1 첫 명도). 값·근거는 `docs/design-tokens.md` 3장.
- **[S01] 규칙 우선 편차**: 확인창 큰 그림자 제거(§6 그림자 ≤ 0 1px 2px) · 다크 주 버튼 글자색 `#0B0B0F`(흰색은 2.6:1) · Lucide 폰트 stroke 는 고정(1.75 는 직접 그리는 아이콘에만).
- **[S01] Dev 도구 게이트**: `AppConfig.devToolsEnabled = bool.fromEnvironment('DEV_MENU') && APP_FLAVOR != 'prod'` (둘 다 컴파일 상수 → prod 에서 트리셰이킹). `env/app.dev.json` 의 `"DEV_MENU": true` 로 켠다. `/_gallery` 라우트와 셰이크 dev 메뉴가 이 게이트를 쓴다.
- **[S01] 클라이언트 env 키**: `APP_FLAVOR` · `SUPABASE_URL` · `SUPABASE_ANON_KEY` · `REVENUECAT_PUBLIC_KEY_ANDROID` · `REVENUECAT_PUBLIC_KEY_IOS` · `DEV_MENU`. service role 키 자리는 없다(D12).
- **[S01] iOS flavor 구성**: 스킴 `dev`·`prod`, 빌드 구성 `Debug-dev`·`Release-dev`·`Profile-dev`·`Debug-prod`·`Release-prod`·`Profile-prod`, 각 구성이 `ios/Flutter/<Config>-<flavor>.xcconfig`(CocoaPods include + `Flavor-<flavor>.xcconfig` 의 번들 ID·표시 이름)를 base configuration 으로 쓴다. macOS 없이 작성했으므로 S15 에서 Xcode 로 검증.
- **[S01] Android flavor 구성**: `flavorDimensions "env"`, `dev` 는 `applicationIdSuffix ".dev"`·`versionNameSuffix "-dev"`, 앱 이름은 `resValue app_name`(순공 dev / 순공). 릴리스 서명은 S15(`android/key.properties`, gitignore 됨).
- **[S01] 브랜치 이름**: 이 세션은 클라우드 세션이 지정한 `claude/new-session-wpnapa` 에서 작업했다(지시문의 `feat/s01-scaffold` 대신). → S01b 에서 CLAUDE.md §8 을 "세션 지정명 허용, PR 제목 `[SNN] 요약`" 으로 갱신했고, D13·D21 의 레포명을 `byite-co/soongong` 으로 정정했다.
- **[S01b] 후속 수정(기능 추가 없음)**: Android desugaring(desugar_jdk_libs 2.1.4) · pbxproj 중복 ID 재부여 · `ios/lib/**` 오생성 삭제 · CI 드리프트 검사를 `tool/ci/check_clean_tree.sh`(비어 있지 않은 `git status --porcelain` → 실패)로 · FakeReadingEngine `submit` 순서(tombstone → 같은 id 멱등 → 활성 → 미저장 done(D17) → 쿼터 → 시나리오)와 `updateMarks` 차이 계산(새 비O 문항은 `wrongItemId` 필수, O 문항 제거, 나머지 mark 갱신·id 유지, 언급 없는 문항 유지) · `showAppModal` 은 `onConfirm` 실행 중 바깥 탭·뒤로가기·취소 무시, 반환값 `bool`(true = 실행 완료) · AppButton small/토스트 액션 탭 영역 44 를 탭 위젯 안쪽으로 · 다크 토스트 액션 `#2F49E0`.

## [S02] 세션 결정 — 지시문에 없던 사항 (2026-10-01)

- **[S02] 시각 저장 방식**: drift `DateTimeColumn` 대신 `TEXT` + `UtcDateTimeConverter`(ISO 8601 UTC, `Z` 접미). 날짜 키는 `LocalDate`(`yyyy-MM-dd`), 하루 중 시각은 `LocalTime`(`HH:mm`) 값 타입(`core/domain/local_date.dart`). enum 은 `WireEnum.wire`(snake_case 와이어 이름) 로 저장. 서버 DDL 도 같은 표현.
- **[S02] `reading_quota.limit` → `quota_limit`**: `limit` 은 SQL 예약어라 로컬·DDL 컬럼명은 `quota_limit`. 서버 JSON(pull `ledger`)의 키는 `limit` 그대로이며 `QuotaRepository.applyLedger` 가 `limit`↔`quota_limit` 를 매핑한다(`quota_limit` 키도 허용).
- **[S02] 감도 레벨 ↔ 이탈 임계**: `sensitivity_level` 0·1·2 → 60·75·90초(PRD "60–90초", D23 "최대 90초 소급" 과 일치하도록 최대값이 레벨 2 에서 닿게 배분. 지시문의 "+10초씩" 은 레벨 3단계에 맞춰 15초 간격으로 조정). `SensitivityPolicy`: 최근 2주 정정 건수 `~/ 3` 을 레벨로(상한 2), 변동 시에만 토스트. 자동 조정 off 면 수동 레벨 유지.
- **[S02] 이탈 후보 구간**: 임계 미만의 짧은 미검출(확인 대기)은 복귀하면 그대로 착석으로 남긴다. 임계를 넘겨 확정될 때만 `last_seated_at` 으로 소급(최대 90초)해 away 세그먼트가 시작된다(D23).
- **[S02] DAO 계층 없음**: drift `@DriftAccessor` DAO 를 따로 두지 않고 타입 안전 쿼리는 각 저장소 안에, D2 공통 처리(`markUserWrite·enqueue·softDelete·undoDelete·commitDelete·hideLocally·applyServer·applyServerColumns`)는 `SyncWriter` 한 곳에 둔다. 저장소가 "DAO + outbox 규칙" 역할을 겸한다.
- **[S02] 엔티티 2층 구조**: drift 행 클래스는 `*Row`(내용 컬럼 nullable, tombstone 수용), 화면·도메인은 freezed 엔티티(`core/domain/entities/`, 내용 non-null, 공통 필드는 중첩 `SyncStamp`). `deleted_at` 이 있는 행은 매퍼가 `null` 을 돌려주고 엔티티를 만들지 않는다(`Tombstone`).
- **[S02] `applyServer` 는 무조건 덮어쓴다**: pull 행이 로컬 dirty 행(outbox 대기)과 겹치면 `ApplyServerReport.dirtyOverwritten` 에 id 를 돌려줄 뿐 LWW 를 결정하지 않는다. LWW·`sync_conflicts` 기록은 S13 이 `applyServer` 호출 전에 한다. `client_rev` 유지, `base_server_version = server_version`, outbox 미등록.
- **[S02] 로컬 전용 쓰기 경로**: `reading_requests.status = sending`(제출 호출 중 표시)·`payload_hash` 캐시·`confirmed_marks_json` 은 `SyncWriter.applyServerColumns`(rev 유지·outbox 없음) 로 쓴다. 서버 컬럼은 어떤 경우에도 push 컬럼이 아니므로(S13 이 데이터모델 §1.1 push 컬럼만 보냄) 서버로 흘러가지 않는다.
- **[S02] 초안(`selecting`) 삭제**: 서버에 `selecting` 삭제 경로가 없으므로(D24: 삭제 전용 mutation 은 `saved` 만) 한 번도 push 되지 않은 초안은 물리 삭제 + outbox 제거, 이미 push 된 초안은 로컬 숨김(`deleted_at`, outbox 없음). 서버의 고아 초안 정리는 S03 cron 후보.
- **[S02] 과목 삭제 시 재지정 범위**: sessions · planner_items · recurrences · wrong_items · `selecting` 초안의 `subject_id` 를 "기타"로 바꾸고(각각 사용자 쓰기) 과목을 tombstone. 제출 이후의 reading_requests 는 서버 소유라 `subject_id` 를 두고 UI 가 "기타" 이름으로 대체 표시.
- **[S02] 로컬 tombstone 표현**: `commitDelete` 는 서버와 같은 모양으로 내용 컬럼을 즉시 NULL 로 지운다(유지 키·공통 필드 유지). S13 의 삭제 payload 는 `{deleted_at}`(+ 공통 필드)만 보내면 된다. 세션 삭제는 세그먼트·정정까지 함께 commit, 저장된 판독 결과 삭제는 요청 행만 commit 하고 자식은 `hideLocally`.
- **[S02] outbox 행 규칙**: PK `(table_name, row_id)` 로 행당 1건. 미전송 상태의 재편집은 `mutation_id` 유지(payload 는 전송 시점 행), 전송된 뒤(`sent_client_rev != null`) 편집되면 새 `mutation_id`·`attempts=0`. 승인 응답 처리(행 삭제 또는 유지)는 S13.
- **[S02] 저장소 패치 인자**: 부분 수정 메서드(`updateItem·updateRecurrence·updateDraft`)는 drift `Value<T>` 를 받아 "미지정"과 "null 로 설정"을 구분한다(기능 세션은 `package:drift/drift.dart show Value` 만 import).
- **[S02] 현재 사용자 id**: `currentUserIdProvider` 는 S05 전까지 `'local'` 상수. S05 는 로그인 후 `auth.uid` 로 override 하고 계정 전환 시 `AppDatabase.wipeAll()`(D27).
- **[S02] 반복 일정 노출 시작일**: `RecurrenceExpander` 는 생성일(`created_at` 의 로컬 날짜)부터 `ends_on`(포함)까지, `active` 인 것만 전개. 과거 주에는 나타나지 않는다.
- **[S02] 스트릭 계산**: 오늘 세션이 없으면 어제까지의 연속 일수를 그대로 보여준다(자정 전까지 유지). 오늘 세션이 생기면 오늘부터 센다. `longest` 는 사실 표시용.
- **[S02] 세션 시계**: `SessionClock(wall, monotonic)` 이 시작 시점의 벽시계+단조 시계 기준점을 메모리에만 보관하고 `now()` 를 만든다. `SessionTimeline` 은 시각을 인자로만 받는다(시계를 읽지 않음). 스냅샷에는 기준점을 저장하지 않는다(D23).
- **[S02] 복습 엔트리 id**: 큐 이탈(2연속 맞음)로 tombstone 된 엔트리는 재풀이 기록 취소로 되살아날 때 **새 id** 로 다시 만든다(tombstone id 재사용 금지, D16 와 같은 규칙).
- **[S02] 샘플 데이터·시드**: dev flavor 는 시작 시 `DevSeeder.seedSubjects()`(국어·수학·영어·과학·사회 + 기타, 과목이 없을 때만). "샘플 데이터 넣기"는 저장소를 통해 쓰고 마지막에 `sync_outbox` 를 비운다(샘플은 push 금지). "지우기"는 `wipeAll()` 후 과목만 재시드. RNG seed 42 로 결정적.
- **[S02] DB 파일명·초기화**: `soongong_<flavor>`(dev 와 prod 가 같은 기기에서 분리). `AppDatabase.wipeAll()` 이 계정 전환·로그아웃·purge-all·epoch 불일치의 공통 초기화 지점(사진 파일 삭제는 호출자).
- **[S02] 내보내기 JSON**: `user_id` 포함, 사진은 `local_path` 제외, 원장 캐시·sync_* 제외, 살아 있는 행만. CSV 는 UTF-8 BOM + CRLF.
- **[S02] `activity_days` 네임스페이스 uuid**: `6f0b3a2e-3c5b-4b7e-9a1d-2f4a8c1e5d70`, name = `"<user_id>|<yyyy-MM-dd>"`. 서버(S03)도 같은 값을 쓴다.
- **[S02] `settings` 행 id 도 결정적**: `uuid_v5(7a1c6d2b-0e4f-4c3a-8b5d-9e2f1a3c4d5e, "<user_id>|<key>")`. 두 기기가 같은 설정 키를 먼저 만들면 id 가 달라 pull 에서 `UNIQUE (user_id, key)` 가 깨지므로(테스트로 확인) activity_days 와 같은 방식으로 병합한다.
- **[S02] outbox 재편집 시 `sent_client_rev` 초기화**: 전송된 행을 편집하면 새 `mutation_id` 와 함께 `sent_client_rev = null`(미전송 상태로 복귀). "null = 미전송" 의미를 유지한다.
- **[S02] 새 패키지**: `archive`(CSV 3파일 zip, 유지보수 활발·순수 Dart).
- **[S02] S01 이월 수정**: AppButton 탭 영역 고정 높이, FakeReadingEngine 재제출 검사 순서·tombstone id 재사용 거부, AppModal 반환값 문서(`false` ≠ 미실행 보장). 세부는 `docs/handoff/S02.md`.

## [S02b] 후속 수정 결정 (2026-10-01)

- **[S02b] 쓰기 원자성**: `SyncWriter` 의 모든 변경 메서드(`markUserWrite·softDelete·undoDelete·commitDelete·hideLocally·tombstoneLocally·applyServer·applyServerColumns`)는 drift `transaction` 안에서 행 변경과 outbox 등록을 함께 커밋한다. 저장소의 다중 행 작업은 `SyncWriter.runInTransaction` 으로 감싼다(drift 는 중첩 호출을 바깥 트랜잭션에 합친다).
- ~~**[S02b] 미전송 판정**: 물리 삭제는 `server_version IS NULL` 그리고 outbox `sent_client_rev IS NULL` 일 때만.~~ **S02c 에서 폐기** — 아래 `[S02c] 초안 삭제는 전송 이력과 무관하게 tombstone`. `selecting` 초안의 `deleted_at` 을 `sync_push` 허용 컬럼에 넣는 계약(data-model §7 ①)은 유지.
- **[S02b] `wrong_items` push 컬럼**: `subject_id·status·resolved_at` 만(data-model §7 ②). 과목 삭제 재지정은 유지하되 과목 tombstone 과 같은 트랜잭션.
- **[S02b] 복습 전이 단일화**: `ReviewScheduler.applyResult(state, result, at)` 하나로 증분(`record`)과 재계산(`rebuild`)이 같은 결과를 낸다(속성 테스트). **졸업 후**: 맞음 → 졸업 유지, 또 틀림 → 1일로 재진입, 부분 → 졸업 당시 간격으로 재진입(`ReviewGraduated.intervalDays`). `ReviewRepository.recordRetry` 는 살아 있는 엔트리가 없으면 비취소 기록으로 상태를 재구성한 뒤 전이한다.
- **[S02b] 서버 삭제·만료 수신 정리**: `applyDeleted`(410)는 내용·`result_json·marks_json·confirmed_marks_json` NULL 의 tombstone, pull tombstone 도 로컬 전용 `confirmed_marks_json·pending_delete_until` 을 지운다. `expired·discarded` 수신(응답·pull) 시 `result_json·confirmed_marks_json` NULL.
- **[S02b] 부분 유일 인덱스**: `review_entries_live_wrong_item` 은 `MigrationStrategy.onCreate` 의 `customStatement`(`AppDatabase.partialUniqueIndexes`). drift `@TableIndex` 는 `WHERE` 를 지원하지 않는다. 서버 DDL 동일 문장(data-model §7 ③).
- **[S02b] 판독 월 키 = KST 고정**: `ReadingQuotaPolicy.monthKey` 는 `now.toUtc() + 9h` 의 `yyyy-MM`. 기기 시간대와 무관하게 서버 `quota_month` 와 같은 키로 표시·조회. S02 의 "기기 현지 월" 결정은 폐기.
- **[S02b] 날짜 차이**: `LocalDate.daysUntil` 은 UTC 날짜 차이(달력 일수). DST 전환일(23/25시간)에서도 1일.
- **[S02b] `applyServer` 는 행을 통째로 치환**: drift 의 `insertOnConflictUpdate` 가 null 컬럼을 absent 로 취급해 서버 tombstone 이 로컬 내용을 못 지우던 문제 → 기존 행이 있으면 같은 트랜잭션에서 `DELETE` 후 `INSERT`. 서버 행이 곧 로컬 행이다(로컬 전용 컬럼만 유지).

## [S02c] 후속 수정 결정 (2026-10-01)

- **[S02c] 초안 삭제는 전송 이력과 무관하게 tombstone**: `SyncWriter.deleteIfLocalOnly`(물리 삭제 경로) 제거. `selecting` 초안 삭제 = `commitDelete`(내용 NULL · `deleted_at` · rev+1 · outbox) → `sync_push` 가 tombstone mutation 을 보낸다(data-model §7 ①: 서버는 자기 사본을 tombstone 으로 바꾸거나, 없으면 D2 규칙대로 tombstone insert). 로컬 행은 절대 물리 삭제하지 않는다. outbox 의 `sent_client_rev` 초기화 로직(전송 후 편집 → 미전송)은 dirty 판정용으로 그대로.
- **[S02c] `sending` 상태 삭제 금지**: `ReadingRepository.deleteDraft` 는 `DraftDeleteOutcome` 을 돌려준다 — `deleted`(selecting 만) · `submitting`(sending, 행·outbox 불변) · `notDraft`(제출 이후) · `notFound`. 예외 없음. `revertLocalSending` 은 `revertToSelecting` 으로 개명. 호출자(S10) 흐름: `deleteDraft` 가 `submitting` 이면 `reading-status` 확인. `processing`/`taking_long` → `cancel()`. **404는 미접수 확정이 아님** — `revertToSelecting` 후 `deleteDraft` 로 tombstone mutation 을 push 하고 서버 승인(accepted)을 받아야 삭제 확정. 거부(`server_row` 가 `processing` 등)면 서버 상태로 취소·완료 처리.
- **[S02c] 스키마 v2(SCHEMA-CHANGE)**: `schemaVersion = 2`. `onUpgrade(from < 2)` 가 `review_entries` 의 살아 있는 중복을 `wrong_item_id` 별로 정리(최신 `client_updated_at` 1개 유지, 동률은 id 오름차순 첫 행, 나머지는 내용 NULL tombstone + rev+1 + outbox 등록 → 서버도 수렴)한 뒤 부분 유일 인덱스 `review_entries_live_wrong_item` 을 만든다. `onCreate` 는 S02b 그대로. 기존 마이그레이션 수정 없음(D27). dedupe 와 인덱스 생성은 **하나의 명시적 `transaction()`**(drift 의 `onUpgrade` 는 트랜잭션 밖에서 실행됨) — 중간 실패 시 둘 다 남지 않는다(테스트). pull 로 받은 행이 이 인덱스를 어기면 서버 쪽 중복이므로 S03 DDL 의 같은 인덱스가 전제.

## [S04] 세션 결정 — 지시문에 없던 사항 (2026-10-01)

- **[S04] 검출기 = ML Kit Face Detection fast, presence only**: 랜드마크·분류·윤곽·추적 OFF, 결과에서 `faces.isNotEmpty` 만 읽는다(bbox·각도 미사용). Pose/MediaPipe 와의 비교와 전환 조건(P2 고개 숙임 < 90%)은 `docs/seat-engine.md` §2. 교체 지점은 `PresenceDetector` 하나.
- **[S04] 유지 창(히스테리시스) 3초는 엔진 내부 고정값**: `SeatHysteresis(hold: 3s)`. 감도 0·1·2(60·75·90초)와 무관하며 `SeatEngineConfig` 에 없다. S06 이 바꾸려면 `CONTRACT-CHANGE`.
- **[S04] 이벤트 의미**: `SeatCameraLost` = 실행 중 3초 프레임 없음 · 점유/치명/정책 오류 · 백그라운드 진입(엔진이 스스로 stop, 카메라 해제). `SeatCameraRecovered` = Lost 이후 첫 프레임(그 사이 stop/start 여부 무관, 1회). Lost 동안 샘플 없음(D23 paused). `SeatError(code)` 는 `permission_denied · no_camera · camera_busy · camera_init_failed · detector_failed`.
- **[S04] `checkAvailability` 는 권한 프롬프트를 띄울 수 있다**(미결정 상태일 때만). `start` 는 프롬프트 없이 `SeatError('permission_denied')`. 권한 흐름 헬퍼는 `CameraPermission.request()/status()/openSettings()`.
- **[S04] iOS 점유는 `cameraBusy` 로 구분되지 않는다**: `camera_avfoundation` 이 세션 인터럽션을 노출하지 않아 프레임 정지 → 3초 뒤 Lost 로 나타난다. Android 는 CameraX `CameraState` 오류 문구로 점유를 분류(`classifyCameraFault`, 플러그인 버전 의존).
- **[S04] 처리 주기**: `sampleHz` 는 1–2 로 클램프(1000ms/Hz), `lowPower` 는 2초 + 카메라 목표 fps 10(기본 15). 해상도는 `ResolutionPreset.low` 가 하한. 전면 카메라가 없으면 첫 카메라를 쓴다.
- **[S04] `SeatSample.confidence` 는 null**: ML Kit 는 검출 신뢰도를 주지 않는다. Fake 의 숫자는 데모용.
- **[S04] `seatEngineProvider` 분기**: prod flavor → `SeatEngineImpl.camera()`. dev → dev 메뉴 "구현: Fake / 실제 카메라" 스위치(`DevFakeSettings.seatReal`, 기본 Fake). 위젯 테스트는 기본 Fake 를 받는다.
- **[S04] `/_seat_lab` 라우트 위치**: `app_router.dart` 는 S05 소유라 `features/measure/measure_routes.dart` 에 `AppConfig.devToolsEnabled` 조건부로 등록. 화면은 `core/dev/seat_lab/`. S05/S14 가 `/_gallery` 옆으로 옮겨도 된다.
- **[S04] `minFaceSize` 기본 0.1**(ML Kit 기본). 포스터·사진 음성 케이스 결과에 따라 0.15/0.20 으로 올릴 수 있도록 실험실에서 선택 가능(엔진 생성자 인자).
- **[S04] 새 패키지**: `permission_handler ^12.0.3`(권한 상태·프롬프트·설정 열기. 13.x 는 `permission_handler_android` 14 = compileSdk 37 요구라 Flutter 3.47.5 기본 36 과 맞을 때까지 보류) · `battery_plus ^7.1.1`(실험실 배터리 % 기록, 런타임은 dev 화면에서만 사용).

## [S04b] 후속 결정 — focus-engine 선별 이식 (2026-10-03)

- **[S04b] 세대(generation)**: `start()` 마다 세대 +1(`InferenceGate.open`), `stop()` 도 +1(펜스). 카메라 콜백(프레임·오류)은 카메라 세션을 연 세대를 들고 오고, 추론 결과는 시작 세대가 현재 세대일 때만 `samples`·`events`·`diagnostics` 에 반영한다. 이전 세대의 늦은 결과는 `suppressedResults` 로만 센다(재시작 경합 테스트 고정).
- **[S04b] 종료 순서**: `stop()` = 펜스 → 카메라 해제 → 진행 중 추론 **최대 500 ms** 대기 → `SeatStopReport`. 펜스 뒤 결과는 기다렸든 아니든 버린다(`stop()` 이후 샘플·이벤트 없음). 검출기는 `stop()` 에서 닫지 않고 재사용하며, `dispose()` 는 추론 도중이면 close 를 미루고 돌아온 추론이 닫는다(추론 도중 close 0회). 지시문의 "완료 또는 타임아웃 후 close" 는 이 의미로 구현.
- **[S04b] 시각 분리**: `SeatSample.at` = 촬영 시각(카메라 콜백 도착 순간의 벽시계; `camera` 플러그인은 프레임 타임스탬프를 Dart 로 주지 않아 콜백 도착 시각이 가장 가까운 값). 처리 완료 시각은 `SeatDiagnostic.completedAt` 로 실험실 전용. 유지 창 3초도 촬영 시각 기준.
- **[S04b] 실험실 구간·제외**: 시작→정지가 1구간. 비정상 종료(엔진 자체 정지[백그라운드]·카메라 끊긴 채 종료·구간 중 오류·추론 대기 초과·restart) 구간은 요약 집계에서 제외하고 CSV 에 `excluded=1` 로 남긴다(focus-engine 의 stop-integrity "비교 불가" 개념의 축소판). 실험실과 엔진은 같은 단조 시계를 공유한다.
- **[S04b] 미도입 명시**: 7상태 판정 · 30초 확정 버퍼 · 백그라운드 포그라운드 서비스 · MediaPipe 경로는 D23·PRD 와 충돌해 도입하지 않는다. MediaPipe 는 실기기 결과가 목표 미달일 때 ML Kit Pose 와 함께 비교 후보로만 기록.
