# RC 임시파일·계정 경계 증거 대조표

2026-10-13. 신규 40개 중 **TMP-01~08, DEL-01~08, REG-02/04의 18개**를 대조한 보조 인계 문서다. 원본 58개 판정표를 대체하거나 합산하지 않는다.

테스트 목록은 통합 커밋 `8ebdd9e`와 추가 테스트 `fe1e36a`, lifecycle 중첩 테스트 `9a082a1`에서 확인했다. `fe1e36a`의 recovery gate·깨진 symlink 회귀는 통합 담당자의 대응 제품 수정이 필요하다. 이 문서 작성 시 최종 통합 HEAD의 실행 로그는 아직 확인하지 않았다. **아래 상태는 모두 UNVERIFIED(최종 CI 대기)**다. 테스트 소스가 있다는 이유로 PASS로 쓰지 않는다.

최종 담당자는 PR HEAD, base main, CI checkout SHA, tree SHA, 네 workflow URL과 실제 pass/fail/skip 수를 [EXT-FIX-02](EXT-FIX-02.md)에 기록하고, 아래 각 행에서 실행된 범위만 판정해야 한다. merge-ref 실행이면 HEAD와 tree가 일치하는지 확인한다. 제품/테스트가 바뀐 뒤 이전 초록 CI를 재사용하지 않는다.

## 증거 수준

- **FS**: 실제 임시 디렉터리·파일·symlink·재시도 결과를 검사한다. root/열거/삭제 오류 일부는 주입한다. 실제 OS 저장소 부족·보호 잠금·프로세스 kill은 아니다.
- **DB**: 실제 파일 sqlite3mc/Drift executor와 암호화 DB를 검사한다. 키 저장소는 합성 구현이다. Android/iOS Release의 Keychain/Keystore·잠금·backup 동작은 아니다.
- **APP**: 실제 provider/controller/repository를 사용한다. AppHarness DB는 in-memory SQL이고 auth/server 응답은 FakeAuthBackend/GatedAuthBackend다.
- **UI**: 실제 Flutter 화면·modal/router 함수를 실행하는 host widget 검사다. 실제 수신 앱·카메라·화면 읽기·OS 인증 만료를 뜻하지 않는다.
- **STATIC**: 호출 연결/문구/로그 인자 검토다. 런타임 결과나 산출물 전체 검사로 승격하지 않는다.

## TMP-01~08

