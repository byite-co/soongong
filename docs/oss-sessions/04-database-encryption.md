# EXT-04 — DB 전체 암호화

> 구현 상태 갱신: 이 문서는 사전 계획이다. 순차 적용된 코드·한계는 [EXT-04 인계](../handoff/EXT-04.md), 최신 검증은 [EXT-FINAL](../handoff/EXT-FINAL.md) 참조.

이전: [EXT-03](03-gaze-inference.md) · 다음: [최종 통합 점검](05-final-integration.md)

## 세션 시작 지시문

> 앞 세션까지의 최종 SQLite DB 전체를 암호화한다. 현재 로그아웃·계정 전환·purge 실제 동작과 모든 로컬 테이블을 먼저 확인한다. SQLite3MultipleCiphers 지원 바이너리, 별도 보안 저장 키, 평문→암호화 이전과 중단 복구를 구현한다. 미동기화 데이터 손실 없이 Android/iOS release 빌드에서 검증하고 main에는 병합하지 않는다.

범위 가정: 앞선 온디바이스 보안 후보 S2와 연결하여 **기기 내 SQLite 전체 파일**을 대상으로 한다. outbox/meta/conflicts/snapshot과 EXT-01~03 신규 테이블도 포함한다. Supabase 서버 Postgres의 고객 관리 키/E2EE, 이미지 파일, 사용자가 내보낸 JSON/CSV/ZIP의 암호화까지 완료했다고 주장하지 않는다. 서버 DB까지 뜻하는 요구가 추가되면 RLS/검색/sync/백업과 양립하는 별도 설계를 추가해야 한다.

## 현재 코드와의 정합성

- `lib/data/db/app_database.dart`: schemaVersion 2, 19개 등록 테이블, `driftDatabase(name: 'soongong_$flavor')`, WAL. 이 수치는 준비 시 기준이며 구현 시 새 테이블을 다시 열거한다.
- `syncTables`는 DB 전체가 아니다. 이것만 복사하면 outbox/meta/conflicts/snapshot/원장 캐시 등 로컬 데이터가 빠진다. schema 객체·인덱스·trigger·user_version까지 보존한다.
- `lib/data/auth/account_binding.dart`와 PR #8 logout 실행 경로는 DB 기록을 유지한다. 헤더의 “logout wipe” 주석을 근거로 로그아웃 때 키를 삭제하면 다음 로그인에서 기록을 잃는다. 실제 동작을 보존하고 틀린 주석은 함께 고친다.
- PR #9의 secure auth tombstone·PKCE·device ID 키는 별개다. DB 키 도입을 이유로 secure storage 전체를 삭제하지 않는다.
- `lib/data/repositories/repository_providers.dart`, 부트스트랩·startup·PR #8 purge는 DB 사용 가능 시점에 의존한다. 비동기 키 준비/이전 동안 기존 provider가 먼저 DB를 열지 못하게 명시적 초기화 gate를 만든다.

## 바이너리와 키 설계

기존 lock의 sqlite3 3.5.2 공식 아카이브 문서에서 `hooks.user_defines.sqlite3.source: sqlite3mc` 지원을 확인했다. 패키지 버전을 무조건 최신으로 올리는 작업부터 시작하지 않는다. 현재 Drift/Flutter/native asset 조합을 확인하고 필요한 최소 변경을 선택한다. 과거 `sqlcipher_flutter_libs` 방식과 두 SQLite 바이너리를 혼합하지 않는다.

현재 lock에는 `sqlcipher_flutter_libs 0.7.0+eol`, `sqlite3_flutter_libs 0.6.0+eol` 전이 항목도 있다. 이 이름이 있다는 이유로 이미 암호화됐다고 판단하지 말고, 실제 의존 경로와 최종 링크된 native asset을 확인한다.

- 플랫폼 CSPRNG로 생성한 256bit 키를 기존 플랫폼 secure storage의 **DB 전용 namespace**에 저장한다. flavor·프로젝트·DB 파일 식별을 분리하고 인증 access token/사용자 비밀번호를 DB 키로 쓰지 않는다.
- 실제 배포 바이너리의 SQLite3MultipleCiphers/SQLite 버전, cipher 방식·KDF/포맷 설정, native artifact 해시·라이선스를 기록한다. 조사한 upstream HEAD가 실제 앱에 포함된 버전이라고 가정하지 않는다.
- 키를 설정하기 전 schema query가 실행되지 않게 한다. release 모드에서도 cipher 지원과 올바른 키로의 읽기를 확인하고, 지원이 없으면 실패를 표시한다. assert-only 검사나 오류 후 평문 fallback은 금지한다.
- Keychain/Keystore 접근 가능 시점, 기기 잠금·앱 재설치·OS backup/restore 정책을 플랫폼별로 정한다. 키가 없는 기존 DB, 잘못된 키, 잠금 때문에 일시 접근 불가를 구분한다. 조용히 빈 DB를 만들어 “복구 성공”으로 처리하지 않는다.
- 로그아웃은 DB 키를 유지한다. 계정 전환/purge/계정 삭제는 기존 소유권·epoch·보존 정책과 함께 처리하고, 키 회전은 독립적인 crash-safe 작업으로 설계한다. 서버 동기화로 복원할 수 없는 outbox가 있을 수 있음을 전제로 한다.

