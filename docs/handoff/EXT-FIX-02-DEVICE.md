# EXT-FIX-02 부록 — DEVICE-01~12 실행 절차

2026-10-13 작성. **12개 모두 UNVERIFIED**다. 이 작업 환경에서 실제 기기·서명된 설치물·모델·평가셋 실행 증거를 확보하지 않았다. 아래는 PR #9 고정 빌드에서 실행할 절차이며 실행 완료 보고가 아니다. main 병합이나 운영 공개 활성화를 전제로 하지 않는다.

## 공통 준비와 증거 형식

1. 실행할 PR commit SHA, checkout/tree SHA, CI URL을 고정한다. APK/IPA/앱 bundle SHA-256, flavor, Debug/Release, 서명 유무·서명 프로필, native/model dependency lock 및 모델 artifact hash를 기록한다. CI의 Android dev Debug 빌드와 iPhone ARM64 dev Release **no-codesign 빌드만으로 설치/실행 PASS를 주지 않는다**. 기기 Release 검증은 별도 서명된 같은 소스 빌드가 필요하다.
2. 실제 Android/iPhone, OS 버전, 모델명, 여유 공간, 카메라 권한, 사진 권한, 화면 잠금/절전 설정을 적는다. Android 작업 패키지는 manifest/flavor에서 확인하며 현재 dev는 `co.byite.soongong.dev`다. iOS는 설치 artifact의 실제 bundle ID를 확인한다.
3. 초기화 가능한 시험 기기와 합성 사진·문서, 일회용 계정 A/B 및 격리된 시험 서버를 준비한다. gallery 원본과 저장 완료 문서의 hash/개수를 사전 기록한다. 외부 앱 수신본은 통제 범위 밖으로 별도 표기한다. 개인 원문/키/계정 식별자/사진 경로를 증거 로그에 남기지 않는다.
4. 앱 sandbox 검사에는 해당 빌드에서 허용되는 Android Studio Device Explorer/run-as, Xcode 다운로드 container 또는 시험용 계측을 쓴다. Release sandbox/키에 접근할 수 없으면 fixture 결과를 대신 쓰지 말고 해당 증거를 UNVERIFIED로 둔다. 진단 계측이나 debugger breakpoint가 필요하면 위치와 변경 diff, 실제 출시 빌드와 차이를 기록한다.
5. 각 행은 `ID / 사전조건 / 반복·중단 지점 / 기대값 / 실제값 / 증거 링크·hash / PASS·FAIL·UNVERIFIED·N/A / 잔여 범위`로 기록한다. 예상값을 실제값에 복사하지 않는다. 지연·정확도·전력 합격 기준은 실행 전에 확정·버전 고정한다. 미확정이면 측정값만 보고하고 PASS를 주지 않는다.

소유 임시 경로의 기준은 platform cache 아래 `soongong-owned-v1/<opaque scope>/<opaque task>/marker.json`과 `payload/`다. 실제 최종 파일 수명표/네이티브 감사 문서와 대조한다. 디렉터리 경로나 파일명 자체를 외부 로그에 남기기보다 종류별 개수·bytes·합성 hash·marker 상태를 기록한다. `.revoked`/`.delete` 및 DB 정리 책임이 재시작 후 유지되는지 함께 본다.

공유 인계 후/인계 불명확 파일은 **생성 시점부터 24시간 유예 뒤 다음 앱 시작·foreground·재시도·다음 export 진입 기회에 정리 대상**이다. 24시간은 제품 기본값이며 OS의 수신 완료 보장이 아니다. 앱 종료 중 정확한 만료 시각에 삭제됐다고 안내하지 않는다. 명시적 계정 종료/삭제/전체 삭제에는 유예를 적용하지 않는다. unlink는 외부 앱이 이미 연 descriptor나 만든 사본을 회수하거나 flash의 물리적 완전 삭제를 보장하지 않는다.

## DEVICE-01 — Android activity 재생성