| ID | 기대값 | 실제 작성된 검사·증거 | 아직 입증하지 않은 조건 |
|---|---|---|---|
| TMP-01 | 두 계정·두 기능·외부 원본 중 대상 소유 파일만 삭제 | FS: `owned_temp_store_test.dart`의 `TMP-01 two account scopes and two features preserve other bytes`는 A의 picker/export만 없애고 B 두 파일과 외부 원본 bytes를 비교한다. DB: `temp_ownership_test.dart`의 `TMP-01 account mapping is in real encrypted DB and absent from plaintext ledger`는 owner/generation/scope 매핑, 평문 marker에 계정·절대경로 부재, DB 평문 읽기 불가를 검사한다. | 실제 사진 라이브러리·공유 수신 앱은 fixture 밖이다. DB 암호화가 payload 파일 암호화까지 뜻하지 않는다. |
| TMP-02 | traversal·유사 접두사·외부 symlink 삭제 0회 | FS: `TMP-02 traversal and similar prefixes are never owned`; `TMP-02 $position symlink never deletes its external target`의 payload-file/task-directory/scope-directory 3분기; 추가 `TMP-02 broken task symlink is unknown, never treated as absent`. `photo_store_ownership_test.dart`의 `TMP-02 legacy PhotoStore never follows external directory or derived symlinks`도 유지한다. | symlink fixture는 host filesystem 증거다. 다른 프로세스가 매 syscall 사이 경로를 교체하는 모든 TOCTOU를 증명하지 않는다. |
| TMP-03 | 루트·열거 실패는 unknown, 재시도 유지 | FS: `TMP-03 root lookup failure reports unknown and remains retryable`, `TMP-03 directory enumeration failure cannot be reported as zero remaining`. 추가 `TMP-03 recovery uncertainty blocks sweep before deletion or clock mutation`은 recoveryReady=false에서 root 호출 0회, `.clock` bytes 불변, payload 보존 후 gate가 열리면 회수를 검사한다. legacy store의 `TMP-03 legacy cache root failure is unknown rather than zero cleaned`도 있다. | 실제 보호 잠금/권한/저장소 부족은 DEVICE-06/07. 새 recovery guard 제품 수정과 같은 HEAD로 테스트해야 한다. |
| TMP-04 | 실패 보존·중복 재시도 합류·멱등 수렴 | FS: `TMP-04 failed deletion leaves evidence and joined retries converge`는 `.delete` 유지, 동일 sweep Future, 회수 후 cleanup 반복을 검사한다. `TMP-04 native producer uncertainty keeps the obligation until quiescence`는 beforeDelete=false/throw/true에서 보존·unknown·후속 회수를 검사한다. | beforeDelete의 네이티브 응답은 대체했다. 실제 native writer의 quiescence나 열린 외부 fd 회수 증거가 아니다. |
| TMP-05 | 생성/원장 기록 사이 중단 뒤 소유 파일 회수 | FS: `TMP-05 restart finds a payload whose task marker was interrupted`는 정상 생성한 task의 marker를 제거하여 중단 상태를 구성하고, 새 OwnedTempStore가 payload와 task를 회수함을 검사한다. STATIC: 제품 생성은 소유 task 디렉터리/marker를 payload보다 먼저 만든다. | 실제 생성 중 해당 instruction 위치에서 process를 kill한 검사는 아니다. native pre-callback 생성 지점과 실기기 kill은 PICK-08/DEVICE-02/03에서 따로 확인한다. |
| TMP-06 | 원장 기록 후 삭제 전 중단에도 정리 의무 유지 | FS: `TMP-06 durable revocation survives interruption before deletion`은 shared 파일에 `.revoked`만 남긴 상태에서 새 store를 만들고 즉시 회수한다. | 같은 host process 안에서 객체를 새로 만든 재시작 fixture다. 물리 전원 손실/flush 내구성은 별도다. |
| TMP-07 | payload 삭제 후 원장 제거 전 중단에 오류 루프 없음 | FS: `TMP-07 payload absent before ledger removal finishes without an error loop`는 `.delete` 유지·payload 부재 상태에서 새 store의 연속 두 sweep이 완료되고 task 디렉터리가 없어짐을 검사한다. | OS kill/물리 전원 손실은 직접 실행하지 않았다. |
| TMP-08 | DB wipe/rebind 뒤 A 의무·B bytes 보존 | DB+FS: `TMP-08 DB wipe and account rebind preserve old cleanup obligation and new bytes`; `TMP-08 restart recovers failed old-scope deletion after the mapping was wiped`; `TMP-08 failed durable revocation blocks success and retains encrypted mapping`. 마지막 검사는 `.revoked` 위치에 실제 디렉터리를 만들어 marker 기록을 실패시킨다. | Android/iOS 강제 종료와 DB wipe 순서의 실기기 증거는 DEVICE-05/06/09. DB 매핑 보존과 실제 파일 삭제는 각각 확인해야 한다. |

파일: [owned_temp_store_test.dart](../../test/unit/data/owned_temp_store_test.dart), [temp_ownership_test.dart](../../test/unit/data/temp_ownership_test.dart), [photo_store_ownership_test.dart](../../test/unit/data/photo_store_ownership_test.dart).

## DEL-01~08

