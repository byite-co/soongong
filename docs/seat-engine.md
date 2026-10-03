# 착석 감지 엔진 (S04 · S04b · S04c · S04d) — 기술 선택 · 구현 · 측정 프로토콜

작성 2026-10-01 · S04b 보완 2026-10-03 · S04c 보완 2026-10-03 · S04d 보완 2026-10-03 · 브랜치 `ccr-d3a4cdaa-goy1d8` · 계약 `core/contracts/seat_engine.dart`(S01 · **S04c CONTRACT-CHANGE**: `SeatSample.receivedAt/sinceStart`, `SeatPaused`) · 결정 D3 · D23

이 문서는 세 가지를 담는다. (1) 검출기 선택 스파이크의 비교표와 선택 이유, (2) `SeatEngineImpl` 의 동작 규약(S06 이 의존하는 이벤트 의미), (3) 실기기 측정 프로토콜과 목표치. 측정 결과 기록 칸은 `docs/handoff/S04.md` 에 있다(사람이 채움).

## 1. 범위

- 출력은 **착석 불리언 1초 주기 + 카메라 상태 이벤트** 뿐이다. 얼굴 식별·표정·시선·점수·bbox 좌표는 만들지도, 읽지도 않는다(D3, CLAUDE.md §1·§9).
- 이탈 판정(60–90초, 감도 0·1·2)은 S06 `AwayPolicy` 의 몫이다. 엔진 안의 시간 논리는 **3초 유지 창(히스테리시스)** 하나뿐이다.
- 카메라 프레임은 플러그인 콜백 안에서 검출기로 넘기거나 버린다. 디스크·메모리 보관·전송 없음(§4.4 검증 방법).

## 2. 기술 선택 스파이크

### 2.1 후보 비교

클라우드 세션에서는 실기기 측정이 불가능하므로 아래 "처리 시간·유지율" 열은 **공개 문서·모델 특성에 근거한 기대치**이며, 실측은 §5 프로토콜에서 `/_seat_lab` 으로 한다. 실측이 기대치와 어긋나면 §2.3 의 전환 조건을 따른다.

| 기준 | A. ML Kit Face Detection (fast) **[선택]** | B. ML Kit Pose Detection (base) | C. MediaPipe Tasks (Face/Pose) |
|---|---|---|---|
| Flutter 플러그인 | `google_mlkit_face_detection` 0.15.1 (이미 의존성, 활발) | `google_mlkit_pose_detection` (같은 저자, 활발) | 공식 Flutter 플러그인 없음 → 양 플랫폼 채널 직접 구현·유지 |
| 프레임당 처리(320×240, 중급 기기, 기대치) | **수 ms~20 ms** (fast 모드, 랜드마크·분류 OFF) | 30–60 ms (BlazePose 상반신+전신 33점, 모델 크기 수 MB) | A·B 와 유사하나 네이티브 통합 비용이 큼 |
| 입력 데이터 최소성 | 얼굴 bbox 존재 여부만 사용(좌표 미사용) | 신체 랜드마크 33점 — 필요 이상으로 많은 신체 정보를 계산 | 동일 |
| 고개 숙임(필기 자세) | 정면 대비 떨어짐. 짧은 미검출은 3초 유지 창으로 흡수, 긴 숙임은 측정 항목 P2 | 상반신 랜드마크로 **강함** | 동일 |
| 측면 | 정면에서 벗어날수록 fast 모드 검출이 약해짐(플러그인 문서: Euler Y 각은 accurate 모드에서만 보장) — 측정 항목 P3 | 강함 | — |
| 저조도 | 전면 카메라 노이즈에 민감. 해상도 최저·자동 노출에 의존 | 비슷 | — |
| 음성 케이스(포스터·사진 속 얼굴) | 얼굴이면 검출됨 → `minFaceSize` 로 먼 얼굴 배제, 실험실에서 0.10/0.15/0.20 비교 | 포스터 "사람" 도 검출 가능 | — |
| 배터리 | 가장 가벼움 | 모델이 무거워 불리 | — |
| 바이너리 증가 | 소(이미 포함) | 중(모델 번들/다운로드) | 중 |

### 2.2 선택: A (ML Kit Face Detection, fast, presence only) + 3초 유지 창

- PRD §8 의 1초 주기·배터리 ≤ 8%/h 에 가장 유리하고, 계산되는 정보가 "얼굴 bbox 존재" 로 가장 적다(개인정보 표면 최소).
- 고개 숙임 약점은 (1) 유지 창 3초, (2) 이탈 임계 60–90초(S06) 두 겹으로 완충된다. 10분 필기 중 3초 넘는 미검출이 1분 이상 연속되어야 이탈 오판이 난다.
- 플러그인이 이미 의존성에 있어 새 네이티브 코드가 없다(MediaPipe 는 유지보수 부담으로 제외).

### 2.3 전환 조건(후속 결정 후보)

- `/_seat_lab` 실측에서 **P2(고개 숙임) 검출률 < 90%** 또는 **P3(측면) < 80%** 가 재현되면 검출기를 B(Pose, 상반신 랜드마크 존재 여부만)로 바꾼다. 교체 지점은 `PresenceDetector` 하나(`lib/data/engines/seat/seat_frame_source.dart`) — 엔진·히스테리시스·하니스는 그대로다.
- 렌즈 가림(N7)과 빈 자리를 구분해야 하면 프레임 평균 휘도 기준 `cameraLost` 판정을 `CameraSeatFrame` 단계에 추가한다(지시문 §4.5 의 후속 결정 항목).

