# 순공 (SoonGong)

순공시간 측정 · 플래너 · AI 판독(오답 → 복습) Flutter 앱. 제품 원칙과 세션 규칙은 [`CLAUDE.md`](CLAUDE.md), 결정 기록은 [`docs/decisions.md`](docs/decisions.md).

## 시작하기

```sh
fvm use                                   # .fvmrc → Flutter 3.47.5 (또는 같은 버전의 flutter 사용)
flutter pub get
dart run build_runner build --delete-conflicting-outputs
cp env/app.dev.example.json env/app.dev.json   # 공개 키만 채운다 (env/README.md)
flutter run --flavor dev --dart-define-from-file=env/app.dev.json
```

검사: `flutter analyze --fatal-infos` · `dart run tool/check_forbidden_phrases.dart` · `flutter test`
서버: `supabase/tests/local/run.sh`(로컬 PostgreSQL 16 + pgTAP) · `cd supabase/functions && deno test -A _tests/`

## 구조

- `lib/core/` — theme(토큰) · widgets(공통 위젯) · contracts(인터페이스 + Fake) · domain(엔티티·enum·LocalDate·Clock) · router · strings · dev(dev 메뉴·위젯 카탈로그 `/_gallery`·착석 감지 실험실 `/_seat_lab`)
- `lib/features/<feature>/` — `<feature>_routes.dart` · presentation / application / domain(순수 Dart 정책)
- `lib/data/` — db(drift 스키마 v1, `docs/data-model.md`) · repositories(outbox · applyServer · D22 소프트 삭제) · export(JSON·CSV) · seed(dev 샘플) · startup · engines(`SeatEngineImpl`, `docs/seat-engine.md`) · sync(S13)
- `supabase/` — migrations(DDL · RLS · RPC · 가입 훅/트리거 · 판독 원장 · cron) · functions(Edge 18개) · tests(pgTAP + Deno) · dev(dev 전용) — `docs/sync-rpc.md` · `docs/reading-api.md` · `docs/supabase-auth.md`
- `docs/` — decisions · design-tokens · versions · reference · handoff

## Flavor

| flavor | Android applicationId | iOS bundle id / scheme | 용도 |
|---|---|---|---|
| dev | `co.byite.soongong.dev` | `co.byite.soongong.dev` / `dev` | 개발 · dev 메뉴 · `/_gallery` · `/_seat_lab` |
| prod | `co.byite.soongong` | `co.byite.soongong` / `prod` | 출시 |

CI: `.github/workflows/analyze-test.yml`(PR) · `build-android.yml`(수동, dev APK 아티팩트).