새 파일 후보: `lib/data/db/db_key_store.dart`, `lib/data/db/encrypted_database_opener.dart`, `lib/data/db/encryption_migration.dart`. 모두 **예정 경로**다.

## 이전 상태 기계

암호화 이전은 일반 데이터 schema migration과 구분한다. 상태 기록에는 키/원문을 넣지 않는다. 동일 볼륨의 임시 파일·기존 파일·검증 상태·정리 상태를 재시작 후 식별할 수 있게 한다.

| 단계 | 해야 할 일 | 중단 후 요구 동작 |
|---|---|---|
| 사전 점검 | 디스크 여유·키 저장 가능·현재 파일/버전 판별, writer/동기화/export/snapshot 중지 | 기존 파일과 미동기화 행 그대로 유지 |
| snapshot | 모든 DB 연결을 정리하고 WAL checkpoint 결과를 확인. SQLite backup/VACUUM 등 일관된 snapshot 사용 | `.db` 파일만 복사해 WAL의 최신 행을 버리지 않음 |
| 암호화 임시본 | 새 키 저장/readback 후 검증된 codec 절차로 암호화. 이전 중 임시 평문도 앱 보호 영역 안에만 생성 | 새 키와 원본을 잃지 않고 재시도 가능한 상태 |
| 검증 | 새 연결로 reopen, integrity_check, schema/user_version, 모든 테이블 행 수와 canonical digest 비교 | 검증 실패 시 원본 유지, 자동 새 DB 생성 금지 |
| 교체 | 파일/디렉터리 내구성 보장 절차와 같은 볼륨의 원자적 rename, migration marker 갱신 | rename 전후 어느 쪽인지 판단해 검증된 파일로 복구 |
| 정리 | durable commit 확인 후 기존 평문·WAL/SHM·임시본·backup 잔여 제거, 삭제 결과 확인 | 정리 실패를 성공으로 숨기지 않고 다음 시작에 정리 재개 |
| 재개 | 암호화 DB로 provider/동기화/export를 다시 열고 상태 해제 | 이전 완료 전 writer가 잘못된 파일에 쓰지 못함 |

현재 codec 버전의 WAL rekey 지원을 확인하지 않은 채 열린 DB에서 단순 `PRAGMA rekey`만 실행하지 않는다. hash/검증 결과는 원문이나 키와 함께 로그에 남기지 않는다. 플래시의 물리적 덮어쓰기/완전 삭제를 보장한다고 표현하지 않는다.

## 검증 행렬

| 대상 | 필수 재현 |
|---|---|
| 기존 데이터 | v1→현재 schema, 현재 평문 DB, 빈 DB, 큰 DB, 삭제 tombstone, 신규 OCR/풀이 테이블 |
| 동기화/계정 | 미전송 outbox, 충돌 행, snapshot, PR #8 pending purge/receipt·epoch, 같은 계정 재로그인·계정 전환 |
| 중단/실패 | 각 단계 프로세스 종료, 디스크 부족, checkpoint busy, rename 실패, 정리 실패, 키 저장/readback 실패 |
| 키 | 잘못된 키·키 소실·잠금 중 접근 불가·키만 있고 파일 없음·파일만 있는 OS 복원, 키 회전 중단 |
| 파일 | 올바른 키로 전체 읽기/무결성, 잘못된 키로 실패, 평문 SQLite 도구로 조회 실패, WAL/temp/backup 평문 잔여 점검 |
| 기기 | Android/iOS release 빌드 native codec 실제 탑재, 콜드 스타트·잠금 해제·재시작·export·성능/배터리 측정 |

SQLite 헤더가 보이지 않는 검사 하나만으로 암호화 검증을 끝내지 않는다. in-memory unit test는 파일·secure storage·codec·이전 원자성을 증명하지 않는다. 앱 최초 실행 지연/DB open·읽기·쓰기 p50/p95와 이전 소요·최대 디스크 사용량도 기록한다.

되돌리기 정책: 암호화 후 옛 평문 전용 앱 바이너리는 해당 파일을 열 수 없다. feature flag를 껐다고 자동 복호화하거나 기존 backup을 되살리지 않는다. 배포 복구는 암호화 포맷을 읽는 수정 버전으로 roll-forward하는 것을 기본으로 하고, 이전 전 실패 복구와 이전 후 배포 rollback을 구분해 문서화한다.

`docs/handoff/EXT-04.md`에는 최종 schema와 모든 테이블 검증 목록, 바이너리/키 수명 정책, 단계별 장애 주입 결과, 실제 기기 결과, 남은 평문 파일 범위, 복구 절차를 남긴다.
