# EXT-FIX-02 — RC-01~05 실제 구현 인계

2026-10-13. 기준 `d55bbfe6c7d4ed318a366f4613dc819f5188ea61`, 저장소 `byite-co/soongong`, 기존 PR #9 `feat/s14-oss-integration`. 사용자가 코드 수정·테스트·커밋·기존 PR 반영을 명시적으로 지시했다. Draft를 유지하며 병합·운영 배포·공개 활성화는 실행하지 않는다. CLAUDE.md의 종전 역할 분담보다 이번 사용자 실행 지시를 우선한다.

## 변경 경계와 단계별 정합성

| 단계 | 실제 제품 경로 | 정합성 검토 / 검증 경계 |
|---|---|---|
| RC-01 | `data/temp/owned_temp_store.dart`, `temp_ownership.dart`, `photo_store.dart` | 전용 UUID 루트, 쓰기 전 marker, 독립 revoke/delete 표식, 암호화 DB의 계정·purge 세대 매핑. 실제 파일 fixture와 실제 암호화 DB 테스트. 외부·symlink·unknown을 빈 저장소로 취급하지 않음. |
| RC-02 | `owned_picker_coordinator.dart`, `transcription_screen.dart`, Android/iOS 고정 버전 picker 패치 | 앱 단일 복구/선택 조정. 네이티브 생성 전 소유권, 모든 앱 복사본을 payload에 한정. Android lost-data는 자동 표시·전송·저장하지 않고 정리 후 재선택. 새 작업/오래된 callback의 owner 분리. |
| RC-03 | `share_export.dart`, 개인정보 export provider, seat 진단 export, Android/iOS owned share bridge | 쓰기 전 소유권, OS 직전 동기 guard, share_plus의 전역 복사 cache를 사용하지 않는 직접 공유. 애매한 인계 결과도 유예, cleanup retry에서 재공유 0회. |
| RC-04 | `account_binding.dart`, `auth_gate.dart`, `account_controller.dart`, `photo_retention.dart`, `privacy_providers.dart`, startup/foreground/개인정보·계정 UI | 즉시 작업 세대 무효화, DB wipe 전 독립 정리 책임 보존. 강제 인증 종료는 접근을 즉시 차단. 서버 삭제 영수증 후 재시도는 로컬 단계만 수행. 정리 건수와 unknown을 구분. |
| RC-05 | StudyRepository, 풀이/판독 화면, CameraFrameSource 공통 lease, DB 암호화 준비/승격 잠금 | 기존 후보를 실제 제품 경로로 먼저 재현. DB 3개 실패와 화면·저장소·카메라 11개 실패(8개 원인)를 구분. 기존 10건 보호 회귀와 전체 CI를 유지. |

원본 10건 F-EXPORT/MIGRATION/JOURNAL/EMPTY-DB/CAS/TIMEOUT/PICK/GAZE-CLOSE/COPY/THEME를 새 결함 수에 다시 넣지 않는다. 새 DB 테이블/버전 이전이나 `core/contracts` 메서드 시그니처 변경은 없다. `sync_meta`의 새 값은 기존 암호화 경계 안에 있고, 파일 표식에는 계정·입력·키·토큰·사진 절대경로가 없다. native path override는 기존 locked 버전의 생성/공유 경계만 수정하며 출처·라이선스·원본 hash는 [native 감사](../../third_party/OWNED_NATIVE_AUDIT.md)에 기록했다.

## 파일 경로 원장

`TMP`는 path_provider의 임시 루트다. Android는 앱 cache, 고정 iOS path_provider_foundation 2.6.0은 NSCachesDirectory다. iOS의 NSTemporaryDirectory로 추정하지 않는다.

| 경로 / 생성 주체·시점 | 원본·소유자 / DB | 공유 | 정상·취소·중단 후 정리 / 백업 |
|---|---|---|---|
| 갤러리·사진 라이브러리·외부 provider | 사용자/OS 원본, 앱 DB 소유 아님 | 입력 원본을 공유하지 않음 | 앱 삭제 대상 아님. 외부 backup 정책 통제 불가. |
| `ApplicationSupport/photos/<request>/<id>.*` / 기존 사진 저장 경로 | 앱 사본, 사진 행은 상대경로 | 기존 사진 export 제외 | 기존 30일 정책, 개별 삭제/로그아웃/purge. 원본·파생 파일 함께 처리; 기기 backup 제외 실측은 DEVICE-08. |
| `TMP/soongong-owned-v1/<scope>/<task>/marker.json` / Dart, payload 생성 전 | UUID scope·task·종류·생성/만료, 계정 매핑은 암호화 sync_meta | 없음 | payload 뒤 원장 제거; marker 전 kill도 예약된 UUID 디렉터리에서 회수. cache는 영속 backup 수단이 아님. |
| 같은 task의 `payload/*` / Android camera output, provider stream 복사, resize 및 iOS camera/PHPicker codec | 앱 임시 사본, 캡처된 불변 owner. photo DB 행 없음 | OCR 동의·확인 경계 유지 | 취소·오류·크기 초과·읽기 완료·화면 이탈·revoke 정리. 재시작 시 native producer 종료를 확인하고 고아 사본 정리. 실제 OS 중단은 DEVICE-01~03. |
| 같은 task의 `payload/attachment.json/csv/zip/txt` / Dart export | 명시적 평문 반출 사본, export scope·세대 | 직접 URI/URL, 추가 앱 공유 사본 없음 | 인계 전 확실한 취소 즉시 정리; 인계 시도 이후 기본 24시간과 첫 정리 기회. 명시 삭제는 유예 없음. |
| scope `.revoked`, task `.delete` / Dart/native | 민감 정보 없는 독립 정리 책임. DB wipe 후에도 유효 | 새 URI 열기·지연 item callback 거부 | 실패 시 보존·재시도. payload가 이미 없어도 멱등 수렴. scope tombstone은 늦은 생산자 차단을 위해 남을 수 있으며 사진 bytes 잔여로 세지 않음. |
| task `.shared`, root `.clock` / Dart | 인계 시도·보수적 시간 기준 | 수신 완료 영수증 아님 | rollback/재시작 시 시계 비진행을 감지해 보수적 만료. 프로세스 내 Stopwatch로 lease/보관이 영구 연장되지 않게 함. |
| DB·키·암호화 marker/candidate/predecessor/lock | 암호화 계층 전용 | 없음 | temp scanner 대상 아님. DB를 열 수 없으면 reset하지 않고 bootstrap을 차단. 파일 정리를 위해 DB를 초기화하지 않음. |
| 수신 앱/OS가 보관한 사본·이미 열린 외부 FD | 앱 통제 밖 | 사용자 인계 결과 | 앱 사본 unlink나 revoke로 회수 보장 불가. 물리적 보안 소거 증거 아님. |