## 3. 구현

### 3.1 파이프라인

```
camera 플러그인(전면 · ResolutionPreset.low · NV21/BGRA · fps 15, 저전력 10 · 오디오 OFF)
  └ CameraFrameSource.open() → SeatCameraHandle(이 run 의 컨트롤러) · onFrame(frame)  ← 콜백 안에서만 유효
      └ SeatEngineImpl._onFrame
          ├ 프레임 도착 기록(워치독) · 쓸 검출기 확보(폐기됐으면 새로 생성, 상한이면 무시) · Lost 상태면 Recovered 발행
          ├ FrameCadence.accept  — 주기(1000ms/sampleHz, 저전력 2000ms) 미도달 또는 검출 진행 중이면 **동기 드롭**
          └ PresenceDetector.detect(frame)       ← ML Kit fast, faces.isNotEmpty 만 읽음
              └ SeatHysteresis.observe(at, detected) → seated
                  └ samples.add(SeatSample(receivedAt: wall, sinceStart: mono − start() 호출 시각, seated))  (confidence 는 null)
```

| 파일 | 역할 |
|---|---|
| `lib/data/engines/seat_engine_impl.dart` | 계약 구현. 가용성·시작/정지(run 토큰·세대·종료 순서, §3.6)·검출기 교체(§3.7)·워치독·라이프사이클·이벤트. 진단 스트림(`diagnostics`)·`lastStopReport` 는 실험실 전용 |
| `seat/work_generation.dart` | S04b. `WorkGeneration`(세대 번호) + `InferenceGate`(진행 중 추론 1건의 세대 게이트). 순수 Dart |
| `seat/seat_frame_source.dart` | 추상화: `SeatFrame`·`SeatFrameSource`(`open()` → `SeatCameraHandle`)·`PresenceDetector`·`PresenceDetectorFactory`·`CameraPermissionGateway`·`LifecycleSource` |
| `seat/camera_frame_source.dart` | `camera` 플러그인 어댑터. 전면 카메라 선택, 프로브(점유 판정), `open()` 마다 컨트롤러 1개를 핸들로 반환(S04d), 플러그인 오류 → `CameraFault` |
| `seat/mlkit_face_presence_detector.dart` | ML Kit 어댑터 + `inputImageFromCamera`(NV21/BGRA 단일 평면만) |
| `seat/seat_hysteresis.dart` · `seat/frame_cadence.dart` · `seat/seat_availability.dart` · `seat/camera_geometry.dart` | 순수 Dart(유닛 테스트) |
| `seat/camera_permission.dart` | `CameraPermission.request()/status()/openSettings()` (permission_handler) |
| `seat/widgets_binding_lifecycle_source.dart` | 백그라운드 감지 |

### 3.2 S06 이 의존하는 규약

