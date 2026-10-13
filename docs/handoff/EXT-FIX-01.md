# EXT-FIX-01 — PR #9 검토 후 수정

사용자의 2026-10-13 명시적 구현 지시로 기존 검토 전용/CC 구현 역할의 예외를 적용한다. PR #9에 단계별 누적, Draft 유지. 병합·운영 배포는 범위 밖이다.

기준 HEAD `325781b191fdffa48cac7dc6071a04eee78c2e08`, main `c5723529c11c225032f9f9b0038fe05255e1c903`, PR #8 `7472b41f5b52d0a0718833b6eb9d5016e9ab2e40` 모두 시작 시 원격 재확인.

## 1. F-EXPORT

PrivacyActions는 삭제 세대를 transaction에서 초기화하고 계정 소유권/진행 중 삭제를 확인한다. 인스턴스 dispose와 계정 이벤트는 영구 취소하며, ExportGuard로 인코딩 이후/파일 준비 전후/OS 공유 직전을 검사한다. 마지막 동기 검사부터 플랫폼 호출 사이에는 await가 없다. 공유 시트 대기 동안 DB transaction을 유지하지 않는다.

공유 어댑터는 요청별 임시 디렉터리만 정리한다. 공유 호출 전 취소·쓰기 실패는 소유 파일을 제거한다. OS 인계 이후에는 수신 앱의 파일 소비 시점을 보장할 수 없어 즉시 삭제하지 않는다. 내보내기 메모리 bytes는 완료/실패 후 덮어쓴다(물리 메모리 소거 보장은 아님). 이미 OS에 인계된 파일의 회수는 보장하지 않는다.

실제 PrivacyActions/공유 어댑터 회귀를 `export_race_test.dart`에 추가했다. JSON/CSV 계정 내용 필터 기존 회귀와 privacy widget 재시도 회귀를 유지한다. 로컬 Flutter 제한을 우회하지 않으며 실행 결과는 최신 CI로 갱신한다. CI codegen gate는 유지하고 실패 시 정확한 생성 diff를 artifact로 제공한다.

## 2. F-MIGRATION / F-JOURNAL

`AppDatabase.migration`은 신규/v1/v2 스키마, v1 중복 정리/outbox, `user_version=3`을 같은 durable transaction에서 확정한다. Drift 2.35.0의 이후 동일 버전 쓰기를 고려했다. 스키마 모양/버전 변경 없이 기존 원자성을 수리한 명시적 예외다. 이미 존재하는 v2+study_documents는 목표 DDL·제약·PK index가 정확히 일치할 때만 보존 복구하며 임의 index/trigger/view는 거부한다.

`beforeOpen`에서 파일 DB DELETE / 메모리 DB memory와 temp_store=2를 반환값으로 검증한다. `requireReadyDatabase`는 저장소/auth 시작 전에 실제 query로 열고, 실패한 executor는 닫아 다음 재시도에서 교체한다. 테스트 `encrypted_schema_migration_test.dart` 29건은 실제 sqlite3mc/Drift를 사용해 데이터·BLOB·outbox·사용자 객체·autoincrement·버전 보존 및 pre/post-commit 실패를 확인한다. throw/query_only 주입을 실제 kill·물리 전원 손실로 표현하지 않는다.

## 3. F-EMPTY-DB

`DatabaseProtection`과 실제 키 준비 경계는 파일 부재와 기존0바이트 파일을 구분한다. 기존0바이트·모호한 생성 잔여물·임시 marker는 보존 후 차단하며, 키/marker가 있다는 이유로 신규 생성하지 않는다. prepare는 동시 실행만 공유하고 성공을 영구 캐시하지 않는다. prepared opener의 실제 첫 연결 전에도 파일 부재/0바이트를 검사한다.

`database_creation_protection_test.dart` 18건은 실제 codec으로 잘못된 키/키 없음/절단/marker/4개 생성 중단/준비 후 실패·재시도·파일 소실/동시 준비를 검사한다. 파일 bytes와 키 write 횟수를 비교한다. 기존10건 암호화 이전/WAL/복구 검사는 유지한다. 앱 밖 프로세스의 모든 파일 경합을 원자적으로 잠갔다고 주장하지 않는다.

## 4. F-CAS / F-DEADLINE

