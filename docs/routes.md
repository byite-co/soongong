# 라우트 예약 표 (`docs/routes.md`) — S05 작성 · 레인이 추가할 때 갱신

`core/router/app_router.dart` 는 S05 소유(머지 후 S14). 다른 레인은 `features/<feature>/<feature>_routes.dart` 의 목록만 채운다. 경로 이름은 유저플로우 노드 ID 기준(CLAUDE.md §4). 시트·모달은 라우트가 아니다(`showAppSheet`/`showAppModal`).

## 1. 구조

```
/                     launch     세션·프로필 확인 중(LaunchScreen) · 프로필 읽기 실패 시 재시도
/gate                 ageGate    생년월일 → age-check → 티켓(메모리) → /login
/gate/blocked         ageBlocked 만 14세 미만 · 닫기 → /gate
/login                login      Apple · Google · 카카오 · 이메일 (티켓 있으면 "계정 만들기")
/login/email          lgEmail    check-email → 기존 /login/password · 신규 /gate(→ /login/signup)
/login/password       lgPw       기존 계정 비밀번호 · 잊었어요(lgReset, 재설정 메일)
/login/signup         lgSignup   새 계정 비밀번호(8자 이상) · 티켓 필요
/auth/reset           —          비밀번호 재설정 딥링크 soongong://auth/reset (미로그인 허용)
/signup/complete      —          동의 ① → complete-signup (profiles 생길 때까지 재실행에도 표시)
/onboarding/1..3      ob1 ob2 ob3
StatefulShellRoute (탭 4개 · 태블릿 ≥600dp 는 좌측 레일)
  /home               home homeEmpty s1–s4 s14 t5 recover recoverConfirm
  /planner            (S07 placeholder)
  /timetable          (S07 placeholder)
  /stats              (S08 placeholder)
/settings             (S09 placeholder · 홈 헤더 기어 · 탭 밖, root navigator push)
/measure/setup        setupOn (S06 placeholder · 홈 CTA · 복구 "이어서" = ?resume=<sessionId>)
/_gallery             dev 전용(DEV_MENU)
```

## 2. 가드 (`features/auth/domain/auth_redirect.dart` · 순수 함수, 유닛 테스트 `test/unit/domain/auth_redirect_test.dart`)

| `AuthGate` 상태 | 규칙 |
|---|---|
| `loading` · `profileError` | `/` 에 머문다(`/auth/reset` 예외). 프로필 읽기 실패는 `/` 에서 재시도 |
| `signedOut` | `/gate/*` `/login/*` `/auth/reset`(+dev `/_gallery`)만 허용, 나머지 → `/gate` |
| `signedIn` · `profiles` 없음 | 모두 → `/signup/complete` |
| `signedIn` · `onboarding_done == false` | 모두 → `/onboarding/1`(온보딩 단계 안에서는 이동 허용) |
| `signedIn` · 완료 | 요청 경로 유지. `/` `/gate/*` `/login/*` `/signup/complete` `/onboarding/*` 는 → `/home` |
| `localOnly`(dev · 백엔드 env 없음) | 인증 없음 · `/` 와 인증 경로 → `/home` |

딥링크 `soongong://auth/reset` 은 플랫폼이 host `auth` + path `/reset` 로 전달하므로 가드가 `/auth/reset` 로 정규화한다. 가드는 `authGateProvider` 변화마다 재평가된다(`refreshListenable`).

## 3. 레인이 라우트를 추가하는 절차

1. `features/<feature>/<feature>_routes.dart` 의 `List<RouteBase>` 에 `GoRoute` 를 추가한다(placeholder 가 있으면 builder 만 교체).
2. 탭 안에 머물러야 하는 화면(플래너 상세 등)은 **탭 루트의 `routes:` 하위**에 둔다 — 그래야 탭바가 유지되고 뒤로가기가 탭 안에서 돈다. 전체 화면(측정·설정·판독)은 자기 routes 목록의 최상위에 두면 root navigator 로 push 된다.
3. 이 표에 노드 ID ↔ 경로를 적는다. 가드 예외(미로그인 허용)가 필요하면 `resolveAuthRedirect` 와 테스트를 함께 고친다(S14 와 상의).
4. `app_router.dart` 는 건드리지 않는다.

## 4. 홈 슬롯 (`features/home/application/home_slots.dart`)

| Provider | 소유 | 위치 |
|---|---|---|
| `readingCardSlotProvider` | S10 (`hbReading` · `hbDone`) | 헤더 아래, 히어로 위 |
| `subscriptionCardSlotProvider` | S12 (`s14` 프리미엄 카드 · `roHome` 읽기 전용) | 할 일 목록 아래 |
| `recoverySlotProvider` | S06 (선택) | 맨 아래 |

값은 `Widget Function(BuildContext)?` — null 이면 그리지 않는다. `bootstrap()` 의 `ProviderContainer(overrides:)` 또는 provider 본문 교체로 공급.

## 5. 세션 복구 콜백 (`features/home/application/session_recovery.dart`)

`sessionRecoveryHandlerProvider` → `SessionRecoveryHandler { resume · finish · discard }`. 홈은 `session_snapshot` 행(또는 `active`/`paused` 세션 행)이 있으면 앱 실행당 1회 시트를 띄우고 세 버튼을 이 핸들러로 보낸다. 기본 구현(S05): `finish` = `SessionTimeline.recover` + `saveFinished(status: interrupted)`(D23), `discard` = 스냅샷 삭제(+행이 있으면 commitDelete), `resume` = `/measure/setup?resume=<sessionId>` 로 이동. **S06 이 이 provider 를 교체**해 측정 화면으로 이어가고 정산을 소유한다.
