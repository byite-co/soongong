# 순공 (SoonGong)

순공시간 측정 · 플래너 · AI 판독(오답 → 복습) Flutter 앱. 제품 원칙과 세션 규칙은 [`CLAUDE.md`](CLAUDE.md), 결정 기록은 [`docs/decisions.md`](docs/decisions.md).

## 시작하기

```sh
fvm use                                   # .fvmrc → Flutter 3.47.5 (또는 같은 버전의 flutter 사용)
python3 tool/fetch_gaze_model.py            # 고정 모델 다운로드 + SHA-256 검증
flutter pub get
dart run build_runner build --delete-conflicting-outputs
cp env/app.dev.example.json env/app.dev.json   # 공개 키만 채운다 (env/README.md)
flutter run --flavor dev --dart-define-from-file=env/app.dev.json
```

검사: `flutter analyze --fatal-infos` · `dart run tool/check_forbidden_phrases.dart` · `flutter test`
서버: `supabase/tests/local/run.sh`(로컬 PostgreSQL 16 + pgTAP) · `cd supabase/functions && deno test -A _tests/`

## 구조

- `lib/core/` — theme(토큰) · widgets(공통 위젯) · contracts(인터페이스 + Fake) · domain(엔티티·enum·LocalDate·Clock) · router · strings · dev(dev 메뉴·위젯 카탈로그 `/_gallery`·착석 감지 실험실 `/_seat_lab`·시선 관측 실험 `/_gaze_lab`)
- `lib/features/<feature>/` — `<feature>_routes.dart` · presentation / application / domain(순수 Dart 정책)
- `lib/data/` — db(drift 로컬 스키마 v3, `docs/data-model.md`) · repositories(outbox · applyServer · D22 소프트 삭제) · export(JSON·CSV) · seed(dev 샘플) · startup · engines(`SeatEngineImpl`, `docs/seat-engine.md`) · sync(S13)
- `supabase/` — migrations(DDL · RLS · RPC · 가입 훅/트리거 · 판독 원장 · cron) · functions(Edge 18개) · tests(pgTAP + Deno) · dev(dev 전용) — `docs/sync-rpc.md` · `docs/reading-api.md` · `docs/supabase-auth.md`
- `docs/` — decisions · design-tokens · versions · reference · handoff

## Flavor

| flavor | Android applicationId | iOS bundle id / scheme | 용도 |
|---|---|---|---|
| dev | `co.byite.soongong.dev` | `co.byite.soongong.dev` / `dev` | 개발 · dev 메뉴 · `/_gallery` · `/_seat_lab` |
| prod | `co.byite.soongong` | `co.byite.soongong` / `prod` | 출시 |

CI: `.github/workflows/analyze-test.yml`(PR) · `build-android.yml`(수동, dev APK 아티팩트).

## EXT 통합 (main 병합 전)

손글씨 OCR → 수학 풀이 → 기기 내 시선 관측 → SQLite 전체 암호화 코드가 PR #9에 순서대로 적용되어 있다. 실제 모델 서비스 연결, 한국어/수능 평가와 실기기 검증은 자동 검사와 구분한다. 최신 결과와 미완료 항목: [`docs/handoff/EXT-FINAL.md`](docs/handoff/EXT-FINAL.md).

OCR/풀이의 배포 설정은 [`services/study_worker/README.md`](services/study_worker/README.md)를 참고한다. 서버는 기본 비활성화이며 앱에서 가짜 결과를 제공하지 않는다. 시선 관측은 dev 메뉴의 실험 화면이며 시간 집계에 반영되지 않는다. 암호화된 로컬 기록은 기기에 묶인 키를 사용하므로 OS 백업/기기 이전에서 제외되고, S13 동기화는 아직 Fake다.

### iOS 네이티브 빌드 대상

현재 ML Kit + MediaPipe 조합은 시뮬레이터에 공통 지원 아키텍처가 없어 **iPhone ARM64**를 대상으로 합니다. 모델 다운로드·pub get 후 `flutter build ios --release --flavor dev --no-codesign --dart-define-from-file=env/app.dev.example.json`으로 서명 없이 빌드할 수 있습니다. 실제 실행에는 기기/서명이 필요하며, CI 빌드는 카메라·키체인 실기기 검증을 대신하지 않습니다. 근거와 제한은 [EXT-03](docs/handoff/EXT-03.md)에 기록했습니다.
