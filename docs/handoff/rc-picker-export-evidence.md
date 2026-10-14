# RC picker·export 증거 대조표

2026-10-13. 신규 40개 시나리오 중 **PICK-01~10, EXP-01~10, REG-01의 21개**를 다룬다. 소스 대조 기준은 통합 `af495305133e3fe72913e8b7f06b3f564d93f75a`다. 원본 58개 판정과 합산하지 않는다. 기존 테스트 이름의 `PICK-*`/`EXP-*`는 종전 검토 번호일 수 있으므로 **아래 기대 동작을 기준으로 연결했다**. 예를 들어 기존 `EXP-05 cancellation ...`은 신규 EXP-01/02, 기존 `PICK-05 current selection ...`은 신규 PICK-01/02 근거다.

**21개 모두 최종 판정은 UNVERIFIED(최종 통합 CI 대기)**다. 아래의 이전 실행 결과는 확인한 부분 증거이며, 후속 수정 HEAD의 합격 판정이 아니다. 실제 OS picker/lost-data/수신 앱/실기기 kill은 별도 UNVERIFIED로 남는다.

## 확인한 실행과 증거 수준

PR HEAD `82b2fd505bb8e35ef2903ec0b2972aff12cc4a36`에 연결된 실행:

- [analyze-test 38341188635](https://github.com/byite-co/soongong/actions/runs/38341188635): codegen clean-tree, analyze, 금지 문구 gate 성공. 전체 Flutter **860 통과 / 3 실패**. 실패는 `DEL-02 explicit logout on unknown cleanup stays signed in and can retry`, `RC05-GAZE02 gaze and actual measurement share camera; blocked start adds no seated time`, `DEL-07 account deletion modal distinguishes acknowledged server deletion and retries only local cleanup`다. 이 실행을 전체 CI 성공으로 표기하지 않는다.
- [native-check 38341188853](https://github.com/byite-co/soongong/actions/runs/38341188853): Android dev Debug APK 성공. `OwnedImageStoreTest` XML은 **13 tests / 0 failures / 0 errors / 0 skipped**다. iPhone ARM64 dev Release(no-codesign) 빌드 및 **iOS Foundation 54 assertions** 성공.
- 같은 native 실행의 app share 테스트는 `packageDevDebugUnitTestForUnitTest`가 Flutter assets 작업 의존성을 선언하지 않아 **실행 전에 실패**했다. `OwnedShareBridgeTest` 3개를 통과 수에 넣지 않는다. 통합 `9e24cce`가 작업 의존성을 추가했으며 재실행이 필요하다.
- `af49530`에서 추가한 다음 export 진입/시작·foreground 만료 호출 검사는 위 실행 이후 작성됐다. 계정 modal/fixture 수정과 카메라 시작 시간 수정도 후속 CI 대기다. 최종 담당자는 PR HEAD/base/CI checkout SHA/tree SHA를 대조해야 한다. 이 문서는 PR merge-ref와 HEAD의 tree 동일성을 독립 확인한 증거가 아니다.

증거 수준:

- **FS**: 실제 host 임시 디렉터리·bytes·symlink 검사. 일부 root/write/delete 실패는 주입한다. 새 store 객체는 실제 프로세스 재시작이 아니다.
- **APP/UI**: 실제 Dart adapter/provider/화면을 실행한다. auth·서버·picker·MethodChannel 또는 지연 입력은 합성 경계다. 화면 테스트의 `ControlledImage` cleanup 횟수는 실제 디스크 삭제 증거와 구분한다.
- **ANDROID**: Robolectric에서 실제 소유권 helper, provider stream 복사, camera 파일 생성, FileProvider를 검사한다. `forgetProcess()`는 static 상태 재초기화이며 Android process kill/Activity 재생성 시험이 아니다.
- **IOS**: macOS에서 실제 Foundation 소유권 helper를 컴파일해 검사한다. orphan 사례는 별도 child process가 파일 생성 후 `_Exit(0)`한 실제 프로세스 경계다. UIKit/PHPicker/camera/Flutter 시작 scanner를 함께 실행한 end-to-end 검사는 아니다. 54는 assertion 수이며 테스트 함수 54개가 아니다.
- **BUILD**: 네이티브 컴파일/링크 성공. 설치·서명·실행·수신 앱 호환성의 증거가 아니다.

아래 약어는 정확한 소스 파일을 가리킨다.

| 약어 | 파일 |
|---|---|
| P | [owned_picker_coordinator_test.dart](../../test/unit/data/owned_picker_coordinator_test.dart) |
| C | [study_image_picker_test.dart](../../test/unit/data/study_image_picker_test.dart) |
| W | [transcription_race_test.dart](../../test/widget/transcription_race_test.dart) |
| E | [owned_share_adapter_test.dart](../../test/unit/data/owned_share_adapter_test.dart) |
| R | [export_race_test.dart](../../test/unit/data/export_race_test.dart) |
| T | [owned_temp_store_test.dart](../../test/unit/data/owned_temp_store_test.dart) |
| L | [temporary_lifecycle_overlap_test.dart](../../test/widget/temporary_lifecycle_overlap_test.dart) |
| A | [OwnedImageStoreTest.java](../../third_party/image_picker_android/android/src/test/java/io/flutter/plugins/imagepicker/OwnedImageStoreTest.java) |
| S | [OwnedShareBridgeTest.java](../../android/app/src/test/java/co/byite/soongong/OwnedShareBridgeTest.java) |
| I | [OwnedImageStoreTests.m](../../third_party/owned_native_tests/OwnedImageStoreTests.m) |
| G | [gaze_lab_lifecycle_test.dart](../../test/widget/gaze_lab_lifecycle_test.dart) |

## PICK-01~10

| ID | 기대값 | 연결한 검사명과 실제 단언 | 남은 조건 |
|---|---|---|---|
| PICK-01 | 취소·크기 초과·read 실패의 불필요 파일 제거, 이유 표시 | P `PICK-01/02 cancellation and read failure close owned file lifetime`: 취소 task 제거, 실제 파일 부재로 read 예외, 중복 cleanup 수렴. W `PICK-05 current selection $outcome retains normal behavior`의 success/oversize/cleanup error: cleanup 1회, 초과·정리 실패 문구, 미처리 예외 없음. | read 실패의 파일 정리와 UI 이유 검사는 서로 다른 fixture다. Android/iOS 실제 선택 취소·codec 실패는 DEVICE-01~03/06. |
| PICK-02 | 정상 완료/화면 종료 후 bytes·파일 수명 종료, 미처리 예외 없음 | W 위 정상 success 분기 및 `PICK-04 disposed screen ignores late bytes and still cleans`: dispose 후 늦은 bytes가 0으로 덮이고 cleanup 1회, widget 예외 없음. P의 실제 FS cleanup 검사, `PICK callback waits for its native writer before release`: active 상태가 끝난 뒤 release/cleanup. | widget bytes 덮어쓰기와 FS unlink를 물리 소거로 해석하지 않는다. 실제 camera writer 완료는 기기 확인 필요. |
| PICK-03 | 이전 성공·오류·finally가 새 사진/동의/문구/busy를 변경하지 않음 | W `PICK-01/02/03 late $failure after purge cannot change new selection`의 oversize/length/read/cleanup 4분기: 새 이미지·동의 유지, 오래된 오류 문구 없음, busy 종료, old cleanup 1회. A `delayedResolverCallbackCannotAcquireANewOwner`: 캡처된 이전 owner가 새 owner를 획득하지 못함. I의 이전 owner block 거부·새 payload 비어 있음 검사. | 합성 지연/owner 경계 증거다. 실제 OS 중복·지연 callback, OCR 모델의 늦은 응답은 별도. |
| PICK-04 | 동일 경로 재사용/route 중첩에서 현재 파일 오삭제 0회 | C `PICK-03 older same-path cleanup cannot delete newer selection`, `PICK-04 claims survive disposal and a new picker instance`: 오래된 cleanup 뒤 새 파일 보존, 새 cleanup 후 삭제. P `PICK-09 recovery precedes new picker and overlapping request is refused`: 실제 coordinator의 중첩 거부·active 파일 보존. | C는 유지된 legacy claim/test hook 회귀다. 현재 제품의 전용 task 경로와 coordinator 방어를 P/A와 함께 읽어야 한다. 실제 두 OS route 시험은 아니다. |
| PICK-05 | Android lost-data 없음/복수/예외의 단일 소비·명시 상태 | P `PICK-05 single joined recovery consumes $mode without reading or restoring bytes`의 none/multiple/exception: 동일 Future, lost 호출 1회, 새 pick 0회, 외부 원본 보존. `PICK-05 thrown recovery is explicit and retries without a new selection`: unavailable 후 명시 재시도. | ImagePicker는 대체했다. 실제 `retrieveLostData` 전달·Activity 재생성은 UNVERIFIED, DEVICE-01. |
| PICK-06 | A 선택→kill→B에서 A 표시·전송·저장 0회, 소유 파일 정리 | P `PICK-06/07 restart discards account A before B selection`: A 복구 파일 제거 후 B bytes만 반환. A `recoveredPreCallbackRootIsFencedAndCannotBecomeNextAccountResult`: 재초기화 뒤 이전 task fence·오래된 request code 차단. | P는 새 store 객체, A는 static 재초기화다. 실제 Android kill→B 로그인→화면/OCR/DB를 한 번에 관찰한 증거가 아니므로 DEVICE-02/05는 UNVERIFIED. |
| PICK-07 | 같은 계정 전체 삭제 전 세대의 복구 결과 사용 0회 | P `PICK-06/07 restart discards purged generation before B selection`: revoke된 이전 scope 제거. T `TMP-06 durable revocation survives interruption before deletion`: 독립 표식 뒤 새 store 회수. | 이전 삭제 세대 처리는 검사했으나 P의 새 선택 fixture는 B scope다. 실제 같은 계정 purge→OS lost-data 전체 흐름은 DEVICE-05. |
| PICK-08 | callback 전 고아 파일/lost-data 없음도 소유 루트에서 회수, tmp 전체 삭제 없음 | P `PICK-08 pre-callback orphan with no lost data is recovered only under reserved root`: marker 부재 orphan 회수, 다른 기능 bytes 보존. A `galleryCopyIsOwnedBeforeCallbackAndOriginalSurvives`, `realCameraTemporaryFileStartsInsideOwner`: 실제 생성 위치 확인. I child `_Exit(0)` 뒤 marker/사진 각 1개 발견·recover inactive. | I는 실제 child exit/발견 증거이며 Dart scanner의 기기 시작 회수와 분리된다. Android actual kill 및 iOS camera/PHPicker 종료는 DEVICE-02/03. |
| PICK-09 | 복구 선행·중첩 선택 거부/직렬화, 새 파일 보존 | P `PICK-09 recovery precedes new picker and overlapping request is refused`: 복구 대기 중 pick 0회, 중첩 throwsStateError, sweep 중 active bytes 유지. A `recoverCannotReleaseALiveWriter`, `blockedProviderCloseDoesNotBlockCancelOrPretendWriterStopped`: 살아 있는 producer를 완료로 표시하지 않음. | MethodChannel/OS lifecycle 실제 순서와 열려 있는 외부 camera FD의 종료는 UNVERIFIED. |
| PICK-10 | 외부 원본/다른 기능 결과 오삭제·잘못된 입력 0회 | P `PICK-10 out-of-scope original cannot become OCR input or be deleted`: 외부 반환 거부, 원본 bytes 보존. C `PICK-04 originals outside app cache are preserved`; A `symlinkCannotRedirectPayloadOrSourceFile`, `galleryCopyIsOwnedBeforeCallbackAndOriginalSurvives`. | 잘못된 반환은 합성 picker/provider다. 모호한 legacy 절대경로는 소유 파일로 승격하거나 삭제하지 않고 unknown으로 남긴다. |

## EXP-01~10

| ID | 기대값 | 연결한 검사명과 실제 단언 | 남은 조건 |
|---|---|---|---|
| EXP-01 | 생성/쓰기/OS 직전 계정·세대 변경이면 공유 0회·소유 파일 정리 | R `EXP-02/04 $cancel while encoding never shares`(dispose/purge started/purge completed), `EXP-03 provider A to B to A revokes old work and binds fresh export`, `EXP-05 actual action and adapter cancel $cancel during file write`, `EXP-05 cancellation after final validation prevents OS invocation`. E `EXP-01/02 account revoked during paused write never reaches OS and late bytes are cleaned`: 호출 0회·payload 제거. | 실제 provider/adapter와 합성 server/share 경계. OS sheet를 열린 상태로 A→B 전환하는 시험은 DEVICE-05. |
| EXP-02 | write 실패/인계 전 취소의 부분 파일 제거 또는 재시도 책임 | E `EXP-02/09 failed partial write keeps retry ledger and retry never shares`: 일부 bytes 쓴 뒤 throw와 삭제 실패 주입, `.delete`/payload 보존, 복구 후 두 sweep 수렴·share 0회. E의 paused write 취소 및 R의 cancelled write 격리 검사. | 실제 저장소 부족·보호 잠금 실패는 DEVICE-06. |
| EXP-03 | success/dismissed/unavailable에서 불확실성 유지·즉시 무조건 삭제 없음 | E `EXP-03/05 actual owned-share adapter retains $result for delayed reader` 3분기: native channel 호출 시 `.shared`가 이미 존재하고 결과 종류와 무관하게 23시간 bytes 보존, 24시간 회수. | 결과 문자열은 MethodChannel mock 값이다. 실제 bridge는 인계 시도 `handedOff`를 반환하며 수신 완료를 보장하지 않는다. 실제 공유 취소·unavailable은 DEVICE-04. |
| EXP-04 | 인계 호출 후 throw/timeout에도 잔여 원장 유지 | E `EXP-04 attempted share ${timeout ? 'timeout' : 'throw'} retains ambiguity ledger`: 실제 adapter에 실패/미완료 Future를 주입, `.shared`·bytes 유지, 이후 TTL 회수, 호출 1회. | timeout은 OS 작업 취소·외부 reader 종료의 증거가 아니다. |
| EXP-05 | 유예 내 지연 reader의 정상 읽기·성급한 TTL 삭제 없음 | T `EXP-05/06 delayed reader works within grace and expiry removes the owned copy`; E 위 3결과 분기: 23시간 host File 읽기 성공. S `receiverReadUsesOwnedSourceAndRevocationBlocksReopen`는 실제 provider stream 읽기 후 revoke 차단 검사로 작성됨. | S는 이전 CI에서 실행되지 않았다. host File 읽기를 실제 수신 앱 호환성으로 승격하지 않는다. DEVICE-04는 UNVERIFIED. |
| EXP-06 | 만료 후 시작/복귀/다음 export에서 소유 파일·사본 회수 | T 위 24시간 만료 회수. **후속 CI 대기**: E `EXP-06 next actual export expires the previous shared attachment`; L `DEL-08/EXP-06 startup foreground and privacy join one cleanup and preserve new tasks (export)`는 실제 share adapter/시작·resumed·privacy 진입을 통과해 옛 payload 제거·새 bytes 보존 검사. | L은 desktop-host 분기이며 native quiescence를 대체했다. Android/iOS 실제 시작 복구와 share 사본 부재/수신 앱은 DEVICE-02~04. |
| EXP-07 | 인계 직후 kill 뒤 소유 경로·원장 복구, 생성 시점 정책 유지 | T `EXP-07 restart recovers shared path and keeps creation-based expiry`; E `EXP-07/08 handoff kill and concurrent A/B same-name exports recover without cross deletion`: 새 store가 A revoke 후 B를 유예/만료 정책대로 처리. | 테스트 이름의 “kill”은 실제 process kill이 아니라 store 재생성 fixture다. 실제 OS 인계 직후 kill→재시작은 UNVERIFIED, DEVICE-04/05. |
| EXP-08 | 동시 A/B·같은 이름의 경로 격리, 교차 내용/삭제 0회 | T `EXP-08 concurrent same-name exports have isolated paths and cleanup`; E 위 A/B 분기. A `twoExportsHaveIndependentRootsWithoutCopyOrGlobalClear`와 I의 두 export task 경로·scope revoke 검사. S `twoDelayedAttachmentsRemainIndependentAndNoGlobalCacheIsMade`는 실제 Intent 두 번과 share_plus 폴더 부재 검사로 작성됨. | A 13/I 54에는 helper 경계만 포함한다. S 3개 실행 및 실제 수신 앱 동시 읽기는 아직 별도 증거가 필요하다. |
| EXP-09 | 정리 재시도는 재공유 0회, 파일 정리만 수행 | E `EXP-02/09 failed partial write keeps retry ledger and retry never shares`: 실패 후 두 번 sweep, share 호출 0회. T `TMP-04 failed deletion leaves evidence and joined retries converge`: 같은 Future 합류·멱등 회수. | R의 기존 `EXP-06 a failed share can retry with freshly encoded bytes`는 사용자가 export를 다시 요청하는 검사이며 **정리 전용 retry 근거가 아니다**. |
| EXP-10 | 시계 역행·재시작·활성 공유 고착에도 무기한 보관 없음 | T `EXP-10 wall-clock regression ends retention at the next sweep`; `EXP-10 frozen clock has bounded retention with release=$release` 2분기; `EXP-10 invalid future-expiry metadata is an owned orphan, not an indefinite lease`; `EXP-10 future creation without clock history cannot retain a file indefinitely`. 실제 host Stopwatch를 사용한 짧은 정책 fixture 포함. | 24시간은 제품 기본값이지 OS 수신 완료 보장 시간이 아니다. 앱 종료 중 정확히 만료 시각에 실행되지는 않는다. 물리 전원 손실/backup은 별도. |

## REG-01

| ID | 기대값 | 연결한 검사명과 확인 결과 | 남은 조건 |
|---|---|---|---|
| REG-01 | 기존 F-EXPORT/F-PICK/F-GAZE-CLOSE guard·시간 상한 유지 | F-EXPORT는 R의 encoding/write/마지막 동기 guard 및 A→B→A 회귀, F-PICK은 C/W의 같은 경로·이전 callback·dispose 회귀를 유지한다. F-GAZE-CLOSE는 G `stream stop has 2 s then native close has its own 2 s budget`, `failed camera CloseResult keeps the failure latch`, `native pending after clean camera release times out at 2 s`, `repeated stop, background, and dispose join the same close`, `a late camera open is bounded and blocks another route acquisition`를 연결한다. 해당 파일은 82b2fd5 전체 실행에 포함됐고 기록된 3개 실패 파일에 해당하지 않는다. | 같은 실행의 새 `camera_ownership_test.dart` GAZE02 검사는 seated time 51ms로 실패했으므로 카메라 경합 전체가 통과했다고 쓰지 않는다. `f5680ce`의 시작 시간 수정과 추가 회귀는 최종 CI 대기. host timeout/latch를 실제 OS camera 해제 증거로 쓰지 않는다. |

## 후속 판정 규칙

최종 같은 tree의 전체 Flutter 및 native 검사 결과로 위 자동 검증 상태를 갱신한다. 실패·skip·실행 전 차단을 구분하고, 하나의 native assertion 수를 21개 시나리오의 합격 수로 환산하지 않는다. 기존 경로 원장과 legacy uncertainty는 [EXT-FIX-02](EXT-FIX-02.md), [native 감사](../../third_party/OWNED_NATIVE_AUDIT.md)를 함께 읽는다. legacy export/picker의 소유 세대를 증명할 수 없으면 이름 접두사만으로 삭제하거나 새 계정에 귀속하지 않으며, unknown을 잔여 0개로 보고하지 않는다.

실기기 Activity 재생성, 실제 process kill, iOS PHPicker/camera, 수신 앱 지연 읽기, 원본 보존, storage failure, backup/restore는 [DEVICE 절차](EXT-FIX-02-DEVICE.md)의 별도 UNVERIFIED다. 이미 열린 외부 FD/외부 앱 사본 강제 회수나 물리 보안 소거를 보장하지 않는다. 이 문서는 병합·배포·공개 활성화 승인이 아니다.