- **`checkAvailability()`**: 권한 상태 확인 → 미결정이면 **프롬프트를 띄운다**(이미 거부/영구 거부/제한이면 띄우지 않음) → 하드웨어·점유 프로브(카메라를 잠깐 열고 닫음, Android 는 열린 뒤 600 ms 안의 "in use" 오류를 봄) → `ok · permissionDenied · cameraBusy · unavailable`. 온보딩에서 `CameraPermission.request()` 를 먼저 호출했다면 프롬프트는 다시 뜨지 않는다.
- **`start(config)`**: 프롬프트 없음. 호출 즉시 **run 토큰**을 만들고 그 순간이 `sinceStart` 의 0 이다(카메라를 열기 전, S04d §3). 진입 즉시 라이프사이클을 구독하고 현재 상태를 본다 — 앱이 이미 백그라운드면 카메라를 열지 않고 `SeatPaused(backgroundDuringStart)`. 권한이 없으면 `SeatError('permission_denied')`. 쓸 검출기가 없으면(폐기된 검출기 2개가 아직 돌아오지 않음, §3.7 (b)) 카메라를 열지 않고 `SeatError('detector_failed')`. 카메라를 못 열면 `SeatError(code)` — 코드는 `permission_denied · no_camera · camera_busy · camera_init_failed · camera_init_timeout`(8초, §3.7). 열리는 도중 백그라운드로 가면 열린 카메라를 다시 해제하고 `SeatPaused(backgroundDuringStart)`. 성공하면 `isRunning == true`. 재호출은 무시(멱등). 호출마다 **세대가 +1** 된다(§3.6). 카메라 핸들은 그 run 에 귀속되고(S04d §1), 이전 run 의 정리(늦은 open 의 해제·카메라 해제·늦은 추론)가 아직 백그라운드에서 끝나지 않았어도 새 run 의 `start()` 는 허용된다 — 이전 run 의 카메라가 뒤늦게 열려도 자기 핸들만 닫고 새 run 의 카메라·스트림은 건드리지 않는다.
- **`stop()`**: 실행 중이면 즉시 펜스(새 프레임 거부·세대 +1) → 이 run 의 카메라 해제(**최대 2초**) → 진행 중 추론 대기(**최대 500 ms**) → 반환. 즉 최대 약 **2.5초** 안에 돌아오며, 상한을 넘긴 해제·추론은 백그라운드에서 끝난다(`SeatStopReport.cameraReleaseTimedOut · inferenceTimedOut`). **카메라가 아직 열리는 중이면(S04d §6a) run 토큰을 취소하고 즉시 반환**한다 — 열리던 카메라는 도착하는 순간 자기 핸들로 백그라운드 해제되고, 그 `start()` 는 이벤트 없이 끝난다(8초 상한은 그대로). 펜스 뒤에 돌아온 결과는 기다렸든 아니든 버린다 — `stop()` 이후 샘플·이벤트는 오지 않는다. 검출기는 닫지 않고 재사용한다(닫는 것은 `dispose()` 또는 폐기 — 추론 도중에는 절대 닫지 않고, 폐기된 검출기는 자기 호출이 돌아올 때 닫는다. 영원히 돌아오지 않는 검출기는 끝내 닫지 않는다).
- **`samples`** (CONTRACT-CHANGE S04c, 기준점 S04d): 처리된 프레임마다 1건(기본 1초, `sampleHz` 는 1–2 로 클램프, `lowPower` 는 2초). `SeatSample.sinceStart` = **`start()` 를 호출한 순간**부터 촬영 시점까지의 단조 경과 시간(Stopwatch 기반, 카메라 여는 시간을 포함, 실행마다 0 부터), `receivedAt` = 같은 순간의 벽시계(정보용). 샘플의 위치는 **`sinceStart` 로만** 정한다: `start()` 직전에 잡은 벽시계 1개(`runStartedAt = clock.now()`) + `sinceStart`. 카메라가 5초 걸려 열리면 첫 샘플의 `sinceStart` 는 5초 이상이고, 백그라운드 뒤 다시 `start()` 하면 복귀 첫 샘플은 중단 구간 뒤에 놓인다(테스트 고정). 기기 시각이 ±1시간 바뀌어도 `sinceStart` 의 단조성·구간 길이·60/75/90초 임계는 변하지 않는다(테스트 고정). **카메라가 끊긴 동안은 샘플이 없다**(판정 없음 = D23 의 paused).
- **`SeatPaused(reason)`** (CONTRACT-CHANGE S04c): 앱이 포그라운드를 벗어나 엔진이 스스로 멈추고 카메라를 해제했다(`background` = 실행 중, `backgroundDuringStart` = 열리는 도중/시작 시점). 복귀 후 `start()` 는 호출자 책임이며, 다음 실행의 첫 프레임이 `SeatCameraRecovered` 를 낸다. `SeatPaused` 를 받았는데 앱이 이미 포그라운드면(열리는 도중에 잠깐 나갔다 온 경우) 바로 `start()` 를 다시 부르면 된다.
- **`SeatCameraLost`**: (1) 실행 중 3초간 프레임 없음, (2) 플러그인이 점유·치명·정책 오류를 보고, (3) 판정할 검출기가 없음(무응답으로 폐기된 검출기 2개가 아직 돌아오지 않음, S04d §2 — 카메라는 돌지만 판정 불가). 백그라운드 진입은 S04c 부터 `SeatPaused` 다. Lost 시점에 진행 중이던 추론은 **무효화**된다(S04c §1): 끊긴 스트림 위의 판정은 발행하지 않는다. 사유는 `lastLostReason`(진단) 으로 본다.
- **`SeatCameraRecovered`**: Lost 또는 Paused 이후 **판정 가능한 첫 프레임**이 오면 1회(검출기 고갈 Lost 는 새 검출기를 만들 수 있게 된 뒤의 첫 프레임). 그 사이에 stop/start 가 있었는지와 무관하다(자가 복구·재연결·백그라운드 복귀 모두 같은 경로). `SessionTimeline.resume` 은 paused 가 아니면 무시하므로 중복 호출은 무해.
- **`SeatError('detector_failed')`**: (1) 검출기가 예외로 3회 연속 실패하면 1회(카메라는 계속 돌고, 성공이 끼면 다시 센다), (2) 무응답으로 폐기한 검출기가 2개 쌓여 새 검출기를 만들 수 없을 때 1회 + `SeatCameraLost`(S04d §2), (3) 그 상태에서 `start()` 를 부르면 실행하지 않고 1회. 복구는 새 검출기로만 — 매달린 호출 하나가 돌아오면 다음 프레임(또는 다음 `start()`)이 새 검출기를 만든다.
- **`previewOrNull()`** 은 항상 `null`(측정 화면은 상태 아이콘만).
- **`SeatSample.confidence`** 는 `null`. ML Kit 는 검출 신뢰도를 주지 않으며 지어내지 않는다.
- 감도(0·1·2)는 `SeatEngineConfig` 에 없다. 유지 창 N초를 S06 이 바꾸려면 `CONTRACT-CHANGE` 로 조율(현재 `SeatEngineImpl(hold:)` 생성자 인자로만 노출).

### 3.6 세대 · 종료 순서 · 시각 분리 (S04b, focus-engine 선별 참조)

`byite-co/focus-engine`(main `9b090ab`)의 `WorkGeneration` · `AnalysisGate` · `StopSequence` · 시간 기준(Timebase) **설계만** 참조해 Dart 계약에 맞게 다시 구현했다(코드 복사 없음). 엔진의 출처(검출기 A = ML Kit Face)는 그대로다.

