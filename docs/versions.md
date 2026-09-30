# 버전 고정 (D12) — S01 기준

| 항목 | 값 | 고정 위치 |
|---|---|---|
| Flutter | **3.47.5** (stable, 2026-09-17, revision `6a19cca564`) | `.fvmrc` · `pubspec.yaml environment.flutter` · CI `subosito/flutter-action` `flutter-version` |
| Dart | **3.13.4** | `pubspec.yaml environment.sdk: '>=3.13.4 <4.0.0'` |
| DevTools | 2.60.0 | (Flutter 번들) |
| Android Gradle Plugin | 9.1.0 | `android/settings.gradle.kts` |
| Kotlin | 2.4.0 | `android/settings.gradle.kts` |
| Gradle | 9.3.1 | `android/gradle/wrapper/gradle-wrapper.properties` |
| JDK (CI) | 17 (Temurin) | `.github/workflows/*.yml` |
| Java 소스 호환 | 17 | `android/app/build.gradle.kts` |
| Pretendard | 1.3.9 Variable (OFL-1.1) | `assets/fonts/` |

패키지 버전은 `pubspec.lock` 이 원본이다(커밋). `flutter pub upgrade` 는 별도 작업(PR)으로만 한다.

## 주요 패키지 (S01 설치 시점)

| 패키지 | 버전 제약 | 용도 |
|---|---|---|
| flutter_riverpod / riverpod_annotation / riverpod_generator | ^3.4.3 / ^4.0.7 / ^4.0.9 | 상태 (codegen) |
| go_router | ^18.0.2 | 라우팅 |
| freezed / freezed_annotation | ^4.0.2 / ^3.1.0 | 모델 |
| json_serializable / json_annotation | ^6.14.1 / ^4.12.0 | JSON |
| drift / drift_dev / drift_flutter | ^2.35.0 / ^2.35.0 / ^0.3.1 | 로컬 DB (sqlite3 native assets) |
| supabase_flutter | ^2.18.0 | 백엔드 |
| purchases_flutter | ^10.13.2 | RevenueCat |
| camera / google_mlkit_face_detection | ^0.12.1 / ^0.15.1 | 착석 감지 (S04) |
| flutter_local_notifications | ^22.3.1 | 알림 |
| intl / uuid / logger / path_provider / share_plus / file_picker / image_picker | 최신 | 유틸 |
| flutter_secure_storage | ^11.2.0 | deviceId 보관 [S01 추가] |
| lucide_icons_flutter | ^3.1.20 | Lucide 아이콘 [S01 추가] |
| sensors_plus | ^7.1.0 | dev 메뉴 셰이크 [S01 추가] |
| build_runner | ^2.16.1 | codegen |
| flutter_lints / riverpod_lint | ^6.0.0 / ^3.1.9 | 린트 (riverpod_lint는 analysis_options.yaml `plugins:`로 설치되는 analyzer 플러그인) |

## 로컬 개발

```sh
fvm use            # .fvmrc → 3.47.5
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze && dart run tool/check_forbidden_phrases.dart && flutter test
```

업데이트 절차: Flutter/Dart 버전 변경은 `.fvmrc` · `pubspec.yaml` · CI 워크플로 · 이 문서를 한 PR에서 함께 바꾼다.