계산 성공 값과 실패를 `CasResult`로 구분하고 하나라도 실패하면 남은 도구/추가 모델/정답 대조를 중단한다. 기준답을 모델에 보내지 않는다. 기존 외부 응답 계약의 비성공 경로를 사용한다. CAS CPU4초/주소공간768MiB/벽6초 및 환경 비밀 제거를 유지한다.

Edge `StudyDeadline`은 handler 진입부터 인증·본문·profile·worker·최종 재검증 전체55초다. 이미 취소된 요청은 외부 호출0회다. signal을 실제 fetch/body/auth/profile에 전달하고 cancel/cleanup의 무한 대기를 막는다. worker는 슬롯 이후 본문+추론+종료 총50초, 본문 절대10초다. 부분 pipe 응답도 소유자의 deadline을 막지 않는 제한된 JSON reader를 사용한다. Linux 요청 그룹의 자손을 종료·회수하고 회수가 실패하면 슬롯을 반환하지 않는다. 커널이 자원을 회수하지 못하는 경우는 정상 복구로 숨기지 않고 supervisor 재시작이 필요하다.

`study_deadline_test.ts` 12건 + 기존 Edge33건, Python `test_lifetime.py`/solver/worker 전체29건은 제어 시계·합성 입력·localhost·실제 제한 자식 프로세스를 사용한다. Python3.11과 해시 고정 solver/Pillow12.3.0 환경에서 실행한다. 부분 pipe·worker 취소·SIGTERM 무시 후 group kill·자손 PID 회수도 포함한다. 단축 deadline 시험과 기본55/50/10 상수 확인을 구분하며 실제 운영 ingress의 헤더 수신 제한/모델 서버 취소는 미검증이다.

## 5. F-PICK

`TranscriptionScreen._pick`은 각 await 이후 성공/크기 초과/오류/cleanup UI 변경에 현재 작업/owner/삭제 generation을 적용한다. generation 초기화를 기다리는 동안 삭제가 시작되어도 해당 작업의 busy는 해제하고 새 작업은 건드리지 않는다. `StudyImagePicker`는 요청 시작 순서와 route 간 경로 claim으로 오래된 cleanup이 새 선택을 삭제하지 않게 한다. canonical 앱 임시 디렉터리 밖 원본과 밖으로 향하는 symlink는 지우지 않는다.

실제 widget 9건 + 실제 파일 adapter 3건을 추가했다. 길이/읽기/cleanup을 Completer로 멈춰 같은 계정 삭제 뒤 새 이미지·문구·동의·busy를 검사한다. picker 완료 전 kill의 고아 캐시/Android lost-data는 이번 경합 수정과 별개다.

## 6. F-GAZE-CLOSE

gaze run 종료는 카메라 close 전체2초, finally native close2초이며 반복 stop/dispose/background는 같은 작업에 합류한다. 늦은 open/close도 해당 run의 소유권으로 정리한다. ProviderScope 수명의 gaze lease와 실패 latch로 실제 해제를 확인하지 못한 뒤 route 재진입까지 재시작을 막는다. Future timeout을 실제 OS 해제로 취급하지 않는다.

`gaze_lab_lifecycle_test.dart` 실제 widget/CameraFrameSource 경로11건: 정상1회씩, pending/throw, 2+2 예산, late open/close, 반복 종료, background/dispose. 공통 CameraSession/SeatEngine 계약과 순공시간은 변경하지 않는다. 실제 기기 측정 화면과의 카메라 소유권·발열·전력은 별도 미검증이다.

## 7. F-COPY / F-THEME

개인정보·도움말·계정·로그아웃·D14 안내는 현재 기기 저장/기기 변경 복원 미지원/파일 내보내기를 설명한다. 가져오기·자동 복원을 암시하지 않는다. OCR/풀이의 별도 동의 외부 처리와 gaze 온디바이스 처리를 구분한다. 실제 S13 동기화를 구현한 변경은 아니다.

DB 준비/차단 화면은 `StartupApp`에서 기존 Pretendard/토큰/한국어/시스템 light·dark를 사용한다. DB/Auth/router 의존 없이 렌더하고 정상 앱은 기존 사용자 테마 설정을 따른다. 오류 화면은 스크롤 가능하며 retry 중복을 막는다. 공용 AppButton은 동작 줄이기에서 busy 회전을 정적 표시로 바꾼다.