| ID | 기대값 | 실제 작성된 검사·증거 | 아직 입증하지 않은 조건 |
|---|---|---|---|
| DEL-01 | 로그아웃 시작 시 이전 OCR/export 무효화·대상 파일 정리·정확한 완료 표시 | APP+FS: `account_temp_lifecycle_test.dart`의 `DEL-01 logout synchronously invalidates pending picker and export then removes both`는 실제 controller 호출 직후 두 task의 늦은 file 접근 거부, 두 디렉터리 삭제와 signOut 1회를 검사한다. 기존 `settings_s09_test.dart`의 `logout: photos wiped, records kept, signed out`와 `settings_flow_test.dart`의 `account screen: email · provider · consent ①·② facts · sync "—" / 미연결; 로그아웃 → gate`를 유지한다. | 이 새 DEL-01 test의 picker/export는 실제 owned task이며, 모델 OCR 응답을 로그아웃 동안 멈춘 end-to-end 시험은 아니다. 실제 OS picker/share 대기 및 늦은 네이티브 callback은 DEVICE-05. |
| DEL-02 | 사용자 로그아웃 실패/unknown을 성공으로 닫지 않고 재시도 | APP+FS: `DEL-02 explicit logout on unknown cleanup stays signed in and can retry`는 PhotoWipeFailed.storeUnavailable, signOut 0회·A 세션 유지, 재시도 성공을 검사한다. 기존 `s09b_regressions_test.dart`의 `D: logout with an undeletable photo does not sign out; the row stays for a retry`, `s09c_regressions_test.dart`의 `repro: logout with an undeletable cache file does not sign out`는 알려진 파일 실패를 검사한다. | 새 로그아웃 unknown 문구는 AccountScreen 연결 STATIC 증거다. 실제 기기 권한/공간 실패와 screen reader 재시도 식별은 별도다. |
| DEL-03 | 강제 인증 종료는 접근을 즉시 막고 정리 실패 의무 유지 | APP+FS: `DEL-03 forced sign-out gates access despite cleanup failure and durable owner remains`는 backend session 이벤트 후 SignedOut, task 접근 거부, 기존 파일/DB owner 보존, 복구 뒤 revoke 수렴을 검사한다. | backend는 합성 세션 이벤트다. 실제 토큰 만료·SDK 재시작·OS 저장소 보호는 직접 실행하지 않았다. 이 test는 process restart 증거가 아니다. |
| DEL-04 | 오래된 A 정리/callback이 B와 새 A의 내용·파일을 변경하지 않음 | APP+FS: `DEL-04 failed durable revocation blocks account B binding and cached sign-in`은 storageBlocked, userId=null/hasUser=false, home→launch redirect, A binding 보존, 재시도 후 B bytes 보존을 검사한다. `DEL-04 old controller stays cancelled across A to B to A`는 이전 controller의 logout 거부를 검사한다. DB+FS: `DEL-04 delayed old A revoke cannot collect the fresh A scope after A to B to A`는 실제 Drift transaction 밖에서 대기한 old revoke가 새 scope/tombstone/bytes를 건드리지 못함을 검사한다. legacy `DEL-04 deletion rechecks owner after asynchronous root resolution`도 포함한다. | router/foreground의 정상 사용자 경로 차단이다. 모든 repository 직접 API에 보편적인 auth 검사가 새로 생긴 것은 아니다. 실제 기기 account 전환·native callback은 DEVICE-05. |
| DEL-05 | purge 뒤 늦은 picker/write 반환의 재생성·전송·저장 0회 | APP+FS: `temporary_privacy_test.dart`의 `DEL-05 purge revokes picker/export before await and preserves unrelated scope`, `DEL-05 temp epoch alone cancels encoding without purge generation change`. DB: `DEL-05 stale purge generation cannot allocate a task or reuse the old scope`. 기존 `transcription_race_test.dart`의 `PICK-01/02/03 late $failure after purge cannot change new selection`, 기존 `export_race_test.dart`의 `EXP-05 actual action and adapter cancel $cancel during file write`를 함께 확인한다. | 옛 EXP/PICK 테스트 prefix는 이전 검토의 번호다. 신규 EXP-05 등의 의미로 재분류하면 안 된다. host의 controlled engine/picker/native stand-in은 실제 모델/기기 반환 증거가 아니다. |
| DEL-06 | server purge 성공 후 로컬 실패를 부분/대기로 구분·같은 요청 유지 | APP+FS: `temporary_privacy_test.dart`의 `DEL-07 served purge and failed durable cleanup resume locally without another server delete`는 이름과 달리 실제 `purge-all` 1회와 pending epoch, rows/map 보존, resume 로컬 완료를 검사하므로 **DEL-06** 근거다. `DEL-06/08 failed payload deletion retains retry evidence; duplicate retry is harmless`, `DEL-06 unreadable root with no account mapping is unknown, never all done`도 있다. UI: `DEL-06 unreadable temporary store shows unknown and real retry clears notice`, `DEL-07 server-confirmed local pending UI retries local work without a second purge`도 **DEL-06**이다. | 두 DEL-07 prefix 사례를 계정 탈퇴 증거로 쓰지 않는다. purge 서버는 fake이며 실제 Edge/SQL 계약은 별도 server-tests gate가 필요하다. |
| DEL-07 | server 계정 삭제 성공 후 로컬 실패를 구분·로컬만 재시도 | APP+FS: `DEL-07 server acknowledgement and local failure persist distinct receipt and retry only local work`; `DEL-07 new controller reads confirmed receipt and never repeats server deletion`; `DEL-07 failed sign-out keeps receipt and a rebuilt gate refuses deleted cached session`; `DEL-07 old acknowledged response cannot wipe or sign out newly bound B`. UI: 추가 `account_cleanup_test.dart`의 `DEL-07 account deletion modal distinguishes acknowledged server deletion and retries only local cleanup`는 실제 AccountScreen/AppModal에서 전용 문구, 일반 서버 실패 문구 부재, receipt/일반 기록 보존, retry 후 modal 종료·delete-account 총 1회·DB 정리를 검사한다. | 첫 로컬 receipt 기록 전에 process가 죽는 원격/로컬 원자성 공백이 남는다. gate 재생성은 실제 앱 kill/relaunch가 아니다. 아래 한계 절을 반드시 함께 보고한다. |
| DEL-08 | 시작·foreground·화면 진입 중복 sweep 합류·새 파일 보존 | FS: `TMP-04 failed deletion leaves evidence and joined retries converge`는 같은 store의 겹친 sweep Future가 동일함을 확인한다. APP: `DEL-06/08 failed payload deletion retains retry evidence; duplicate retry is harmless`는 연속 retention retry를 확인한다. UI+FS: `temporary_lifecycle_overlap_test.dart`의 `DEL-08 startup foreground and privacy join one cleanup and preserve new tasks`는 실제 runStartupTasks, ForegroundActivityHook의 resumed, PrivacyScreen 진입을 beforeDelete 대기로 겹쳐 같은 Future·physical scan/삭제 1회·B active task 및 직렬 대기한 새 B task bytes 보존을 검사한다. | 추가 widget은 desktop-host 분기를 실행한다. beforeDelete 대기는 합성 native 경계이고 Android/iOS 복구·OS lifecycle 검증이 아니다. 최종 CI 실행 전에는 작성/정적 검토 증거만 있다. |

