# 공개 코드 통합 현황 — S14

기준: 2026-10-12, main `c5723529c11c225032f9f9b0038fe05255e1c903` (S08 병합 후).

후속 준비(2026-10-13 KST): [손글씨 OCR → 수능 풀이 → 시선 판독 → DB 암호화의 세션별 지시문](oss-sessions/README.md). 정합성·검증·최종 일괄 병합 절차를 정리했으며 네 기능은 아직 구현 전이다.

이 문서는 2026-10-10 두 조사 보고서의 후보를 현재 코드와 대조한 적용 원장이다. **전 후보 적용 완료를 뜻하지 않는다.** 구현·기존 사용·미적용을 구분하며, 미적용 항목은 숨기거나 설치만으로 완료 처리하지 않는다. 현행 제품 결정(D9·D10·D14 등)을 유지한다. 사용자가 이번 Work 세션에서 GPT에 직접 구현을 지시했으므로 CLAUDE.md §8의 기존 역할 분담과 다른 점은 PR에도 명시한다.

## 이번에 연결한 실행 경로

| 영역 | 코드 | 동작 |
|---|---|---|
| 인증 | `lib/data/auth/secure_auth_storage.dart` · `supabase_init.dart` | 세션·PKCE를 플랫폼 보안 저장소에 보관, 이전값 write/read 확인 후 제거, 프로젝트·flavor 키 격리, 로그아웃 저장 순서 보존 + 빈 secure tombstone으로 이전값 재수입 차단 |
| 화면 | `features/timetable/domain/overlap_layout.dart` · `timetable_screen.dart` | 겹친 반복 일정·세션 나란히 표시; 공부 시간 집계에는 영향 없음 |
| 내보내기 | `lib/data/export/export_service.dart` | SQL에서 계정/live 행 선택, JSON/ZIP 인코딩 compute, CSV 연결 행 계정 제한 |
| Edge | `_shared/validation.ts` · `_shared/http.ts` · `reading-submit/index.ts` | Zod 공통 형식 검증, 기존 오류/길이/null 의미 보존 |
| 검증 | `_tests/validation_test.ts` · `plpgsql_diagnostics.sql` | fast-check 계약 회귀, SQL 정적 진단 baseline |

성능 수치는 측정하지 않았다. compute는 모바일/데스크톱 isolate에서 실행하며 web에서는 UI 실행 맥락 분리 효과가 같지 않다. 플랫폼 보안 저장소는 DB 파일 전체 암호화와 다르다.

## 1차 보고서의 16개 후보

