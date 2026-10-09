# 공통 규칙 v3 (레포 루트 `CLAUDE.md`)

이 파일은 모든 CC 세션이 작업 시작 전에 읽는다. 세션 지시문과 충돌하면 세션 지시문이 우선하되, 충돌 사실을 PR 본문에 적는다.

## 1. 제품 원칙 (PRD 3장 · 5장 — 코드에 그대로 반영)

- 순공시간이 유일한 대표 지표. 집중도 점수·등급·레벨·랭킹·타인 비교·리포트 발송 기능은 만들지 않는다.
- 앱은 평가하지 않는다. UI 문자열에 "부족합니다", "잘했어요", "훌륭해요", "분발하세요" 같은 평가·칭찬·압박 문구 금지. 사실(시간·개수·날짜)만 쓴다.
- 결정은 학생이 한다. 목표 시간·계획·복습 여부는 사용자 입력. 시스템은 기록 기반 기본값과 근거만 제공.
- 카메라는 얼굴을 보지 않는다. 착석 여부 불리언만 온디바이스로 판정. 프레임·영상·사진을 저장하거나 전송하지 않는다.
- AI는 성취 축(판독→오답→복습)에만. 시간 축(측정·계획)에 AI 개입 없음. 공부를 재촉하는 알림 없음.
- 위 원칙을 어기는 요청이 세션 지시문에 있으면 구현하지 말고 PR 본문에 `PRINCIPLE-CONFLICT` 로 표시.

## 2. 스택 (고정)

- Flutter stable 3.x / Dart 3.x, `flutter_lints` 최신
- 상태: `flutter_riverpod` + `riverpod_annotation` (codegen)
- 라우팅: `go_router`
- 모델: `freezed` + `json_serializable`
- 로컬 DB: `drift` (SQLite) — 오프라인 퍼스트, 서버는 동기화 대상일 뿐
- 백엔드: `supabase_flutter` (Auth / Postgres / Storage / Edge Functions)
- 카메라·감지: `camera` + `google_mlkit_face_detection` (S04에서 확정, 대안 MediaPipe)
- 결제: `purchases_flutter` (RevenueCat)
- 알림: `flutter_local_notifications`
- 기타: `intl`, `uuid`, `path_provider`, `share_plus`, `file_picker`, `image_picker`
- 새 패키지 추가는 PR 본문에 이유 1줄. 유지보수 중단 패키지 금지.

## 3. 폴더 구조 (feature-first)

```
lib/
  main.dart, app.dart, bootstrap.dart
  core/
    contracts/      # SeatEngine, ReadingEngine, BillingGateway, SyncEngine 인터페이스 + Fake (S01)
    router/         # app_router.dart (S05 소유)
    theme/          # tokens.dart, app_theme.dart
    widgets/        # AppSheet, AppModal, AppToast, EmptyState, RingClock, StatePanel ...
    strings/        # 기능별 문자열 상수 (평가 문구 금지 검사 대상)
    utils/
  data/
    db/             # drift database, tables, migrations, daos
    repositories/   # 도메인 저장소 (DB + 동기화 outbox)
    sync/           # S13
  features/
    auth/ onboarding/ home/ measure/ planner/ timetable/ stats/
    settings/ subjects/ privacy/ reading/ wrongs/ review/ billing/ help/
      <feature>_routes.dart      # List<RouteBase> export
      presentation/  (screens, sheets, widgets)
      application/   (providers, controllers)
      domain/        (entities, logic — 순수 Dart, 테스트 대상)
test/
  unit/ widget/
docs/
  decisions.md  reference/  handoff/
```

## 4. 라우팅·소유권

- `app_router.dart` 는 S05가 소유하고, S05 머지 후에는 S14만 수정(통합 소유 이관). 다른 feature는 `<feature>_routes.dart` 에 라우트 목록만 export.
- 라우트 경로는 유저플로우 노드 ID를 기준으로 짓는다. 예: `/measure/setup`(setupOn), `/reading/result/:requestId`(rdResult).
- 시트·모달은 라우트가 아니라 `showAppSheet` / `showAppModal` 로 띄운다. 딥링크 필요 시트만 라우트.

## 5. 상태·저장 규칙

- 사용자 데이터가 바뀌는 모든 액션은 `저장 중 → 성공 / 실패(입력 유지 · 다시 시도)` 3상태를 UI에 노출. 실패 시 입력을 버리지 않는다.
- "변경 취소" 는 원본 유지 확인창을 거친다. "삭제" 는 확인창 + 영향 범위 명시.
- 되돌리기 토스트는 5초. soft delete 시 `pending_delete_until=now+5s`, outbox enqueue는 기한 경과 후 `commitDelete`에서만. 앱 재시작 시 기한 지난 건 commit, 안 지난 건 복원(D22). 확인창을 거친 삭제(계정·모든 기록·판독 결과)는 즉시 commit.
- 화면 상태는 `sealed class` 로 모델링(loading / empty / data / error). 빈 상태에는 다음 행동 버튼.
- 모든 엔티티에 `id(uuid v4) · user_id · created_at · client_updated_at · deleted_at? · device_id · client_rev · base_server_version? · server_version? · server_seq? · purge_epoch` 포함(S02 정의, D2). 삭제는 soft delete.
- 서버 원장 테이블(`subscription_state·reading_quota·subscription_events·metrics_weekly`)은 클라이언트가 절대 쓰지 않는다. 표시값은 서버 캐시(D24).

