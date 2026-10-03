# 가입·인증 서버 (`docs/supabase-auth.md`) — S03 확정 · S05 접점

D6 의 구현. SQL: `supabase/migrations/0004_signup.sql`(+ dev 전용 `supabase/dev/0001_test_trigger_fail.sql`), Edge: `age-check · issue-pass · complete-signup · update-consent · check-email`, 앱: `lib/data/auth/`(`AuthRepository`·`AgeGateRepository`), 테스트: `supabase/tests/04_signup.sql`(pgTAP 33건) · `supabase/functions/_tests/*`(Deno 16건) · `test/unit/data/auth_repository_test.dart`.

## 1. 흐름(제공자 공통)

```
ageGate ─ birth_date ─▶ age-check ─▶ {allowed:true, ticket(10분)} | {allowed:false → ageBlocked}
   │ (티켓은 age_ok·jti 만, 생년월일은 폐기)
네이티브 SDK ─▶ id_token(+nonce) ─▶ issue-pass(ticket, provider, id_token | email) ─▶ signup_passes 저장(10분)
   │
signInWithIdToken / signUp ─▶ Auth before_user_created 훅(패스 존재 확인, 쓰기 없음)
   │                               └ 없으면 400 "가입 확인이 필요합니다" → 앱 AuthRejection.signupPassRequired
   └▶ auth.identities INSERT 트리거(같은 트랜잭션): 패스 DELETE…RETURNING(소비) → signup_approvals insert
                                                   0행이면 RAISE signup_pass_required → 가입 전체 롤백(백스톱)
complete-signup(consent_version) ─▶ signup_approvals.age_verified 확인 → profiles 생성(멱등) + 동의 ①
```

- **기존 계정**: 티켓 없이 `signInWithIdToken`/`signInWithPassword` → `complete-signup`(멱등). 소셜은 신규 여부를 미리 알 수 없으므로 **먼저 로그인 시도 → `signupPassRequired` 면 신규** → ageGate → 같은 메서드를 `ticket` 과 함께 재호출(`AuthRepository.signInWithProvider`). 이메일은 `check-email` 로 신규/기존 분기.
- `complete-signup` 이 `not_approved`(403) 면 앱은 세션을 끊고 `AuthRejection.notApproved`(profiles 없는 토큰은 RLS 로 전면 차단).
- 계정 연결(같은 이메일 OAuth 자동 연결): 트리거 ① 분기 — `signup_approvals` 가 이미 있으면 패스 조회·소비 없이 통과.

## 2. Edge 계약

| 함수 | 인증 | 입력 | 출력 |
|---|---|---|---|
| `age-check` | 없음(verify_jwt=false) | `{birth_date:"yyyy-MM-dd"}` | `{allowed:true, ticket, expires_in:600}` · `{allowed:false}` · `400 invalid_field` |
| `issue-pass` | 없음 | `{ticket, provider: apple\|google\|kakao\|email, id_token?, nonce?, email?}` | `{issued:true, provider, expires_at}` · `400 ticket_invalid \| id_token_invalid \| nonce_required \| nonce_mismatch \| invalid_field` · `500 provider_not_configured` |
| `complete-signup` | 사용자 JWT | `{consent_version}` | `{profile}` · `403 not_approved` |
| `update-consent` | 사용자 JWT | `{granted:bool, consent_version?}` | `{profile}` |
| `check-email` | `x-app-key`(앱 키) + IP 분당 20회 | `{email}` | `{exists:bool}` · `401 unauthorized` · `429 rate_limited` |
| `submit-inquiry` | 사용자 JWT | `{body ≤2000, reply_email?}` | `201 {id, created_at}` · `429 rate_limited`(하루 10건) |
| `purge-all` | 사용자 JWT | — | `{epoch}` |
| `delete-account` | 사용자 JWT | — | `{deleted:true}` |