`database_startup_test.dart` 5건은 시스템 테마·한국어·DB접근0·200%/320×568·4.5대비·44타깃·semantics·reduced motion·retry/error/dispose를 검사한다. 개인정보 기존widget도 실제 안내를 확인한다. 실제 화면읽기 초점과 기기별 글꼴 렌더는 미검증이다.

## 공용 변경·호환성

- DB `app_database/database_protection/encrypted_database`, bootstrap; privacy provider/생성 hash; export service/guard/adapter; dev menu/seat lab 공유 호출자; 공용 AppButton; app locale/theme shell; auth helper의 선택적 AbortSignal; study gateway/worker/solver/IPC.
- 새 패키지·lock 업데이트 없음. 스키마 모양과 버전3, `core/contracts`와 외부 전사/풀이 v1 응답은 유지한다. 내부 ShareExport의 필수 guard, CAS 결과·IPC 형식은 내부 호출자/테스트를 함께 변경했다. 이 후속 작업 자체에 새 SCHEMA-CHANGE/core CONTRACT-CHANGE는 없다. 원래 PR의 v3/전사·풀이 v1 변경 표시는 유지한다.
- CI gate를 약화하지 않았다. codegen 불일치 때 실제 patch를 얻는 실패 전용 artifact만 추가했다. 초기 CI에서 생성 hash/공용 호출자/새 테스트 주입/임시 폴더 생성 오류를 발견해 고쳤다. 최종 성공 여부는 같은 HEAD의 Actions로만 판정한다.

## 검증 방법·범위

기존4개 workflow를 유지한다: `analyze-test.yml`(모델 hash/pub/codegen clean/analyze/금지문구/전체 Flutter), `server-tests.yml`(일회용 PostgreSQL pgTAP404/SQL 진단, Deno45/모든 함수 타입검사), `study-worker.yml`(Python3.11 + 해시 고정 solver/Pillow, 29건), `native-check.yml`(Android dev Debug APK / iPhone ARM64 dev Release/no-codesign). 코드 수정에 따른 신규 Flutter 검사는 최종 CI 실측 수를 사용한다. 기존1123건을 고정 목표로 삼지 않는다.

로컬 Flutter/pub는 이전 metadata 접근 자동 승인 거절 이후 실행하지 않았고 허용된 GitHub Actions를 사용한다. CI에서 실패하면 실제 로그에 따라 고쳐 같은 gate를 재실행한다. 최종 HEAD/main/PR8/checkout merge ref·tree·각 실행 URL·58개 상세 결과는 PR 본문 및 최종 검토 산출물에 기록한다. 이 문서에 실행 예정인 결과를 성공으로 미리 쓰지 않는다.

## 미완료·병합 조건

코드 수정/자동 검증/실제 모델·기기 검증은 별개다. 고유10건에 대한 자동 회귀가 통과해도 복합58항목의 다른 미검증 조건은 PASS로 바꾸지 않는다. 다음 조건이 남아 전체 병합·공개 활성화·출시는 보류한다.

1. 실제 모델 가중치·권리/라이선스·전이 lock/container, 권리 있는 한국어 손글씨/수능셋, 확정 정확도/성능 합격선·지연·비용.
2. 카메라 방향/안경/조명/자세/보정/측정과 소유권·발열/전력, 실제 화면읽기.
3. Android/iOS Release 실기기 codec/키 잠금/backup·기기 이전 제외·저용량·강제 kill·물리 전원 손실·시작/조회 성능.
4. picker 완료 전 고아 캐시/Android lost-data/계정·전체 삭제와 cache 연동, OS에 인계된 export의 보존/정리.
5. S13 실제 sync/기기 복원, 공개 사용량·비용 정책/큐, 운영 ingress. 현재 iOS simulator 공통 지원 아키텍처 부재는 그대로다.

원본의 두 opener 키 생성 경합·구 plaintext writer 승격 경합·pending 삭제 planner/UUID·저장/dialog finally·gaze/measure 소유권 의심은 미재현 후보로 유지한다. 이10건 수정으로 해결했다고 집계하지 않는다. 다음 검증은 모델/평가셋 승인과 실제 기기 보호·카메라·캐시 시험을 각각 증거로 남기고58항목을 갱신하는 순서다. 실제 merge/deploy는 실행하지 않는다.