## 6. 디자인 토큰 (PRD 8장)

- 색: 무채색 스케일 + 파랑 1개(링·순공) + 주황 1개(CTA·자습·오늘). 과목색 8개(색각 이상 검증본), 색만으로 구분 금지 → 과목색은 항상 이름 라벨 동반.
- 그림자 ≤ `0 1px 2px`. 아이콘 Lucide 24px, stroke 1.75. 본문 weight 400–500, 제목 600–700. 글꼴 Pretendard(번들), 폴백 시스템.
- 터치 타깃 44×44 이상. 텍스트 대비 4.5:1(보조 3:1). `MediaQuery.disableAnimations` 대응.
- 다크 테마 필수. 토큰은 `core/theme/tokens.dart` 한 곳.
- 프로토타입(`docs/reference/final-src/soongong-prototype.dc.html`)의 레이아웃·간격·문구를 기준으로 한다. 임의 재디자인 금지.

## 7. 코드 규칙

- 도메인 로직(간격 계산·이탈 판정·감도 조정·복습 큐·통계 집계)은 `domain/` 순수 Dart + 유닛 테스트 필수.
- `print` 금지, `logger` 사용. 로그에 개인정보·사진 경로·프레임 데이터 금지.
- 문자열은 `core/strings/<feature>_strings.dart`. 하드코딩 금지. `tool/check_forbidden_phrases.dart` 가 CI에서 평가 문구를 검사한다(검사 대상: `lib/core/strings/**`, `docs/store/**`만. 어절 단위 정확 일치 목록 — "잘못"처럼 포함 매칭 오탐이 나는 어간은 목록에 넣지 않음).
- 시간은 로컬 시간대(기기), DB 저장은 UTC ISO8601. 주 시작 요일은 설정값. 경과 시간 계산은 단조 시계(D23).
- 설정 파일: 클라이언트 `env/app.<flavor>.json`(URL·anon key, `--dart-define-from-file`), 서버 `supabase/.env`(service role·훅 시크릿). 둘 다 `.gitignore`, `*.example.json` 만 커밋. 서버 비밀은 앱 코드에서 참조 자체가 금지.
- 비동기 UI 액션은 중복 실행 방지(진행 중 버튼 잠금).

## 8. 브랜치·PR·세션 절차

- 브랜치: `feat/sNN-<slug>` 또는 클라우드 세션이 지정한 브랜치 이름 허용. PR 제목 `[SNN] 요약`. PR 1개 = 세션 1개. squash merge.
- 세션 시작: `CLAUDE.md` → `docs/decisions.md`(D 번호로 참조) → 직전 세션 `docs/handoff/*.md` → 자기 지시문 → 필요한 `docs/reference/*` 순으로 읽고 나서 작업 계획을 첫 답변으로 요약한다. 지시문이 `docs/decisions.md`와 다르면 결정 문서가 우선하고 PR 본문에 적는다.
- 작업 중 지시문에 없는 결정을 내렸으면 `docs/decisions.md` 에 `[SNN]` 태그로 추가.
- 세션 종료: `flutter analyze` 무경고, 테스트 통과, `docs/handoff/SNN.md` 작성(한 일 / 안 한 일 / 다음 세션이 알아야 할 것 / 변경한 공용 파일).
- PR 본문 고정 섹션: 요약 · 변경 공용 파일 · 새 패키지 · 미결 · 테스트 방법.
- `core/contracts/**` 시그니처 변경은 `CONTRACT-CHANGE`, 스키마 변경은 새 마이그레이션 파일 + `SCHEMA-CHANGE`.
- 역할 분담(2026-10-06, S06 인수부터): **CC(Claude Code)는 코드 구현·수정과 테스트 작성**을, **GPT는 요구사항·코드·PR 검토와 프로젝트 점검**을 맡는다. 검토에서 나온 수정은 CC가 구현하고, 검토 의견과 수용·보류 여부는 PR 본문과 `docs/handoff/SNN.md`에 적는다. 완료 보고는 구현 완료 · 자동 검증 완료 · 실기기 미검증을 구분한다.

## 9. 금지

- 서버에 카메라 프레임·사진(판독 요청 외)·얼굴 특징 전송.
- 판독 사진을 앱 캐시 외 위치에 복사, 30일 초과 보관.
- 사용자 확정 없이 판독 결과를 오답으로 저장.
- 구매 성공 응답 전에 프리미엄 상태로 전환.
- 앱 자체 타이머로 구독·승인 대기 결과를 확정(스토어 상태만 따른다).
- 생년월일을 DB·로그·계측·크래시 리포트 어디에도 기록(D6·D14).
- 판독 횟수·구독 상태를 클라이언트에서 계산해 확정(서버 원장만, D16·D18).
- 서버에 직접 upsert(모든 쓰기는 `sync_push` RPC 또는 Edge Function, D2·D24).