| 항목 | focus-engine 설계 | `SeatEngineImpl` 구현 |
|---|---|---|
| 세대(WorkGeneration) | 작업 시작 시 세대 포착, 종료 타임아웃에 bump, 세대가 다르면 결과 미게시 | `start()` 마다 run 토큰 + `InferenceGate.open()` 으로 +1. 카메라 콜백(프레임·오류)은 열 때의 세대를 들고 오고, 추론 결과는 시작 세대가 현재 세대일 때만 `samples`·`events`·`diagnostics` 에 반영. `stop()` 도 +1(펜스). 카메라 핸들은 run 에 귀속(S04d) |
| 게이트(AnalysisGate) | begin/end/cancel, 억제 건수 | `InferenceGate.begin()`(닫혀 있으면 null → 아무것도 게시 안 함) · `end(gen)`(현재 세대일 때만 true) · `cancel()`(닫고 +1, 진행 중 여부 반환). `suppressedResults` 로 폐기 건수 노출 |
| 종료 순서(StopSequence) | 입력 중단 → 펜스 → 분석 스레드 대기(500 ms, 초과 시 bump) → Pose 대기(500 ms) → 큐 drain → 펜스 시각에 finish | ① 펜스(`isRunning=false`, 게이트 cancel) ② 카메라 해제 ③ 진행 중 추론 ≤ 500 ms 대기 → `SeatStopReport(hadInFlight · inferenceWait · inferenceTimedOut · suppressedResults)`. 늦은 결과는 게이트가 버린다 |
| 추론 중 close 금지 | 워커가 실행 중 run 이 돌아온 뒤 스스로 landmarker 를 닫음 | `dispose()` 는 추론이 진행 중이면 `detector.close()` 를 미루고, 돌아온 추론이 닫는다. 추론 도중 close 호출 0 |
| 시각 분리(Timebase) | raw 촬영 timestamp 가 프레임의 정체성, 처리 시각은 별도 | `SeatSample.receivedAt`(촬영 벽시계, 정보용) + `sinceStart`(start 기준 단조 경과; S04c 전에는 `at` 하나) — 배치는 `sinceStart` 로만. `SeatDiagnostic.capturedAt/completedAt`(단조) + `latency` 는 실험실 전용. 유지 창 3초도 촬영 시각 기준 |
| 종료 무결성(StopIntegrity) | drain 미완·늦은 결과가 있으면 세션 비교 불가 | 실험실: 비정상 종료 구간(엔진 자체 정지·끊긴 채 종료·오류·추론 대기 초과)은 **요약에서 제외 표시**, CSV 에는 `excluded=1` 로 남김(§4) |

재시작 경합(`stop()` → `start()` 사이에 이전 세대의 결과가 도착)은 `test/unit/engines/seat_engine_s04b_test.dart` 가 고정한다: 이전 세대의 `seated=true` 결과가 새 세션(`seated=false`)에 섞이지 않고 `suppressedResults` 로만 센다.

S04c 추가(`seat_engine_s04c_test.dart`): `InferenceGate` 의 티켓은 (세대, epoch, 시작 시각)이다. **Lost** 는 epoch 를 올려 진행 중 추론을 무효화하고 슬롯을 비운다(실행은 계속, 복귀 뒤 프레임은 새 티켓). 발행 조건 = 티켓의 세대·epoch 가 현재 && `!lost` && `running`. **start() 중 라이프사이클**: 진입 즉시 구독 → 이미 백그라운드면 열지 않음 → `open` 뒤 재확인(열리는 동안 백그라운드 이벤트가 왔거나 현재 상태가 백그라운드) → 해제 + `SeatPaused(backgroundDuringStart)`.

S04d 추가(`seat_engine_s04d_test.dart`): **open 소유권** — `start()` 마다 run 토큰(`_Run`: 호출 시각·세대·카메라 핸들·취소/백그라운드 플래그)을 만들고, `SeatFrameSource.open()` 이 돌려준 `SeatCameraHandle` 은 그 run 에만 속한다. 8초 상한을 넘겨 뒤늦게 열린 카메라, `stop()` 이 취소한 run 의 카메라, 라이프사이클로 중단된 run 의 카메라는 모두 **자기 핸들만** 닫는다(`CameraFrameSource` 도 `open()` 마다 컨트롤러 1개를 핸들로 반환 — 소스 전역 `_controller` 없음). 테스트: 첫 open 이 미완료인 채 두 번째 `start()` 가 성공한 뒤 첫 open 이 완료되면 첫 컨트롤러만 dispose 되고 새 run 의 스트림은 그대로다. **검출기 교체** 는 §3.7 (b). **sinceStart 기준점** 은 `start()` 호출 순간(§3.2). **초기화 중 stop()** 은 §3.7 (c).

### 3.7 무응답 상한 (S04c §3)