- 자원/사전조건: 실제 Android, 서명된 dev 빌드, gallery 합성 사진, OS activity 재생성 제어와 sandbox 계수 수단. OS `Don't keep activities`를 사용하면 설정과 복원 여부를 기록한다.
- 절차: OCR 선택창을 열고 activity를 background→재생성한다. 선택 전, 선택 후 Dart 반환 전을 구분하여 화면 회전/OS activity 제거 후 복귀를 반복한다. 복구 중 새 picker를 시작하고, 기존 요청이 늦게 돌아오는 경우도 관찰한다.
- 기대값: recovery/new picker 직렬화 또는 명시 거부. 이전 사진 자동 복원·자동 전송 0, 중복 복구 0, 새 입력/동의/버튼 상태 오염 0. 불완전 입력은 정리 후 다시 선택 안내. gallery 원본 및 새 task 보존.
- 증거: activity lifecycle 시간선, 네트워크 요청 종류·개수(본문 제외), task별 전후 개수, 화면 상태. 실제값: 미수집. 판정: UNVERIFIED.

## DEVICE-02 — Android picker 실제 process kill

- 자원/사전조건: DEVICE-01 환경, PID 종료 확인 수단, gallery/provider 제어 또는 debugger breakpoint. callback 이전 native payload 생성 경계를 관측할 수 있어야 한다.
- 절차: (a) task/marker 작성 후 선택 전, (b) gallery 복사 또는 camera 출력 파일 생성 후, (c) native 쓰기 후 Dart callback 전의 각 지점에서 앱 프로세스를 종료한다. `am kill`은 background PID 실제 종료를 확인하고, force-stop은 다른 OS 동작이므로 별도 사례로 명시한다. 재시작/복구와 B의 신규 선택을 겹치고 A의 늦은 OS result를 반환한다.
- 기대값: 미완료 입력 자동 전송/저장 0. A의 검증된 앱 소유 잔여만 회수, gallery 원본 불변, B 파일 보존. 이전 request code가 B 결과로 소비되지 않음. live writer/상태 불명이면 성공0개로 숨기지 않고 차단·재시도.
- 증거: kill 전후 PID, interruption 위치, 재시작 task inventory·original hash·B 결과. 시뮬레이트한 static reset은 실제 kill 증거에서 제외한다. 실제값: 미수집. 판정: UNVERIFIED.

## DEVICE-03 — iOS 선택/촬영 취소·재시작

- 자원/사전조건: 실제 iPhone, 서명된 ARM64 dev 빌드, Xcode Instruments/container 관측, 합성 Photos 원본. simulator 빌드 대체 없음.
- 절차: Photos 선택, camera 촬영 각각 정상/취소/권한 거부를 실행한다. callback 전 background·프로세스 종료 뒤 재실행한다. 이어 새 선택을 시작하고 늦은 이전 callback과 화면 dispose를 확인한다.
- 기대값: app cache의 owned payload만 생성·정리, Photos 원본 유지, 이전 callback의 새 입력·동의·busy 변경 0. Android lost-data API가 있다고 가정하지 않음. 취소·정리 실패는 실제 상태로 안내.
- 증거: 권한/lifecycle 기록, Photos 원본 hash, container 전후 count, 화면 및 전송 개수. 실제값: 미수집. 판정: UNVERIFIED.

## DEVICE-04 — 실제 공유 수신과 만료

- 자원/사전조건: Android/iOS 실제 기기, Files/문서 viewer 등 실제 수신 앱과 제어 가능한 지연 reader, 동일 이름의 A/B 합성 export. 수신 앱·버전 기록. 장시간 실제 유예 사례를 위한 기기 보관 시간 확보.
- 절차: JSON/CSV/ZIP을 각각 공유하여 유예 내 즉시/지연 읽기, sheet 취소·unavailable·인계 후 예외/앱 종료를 구분한다. 두 export를 동시에 만들고 내용 분리 확인. 생성 후 실제 24시간 경과 뒤 시작/foreground/재시도/다음 export로 정리한다. 시계 역행 및 재시작도 별도 실행한다. 합성 시간 주입은 실제 24시간 관측과 구분한다.
- 기대값: 유예 내 reader 내용 정상, 반환 직후 무조건 삭제 0. 인계 불명확 상태에도 원장 유지. 만료 후 실행 기회에서 해당 앱 소유 파일·복사본 0으로 수렴. cleanup 재시도는 공유 재호출 0; B와 다른 기능 파일 유지. 시계 역행/활성 share 때문에 무기한 잔존하지 않음.
- 증거: 생성/인계/읽기/만료/정리 시간선·hash·파일 개수·OS 호출 수. 열린 FD의 unlink 후 읽기 지속이나 외부 수신본 잔존은 통제 경계를 명시하고 앱 소유 신규 open과 구분한다. 실제값: 미수집. 판정: UNVERIFIED.