pre-RC picker/export가 남긴 소유자 없는 legacy cache를 v1의 완전 정리 증거로 포함하지 않는다. Android의 모호한 lost-data 상태는 unknown으로 보존하며, 임의 절대경로/앱 tmp 전체를 삭제하지 않는다. 업그레이드 fixture와 실제 OS cache 확인은 기기 절차에 포함한다.

## 정책과 실패 처리

- `TempRetentionPolicy.shareGrace` 기본값 24시간, `activeLease` 10분. 변경 가능한 내부 정책이며 플랫폼이 수신 완료를 보장하는 시간이 아니다. 유예는 생성 시각 기준이고 앱이 종료된 동안 정확히 24시간째 실행되는 timer가 아니다. 시작·복귀·개인정보 재시도·다음 export의 첫 실행 기회에 정리한다.
- 명시 로그아웃·계정 삭제·전체 삭제는 기존 작업을 먼저 무효화하고 앱 사본 정리를 즉시 시도한다. 진행 중 공유 중단 영향을 확인 문구에 표시한다. 실패/unknown이면 성공으로 닫지 않는다. 계정 변경은 이전 owner의 정리 책임을 남기며 B 접근·파일과 분리한다.
- `remaining`은 임시 task 수다. 기존 PhotoStore 잔여와 합친 UI는 ‘정리 N건’으로 표시하며 실제 payload 파일 수를 단정하지 않는다. unknown을 0건으로 바꾸지 않는다.
- 공유 success/dismissed/unavailable/throw/timeout은 외부 읽기 완료 증거가 아니다. `.shared`를 호출 전에 기록하고 일반 반환 직후 삭제하지 않는다. 마지막 동기 account/generation guard와 OS 호출 사이에는 await가 없다. OS 대기 동안 DB transaction을 잡지 않는다.
- Android lost-data는 앱 한 곳에서 소비한다. 결과 없음·복수·예외·이전 계정·삭제 이전 세대를 구분하고, 중단된 입력은 새 입력으로 되살리지 않는다. native 상태가 unknown이면 복구와 기능을 막고 다음 기회에 재시도한다.
- 서버 계정 삭제와 최초 로컬 영수증 기록은 분산 원자 transaction이 아니다. 서버 응답 직후 최초 영수증 전 process kill에서는 ‘정확히 한 번’ 재시도를 보장하지 않는다. 이미 영수증이 남은 재시도/계정 변경은 로컬 정리만 수행하며 새 B 자료를 지우지 않는다.
- 파일 flush·논리적 crash fixture·macOS child process exit는 실제 기기 전원 손실이나 parent-directory fsync 보장이 아니다. 물리 내구성은 DEVICE-09/ENC-12에 남긴다.

## 검증 증거와 남은 범위

신규 40개는 테스트 함수 수와 다르다. 각 항목의 기대값·실제값·파일/테스트명·CI 결과·PASS/FAIL/UNVERIFIED/N/A는 PR 본문과 최종 검토 산출물의 표에서 대조한다. 이 문서 작성 시 아직 끝나지 않은 CI를 성공으로 미리 집계하지 않는다. 최종 보고는 PR HEAD/base/CI checkout/tree를 대조한 뒤 작성한다.

- [RC05 기준 재현과 수정 경계](EXT-FIX-02-RC05.md)
- [TMP/DEL/REG 증거 대조](rc-temp-account-evidence.md)
- [DEVICE-01~12 절차·자원·미검증](EXT-FIX-02-DEVICE.md)
- 전체 gate: analyze-test(codegen clean/analyze/문구/전체 Flutter), server-tests(pgTAP/Deno/typecheck), study-worker(Python), native-check(Android dev Debug, iPhone ARM64 dev Release/no-codesign 및 native 소유권 검사).

로컬 Flutter/pub의 metadata 접근은 앞선 자동 승인 검토에서 거절됐다. 우회하지 않고 허용된 GitHub Actions에서 테스트한다. 직접 Dart formatter는 구문/정렬 처리만 하며 테스트 통과 증거가 아니다.

기존 58개 판정의 실제 모델·기기·물리 저장장치·성능·화면읽기 조건은 host CI만으로 PASS가 되지 않는다. 실기기 12개는 자원/절차를 준비했지만 실행 환경이 없어 UNVERIFIED다. S13 실제 sync/기기 복원은 여전히 FakeSyncEngine이며 구현 자체가 남았다. 승인된 실제 모델 환경·평가 자료/합격선, 공개 사용량·비용·queue/ingress도 별도 미완료다. Draft 유지와 병합·배포·공개 활성화 금지는 최종 보고 후에도 유지한다.
