# EXT-03 — 시선 기반 집중 판독

> 구현 상태 갱신: 이 문서는 사전 계획이다. 순차 적용된 코드·한계는 [EXT-03 인계](../handoff/EXT-03.md), 최신 검증은 [EXT-FINAL](../handoff/EXT-FINAL.md) 참조.

이전: [EXT-02](02-csat-solver.md) · 다음: [EXT-04](04-database-encryption.md)

## 세션 시작 지시문

> 시선·머리 방향의 온디바이스 관측과 품질 판정을 구현하고 집중 판독에 사용할 수 있는지 평가한다. 기존 착석 타이머와 분리된 opt-in 개발 실험 경로부터 연결한다. 프레임 저장·전송 없이 Android/iOS에서 검증하고, 제품 원칙과 계약 변경점을 기록한다. 시선 추정치를 정신적 집중의 정답이나 순공시간 차감으로 자동 변환하지 않는다. main에는 병합하지 않는다.

## 정합성 판정과 결정 경계

`CLAUDE.md` §1 및 D3/D23은 착석 boolean, 순공시간 대표 지표, 시간 축 AI 비개입을 전제로 한다. 사용자의 이번 요청에 따라 시선 기반 기능의 조사·구현을 진행하되, **시선 신호 추가와 사용자 시간 기록 정책 변경은 별개 변경**으로 관리한다. PR에 `PRINCIPLE-CONFLICT`를 명시하고 `docs/decisions.md`에 충돌과 이번 확장안을 기록한다. 원칙 문서를 몰래 삭제하거나 기존 boolean을 집중도 점수로 바꾸지 않는다.

이 세션의 기본 산출물은 opt-in 개발용 관측 엔진·보정·품질·실측이다. 일반 사용자에게 활성화하거나 타이머 계산에 반영하려면 검증 결과를 토대로 표시 문구/오판 대응/사용자 제어/시간 정책을 구체적으로 결정해야 한다. 현재 요청은 그 결정을 숨기고 임의로 시간을 차감할 근거가 아니다. 결정이 남으면 구현 상태와 운영 활성화 보류를 따로 인계한다.

## 실제 연결 지점

| 기존 코드 | 지킬 계약 |
|---|---|
| `lib/core/contracts/seat_engine.dart` | seated boolean, monotonic sinceStart, 기존 confidence 의미 보존 |
| `lib/data/engines/seat/seat_frame_source.dart` | 프레임은 수명 제한된 메모리 데이터. 완료 후 보관 금지, per-run close 계약 유지 |
| `lib/data/engines/seat/mlkit_face_presence_detector.dart` | 현재 얼굴 존재만 반환, landmark/classification/contour/tracking 비활성. 즉시 gaze 엔진으로 간주 불가 |
| `lib/data/engines/seat_engine_impl.dart` | 세대 번호, timeout, 단일 분석 gate, hysteresis, stop/restart 경합 유지 |
| `lib/features/measure/domain/session_timeline.dart` | 단조 시간 계산, 카메라 불가/백그라운드는 paused. away로 바꾸지 않음 |
| `lib/core/dev/seat_lab/` | 개발 실험 진입점. 기존 기록기에 얼굴 좌표를 무조건 추가 저장하지 않음 |

현행 이탈 민감도는 60/75/90초, 착석 boolean hysteresis는 3초, snapshot은 15초다. 새로운 시선 임계값과 혼동하지 않는다. 기존 1Hz sample stream만으로 짧은 눈깜박임·졸음·집중을 판정하지 않는다.

## 차용 설계