## DEVICE-05 — 대기 중 계정 전환·전체 삭제·탈퇴

- 자원/사전조건: 실제 A/B 시험 계정, 격리 backend, 응답을 지연할 수 있는 시험 network, A picker/export의 단계별 breakpoint. 확정 서버 삭제 뒤 local 실패를 만들 수 있는 별도 사례.
- 절차: 파일 write/encoder/OS 직전/OS sheet 인계 후 각각 A 로그아웃·A→B·전체 삭제·계정 삭제를 시작한다. B 문서/파일을 만든 뒤 A 지연 callback을 완료한다. server 성공/local cleanup 실패 뒤 local retry도 실행한다.
- 기대값: barrier 전 A 결과의 새 저장·노출·OS 인계 0; OS 직전 무효화된 export는 공유 호출0. B 자료 불변. 명시 종료 시 A 앱 소유 공유 파일은 유예 없이 정리. server 완료/local 잔여 구분, local 재시도에서 delete-account/purge-all 새 요청0. 외부 수신본 회수 주장은 없음.
- 증거: 계정은 A/B 익명 표기, generation/task 상태, 요청 endpoint별 개수·멱등성 ID의 비가역 식별자, 파일 hash 및 화면. 실제값: 미수집. 판정: UNVERIFIED.

## DEVICE-06 — 저장소 부족·보호 상태와 재시도

- 자원/사전조건: 전용 기기, OS가 지원하는 저장소/파일 보호 조작, 원상 복구 수단. 실제 부족/잠금 사례와 앱 파일 어댑터 주입을 구분한다.
- 절차: marker 작성, payload 쓰기, revoke/delete 표시, unlink 각각에서 공간 부족/권한·보호 상태로 실패시킨다. 로그아웃·전체 삭제·privacy 진입/중복 재시도를 실행한 뒤 환경을 정상화하고 재시도한다. mapping이 없는 root 접근 불가도 확인한다.
- 기대값: 부분/unknown/계정 변경을 구분; 미확인 count를 0으로 표시하지 않음. 완료 toast 없음. durable 의무와 원본 mapping 보존, 복구 뒤 앱 소유 파일만 제거, 중복 삭제·공유 재호출0.
- 증거: OS 오류 분류, 남은 task/bytes, marker/DB mapping 보존, 전후 UI. 실제값: 미수집. 판정: UNVERIFIED.

## DEVICE-07 — Release codec·키 잠금·재부팅

- 자원/사전조건: 실제 Android/iPhone에 설치 가능한 서명 Release, 합성 v1/v2/v3 DB와 outbox/BLOB fixture, 키 접근 상태를 제어할 수 있는 시험 빌드/계측. 운영 키를 출력하지 않는다.
- 절차: 신설/기존 DB에서 실제 codec 확인을 통과시키고 잠금→재부팅→최초 unlock 전/후 시작을 비교한다. 잘못된 키·키 읽기 실패·키 누락은 시험 fixture에서 실행한다. DB 개수/typed digest/outbox/schema/version을 전후 비교한다.
- 기대값: key/codec 확인 실패 시 접근 차단·재시도; DB 초기화·평문 전환0. unlock 후 원래 자료 보존. 실패한 준비 결과를 영구 캐시하지 않음. 로그아웃이 DB 키를 새로 만들지 않음.
- 증거: 실제 codec 식별 반환값(키 제외), 시작 결과, container hash/typed digest, OS 보호 상태. SQLite header 암호화만으로 전체 codec PASS를 선언하지 않는다. 실제값: 미수집. 판정: UNVERIFIED.

## DEVICE-08 — OS backup/restore·기기 이전

