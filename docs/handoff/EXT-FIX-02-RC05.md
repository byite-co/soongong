# EXT-FIX-02 부록 — RC05 경합 재현 근거

2026-10-13. 사용자의 남은 코드 구현 지시 범위에서 수행했다. 이 문서는 원본 58개 항목의 전체 PASS나 병합 가능 판정이 아니다. 최종 통합 HEAD의 회귀 결과는 아래 별도 기록란을 채워 확정한다.

## 기준과 진단 실행

- 제품 기준: `d55bbfe6c7d4ed318a366f4613dc819f5188ea61`.
- 보정 진단 HEAD: `4623e4ee6fd2ca370b1eb67107156802793d7533`.
- [보정 baseline CI 38339498336](https://github.com/byite-co/soongong/actions/runs/38339498336), workflow_dispatch, 2026-10-13 02:59:03–03:04:17 UTC. Analyze/문구/codegen 검사 통과, Test 실패. 실제 집계 **772 PASS / 11 FAIL, 총 783**. 테스트 skip 없음. 실패 후 codegen artifact 등 실행 조건이 맞지 않아 생략된 workflow step을 테스트 skip 수에 섞지 않는다.
- 기준과 진단 HEAD의 전체 diff는 `test/helpers/study_race_harness.dart` 및 아래 회귀 4개 파일뿐이다. `lib`, Android/iOS, worker/서버 제품 변경은 0이다. 기존 769개 테스트에 신규 14개를 추가했으며 신규는 **3 PASS / 11 FAIL**이다.
- 수정 시작 commit `275341147a73df7ea72dffadbfd4f3f97340821e`; fixture/문법 후속 `97385f2eaa5d5cd54ae1611381fbb555bc50db77`. 통합 시 cherry-pick SHA가 달라질 수 있으므로 최종 트리와 CI를 함께 기록한다.

이전 진단 [38338643394](https://github.com/byite-co/soongong/actions/runs/38338643394)도 772/11이었지만 제품 assertion 7개와 fixture 실패 4개가 섞여 있었다. purge helper의 `clearPending` 누락 3개, `RawTooltip`을 `IconButton`으로 읽은 finder 오류 1개를 바로잡았다. 보정 실행의 11개는 모두 아래 제품 assertion 실패이며 그 fixture 오류는 남지 않았다. 이전 실패 수와 보정 실패 수를 더하지 않는다.

## 후보별 실제값과 변경

원인 수는 서로 다른 수정 경계로 집계한다. 동일 UUID 문제의 두 owner 조합, 동일 revision 문제의 두 관측값, 동일 delete snapshot 문제의 purge/account 조합을 중복 집계하지 않아 **8개 원인 / 실패 테스트 11개**다. 아래 로그 위치는 보정 run의 `analyze-test / Test` 단계다.

| 원인 / 원본 후보 | 실제 제품 재현 절차 | 기대값 → baseline 실제값 | 최소 변경 / 회귀 | 증거 시각 UTC |
|---|---|---|---|---|
| RC05-01 / INT-04 | 실제 StudyRepository/SyncWriter에서 기존 문서 ID를 newId로 다시 제공해 신규 저장. 같은 owner와 다른 owner를 각각 실행. | 둘 다 거부, 원본 불변 → 둘 다 예외 없이 StudyDocument 반환(2 FAIL). 후속 원본 동일 assertion에 도달하기 전에 실패. | 신규 INSERT-only; 기존 수정은 owner+revision 조건 UPDATE. `study_repository_race_test.dart`: UUID collision preserves the u1/u2 original row. | 03:02:54.705 / .729 |
| RC05-02 / INT-04 | planner softDeleteItem 후 그 ID를 study 문서에 연결. | StateError, 저장 0 → 문서 반환(1 FAIL). | planner의 pending_delete_until 제외. 같은 파일: pending planner is refused and undo restores eligibility. 수정 후에는 undo 뒤 정상 연결까지 검사. | 03:02:54.772 |
| RC05-03 / RACE-05 | 실제 풀이 화면에서 결과 표시/진행 중 각각 문서 revision을 1→2로 저장하고 provider 갱신. | 이전 답변 제거 및 새 작업 가능 → old answer가 남음; 진행 중 요청의 busy=true가 유지됨(2 FAIL). | ID/revision 렌더 guard, revision/삭제 때 작업 무효화, operation key. `problem_solver_race_test.dart`: revision edit removes cached displayed solution; stale solver error/finally cannot clear newer request. 두 번째 baseline은 busy 해제 assertion에서 멈췄으므로 그 이후 stale-error 결과까지 baseline에서 재현했다고 주장하지 않는다. | 03:03:54.548 / .893 |
| RC05-04 / RACE-06 | 삭제 확인창을 연 상태에서 실제 LocalPurge 완료 또는 AuthGate/AccountBinding A→B 전환 후 같은 ID의 새 문서 생성, 옛 확인창 확정. | 이전 dialog 삭제 호출 0 → purge와 account 각각 현재 문서 delete 호출 1(2 FAIL). | dialog 전에 repo/owner/generation snapshot; 확정 뒤 같은 소유권 재검사. `study_action_race_test.dart`: purge/account while delete dialog is open preserves replacement. | 03:03:49.230 / .575 |
| RC05-05 / RACE-06 | 실제 IconButton의 같은 onPressed를 첫 rebuild 전에 두 번 호출. | dialog 1 → AlertDialog 2(1 FAIL). | dialog 전 busy 선점. 같은 파일: delete re-tap opens one dialog; cancel and normal confirm remain usable. | 03:03:49.865 |
| RC05-06 / RACE-06 | 텍스트 저장을 대기시킨 뒤 purge 완료, 새 OCR 시작 후 옛 저장을 반환해 실제 저장소에서 이전 generation 거부. | 새 OCR busy=true 유지 → false(1 FAIL). | `_save` 성공/catch/finally의 operation/owner/generation 검사. 같은 파일: old text save catch/finally cannot alter new OCR after purge. | 03:03:51.003 |
| RC05-07 / RACE-05 | 풀이 저장을 대기시킨 뒤 purge 완료/문서 재생성/새 풀이 시작, 옛 저장 반환. | 새 풀이 busy=true 유지 → false(1 FAIL). | 풀이 저장 완료 경로 operation/owner 및 generation guard. `problem_solver_race_test.dart`: old save failure after purge leaves new solve busy. | 03:03:55.618 |
| RC05-08 / GAZE-02 | 서로 다른 기본 CameraFrameSource로 첫 소유자가 열린 동안 두 번째 open. | camera_busy, 두 번째 initialize 0 → 두 번째 CameraSession 반환(1 FAIL). | 기본 process-wide CameraLease를 probe/open/stream-stop/dispose에 공유. `camera_shared_default_test.dart`: default camera sources never initialize a second owner. | 03:02:00.497 |

파일 위치: repository 테스트는 `test/unit/data/`, 기본 카메라는 `test/unit/engines/`, 화면 테스트는 `test/widget/`. 회귀는 복사한 구현 대신 실제 repository/LocalPurge/SyncWriter/화면/AppButton/Riverpod/CameraFrameSource를 호출한다. 외부 backend, 모델, camera plugin 응답은 fixture로 제어한다. UUID 고정·Completer 지연·메모리 SQL은 실제 기기나 실제 네트워크 지연 증거가 아니다.

신규 baseline 3 PASS는 다음 검사 범위에서 재현 안 됨으로 기록한다. 이를 새 결함 수정 수에 넣지 않는다.

- ordinary edit advances revision and stale edit changes nothing: 정상 수정과 오래된 revision의 DB 차단.
- duplicate solve and dispose suppress late result: 두 번 호출 및 dispose 이후 풀이 결과.
- disposed text save error has no UI callback: dispose 이후 저장 오류.

## 수정 후 회귀의 추가 범위와 미확정 결과

`test/widget/camera_ownership_test.dart` 7개는 신규 lease 주입 API를 사용하므로 baseline 14개와 구분한다. pending open의 상호 배제, 반복 close 합류, stop/dispose 각각 timeout 뒤 늦은 완료, initialize timeout, probe 해제 실패, 실제 GazeLabScreen+MeasureController+SeatEngine 공통 획득 경계를 검사한다. 종료 실패/timeout latch를 늦은 성공으로 풀지 않는다. 공통 SeatFrameSource의 close 설명을 명확히 했으나 method signature/시간 집계 계약은 변경하지 않았다.

후속 통합 CI [38341188635](https://github.com/byite-co/soongong/actions/runs/38341188635), HEAD `82b2fd5`에서 실제 Flutter **860 PASS / 3 FAIL**이었다. 보정 baseline의 study repository/solver/dialog 실패는 재발하지 않았다. 새 camera 통합 검사에서 native 획득 실패 전 51.364ms가 순공시간에 쌓이는 실제 결함을 추가 확인했다. MeasureController를 camera 준비/재개 완료까지 paused로 유지하도록 수정하고 deterministic clock 회귀 4개를 추가했다. 두 account 실패는 teardown의 강제 revoke와 fixture 삭제 경합, modal reverse animation 대기 부족으로 구분해 기존 제품 기대값을 유지하며 보정했다. 이 실행을 후속 수정 HEAD의 성공 증거로 사용하지 않는다.

마지막 독립 검토에서 prepare 직후 취소/failed release의 native 예약 잔존도 확인했다. `e2cc863`은 cancel→정확한 inactive owner release→삭제와 다음 pick의 cleanup 재시도를 연결했고 두 자동 회귀를 추가했다. legacy export namespace 누락은 별도 unknown probe로 보완했다. 이는 원래 baseline의 8개 원인을 다시 세는 항목이 아니다.

최종 결과는 이 문서의 중간 실행과 구분해 최신 PR 본문 및 RC 검토 산출물의 HEAD/checkout/tree·40개 결과표에 기록한다. 아래는 작성 시점의 확인란이다.

| 항목 | 현재 기록 |
|---|---|
| 최종 통합 HEAD / CI checkout / tree | 미확정 |
| Flutter 전체 PASS / FAIL / SKIP 및 링크 | 미확정; baseline 772/11을 수정 HEAD 결과로 사용하지 않음 |
| RC05 baseline-compatible 14개 + camera 7개 결과 | 최종 통합 CI 대기 |
| 변경 파일·공용 API·문서 검사 | 해당 최종 HEAD에서 재확인 |
| 실제 OS camera 소유/해제/순공시간·프레임 저장/전송 | UNVERIFIED; DEVICE-10 |

로컬 Flutter/pub 제한을 우회하지 않았다. 직접 Dart formatter 구문 처리와 diff 검사만 실행했다. 기준 CI 성공 수에 새 테스트 개수를 단순히 더해 최종 성공 수를 만들지 않는다. 원본 INT-04/RACE-05/RACE-06/GAZE-02의 남은 실제 모델·기기·복합 조건은 이 자동 재현만으로 PASS로 올리지 않는다.

## 독립 네이티브 검토 인계

RC02/03 담당자의 작업 중 소스를 독립 검토하여 두 문제와 보강 테스트를 확인했다. 최종 native commit/CI 결과는 EXT-FIX-02 통합 문서에서 연결한다.

- iOS 공유 sheet 최초 검사 뒤 지연 item callback이 옛 URL을 그대로 제공하던 경로: `FIPOwnedShareAttachment.URL`이 callback 시점마다 owner marker/revocation/canonical regular file을 재검사한다. 파일 삭제 실패로 bytes가 남아도 scope revoke 뒤 getter=nil인 Foundation 회귀를 추가했다.
- Android `cancel`이 owner monitor/main thread에서 원격 InputStream.close를 기다리던 경로: 동기 cancelled flag와 monitor 밖 daemon close로 분리했다. writer finally 전에는 active 유지. block된 close에서도 cancel/status가 반환하고 새 owner가 열리지 않는 회귀를 추가했다.
- 카메라 FileProvider 테스트는 초기 context-null로 guard와 무관하게 실패할 수 있던 점을 지적했고, 담당자에게 정상 open 후 revocation 차단을 비교하도록 보강 요청했다. 제품 결함 수에 포함하지 않는다.
- MediaScanner 비동기 callback의 owner 전달/중복 callback 방어와 private capture 미디어 인덱싱 제외는 native 담당자가 후속 강화 중이다. 완료 여부는 최종 소스/CI로 기록한다. RC05 baseline의 8개 원인에 더하지 않는다.

기기 검증은 [DEVICE-01~12 실행 절차](EXT-FIX-02-DEVICE.md)를 따른다. iOS Foundation의 실제 자식 프로세스 종료나 Android Robolectric 계약 테스트는 iPhone/Android 기기의 picker kill, OS 수신 앱, 파일 보호 상태 검증과 구분한다.