| ID | 후보·원본 | 라이선스(조사 기준) | 적용 상태 |
|---|---|---|---|
| D1 | [Widgetbook](https://github.com/widgetbook/widgetbook) | MIT | 미적용: 기존 /_gallery와 중복. 별도 Widgetbook 카탈로그와 상태 연결 작업 필요. |
| D2 | [Alchemist](https://github.com/Betterment/alchemist) | MIT | 미적용: golden 기준 이미지·CI 폰트/렌더러 기준을 먼저 확정해야 한다. |
| D3 | [Skeletonizer](https://github.com/Milad-Akarie/skeletonizer) | MIT | 미적용: 현재 StatePanel/스켈레톤이 있음. 화면 단위 대체 이득·접근성 비교 필요. |
| D4 | [FL Chart](https://github.com/imaNNeo/fl_chart) | MIT | 미적용: S08 CustomPainter와 중복. 현행 순공 집계·차트 의미를 그대로 보존한다. |
| S1 | [flutter_secure_storage + Supabase 저장 어댑터](https://github.com/juliansteenbakker/flutter_secure_storage) | BSD-3-Clause / Supabase MIT | 구현: 기존 secure_storage 11.2.0 + Supabase 2.18.0 확장점으로 세션·PKCE 보안 저장, 검증 후 이전, 작업 직렬화. |
| S2 | [Drift + SQLite3MultipleCiphers](https://github.com/utelle/SQLite3MultipleCiphers) | 주요 레포 MIT; 내장 구성요소 별도 확인 | 미적용: 평문 DB→암호화 DB의 원자적 이전·복구·키 소실 정책 및 Android/iOS 바이너리 검증 필요. |
| S3 | [local_auth](https://github.com/flutter/packages) | BSD-3-Clause | 미적용: 생체 인증 잠금/복구 UX와 지원 기기 fallback이 아직 없다. |
| S4 | [screen_protector](https://github.com/prongbang/screen_protector) | Apache-2.0 | 미적용: 캡처 방지 범위와 iOS/Android별 동작·앱 전환 복구 정책 필요. |
| P1 | [Drift 선택 조회·집계 스트림](https://github.com/simolus3/drift) | MIT | 구현: ExportService의 사용자·삭제 조건을 Drift SQL 조회로 이동. CSV 연결 조회도 계정 범위 제한. |
| P2 | [Riverpod select·구독 범위 조정](https://github.com/rrousselGit/riverpod) | MIT | 기존 사용 유지: Riverpod 설치됨. 이번 변경에는 select 최적화 없음. 집계 의존성별 프로파일링 후 변경. |
| P3 | [Flutter background_isolate_channels 예제](https://github.com/flutter/samples) | 해당 Dart 코드 BSD 계열; 자산 별도 | 패턴 적용: Flutter compute로 JSON/ZIP 인코딩 분리. DB/client를 보내지 않고 값 snapshot만 전달. 예제 소스 복사 없음. |
| P4 | [flutter_image_compress](https://github.com/fluttercandies/flutter_image_compress) | MIT | 미적용: OCR용 원본 보존·캐시 기한·최소 해상도 및 압축 정확도 벤치마크 필요. |
| B1 | [Zod](https://github.com/colinhacks/zod) | MIT | 구현: Zod 4.6.6으로 공통 HTTP 경계/reading-submit 경로 검증. SQL 인가/원장은 그대로 권위 유지. |
| B2 | [plpgsql_check](https://github.com/okbob/plpgsql_check) | LICENSE 본문 MIT 계열 | 진단 연결: PostgreSQL 16 CI 임시 DB에서 plpgsql_check 실행. 경고·컨텍스트 의존 오류를 출력하는 기존 2건을 명시한 baseline + 신규 오류 차단; pgTAP 대체 아님. |
| B3 | [pg_jsonschema](https://github.com/supabase/pg_jsonschema) | Apache-2.0 | 미적용: 현행 SQL 검증과 중복. JSON schema를 단일 계약으로 관리하는 방식/마이그레이션 필요. |
| B4 | [fast-check](https://github.com/dubzzz/fast-check) | MIT | 구현: fast-check 4.10.2로 JSON·문자열·경로 기존 입력 계약에 2,000회 고정 seed 속성 검증. 원장 전체 검증을 의미하지 않음. |

## 기능별 보고서의 19개 상세 후보

| ID | 후보·원본 | 적용 상태 |
|---|---|---|
| F1 | [byite-co/focus-engine](https://github.com/byite-co/focus-engine/blob/main/android/focus-engine/engine/src/main/kotlin/co/byite/focus/engine/pipeline/scene/SceneGrid.kt) | 기존 부분 참조 유지. 이번에는 SceneGrid/HeadPose 신규 이식 없음. 품질 기준 실측·공개 재배포 권리 확인 필요. |
| F2 | [google-ai-edge/mediapipe-samples](https://github.com/google-ai-edge/mediapipe-samples/blob/main/examples/face_landmarker/android/app/src/main/java/com/google/mediapipe/examples/facelandmarker/FaceLandmarkerHelper.kt) | 미적용: 플랫폼 브리지·모델 조건·실기기 성능 비교 필요. 랜드마크는 정신적 집중의 정답이 아님. |
| F3 | [google_mlkit_pose_detection](https://github.com/flutter-ml/google_ml_kit_flutter/blob/develop/packages/google_mlkit_pose_detection/lib/src/pose_detector.dart) | 미적용: 얼굴 검출 대체 성능이 확인되지 않음. 현행 PresenceDetector boolean 계약의 비교 실험 필요. |
| F4 | [casiez/OneEuroFilter](https://github.com/casiez/OneEuroFilter/blob/main/python/OneEuroFilter/OneEuroFilter.py) | 미적용: 현재 입력은 boolean. 연속 좌표가 없는 상태에서 추가할 실행 경로가 없음. |
| F5 | [emilianavt/OpenSeeFace](https://github.com/emilianavt/OpenSeeFace/blob/master/tracker.py) | 미적용: 데스크톱 Python 추적기이며 모바일 이식·모델 검증 필요. UDP 전송 경로는 채택하지 않음. |
| P1 | [flutter_calendar_view](https://github.com/SimformSolutionsPvtLtd/flutter_calendar_view/blob/master/lib/src/event_arrangers/side_event_arranger.dart) | 부분 차용 구현: 겹침 연결 그룹/열 재사용 배치를 순수 Dart로 재구성. 반복 일정과 세션을 함께 배치. LICENSE/NOTICE 포함. |
| P2 | [JonasWanke/rrule](https://github.com/JonasWanke/rrule/blob/main/lib/src/recurrence_rule.dart) | 미적용: 현재 주간 반복 규칙에 충분한 자체 expander가 있음. rrule 확장은 DB/제품 계약 변경 필요. |
| P3 | [open-spaced-repetition/dart-fsrs](https://github.com/open-spaced-repetition/dart-fsrs/blob/main/lib/fsrs.dart) | 미적용: D9 고정 복습 정책과 다른 스케줄러. 설치만으로 대체하지 않음. |
| I1 | [shirsh94/flutter_doc_scanner](https://github.com/shirsh94/flutter_doc_scanner) | 미적용: S10 촬영/보정 UI와 플랫폼 권한·캐시 수명 연결 필요. |
| I2 | [hnvn/flutter_image_cropper](https://github.com/hnvn/flutter_image_cropper/blob/master/image_cropper/lib/src/cropper.dart) | 미적용: S10 원본/파생 이미지 수명·취소 동작·출처 연결 필요. |
| I3 | [Udayraj123/OMRChecker](https://github.com/Udayraj123/OMRChecker) | 미적용: 정형 OMR용이며 자유 필기/표시 판독과 다름. PyMuPDF 등 의존 라이선스 별도 검토 필요. |
| I4 | [simpleclub/flutter_math](https://github.com/simpleclub/flutter_math) | 미적용: 현재 모델에 교정된 LaTeX/해설 필드가 없음. 수식 표시 계약과 함께 도입. |
| L1 | [flutter_local_notifications + timezone](https://github.com/MaikuB/flutter_local_notifications/blob/master/flutter_local_notifications/example/lib/main.dart) | 기존 SDK 유지. timezone/예약 구현은 열려 있는 S09 PR #8 소유; 이번 브랜치에서 복제·덮어쓰기 없음. |
| L2 | [fluttercommunity/flutter_workmanager](https://github.com/fluttercommunity/flutter_workmanager/blob/main/workmanager/README.md) | 미적용: D10 전경 동기화 정책과 별개 후속 기능. 계정/epoch 재검증·OS 중단 복구 작업 필요. |
| L3 | [RevenueCat/purchases-flutter](https://github.com/RevenueCat/purchases-flutter/blob/main/lib/purchases_flutter.dart) | 기존 SDK 유지. S12 실제 BillingGateway/상품/서버 webhook 연결은 이번 변경에서 구현하지 않음. |
| O1 | [leancodepl/patrol](https://github.com/leancodepl/patrol) | 미적용: 실제 기기·에뮬레이터 CI/권한 시나리오 연결 필요. widget test를 OS 권한 검증으로 간주하지 않음. |
| O2 | [dart-lang/http RetryClient](https://github.com/dart-lang/http/blob/master/pkgs/http/lib/retry.dart) | 기존 http 유지. outbox 재시도 중첩/비멱등 요청 재전송 위험으로 RetryClient 일괄 적용 없음. |
| O3 | [getsentry/sentry-dart](https://github.com/getsentry/sentry-dart) | 미적용: 외부 오류 수집 목적지와 최소 이벤트 계약이 미정. 프레임/사진/원문/인증값을 수집하지 않음. |
| O4 | [DavBfr/dart_pdf](https://github.com/DavBfr/dart_pdf/blob/master/pdf/README.md) | 미적용: 현재 JSON/CSV export를 개선. PDF는 사용자 선택형 기능·폰트/페이지 분할 검증 필요. |

## 손글씨·수식·문제풀이 8개 후보

모두 **미적용**이다. 현행 ReadingEngine은 채점 표시 판독 계약이며 서버 엔진 호출이 501 placeholder다. 문제 원문/LaTeX 교정 → 풀이 작업 → 검증 → 사용자 확정 저장의 새 데이터/API 계약과 모델 실행 환경이 필요하다. 현재 구현에 이를 연결했다고 주장하지 않는다.

| 후보 | 실제 연결 전 필요한 작업 |
|---|---|
| [PaddleOCR](https://github.com/PaddlePaddle/PaddleOCR) | 모델 선택·고정, 한국 손글씨 평가, 서버 추론 자원/사진 즉시 삭제 계약 |
| [UniMERNet](https://github.com/opendatalab/UniMERNet) | 수식 crop→LaTeX 어댑터, 모델/가중치 조건·실패 표현·교정 UI |
| [ko-hand-ocr](https://github.com/jysvai/ko-hand-ocr) | PROVENANCE의 글꼴 권리 확인과 학생 필기 정확도 검증 |
| [ML Kit Digital Ink](https://github.com/flutter-ml/google_ml_kit_flutter/tree/develop/packages/google_mlkit_digital_ink_recognition) | 사진이 아닌 획 x/y/time 입력 화면과 모델 다운로드/삭제 처리 |
| [Qwen-Agent](https://github.com/QwenLM/Qwen-Agent) | 연결 모델/작업 큐/자원 제한 계산 환경; 예제의 unsandboxed exec 실행기 노출 금지 |
| [SymPy](https://github.com/sympy/sympy) | 허용 수학 연산만 받는 구조화 API·입력 크기/시간 제한·별도 계산 프로세스 |
| [Math-Verify](https://github.com/huggingface/Math-Verify) | 기준 정답/파서/타임아웃 계약; 동치 검증과 풀이 논리 검증 구분 |
| [KCSAT-ML](https://github.com/naver-ai/KCSAT-ML) | 평가 체계 참고만. AGPL 코드와 비상업 학술 시험 콘텐츠 조건 때문에 제품 데이터에 복사하지 않음 |

## 그 외 보류·보조 참고

| 후보 | 판단 |
|---|---|
| [supabase/splinter](https://github.com/supabase/splinter) | 미적용. 기능 적합성은 높지만 현재 API 메타데이터에 라이선스가 없고 재귀 트리에서도 LICENSE/COPYING을 찾지 못했다. README의 라이선스 링크도 확보되지 않았다. 코드 복사·내장 추천은 보류하며 Supabase 제공 Advisors 활용을 검토한다. |
| [usebasejump/supabase-test-helpers](https://github.com/usebasejump/supabase-test-helpers) | 미적용. MIT, 관측 마지막 푸시 2024-05-15. 순공은 이미 pg_temp.as_user와 RLS 부정 테스트가 있다. 유지 상태를 추가 확인하기 전 새 의존성 도입 우선순위는 낮다. |
| [gskinner/flutter_animate](https://github.com/gskinner/flutter_animate) | 미적용. BSD-3-Clause, 관측 마지막 푸시 2024-11-25. 중단을 단정할 수는 없지만 유지보수 원칙상 활동 확인이 먼저다. 단순 전환은 기존 Flutter 애니메이션으로 충분하다. |
| [rydmike/flex_color_scheme](https://github.com/rydmike/flex_color_scheme) | 미적용. BSD-3-Clause, 최근 활동 있음. 순공에는 중앙 토큰과 고정 프로토타입이 있어 전면 테마 교체 이득이 작다. 색상 검토 도구나 일부 예제 참고가 적절하다. |
| [fzyzcjy/flutter_smooth](https://github.com/fzyzcjy/flutter_smooth) | 미적용. MIT, 최근 활동은 있지만 공식 문서가 표준 stable 지원을 위한 framework/engine 작업을 설명한다. 고정 Flutter·카메라 구성과의 정확한 엔진 호환성부터 확인해야 한다. |
| [table_calendar](https://github.com/aleksanderwozniak/table_calendar) | 미적용. 기존 월간 플래너 대체 도입 이득부터 확인 |
| [OpenFace](https://github.com/TadasBaltrusaitis/OpenFace) | 미적용. 비상업 조건 때문에 상용 앱 코드 후보에서 제외 |
| [ONNX Runtime](https://github.com/microsoft/onnxruntime) · [OpenCV](https://github.com/opencv/opencv) | 모델/영상 도구의 하위 실행 의존 후보. 독립 기능으로 설치하지 않음 |
| [photo_view](https://github.com/bluefireteam/photo_view) | 미적용. 현재 InteractiveViewer 활용 우선, 유지 상태 재확인 |

## 출처·패키지·라이선스

- `flutter_calendar_view` 부분 차용 기준 commit `0cc89e4cf9b26d6154bb149c9e11f3a3dd360b55`; 정확한 파일 URL과 변경 설명은 `third_party/flutter_calendar_view/NOTICE.md`, MIT 원문은 같은 디렉터리 `LICENSE`. `core/legal/third_party_licenses.dart`를 bootstrap에서 등록해 앱 배포물의 LicenseRegistry에도 포함한다.
- 보안 저장: [Supabase Flutter 2.18.0 LocalStorage](https://github.com/supabase/supabase-flutter/blob/supabase_flutter-v2.18.0/packages/supabase_flutter/lib/src/local_storage.dart) 확장 API 사용. 기존 의존성의 API 연결이며 SDK 구현 복제 없음.
- Drift 조회 API와 Flutter `compute` API를 사용한 자체 구현. 예제 자산·로고·화면·전체 서비스 복사 없음.
- 새 Deno 의존성: `zod@4.6.6`(MIT), 테스트 전용 import `fast-check@4.10.2`(MIT), 전이 `pure-rand@8.0.0`(MIT). `deno.json` 정확 버전과 `deno.lock` integrity 기록. npm 공식 metadata와 tarball SHA-512를 대조하여 추가했으며 CI에서 다시 확인한다.
- `plpgsql_check`는 CI 테스트 DB 전용 extension. 공식 active-mode API를 호출하며 제품 DB migration에는 추가하지 않는다. 경고 및 checker_exception을 숨기지 않는 진단 단계이며 검토한 동적 record 2건 외 error/checker_exception은 CI를 실패시킨다. 기존 pgTAP도 계속 실행한다.
- 신규 Flutter 패키지 없음. 기존 `pubspec.lock` 버전 유지.

## 검증·한계

- 결과와 CI 링크: `docs/handoff/S14.md` 참조.
- 실기기 확인 필요: Android/iOS secure storage 이전/재설치/백업 복원/잠금 상태, PKCE 외부 로그인 복귀, 타임테이블 좁은 열 탭, 대용량 export UI 응답성과 메모리.
- 로컬 Flutter 실행은 클라우드 메타데이터 접근 시도가 자동 승인 검토에서 거절되어 중지했다. 이를 우회하지 않고 기존 GitHub Actions에서 검증한다.
- 로컬 Deno의 JSR/npm 직접 조회가 실패하여 테스트 실행 미완료. 공식 registry tarball 무결성 확인과 CI 실행 결과는 서로 구분한다.
- S09 PR #8의 설정·알림·개인정보 파일을 덮어쓰지 않았으며 병합 전 최신 main 재검토가 필요하다.
