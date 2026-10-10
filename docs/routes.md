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
  /planner            planner planFold plan3d t7 s10 (S07 · `?date=yyyy-MM-dd` 로 그 달·그 날 선택) · 시트: addSheet datePick repeatSheet editItem editCancel editDelete bandEdit discard = `showPlannerItemSheet`
  /timetable          tt t6 evEdit evScope (S08 · 주간 00–24×7열 · 블록 → /session/:id · 반복 일정 수정 = `showPlannerItemSheet` · 전체 삭제 확인창 + 되돌리기)
  /stats              t1 s11 s12 statsP statsF cross(숨김) (S08 · 주간/월간 · 오답 카드 무료/프리미엄/종료)
/settings             settings (S09 · 홈 헤더 기어 · 탭 밖, root navigator push · 시트: 하루 목표 시간 N1 · 주 시작 요일 N2 · 알림 D14 · 확인창: 로그아웃 · 계정 삭제 · 알림 권한 거부 nfDenied)
/settings/subjects    subjects N11 B8 subjDelN (S09 · 과목 추가/편집 시트 · 삭제 확인창 + 되돌리기 5초)
/settings/privacy     privacy N6 N7 expSheet delDlg (S09 · 카메라와 개인정보 · 보관 사진 시트 · 내보내기 시트 · 모든 기록 삭제 확인창)
/settings/help        help N4 (S09 · FAQ · 문의 · 전송 실패 안내 N-문의)
/measure/setup        setupOn setupDen errCam camBusyN s5 (홈 CTA · 복구 "이어서" = ?resume=<sessionId> · 기록 유지 뒤 복구 카드)
/measure/focus        focus away awayLong lost lostFail s6 s7
/measure/summary      summary s8 s9 sumDiscard toast (새 기록 저장·정정 시트 · 저장 → 홈 + 토스트)
/session/:id          session sumEdit sumEditCancel sessDel (플래너 상세의 "실제 N분" 탭)
/measure/corrections  정정 이력 (감도 조정 토스트 · S09 개인정보 화면은 건수만 표시, 이동 없음)
/wrongs               wrongs (S11 placeholder · S08 예약: 통계 오답 카드 "전체 보기" · S09는 손대지 않음)
/paywall              paywall (S12 placeholder · S08 예약: 통계 프리미엄 배지 · 재구독 · 타임테이블 시트 잠금 힌트)
/reading/capture      capture (S10 placeholder · S07 예약: 플래너 판독 버튼 → `?from=planner&itemId=<plannerItemId>`, 범위는 `range_text` 없으면 제목 D27)
/_gallery             dev 전용(DEV_MENU)
/_seat_lab            dev 전용(S04 착석 엔진 실험실 · `measure_routes.dart` 에 등록)
```

## 2. 가드 (`features/auth/domain/auth_redirect.dart` · 순수 함수, 유닛 테스트 `test/unit/domain/auth_redirect_test.dart`)

| `AuthGate` 상태 | 규칙 |
|---|---|
| `loading` · `profileError` | `/` 에 머문다(`/auth/reset` 예외). 프로필 읽기 실패는 `/` 에서 재시도 — 단, 같은 계정의 **캐시된 프로필**(S05b `ProfileCache`)이 있으면 `signedIn(fromCache)` 로 진입하고 백그라운드 재조회 |
| `signedOut` | `/gate/*` `/login/*` `/auth/reset`(+dev `/_gallery` `/_seat_lab`)만 허용, 나머지 → `/gate` |
| `signedIn` · `profiles` 없음 | 모두 → `/signup/complete` |
| `signedIn` · `onboarding_done == false` | 모두 → `/onboarding/1`(온보딩 단계 안에서는 이동 허용) |
| `signedIn` · 완료 | 요청 경로 유지. `/` `/gate/*` `/login/*` `/signup/complete` `/onboarding/*` 는 → `/home` |
| (어느 상태든) `passwordRecovery` 플래그 | 모두 → `/auth/reset` (S05b) |
| `localOnly`(dev · 백엔드 env 없음) | 인증 없음 · `/` 와 인증 경로 → `/home` |

딥링크 `soongong://auth/reset` 은 **Supabase SDK 가 단독으로 처리**한다(S05b): `detectSessionInUri` 의 app_links 관찰자가 PKCE 코드를 세션으로 교환하고 `passwordRecovery` 이벤트를 낸다 → `passwordRecoveryProvider = true` → 가드가 모든 경로를 `/auth/reset` 로 보낸다(새 비밀번호 저장 또는 "재설정 메일 다시 요청" 에서 해제). Flutter 자체 딥링크 라우팅(`flutter_deeplinking_enabled` / `FlutterDeepLinkingEnabled`)은 **꺼져 있어** go_router 는 원문 링크를 받지 않는다(가드에 host 정규화 없음). 가드는 `authGateProvider`·`passwordRecoveryProvider` 변화마다 재평가된다(`refreshListenable`).

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

`sessionRecoveryHandlerProvider` → `SessionRecoveryHandler { resume · finish · discard · finishLocation }`. 홈은 `session_snapshot` 행(또는 `active`/`paused`/미저장 `interrupted` 세션 행)이 있으면 앱 실행당 1회 시트를 띄운다. S06 기본 구현(`MeasureSessionRecoveryHandler`): `resume` = `/measure/setup?resume=<sessionId>`에서 카메라 확인 후 같은 세션에 이어서, `finish` = 마지막 스냅샷을 정산해 `/measure/summary`로 이동 후 사용자가 저장/버리기, `discard` = 세션·구간·정정 기록과 해당 스냅샷 삭제. 열린 구간은 `saved_at` 이후 시간을 더하지 않으며 저장한 복구 기록은 `interrupted`다(D23). 실행 중인 새 측정의 스냅샷으로 숨겨진 홈의 복구 시트가 열리지 않도록 시작 직전에 `RecoveryPrompted.mark()`한다.