`profile` = `{user_id, onboarding_done, consent_account_version, consent_account_at, consent_reading_version, consent_reading_at, consent_reading_revoked_at, consent_reading_active, purge_epoch, created_at}`. 온보딩 완료는 RPC `profile_set_onboarding_done()`.

### 티켓 · 패스 · 토큰 검증

- 티켓: HS256 JWT(`AGE_TICKET_SECRET`), `iss soongong/age-check`, `aud soongong/issue-pass`, 10분, claims `{age_ok:true, jti}`. 만 14세 판정은 **서버 시각 KST 기준 생일 도달 여부**(`isAtLeast14`).
- 패스 키: 소셜 `(provider, sha256(sub))`, 이메일 `('email', sha256(lower(email)))`(hex). 같은 키 미소비 패스가 있으면 만료만 연장. 소비 = 행 삭제.
- id_token: JWKS 서명 · `iss`(Apple `https://appleid.apple.com` · Google `https://accounts.google.com`/`accounts.google.com` · Kakao `https://kauth.kakao.com`) · `aud ∈ 허용 목록`(`APPLE_AUD`/`GOOGLE_AUD`/`KAKAO_AUD`, 쉼표 구분) · `exp` · Apple `nonce == sha256(nonce)`(원문 일치도 허용). 카카오는 OIDC 활성화 + `openid` 스코프.

## 3. 훅 payload 와 subject 추출

`before_user_created` payload(Supabase 문서 2025-04 기준): `user.email`, `user.app_metadata.provider`, `user.user_metadata`, `user.identities = []`(훅 시점엔 비어 있음). 추출(`signup_subject_from_hook`):

| 경로 | provider | subject |
|---|---|---|
| 이메일 | `app_metadata.provider` 없음 또는 `email` | `lower(user.email)` |
| Apple · Google · Kakao | `app_metadata.provider` | `user_metadata.sub` → 없으면 `user_metadata.provider_id` → 둘 다 없으면 **거부** |

**실제 payload fixture(dev, GoTrue v2.197.0, 2026-10-02 — 값은 저장하지 않고 키 경로만 캡처):**

| 경로 | 캡처 | 키 경로(`hook_fixtures.key_paths`) | 결과 |
|---|---|---|---|
| 이메일(`/auth/v1/signup`, 패스 없음 → reject / 패스 있음 → allow) | 11건(reject 3 · allow 8, 키 경로 동일) | `metadata` `metadata.ip_address` `metadata.name` `metadata.time` `metadata.uuid` `user` `user.app_metadata` `user.app_metadata.provider` `user.app_metadata.providers` `user.aud` `user.created_at` `user.email` `user.id` `user.identities` `user.is_anonymous` `user.phone` `user.role` `user.updated_at` `user.user_metadata` | `provider=email` · subject 출처 `email`(= `lower(user.email)`) · 패스 없음 → `reject` → GoTrue 400 "가입 확인이 필요합니다" · 패스 있음 → `allow` → 가입 200, 트리거가 패스 소비·승인(5c–5i) |
| Apple · Google · Kakao | 미캡처 | 제공자 미설정 | `user_metadata.sub` → `provider_id` 가정 유지 |

확인된 점: 이메일 가입에서 `user.identities` 는 빈 배열(하위 키 없음), `user.user_metadata` 는 빈 객체이며 `app_metadata.provider = 'email'` 이 온다 — `signup_subject_from_hook` 의 이메일 분기와 일치. `metadata.ip_address` 가 포함되므로 훅은 payload 를 저장하지 않는다(캡처도 키 경로만).

**소셜 경로 fixture 는 제공자 설정 후 같은 방법으로 캡처해 위 표에 추가한다**(`docs/handoff/S03.md` `## S03b 실행 검증`). 캡처 장치는 `supabase/dev/0002_e2e_support.sql`(dev 전용)에 있다: `server_config.hook_fixtures_capture = 'on'` 이면 훅이 `hook_fixtures` 에 provider · 키 경로 목록(`jsonb_key_paths`, 값 없음) · subject 출처(`email` / `user_metadata.sub` / `user_metadata.provider_id` / `none`) · 결정(allow/reject)만 기록한다. 이메일 경로만 캡처 대상(소셜 제공자 미설정). 소셜 payload 에서 `sub` 위치가 다르면 `signup_subject_from_hook` 만 고치면 된다(트리거는 `auth.identities` 실제 값만 보므로 영향 없음). dev Auth 버전: GoTrue v2.197.0(2026-10-02).