| 경로 | 상한 | 초과 시 | 뒷정리 |
|---|---|---|---|
| (a) 카메라 열기 — `checkAvailability` 프로브 | 8초(`openTimeout`) | 즉시 `SeatAvailability.unavailable`, `lastAvailabilityReason = 'timeout'` | 프로브의 컨트롤러 dispose 는 소스 안에서 2초 상한(`CameraFrameSource.disposeTimeout`), 초과분은 로그만 |
| (a) 카메라 열기 — `start()` | 8초 | 즉시 `SeatError('camera_init_timeout')`, 실행 안 함, 세대 취소 | 늦게 열린 카메라는 도착 즉시 백그라운드에서 해제(`unawaited`, 2초 상한, 실패 로그). 그 세션의 콜백은 세대가 달라 무시 |
| (b) 추론 — 검출기 무응답 (S04d §2) | 2초(`InferenceGate.deadline`) | 워치독(1초 주기)이 슬롯 해제·epoch +1·`inferenceTimeouts`+1 하고 **그 검출기를 폐기 표시**(더 이상 제출 없음) → **새 검출기를 만들어 계속**(`detectorReplacements`+1). 폐기됐지만 돌아오지 않은 호출(`stalledDetections`)이 **2개**(`stalledDetectionLimit`)면 새 검출기를 만들지 않고 `SeatError('detector_failed')` + `SeatCameraLost(detector exhausted)` — 이후 프레임은 제출 없이 무시(60초 공급 테스트: 미완료 ≤ 2 · 새 제출 0 · Lost 1회) | 늦게 돌아온 결과는 세대/epoch 불일치로 폐기. 폐기된 검출기는 자기 호출이 돌아오는 순간 닫힌다(추론 도중 close 금지 유지). 돌아오면 미완료가 줄어 다음 프레임(또는 `start()`)이 새 검출기를 만들고 `SeatCameraRecovered`. 영원히 돌아오지 않는 검출기는 끝내 닫지 않는다(`dispose()` 도) |
| (c) `stop()` — 실행 중 | 카메라 해제 2초 + 추론 500 ms ≈ **2.5초** | 반환하고 초과분은 백그라운드(`SeatStopReport.cameraReleaseTimedOut · inferenceTimedOut`) | 새 run 의 `start()` 는 이전 정리 완료와 무관하게 허용 |
| (c′) `stop()` — 카메라 여는 중 (S04d §6a) | **즉시 반환**(대기 없음) | run 토큰 취소 · 세대 +1 · 라이프사이클 해제 | 열리던 카메라는 도착 즉시 자기 핸들로 백그라운드 해제(2초 상한·로그). 그 `start()` 는 open 완료(또는 8초 상한)에 이벤트 없이 끝난다. 그 사이의 새 `start()` 는 새 run 으로 진행 |
| (d) 늦은 open 의 소유권 (S04d §1) | — | (a)·(c′)·라이프사이클 중단으로 끝난 run 의 카메라가 뒤늦게 열리면 그 run 의 핸들만 닫는다 | 현재 run 의 컨트롤러·스트림 무영향(`CameraFrameSource` 는 핸들마다 컨트롤러 1개) |

실측값(워치독 주기 1초 때문에 (b) 는 최대 3초)은 `/_seat_lab` 의 "폐기된 늦은 결과·추론 대기 초과" 수치로 본다.

**도입하지 않은 focus-engine 항목(의도적)** — D23·PRD 와 충돌한다.

| focus-engine 항목 | 미도입 이유 |
|---|---|
| 7상태 판정(PHONE · ABSENT · PRONE · SLEEP · AWAY · INVALID · PAUSED 등 초당 상태·점수) | 순공 엔진 출력은 착석 불리언 + 카메라 상태뿐(D3). 평가·점수 없음(CLAUDE.md §1) |
| 30초 확정 버퍼(저움직임 30초 등 N초 연속 버킷 확정) | 이탈 확정은 S06 `AwayPolicy` 60·75·90초(D23) 하나뿐. 엔진 안의 시간 논리는 3초 유지 창만 |
| 백그라운드 포그라운드 서비스(`CaptureService`, 화면 꺼짐 중 측정) | 화면 꺼짐·백그라운드는 측정이 아니라 `paused`(D23). 엔진은 백그라운드에서 스스로 멈춘다 |
| MediaPipe Face/Pose Landmarker 경로(478 랜드마크·blendshape·IMU) | 얼굴 특징·랜드마크를 계산하지 않는다(§1). MediaPipe 는 실기기 결과가 §6 목표에 미달할 때 **ML Kit Pose 와 함께 비교 후보로만** 기록(§2.3) |

### 3.3 저전력 모드(`lowPower`)

- 처리 주기 2초, 카메라 목표 fps 10(플러그인 `fps` → CameraX target frame rate / AVFoundation activeVideoMinFrameDuration, 기기가 지원하는 범위에서 best effort).
- 해상도는 플러그인 최저 프리셋(Android 320×240 bound, iOS 352×288)이 하한이라 더 내리지 못한다.
- S06 사용 조건(지시문 §4.3): 배터리 20% 이하 또는 설정에서 선택.

### 3.4 플랫폼 메모

- **Android**: `CAMERA` 권한 + `uses-feature camera/camera.front required=false`. CameraX 가 액티비티 라이프사이클에 묶여 있고 엔진도 `hidden` 에서 즉시 스트림 중단·dispose 하므로 포그라운드 없이 스트림이 유지되지 않는다. 다른 앱 점유는 `CameraState` 오류("already in use")로 와서 Lost 로 매핑된다.
- **iOS**: `NSCameraUsageDescription` = "자리에 앉아 있는지만 기기 안에서 판단합니다. 영상은 저장·전송되지 않습니다." `camera_avfoundation` 은 세션 인터럽션(전화·다른 앱)을 Dart 로 노출하지 않는다 → 프레임이 멈추고 **3초 뒤 Lost** 로 나타난다. 따라서 iOS 에서 `checkAvailability` 는 점유를 `cameraBusy` 로 구분하지 못하고 `ok` 를 돌려줄 수 있다(프로토콜 (b) 에서 Lost 발생 여부로 판정).
- **permission_handler 12.x**: iOS 는 Swift Package Manager 경로에서 `Info.plist` 의 `NSCameraUsageDescription` 존재로 카메라 권한 코드를 컴파일에 포함한다(Podfile 매크로 불필요). 13.x 는 `permission_handler_android` 14(compileSdk 37) 를 끌어와 Flutter 3.47.5 기본(36)과 어긋나므로 보류(`docs/versions.md`).
- 컨테이너에서 Android Gradle 검증 불가(`google()` 차단) — `build-android` 워크플로로 확인.