- 자원/사전조건: 시험용 이전/새 기기, OS backup/transfer 계정과 도구, 합성 DB/키/사진/export. 현재 Android manifest/backup XML 및 iOS Documents 제외 flag를 읽어 예상 제외 범위를 먼저 적는다.
- 절차: 앱 데이터 생성 후 실제 OS backup과 새 기기 restore/직접 transfer를 각 플랫폼에서 실행한다. 새 기기 시작 결과 및 DB·secure key·owned cache·원본 Photos/사용자가 별도 저장한 export를 구분 조사한다.
- 기대값: 기기 결합 키와 민감 로컬 DB/앱 소유 임시파일이 정책 밖으로 복원되지 않음. 불일치 복원 시 빈 DB fallback/조용한 새 키 생성 없음. local-only study_documents 복원 가능 문구 없음. 외부 Photos/사용자 명시 저장 사본과 구분.
- 증거: OS 도구·설정·backup 목록/복원 inventory, 앱 차단/진입 상태. S13이 Fake인 상태에서 서버 동기화/새 기기 복원을 PASS로 올리지 않는다. 실제값: 미수집. 판정: UNVERIFIED.

## DEVICE-09 — 암호화 이전 중 kill·실제 전원 손실

- 자원/사전조건: 전용 시험 기기, 이전 가능한 합성 평문 DB, 원본 별도 안전 보관, native debugger/단계 계측. 실제 전원 차단을 검증하려면 적합한 시험 장비와 복구 가능한 기기가 별도로 필요하다.
- 절차: DatabaseProtection의 copying, encrypted candidate 검증, original rename, candidate install, cleanup 경계를 기준으로 각 지점에서 실제 process kill 후 재시작한다. 실제 전원 손실 사례는 장비·중단 지점·전원 복구 방법을 독립 기록한다. 코드 throw, force-stop, 정상 reboot를 물리 전원 손실로 표시하지 않는다.
- 기대값: 검증된 지원 상태로 복구 또는 원본/marker 보존 차단. 잘못된 키·절단·모호한 잔여에서 초기화0/평문 fallback0. 모든 row/BLOB/outbox/schema/version 전후 일치, 미정리 plaintext 잔여가 있으면 정상 쓰기 허용 없음.
- 증거: 단계·파일 inventory/typed digest/버전·재시작 결과. flash 과거 블록 완전 소거는 주장하지 않음. 실제값: 미수집. 판정: UNVERIFIED.

## DEVICE-10 — gaze/측정 공통 카메라

- 자원/사전조건: 실제 Android/iPhone, dev 메뉴의 시선 관측 실험 및 기존 측정, camera lifecycle/프로세스/네트워크 계측, 고정 gaze 모델 hash. 실제 close 실패를 발생시킬 수단이 없으면 그 하위 사례는 미검증으로 남긴다.
- 절차: gaze→측정 및 측정→gaze 전환, 동시에 시작, pending initialize, background/foreground, 반복 stop·route dispose를 실행한다. native stop/dispose 지연·실패를 발생시키고 timeout 뒤 늦은 완료 및 route 재진입을 관찰한다. 정상 종료 뒤 다음 소유자 획득도 확인한다.
- 기대값: 같은 OS camera의 중복 획득0. 종료 실패/timeout 이후 새 소유자 재시작 차단 유지; Future timeout을 실제 OS 해제로 간주하지 않음. 정상 close는 한 번 실행되고 반복 호출 합류. 측정 차단 중 순공시간 증가0, 기존 착석 시간 집계 불변, 원본 프레임 저장·전송0.
- 증거: OS 카메라 open/close 시간선·busy 상태, 합성 동작 구간별 시간 집계, container 증가량·전송 종류/개수. gaze 좌표·프레임을 로그로 남기지 않는다. 안경/조명/회전 시 방향 품질도 별도로 기록하며 정신적 집중 정확도로 부르지 않는다. 실제값: 미수집. 판정: UNVERIFIED.

## DEVICE-11 — 실제 OCR·수학 모델 평가