## 4. 권한(D24)

- 훅 함수·트리거 함수: `postgres` 소유 `security definer`, EXECUTE 는 `supabase_auth_admin` 만(PUBLIC·anon·authenticated·service_role 회수), `grant usage on schema public to supabase_auth_admin`. 트리거는 `postgres` 가 `auth.identities` 에 생성.
- 콘솔: Authentication → Hooks → **Before User Created** → Postgres function `public.before_user_created_hook` 활성화(`supabase/config.toml` 에도 선언). 검증은 SQL Editor 가 아니라 실제 Auth API 가입으로.
- 훅 호출 순서: GoTrue v2.197.0(dev, 2026-10-02)에서 **훅 → (별도 트랜잭션) 사용자+identity insert → 트리거** 확인 — 5c(allow 행 → 승인 1·패스 0), 5i(동시 2건: 첫 트리거가 패스를 소비한 뒤 두 번째 훅이 reject). `docs/handoff/S03.md` S03b 실행 검증.

## 5. 인수 시나리오(실제 Auth API, dev 키 필요)

| # | 시나리오 | 기대 | 상태 |
|---|---|---|---|
| 1 | 패스 없이 이메일 가입 | 훅 400 `가입 확인이 필요합니다` | pgTAP ✔ · 실 API ✔(5b·5d) |
| 2 | 티켓 → 패스 → 가입 → complete-signup | 사용자·identity·approval 1건, 패스 삭제, profiles 1건 | pgTAP ✔ · 실 API ✔(5c·5f·5g·5h) |
| 3 | 훅 통과 후 트리거 실패(dev/0001: GUC `app.test_trigger_fail=on` 또는 `server_config.test_trigger_fail=on`) | 사용자·identity·승인 미생성, 패스 잔존 | pgTAP ✔(GUC) · 실 API ✔(5e, server_config 스위치) |
| 4 | 훅 비활성 + 패스 없음 | 트리거 차단(백스톱) | pgTAP ✔(트리거 단독) · 실 API ✔(5a) |
| 5 | 기존 승인 사용자에 identity 연결(패스 유/무) | 통과, 승인 1건 | pgTAP ✔ |
| 6 | 동시 가입 2건 | 1건(패스 PK + DELETE RETURNING) | 실 API ✔(5i: 200 + 400) |
| 7 | 가입 10분 후 complete-signup | 성공(패스 TTL 무관) | pgTAP ✔ |
| 8 | 탈퇴 후 재가입 | 새 패스로 정상 | 실 API 미실행 |
| 9 | 잘못된 aud·iss·nonce·티켓 없음 | issue-pass 400 | Deno ✔ |

## 6. 앱(S05) 에러 표

`AuthRejection` → `AuthStrings.forRejection`: `signupPassRequired · notApproved · ticketInvalid · idTokenInvalid · invalidCredentials · emailTaken · weakPassword · rateLimited · network · unknown`. 매핑은 `AuthRejectionMapper`(훅 메시지 `가입 확인이 필요합니다` → `signupPassRequired`, gotrue `code` → 자격 증명/중복/약한 비밀번호, Edge `error` 코드 → 티켓/토큰/승인).

## 7. 로그

`age-check · issue-pass · complete-signup` 과 훅·트리거는 request id 와 outcome 코드만 남긴다. Edge `logger()` 는 이메일·날짜·JWT·`sub=`/`birth_date=` 형태를 마스킹하고(`_tests/log_test.ts`), 앱 `AgeGateRepository` 는 생년월일을 인자로만 쓴다(`auth_repository_test.dart` 로그 캡처).