파일: [account_temp_lifecycle_test.dart](../../test/unit/application/account_temp_lifecycle_test.dart), [account_cleanup_test.dart](../../test/widget/account_cleanup_test.dart), [temporary_privacy 단위 검사](../../test/unit/application/temporary_privacy_test.dart), [temporary_privacy UI 검사](../../test/widget/temporary_privacy_test.dart), [temporary_lifecycle_overlap_test.dart](../../test/widget/temporary_lifecycle_overlap_test.dart), [transcription_race_test.dart](../../test/widget/transcription_race_test.dart), [export_race_test.dart](../../test/unit/data/export_race_test.dart).

## REG-02: DB 보호 회귀

**판정 UNVERIFIED: 최종 같은 tree의 analyze-test 및 native-check 대기.** host codec 검사가 통과한 뒤에도 DEVICE-07/08/09를 자동 승격하지 않는다.

| 파일 | 정확한 검사명/매개변수 | 확인하는 범위 |
|---|---|---|
| [encrypted_schema_migration_test.dart](../../test/unit/data/encrypted_schema_migration_test.dart) | `MIG-01/JRN-01 real encrypted opener: v$version, schema/version, data and final policy` (v0/1/2); `MIG-02/04 v$version $fault rolls back schema and version; new executor retries` (afterDdl/beforeVersion/versionWrite/afterVersion); `MIG-03 v$version $fault leaves completed v3 and retries without duplicate mutation` (afterCommit/afterPolicy) | 실제 encrypted Drift의 schema/user_version, text/BLOB/outbox·객체·autoincrement, commit 전 rollback과 commit 후 재시도. 예외/SQL 쓰기 실패 주입이며 kill은 아니다. |
| 같은 파일 | `MIG-05 known partial v2 plus exact study table recovers without changing rows`; `MIG-05 rejects ${fixture.key} without changing schema/data/version`; `JRN-02 real encrypted writes and repeated reopen keep DELETE and MEMORY`; `JRN-01 in-memory DB retains valid memory journal and MEMORY temp store` | 정확한 legacy schema만 허용하고 final 실제 PRAGMA를 읽는다. 문자열 검색으로 journal 정책을 대신하지 않는다. |
| [database_creation_protection_test.dart](../../test/unit/database_creation_protection_test.dart) | `DB-01 existing ciphertext truncated to zero is preserved and does not write key`; `DB-02 existing empty file without key creates neither key nor database`; `DB-01 successful preparation is not reused after failed schema open`; `DB-01 stale prepared executor refuses $damage file at first query` (empty/missing) | 실제 파일 보존, 키 write 0회, 준비 성공 캐시/낡은 executor 재사용으로 빈 DB가 생기는 fallback 거부. |
| 같은 파일 | `DB-03 absent file with durable new key reaches real encrypted Drift schema`; `DB-03 preparation joins only concurrent work and revalidates later success`; `DB-04 first creation exception at $stage resumes only an absent or valid encrypted file` (creating/created_empty/created_encrypted/creation_verified); `DB-05/06 real codec $fault preserves files and never generates key` | 정상 생성, 동시 준비 합류, 네 생성 중단 상태, wrong-key/missing-key/truncated-nonzero/bad-marker/unknown-marker/orphan-copy/temporary-marker 보존. |
| [database_protection_test.dart](../../test/unit/database_protection_test.dart) | `whole DB encrypted; schema, binary outbox, user version and custom table preserved`; `wrong key fails without changing the encrypted file`; `restart recovers after $crash without losing pending rows`; `uncheckpointed WAL is included in migrated data`; `fresh database is encrypted before schema creation` | 이전 보호, recovery fixture와 WAL 데이터 보존 유지. |
| [database_preparation_race_test.dart](../../test/unit/database_preparation_race_test.dart) | `RC05 another isolate is rejected before key access while preparation holds the lock`; `RC05 two independent openers never replace the first usable durable key`; `RC05 an old plaintext writer cannot acknowledge a row omitted by promotion`; `RC05 verified recovery refuses a source changed after interruption` | 실제 연결/다른 isolate 경합, durable key 1개, 승격 중 구 writer의 acknowledged row 보존, 중단 이후 바뀐 원본·candidate 보존 차단. secure storage만 합성 경계다. |