- 자원/사전조건: 권리 확인된 한국어 손글씨/수식/수학 holdout, 실제 Paddle/UniMERNet/수학 모델 ID·revision·가중치 hash, models.lock.json, 전이 hash lock·container digest, 격리된 GPU/CPU worker와 시험 Edge. 구성은 `services/study_worker/README.md`를 따른다. 미확보 모델을 예시 응답/빈 파일로 대체하지 않는다.
- 절차: 실행 전에 데이터 분할·버전·정확도/오류/지연 합격 기준을 확정한다. OCR 문자 오류와 수식 오류를 분리하고, 사용자 교정 전 풀이 차단/동의 전 외부 요청0을 실측한다. solver는 기준답 있음/없음/범위 밖과 계산 제한을 포함해 정답·풀이 오류·판정 보류·timeout을 각각 집계한다. 같은 digest/manifest 재실행과 의도된 불일치 거부도 확인한다.
- 기대값: 실제 평가값이 사전 기준을 충족; 기준답 없는 verified0, 기준답 모델/도구 노출0, 계산 한도 초과의 안전 종료. 숫자 답 일치와 전체 해설 타당성을 구분한다. 배포망 취소·worker 자손 회수·슬롯 복귀도 별도 실측한다.
- 증거: dataset/model/runner/config hash, anonymized case 결과·집계·P50/P95 지연·메모리·비용·오류 분류. 합격선/runner/모델/권리가 없으면 준비 공백을 적고 SRV-05/EVAL-01/EVAL-02를 UNVERIFIED 유지. 실제값: 미수집. 판정: UNVERIFIED.

## DEVICE-12 — 저사양·장시간·접근성

- 자원/사전조건: 지원 최저 사양 Android/iPhone과 비교 기기, Release 계측, 고정 합성 대용량 DB, OS profiler/전력·온도 도구, TalkBack/VoiceOver. 시작·조회·추론·메모리·발열·전력 기준과 측정 반복 수/장시간 구간을 사전 확정한다.
- 절차: cold/warm start, 대량 기록 조회/export, OCR/풀이, gaze/측정의 장시간 전환을 같은 조건에서 수행한다. P50/P95·최대 메모리·온도/전력 변화·성능 저하를 기록한다. 200% 이상 시스템 글자, 작은 화면, light/dark, 동작 줄이기, 화면 읽기로 동의→선택→교정→저장 및 차단/unknown/cleanup retry를 직접 조작한다.
- 기대값: 확정한 성능 기준 충족; 경로별 접근 가능한 이름/순서/초점, 잘림 없는 핵심 안내와 실행 가능한 retry, 색만으로 상태를 전달하지 않음. 자동 semantics/대비 검사 통과를 실제 화면 읽기 성공으로 대신하지 않음.
- 증거: profiler 원자료와 환경, 접근성 작업별 실제 결과/스크린샷(합성 데이터만), 기준 대비 표. 기준 미확정은 성능 PASS 금지. 실제값: 미수집. 판정: UNVERIFIED.
- REG-04 실기기 보완: 합성 식별 문자열을 가진 camera/picker/filesystem/network 오류를 정상·실패·재시도 경로에 주입하고 앱 로그, OS crash 진단, Seat Lab 진단 CSV 및 전달할 증거 archive를 각각 수집·검사한다. 계정 식별자·원문·사진 경로·키·토큰·프레임이 포함되지 않아야 하며, 오류 종류·고정 코드 외 자유 문자열과 stack trace도 확인한다. 원문 자료를 공유하기 전에 필요한 redaction을 수행하고 검사 범위·누락된 채널·전후 hash를 기록한다. host fixture의 LogEvent/CSV 검사와 실제 OS 로그를 구분하고, 확보하지 못한 채널은 UNVERIFIED로 남긴다.

## 완료 기록

실행자는 위 항목별 실제값·증거를 채운 뒤 하위 사례 누락 여부를 검토한다. 특정 OS/기기만 통과했다면 해당 조합으로 범위를 한정한다. 지원 범위 제외가 승인되지 않았다면 기기 부족을 N/A로 바꾸지 않는다. 실제 모델 구성, S13 동기화 구현/새 기기 복원, 운영 준비 및 병합 판단은 코드/자동 회귀 완료와 별도다.