### 3.5 프레임 비보관 검증

```sh
grep -rn "writeAsBytes\|toImage\|toByteData\|takePicture\|startVideoRecording\|XFile" lib/data/engines lib/core/dev/seat_lab
grep -rn "boundingBox\|landmarks\|headEuler\|trackingId\|contours" lib/data/engines
```

두 명령 모두 주석 외 결과 0 이어야 한다(2026-10-01 기준 0). `appLog` 에는 코드·횟수·플러그인 오류 문구만 남기고 프레임·좌표는 남기지 않는다.

## 4. 측정 하니스 `/_seat_lab`

dev flavor + `DEV_MENU=true` 에서만 컴파일된다. dev 메뉴(흔들기) → "착석 감지 실험실 열기", 또는 라우트 `/_seat_lab`. 하니스는 provider 의 엔진이 아니라 **자기 엔진 인스턴스**를 만든다(진단 스트림·`minFaceSize` 변경 때문).

| 영역 | 내용 |
|---|---|
| 상태 | 대기 / 시작 중 / 실행 중(착석 · 미검출 · 샘플 없음) / 카메라 끊김 · 최근 프레임 검출 여부 · 유지 창 적용 여부 |
| 수치 | 경과(현재 구간) · 처리/전달 프레임 · 드롭 · 처리 주기 · 검출률(60초) · 착석 비율(60초) · 평균 지연(60초) · 이 실행 배터리(시작 측정 → 종료 측정, 실행 중에는 → 최근 읽음) · 60분 연속 배터리 측정 유효 여부(사유) · 이벤트 수 · 정답 대비 집계(전체 · **이 실행** · **케이스별**) · 구간 수(제외 수) · 제외된 샘플 · 폐기된 늦은 결과 · 검출기 교체 · 미완료 추론(폐기된 검출기) · 마지막 종료(정상/비정상 · 사유) |
| 제어 | 가용성 확인 · 권한 요청 · 설정 열기 · 시작/정지 · CSV 내보내기(범위: 전체 / 이 실행 / 이 케이스) · 기록 지우기 |
| 정답 라벨 | 실제 착석 / 실제 이탈 / 표시 안 함 — 변경 이력(시각 순)으로 보관하고, 샘플에는 **촬영 시각**에 유효하던 값을 붙인다(S04c). 추론 중에 라벨을 바꿔도 그 전에 찍힌 프레임은 옛 라벨로 채점된다. 케이스도 같다 |
| 실험 설정 | 저전력 · `minFaceSize`(0.10/0.15/0.20, 정지 상태에서만) · 프로토콜 케이스(P1–P4 · N1–N10) |
| 이벤트 | 최근 10건(`start · stop · cameraLost · <사유> · cameraRecovered · paused · <사유> · error: <code> · self-stop`) — Lost 의 사유는 엔진의 `lastLostReason`(`frame timeout · inUse · … · detector exhausted`) |

CSV 열(S04b): `t_ms,kind,segment,excluded,detected,seated,held,completed_ms,latency_ms,truth,battery,case,note`
- 시간 기준은 실험실과 엔진이 **같은 단조 시계**를 쓴다(화면을 연 시점 = 0).
- `kind=sample` 처리 프레임 1행: `t_ms` = **촬영 시각**, `completed_ms` = 추론 완료 시각, `latency_ms` = 그 차이, `detected`(검출기 원답) · `seated`(엔진 출력) · `held`(유지 창 때문에 seated)
- `segment` = 시작→정지 구간 번호, `excluded` = 그 구간이 비정상 종료(`stop · abnormal · 사유`)면 1. 제외 구간의 행은 CSV 에 남지만 화면 요약(검출률·착석 비율·지연·정답 대비)에서는 빠진다. 사유: 백그라운드로 엔진이 멈춤 · 카메라 끊긴 채 종료 · 구간 중 오류 · 추론 대기 초과(500ms) · restart
- `kind=event` 엔진 이벤트(`start · stop · normal/abnormal · cameraLost · <reason> · cameraRecovered · paused · <reason> · error: <code> · self-stop`) · `kind=mark` 정답/케이스 변경 · `kind=battery` 배터리 % (실행 시작 측정 · 60초마다 · 실행 종료 측정 — 종료 측정 행은 종료 시각으로, `stop` 행 바로 앞에 온다. S04d)
- `truth`·`case` 는 그 행 시점에 유효하던 라벨(샘플은 촬영 시각 기준). CSV 범위를 "이 실행"/"이 케이스" 로 고르면 파일명에 `_runN`/`_<case>` 가 붙고 그 행만 담긴다

## 5. 측정 프로토콜 (D3 승계)

파트너 QA 가 실기기에서 수행한다. 기기 2종 이상(Android 중급 1 · iPhone 1) 권장. 결과는 `docs/handoff/S04.md` 의 표에 적는다.