RC05의 최초 후보 3개는 [baseline analyze-test 실행](https://github.com/byite-co/soongong/actions/runs/38337062234)에서 실패하여 재현됐다. 이 실행은 수정 후 성공 증거가 아니다. 별도 isolate 회귀는 수정과 함께 추가했다. baseline 실패 로그의 합성 키 assertion 출력은 최종 배포 산출물에 그대로 재수록하지 않는다.

## REG-04: 로그·진단·산출물

**판정 UNVERIFIED.** 아래 부분 회귀와 정적 수정만으로 전체 로그·진단·CI artifact·앱 package에 노출 0건이라고 보고할 수 없다.

| 증거 | 실제 단언 | 남은 확인 |
|---|---|---|
| [photo_store_path_test.dart](../../test/unit/data/photo_store_path_test.dart)의 `failure logs carry the failure kind only — never the path (CLAUDE.md §7)` | root FileSystemException 이후 LogEvent에 error 객체가 없고 message에 fixture 절대경로/private.jpg가 없으며 오류 타입만 있는지 검사 | OwnedTempStore/native bridge/AppModal/AuthGate와 최종 CI 전체 로그를 포괄하지 않는다. |
| [auth_repository_test.dart](../../test/unit/data/auth_repository_test.dart)의 `birth date and email never reach the log output` | Logger 출력에 합성 생일 2개, 합성 이메일, 특정 token marker가 없는지 검사 | 모든 토큰/키/원문 경로 및 모든 예외 분기의 증거가 아니다. |
| TMP-01 실제 encrypted mapping/평문 marker 검사 | 계정 owner 및 fixture 절대경로가 plaintext ledger에 없고 account map은 DB 암호화 경계 안에 있는지 확인 | 공유 payload에는 의도한 export 내용이 있다. payload를 암호화했다거나 외부 사본을 회수했다는 증거가 아니다. |
| RC05 키 비교 변경 | assertion은 key 문자열을 직접 expected/actual에 출력하지 않고 boolean 동등성·write 횟수를 검사 | baseline 실패 로그와 과거 artifact는 별도로 처리해야 한다. 새 테스트가 과거 로그를 소급 정화하지 않는다. |

최종 REG-04 증거에는 검사한 로그/artifact의 이름·commit SHA·hash·검사 방법과 발견/조치 결과를 남겨야 한다. 합성 fixture만 사용했는지 확인하고, 실제 사용자 디렉터리·사진·토큰·서비스 secret을 수집하거나 보고서에 복사하지 않는다. 진단 export를 포함한 실제 native 앱 로그 검사는 기기 실검증으로 남는다.

## 삭제 receipt와 실패 복구의 정확한 한계

`confirmed_account_deletion_v1`은 기존 암호화 `sync_meta`에 저장한다. server 삭제가 확인된 뒤 로컬 실패하면 receipt/계정 binding을 남겨 `retryLocalCleanup()`이 server 삭제를 재호출하지 않게 한다. 로컬 DB 정리가 완료돼도 SDK signOut이 실패하면 receipt를 유지하여 복원된 삭제 계정 session이 다시 일반 계정으로 bind되지 않게 한다. 새 B binding이 있으면 오래된 A 응답은 B DB/파일/signOut을 건드리지 않는다.

원격 delete-account 성공과 첫 로컬 receipt 저장은 원자 transaction이 아니다. **서버 응답 직후 receipt 기록 전에 kill되거나 DB가 영구적으로 쓰기 불가해진 경우까지 “서버 재호출 0회”를 증명하지 않았다.** 현재 회귀는 receipt가 기록된 이후의 재시도와 gate 재생성을 다룬다. 실제 프로세스 재시작, OS session persistence, 저장소 보호/전원 손실을 검증하지 않았으므로 이 공백을 완료로 숨기지 않는다.

native producer가 실제로 종료됐는지 알 수 없으면 cleanup은 unknown/pending으로 남는다. 공유 수신 앱 사본이나 이미 열린 fd를 강제로 회수하는 것은 지원 범위 밖이다. 파일 unlink/bytes 덮어쓰기는 물리 보안 소거의 증거가 아니다.

## 실행 위치와 다음 검토

로컬 Flutter/pub metadata 접근이 자동 승인 검토에서 거절된 이력 때문에 이 세션은 Flutter/pub/analyze/test를 실행하지 않았다. 허용된 cached Dart formatter와 `git diff --check`만 실행했다. 패키지 미해결 formatter 경고를 analyze 통과로 취급하지 않는다.

허용된 GitHub Actions에서 기존 `analyze-test.yml`의 전체 codegen clean-tree/analyze --fatal-infos/금지문구/model hash/Flutter test gate를 실행한다. 관련 회귀만 선택하려면 동일 workflow 환경에서 위 파일을 명시하되, 선택 실행이 최종 전체 gate를 대체하지 않는다. DB/symlink 검사는 실제 host library와 filesystem을 쓰므로 runner OS도 기록한다. `server-tests.yml`, `study-worker.yml`, `native-check.yml`은 원래 범위를 유지한다.

최종 CI 이후에도 Android/iOS 실제 picker/share·kill·잠금·backup·수신 앱·전력/성능·화면읽기, 실제 OCR/수학 모델, S13 sync/복원, 공개 서비스 준비는 별도 미검증/미구현이다. 이 문서는 병합·배포·공개 활성화 승인 문서가 아니다.
