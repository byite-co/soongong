# NEXT-02b · 기기 실행 인계 (실행 결과 아님)

현재 Android SDK/adb/emulator/연결 기기와 iOS/Xcode가 없고 승인된 개발 Auth/Edge/worker endpoint도 없다. Android emulator·실기기·iOS 실제 앱 종단 및 K1~K4는 모두 **UNVERIFIED**다. DB close/reopen 및 HTTP/프로세스 worker 테스트와 구분한다. [실행 양식](../evidence/next02b/device-cases.json)에 실제값만 채운다.

## 개발 빌드와 자료

기존 승인된 개발 프로젝트에서만 실행한다. `env/app.dev.json`은 Git 제외 파일이며 공개 anon key와 승인된 URL만 쓴다. service_role/worker secret을 앱에 넣지 않는다. `DEV_OCR_ENABLED=true`는 해당 로컬 시험 빌드에서만 명시한다. 기본 OFF와 저장소 예제는 유지된다. 공개 터널/TLS 검증 해제/운영 활성화는 하지 않는다.

```sh
python3 tool/fetch_gaze_model.py
flutter pub get --enforce-lockfile
flutter devices
flutter run -d DEVICE_ID --flavor dev --dart-define-from-file=env/app.dev.json --dart-define=DEV_OCR_ENABLED=true
```

`DEVICE_ID`는 실제 선택한 시험 기기 ID로 바꾼다. 설치 빌드 SHA·APK/앱 hash·OS·서명·모델 lock을 개인 원문 없이 기록한다. 위 명령은 이 환경에서 기기에 실행하지 않았다. iOS는 서명 가능한 실제 iPhone 및 Xcode가 필요하다. emulator 성공으로 iPhone/DEVICE12를 승격하지 않는다.

사용권 있는 사진 3종(실제 한글·수식·빨간 채점표시), 테스트 계정 A/B와 교정 정답을 로컬 비공개 디렉터리에 둔다. 장치 전송은 해당 시험 기기에만 수행한다. synthetic/인쇄/실제 손글씨·문항별 5종 Mark를 구분한다. 사진·원문·키를 Git/공개 CI에 올리지 않는다. 사진 선택→영역 회전/crop→quote/승인 또는 기존 판독권→실제 모델→대조/교정→명시 저장→암호화 DB 재조회를 text/math/grading 각각 수행한다. UI는 사진1장, 원격 판독 adapter의 최대20장과 다르다. 수식은 LaTeX source이며 조판 미리보기가 아니다.

## 실제 종료 경계

debugger에서 아래 경계를 관측한 다음 앱을 **실제 force-stop**한다. breakpoint 자체나 DB reopen을 process-kill로 기록하지 않는다. K1~K3에서 서버 attempt·영수증·포인트/판독 원장을 같은 익명 request digest에 연결한다. 아래 위치는 실행 시 line 대신 식별자를 확인한다.

| 경계 | 전사 경로의 관측 위치 | 별도 확인 |
|---|---|---|
| K1 | `RemoteAiJobs.execute`: `await beforeSend` 완료 후 `invoke('study-infer')` 전 | `AiRequestRepository.prepare` transaction durable, quote 만료/승인 scope |
| K2 | Edge `AiJobs.dispatch`와 worker 실제 시작 후 응답 전 | 서버 쪽 breakpoint/시험 지연 필요; 앱 breakpoint만으로 dispatch를 증명하지 않음 |
| K3 | `RemoteAiJobs.execute`: `invoke` 반환 후 `onJob` 전 | 서버 succeeded와 receipt durable 여부를 먼저 확인 |
| K4 | `TranscriptionScreen._save` 또는 grading save transaction 완료 후 | 문서/오답·request link·정산 한 번, 사용자 교정 내용 |

grading은 `GradingScreen.submit`/기존 reading repository·job 경로를 따라 동일 의미의 경계를 관측한다. OCR quote/AI 포인트 대신 기존 월 권리와 quota를 기록한다. breakpoint가 모델 CPU/wall 시간을 늘리는 사례는 시간 평가에서 분리하며 제한은 끄지 않는다.

Android dev 앱이 관측 경계에서 실행 중일 때 다음 launcher를 쓴다. `boundary-proof.json`에는 로컬 관측 근거를 보관한다. 출력은 hash/PID만 포함하며 원문 proof는 공개하지 않는다.

```sh
python3 tool/next02b_device_cycle.py --serial DEVICE_ID --operation text --checkpoint K1 --boundary-proof /PRIVATE/boundary-proof.json --output /PRIVATE/text-k1-cycle.json
```

launcher는 `co.byite.soongong.dev`만 대상으로 `am force-stop`, 종료 확인, activity 시작, 새 PID 확인을 수행한다. 데이터 삭제/앱 설치/기능 활성화는 하지 않는다. PID cycle PASS는 복구 PASS가 아니다. force-stop과 background `am kill`은 다른 사례다. iOS는 Xcode에서 관측 경계를 잡아 앱 프로세스 종료 후 재실행하고 PID·원장을 별도로 수집한다.

재시작 후 먼저 같은 ID의 상태 조회를 확인한다. K1은 입력 유실/quote 만료를 확인하고 재승인을 안내하며 새 ID 자동 실행0; K2 pending/unknown은 중복 실행0·비용 unknown 유지; K3 같은 결과 복구와 추가 모델/포인트0; K4 같은 교정 문서1건을 확인한다. 원본 사진 유실 시 원본 대조 불가를 표시하고 `result_expired`를 빈 성공으로 만들지 않는다. 계정 A→B·동의 철회·purge/삭제·동일 계정 토큰 갱신 변형도 실행한다. 결과 미수집 칸은 null/UNVERIFIED로 남긴다.