### 5.1 준비
1. `build-android` 워크플로(debug) 의 `soongong-dev-debug-apk` 설치(iOS 는 S15 워크플로 전까지 Xcode 로컬 빌드).
2. 화면 밝기 50%, **화면 자동 꺼짐 해제 또는 70분 이상**, 전면 카메라 책상 위 50–80 cm.
3. `/_seat_lab` → 권한 요청 → 가용성 확인(`ok` 확인) → 케이스 선택 → 정답 라벨 선택 → 시작.
4. 케이스가 끝나면 정지 → CSV 내보내기(케이스별 파일 1개).

### 5.2 케이스

| id | 종류 | 상황 | 시간 | 정답 라벨 | 판정 |
|---|---|---|---|---|---|
| P1 | 양성 | 정면 착석 | 10분 | 실제 착석 | 검출률(seated/전체 sample) |
| P2 | 양성 | 고개 숙임 필기 | 10분 | 실제 착석 | 검출률 |
| P3 | 양성 | 측면(±45°) | 10분 | 실제 착석 | 검출률 |
| P4 | 양성 | 저조도(스탠드만) | 10분 | 실제 착석 | 검출률 |
| N1 | 음성 (a) | 빈 자리 | 2분 | 실제 이탈 | 오검출(seated/전체 sample) |
| N2 | 음성 (a) | 의자에 걸린 옷 | 2분 | 실제 이탈 | 오검출 |
| N3 | 음성 (a) | 벽 포스터 얼굴 | 2분 | 실제 이탈 | 오검출 (`minFaceSize` 별 비교) |
| N4 | 음성 (a) | 사진 속 얼굴 | 2분 | 실제 이탈 | 오검출 |
| N5 | 음성 (a) | 반려동물 | 2분 | 실제 이탈 | 오검출 |
| N6 | 음성 (a) | 조명 급변(끄기/켜기 반복) | 2분 | 실제 이탈 | 오검출 + `cameraLost` 미발생 확인 |
| N7 | 관찰 | 렌즈 가림(손·테이프) | 2분 | 실제 이탈 | v1 은 이탈 처리. seated=false 유지 여부와 Lost 발생 여부를 **기록만** |
| N8 | 음성 (b) | 화면 끄기 | 2분 | — | `paused · background`(엔진 자체 정지) · 그 구간 sample 행 0 · 화면 켠 뒤 `start` → `cameraRecovered` (§5.4) |
| N9 | 음성 (b) | 전화 수신 | 2분 | — | `cameraLost`(프레임 정지 3초 또는 점유 오류) · sample 행 0 · 통화 끝 → `cameraRecovered`(자가 복구) 또는 `start` 뒤 `cameraRecovered` (§5.4) |
| N10 | 음성 (b) | 다른 앱 카메라 점유 | 2분 | — | Android: `cameraLost · inUse`(또는 가용성 `cameraBusy`). iOS: 프레임 정지 → 3초 내 `cameraLost · frame timeout` (§5.4) |

(b) 에서 `seated=false` 샘플이 찍혀 이탈로 처리되면 **실패**다(D23). (b) 의 "시작 후 재시작" 은 하니스에서 정지 → 시작으로 재현한다(측정 화면에서는 S06 이 자동 재시작).

### 5.3 배터리
P1 조건으로 **한 실행(run) 안에서** 60분 연속(화면 켜짐). 시작 % 와 종료 % 는 **각각 따로 측정**해 그 실행에 귀속한다(S04d: 시작을 누를 때 1회, 정지를 누른 뒤 종료 시각과 함께 1회 — 60초 주기 읽음은 CSV·표시용일 뿐 시작·종료 값이 되지 않는다). 다음 중 하나면 "60분 연속 유효" 불합격(화면의 "60분 연속 배터리 측정" 행 사유): 실행 중 `cameraLost`/`paused` 1회 이상 · 비정상 종료 · 카메라 해제가 정지 상한(2초)을 넘김 · 60분 미만 · 시작 또는 **종료 측정 실패**(배터리를 읽지 못하면 그 실행은 측정이 아니다 — 다시 돈다). 30분 + 30분 두 실행을 합산하지 않는다 — 다시 60분을 돈다. 유효한 실행의 시작 % − 끝 % ≤ 8. 저전력 모드로 한 번 더 측정해 차이를 기록.

### 5.4 가용성 장애 — 케이스별 기대 이벤트 (S04d)

(b) 케이스는 "어떤 이벤트가 오는가" 가 판정이다. 화면 끄기·백그라운드는 라이프사이클이 알려주므로 엔진이 **스스로 멈추고 `SeatPaused`** 를 낸다. 카메라 점유·전화는 라이프사이클이 알려주지 않으므로 **프레임 정지(3초) 또는 점유 오류 → `cameraLost`** 다. 둘 다 그 구간에 `sample` 행이 없어야 하고, `seated=false` 샘플이 찍혀 이탈로 처리되면 실패다(D23).