- MediaPipe Face Landmarker의 Android/iOS 공식 샘플을 native bridge와 모델 수명 관리 참고로 사용한다. 두 플랫폼 샘플 디렉터리는 확인했지만 순공의 Flutter bridge는 신규 구현·빌드 검증 대상이다.
- 얼굴 landmark·머리 자세·눈 관련 신호는 **시선 추정용 관측치**다. MediaPipe 자체가 심리적 집중도를 판정한다고 표시하지 않는다. 얼굴 식별, embedding, 개인 식별자, 감정/정신건강 추론은 범위에 넣지 않는다.
- OneEuroFilter는 필요할 때 연속 좌표/각도의 떨림을 줄이는 데만 적용한다. 단조 timestamp·단위·reset 규칙을 고정하고 MediaPipe 내부 smoothing과 중복 지연을 측정한다. 기존 boolean hysteresis를 대체하지 않는다.
- `byite-co/focus-engine` 관련 코드가 추가 필요하면 파일별 공개 재배포 권리·라이선스와 모델 의존성을 먼저 확인한다. OpenFace 등 사용 조건이 해소되지 않은 코드를 섞지 않는다.

새 파일 후보: `lib/core/contracts/attention_observation.dart`, `lib/data/engines/gaze/`, Android/iOS native bridge. 모두 **예정 경로**다.

`AttentionObservation` 초안: runGeneration, monotonic timestamp, quality(valid/unknown), 얼굴 수, 관측 가능성 이유, 선택적 머리 방향·눈 방향. 품질이 나쁘면 unknown을 반환한다. “집중력 82점” 등 평가 점수·등급·랭킹은 만들지 않는다.

## 작업 순서와 검증

1. Fake 관측 엔진과 개발 feature flag(default off)를 만든다. 동일한 측정 이벤트에 관측을 켜고 끌 때 기존 순공시간이 같음을 회귀 검증한다.
2. 회전/좌우 반전/전면 카메라/Android NV21·iOS BGRA8888 변환을 플랫폼별 검증한다. 카메라 버퍼를 분석 완료 전에 해제하거나 다음 세대로 재사용하지 않는다.
3. 종이 읽기·필기·화면 읽기의 개인별 보정 과정을 만든다. 아래를 보는 필기를 “집중 안 함”으로 고정하지 않는다. 보정 실패·다중 얼굴·가림·안경 반사·어둠은 unknown으로 처리한다.
4. 단일 카메라 소유자를 유지하고 OCR 촬영과 측정 전환 시 release/reacquire를 검증한다. pause/background/권한 철회/stop-timeout/즉시 restart 뒤 늦은 결과를 폐기한다.
5. 동적 frame cadence는 기기 성능에 맞춰 결정한다. 15fps/저전력 10fps인 현재 카메라 소스와 UI 전달 빈도를 구분하고 dropped frame·분석 지연·배터리·발열·시간 오차를 함께 측정한다.
6. 개발자 로그·분석·크래시·DB·네트워크에 프레임이나 얼굴 좌표가 남지 않는지 확인한다. opt-in 실험에도 서버 전송은 추가하지 않는다. 기기 내 보정값이 필요하면 최소 범위/삭제/계정 분리를 명시한다.

평가는 동의한 참여자의 알려진 행동(종이 보기/화면 보기/시선 이탈/가림)과 관측 품질을 기준으로 한다. 자기보고 집중도는 별도 탐색 자료이며 시선의 정답 label로 대체하지 않는다. 참여자별 calibration/holdout을 나누고 행동별 오탐·미탐·unknown 비율·지연을 보고한다. 특정 환경에서 잘못 차감되는 시간도 계산하되 기본 타이머에는 반영하지 않는다.

Android/iOS 실기기에서 장시간 측정, 발열·저전력, 통화/잠금/앱 전환, OCR 촬영 전환, 카메라 사용 실패를 검증해야 한다. Fake나 에뮬레이터 테스트만으로 시선 정확도·배터리 품질 통과라고 하지 않는다.

`docs/handoff/EXT-03.md`에는 신호 정의·보정/품질 기준·모델 해시·실기기 표·미지원 조건·제품 원칙 충돌 처리·feature flag 상태를 남긴다. 저장할 보정값이 생겼다면 EXT-04의 전체 DB 이전 목록에 포함한다.