| 케이스 | 기대 이벤트(CSV `event` 행) | 복귀 | 비고 |
|---|---|---|---|
| N8 화면 끄기 | `paused · background` → `stop · abnormal · 백그라운드로 엔진이 멈춤`(실험실 self-stop) | 화면 켜고 **시작** → 첫 프레임에 `cameraRecovered` | 측정 화면(S06)은 `resumed` 에서 자동 `start()`. `cameraLost` 가 먼저 오면 기록(화면이 꺼진 뒤 라이프사이클 전환이 3초 넘게 늦은 것) |
| 홈 버튼·앱 전환(백그라운드) | N8 과 같음 | 같음 | 열리는 도중이면 `paused · backgroundDuringStart` |
| N9 전화 수신 | `cameraLost · frame timeout`(iOS: 세션 인터럽션으로 프레임 정지) 또는 `cameraLost · inUse`(Android: 통화 UI 가 카메라를 잡는 기기) | 통화 종료 후 프레임이 돌아오면 자가 `cameraRecovered`; 안 돌아오면 정지 → 시작 | Android 전체 화면 수신 UI 가 앱을 `paused` 로 보내면 `paused · background` 가 올 수 있다 — 그 경우도 통과(이벤트 종류를 비고에 적는다) |
| N10 다른 앱 카메라 점유 | Android: `cameraLost · inUse`(CameraX "already in use") 또는 시작 전이면 가용성 `cameraBusy`. iOS: `cameraLost · frame timeout`(3초 내) | 다른 앱을 닫은 뒤 자가 복구가 없으면 정지 → 시작 → `cameraRecovered` | iOS 는 `checkAvailability` 가 `ok` 를 줄 수 있다(§3.4) |
| 검출기 무응답(실기기에서 재현 어려움) | `error: detector_failed` → `cameraLost · detector exhausted` | 매달린 호출이 돌아오면 자가 `cameraRecovered`; 아니면 앱 재시작 | 실험실 "미완료 추론" 행이 2 로 남는다 |

### 5.5 계산

- 검출률 = `truth=seated` 인 sample 중 `seated=1` 비율(하니스 "정답 착석 중 착석 판정" 과 같다).
- (a) 오검출 = `truth=away` 인 sample 중 `seated=1` 비율.
- (b) 장애 이벤트 = 케이스마다 `event` 행에 §5.4 의 기대 이벤트(`paused · …` 또는 `cameraLost · …`)가 있고, 그 행과 다음 `cameraRecovered`/`stop` 사이에 `sample` 행이 없으면 통과. (b) 케이스는 정지가 "끊긴 채 종료"/"백그라운드로 엔진이 멈춤" 으로 기록되어 `excluded=1` 이 되는 것이 정상이다 — 장애 이벤트 판정은 CSV 로 하고, 화면 요약은 양성·(a) 케이스에만 쓴다.
- 처리 시간 = `latency_ms`(촬영→결과) 의 중앙값·p95(스프레드시트). `excluded=1` 행은 뺀다.

## 6. 목표치

| 항목 | 목표 | 근거 |
|---|---|---|
| P1 정면 검출률 | ≥ 97% | 지시문 §4.5 |
| P2 고개 숙임 검출률 | ≥ 90% | 지시문 §4.5 (미달 시 §2.3 전환) |
| (a) 오검출 | ≤ 3% | 지시문 §4.5 |
| (b) 장애 이벤트 | 100% | D23 |
| 배터리 | ≤ 8%/h (화면 켜짐) | PRD §8 |
| 처리 시간 | 중앙값 ≤ 50 ms (주기 1초의 5%) | 배터리 예산 |

## 7. S06 사용 예

```dart
final engine = ref.read(seatEngineProvider); // prod: SeatEngineImpl, dev: 메뉴 스위치
final permission = await CameraPermission.request();
if (!permission.isGranted) {
  if (permission.needsSettings) { /* setupDen: 설정 열기 버튼 → CameraPermission.openSettings() */ }
  return; // 수동 모드 제안
}
switch (await engine.checkAvailability()) {
  case SeatAvailability.ok: break;
  case SeatAvailability.permissionDenied: /* setupDen */ return;
  case SeatAvailability.cameraBusy: /* errCam → camBusyN 수동 */ return;
  case SeatAvailability.unavailable: /* 수동 모드 */ return;
}
// 샘플의 위치: 세션 기준 시각 1개 + 단조 오프셋 (CONTRACT-CHANGE S04c).
// 엔진의 sinceStart 는 start() 를 "호출한 순간" 이 0 이다(카메라 여는 시간 포함, S04d §3).
// 그러므로 runStartedAt 은 start() 직전에 벽시계(SessionClock.now())로 1개만 잡고,
// 실행마다(복귀 뒤 재시작 포함) 다시 잡는다. 첫 샘플은 카메라가 열린 뒤 오므로
// runStartedAt + sinceStart 는 자연히 중단 구간 뒤에 놓인다.
late DateTime runStartedAt;
Future<void> startRun() async {
  runStartedAt = clock.now(); // start() 직전, 1개
  await engine.start(SeatEngineConfig(lowPower: battery <= 20 || settings.lowPower));
}
engine.events.listen((e) => switch (e) {
  SeatCameraLost() => tl.pause(clock.now()),                // D23 paused (프레임 정지 · 점유 · 검출기 고갈)
  SeatPaused() => tl.pause(clock.now()),                    // 백그라운드: 엔진이 멈췄음, 복귀 시 startRun()
  SeatCameraRecovered() => tl.resume(clock.now()),
  SeatError(:final message) => showLostSheet(message),      // start 실패 코드 · camera_init_timeout · detector_failed(재연결 = stop → startRun)
});
engine.samples.listen(
  (s) => tl.onSeatSample(at: runStartedAt.add(s.sinceStart), seated: s.seated), // receivedAt 은 쓰지 않는다
);
await startRun();
// 포그라운드 복귀(AppLifecycleState.resumed) → if (!running) await startRun();
// 종료: await engine.stop()  — 실행 중이면 최대 약 2.5초, 카메라 여는 중이면 즉시 반환; 그 뒤 샘플·이벤트 없음
```
