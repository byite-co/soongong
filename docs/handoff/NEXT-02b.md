# NEXT-02b v2 · 구현·검증 인계

사용자의 NEXT-02b 재개 실행 지시 v2를 실제 구현 지시로 적용했다. 기준 PR #9 `c345c7335058affbc2c8a0adf7c31f186d241aab`에서 기존 브랜치 `feat/s14-oss-integration`에 정상 push했다. 구현 코드 SHA는 **`0b04efcf49a7016d10785f428a9a1ede5628029b`**다. 이후 증거 커밋은 문서/집계만 추가하며 모델/전처리/제품 코드는 변경하지 않는다. 최종 제출 SHA·동일 원격 SHA·최종 네 CI는 push 후 [PR #9](https://github.com/byite-co/soongong/pull/9) 본문 및 로컬 최종 attestation에 기록한다. 이전 CI를 최종 CI로 대체하지 않는다.

**코드 수정·저장·테스트·커밋·push 완료. 실제 모델 평가·앱/기기 검증은 미완료.** GitHub API에서 PR `OPEN`, `isDraft=true`를 확인했다. Draft 해제·병합·배포·공개 활성화·유료 추론 API·실제 결제는 수행하지 않았다. 과거 review-only 지침보다 이번 명시적 구현/기존 PR 반영 지시가 우선한다.

## ENV-01~05와 저장된 변경

| 항목 | 실제 결과 |
|---|---|
| ENV-01 | checkout 및 Git metadata create/write/read/fsync/delete PASS. 시험 파일 제거, 기존 사용자 변경 없음 |
| ENV-02 | 최초 workspace HEAD c5723529(main), PR 기준 c345c733을 fetch해 별도 로컬 브랜치 `codex/next-02b-resume`로 작업. 대상 원격은 기존 PR 브랜치 |
| ENV-03 | Flutter3.47.5/Dart3.13.4, Python3.11.17, Deno2.9.6, PostgreSQL16.15 준비. cgroup CPU4개, memory32GiB. GPU/Android SDK·adb·기기/iOS·Xcode/승인된 dev endpoint 없음 |
| ENV-04 | 첫 `538307d4536bb132059f09851193eea88030f1f0`(worker52 PASS)를 실제 push하고 branch/PR ref 일치 확인. 이어 b306ee7,0b04efc 정상 push; GitHub API가 PR head0b04efc 및 Draft 확인 |
| ENV-05 | 초기 GitHub API Forbidden은 해결됨. 공식 HF metadata/config/tokenizer는 받았지만, Paddle/UniMERNet weights·한국어 사진·수식 ZIP의 정상302 대상 `us.aws.cdn.hf.co`에서 `Tunnel connection failed: 403 Forbidden` 지속. 다른 경로/credential 우회 없음 |

네트워크 초안에 api.github.com, huggingface.co, docs.python.org, jsr.io, storage.googleapis.com 및 실제 관측 CDN us.aws.cdn.hf.co를 저장했다. 기존 package-manager presets를 보존했다. **초안 저장은 runtime 적용/게시가 아니다.** 환경 설정에서 변경을 검토·저장하고 환경을 게시해야 한다. 별도 구현 승인을 다시 요구하는 것은 아니다. 현재 인스턴스의 CDN 차단을 해결한 것으로 보고하지 않는다.

설치/시작 helper와 caches는 `/workspace/soongong-tools`, 실제 실행 logs는 `/workspace/soongong-state/next02b`에 있다. Flutter bootstrap/Pub/codegen 및 Deno 이전 차단은 해소됐다. Paddle70개 의존성을 기존 hash lock 그대로 별도 venv에 설치했다. 완전한 모델 root는 없다. Android 로컬 빌드는 `No Android SDK found`로 중단됐으며 공식 SDK HEAD200은 확인했다. native CI 빌드와 실제 기기는 별개다. 새 작업에서 snapshot 복원 성공은 아직 검증하지 않았다.

## 구현과 원인 판정

- 바이트 상한과 이미지 유효성을 분리했다. 4MiB 초과·빈 입력·base64·형식·frame·손상·12M pixel을 고정 내부 코드로 구분하며 모델 검증/로드 전에 거절한다. 공개 `invalid_image`/`inference_failed` 및 HTTP 계약은 유지한다. 보고된 4,540,191/4,207,053 바이트 각각3회 거절 검사는 **합성 바이트**이며 원래 사진6회의 실제 평가가 아니다.
- opt-in 요청 진단은 고정 크기 숫자 shared buffer다. decode/model validation/load/detect_recognize/recognize/grading/serialize/IPC/cleanup monotonic 경계를 남긴다. Paddle이 합쳐 수행하는 detect/recognize를 가상 분리하지 않는다. 원문·키·경로·예외 문자열·모델 stdout/stderr를 진단에 넣지 않는다.
- Linux `waitid(WNOWAIT)`로 부모 정리 전 종료를 관측하고 multiprocessing의 단일 join/reap 소유권을 유지한다. 부모 SIGTERM/SIGKILL 시각·이유·전달 여부와 정리 후 exitcode는 별도다. EOF/SIGKILL만으로 OOM·native crash·CPU 제한 원인을 확정하지 않는다.
- 자식 `RUSAGE_SELF` RSS/CPU를 단계 경계 및 target 반환 때 기록한다. Linux KiB→bytes/macOS bytes/미상 null. 자손/GPU 제외, 강제 종료 전 최종 표본 미수집은 incomplete다. 부모 `RUSAGE_CHILDREN`은 누적 회수 자식 통계이며 CPU 차분과 RSS 누적 최고값을 별도 기록한다. **과거 max_child_rss_kib는 요청별 RSS가 아니었다.** 원본 측정파일은 유지하고 새 범위 정정을 추가했다.
- 평가기는 입력 hash와 허용/거절 층을 실행 전에 동결한다. `--repetitions 3`의 전체 시도를 보존하며 EOF를 거절층으로 옮기지 않는다. raw 보고서는 checkout 밖 새 파일만 허용한다. `--paddle-cpu-threads 1|2|4`는 평가 child의 constructor만 바꾸며 제품 기본4·mkldnn OFF와 모든 자원 한도를 유지한다. 설정 인자 전달 테스트는 통과했지만 실제 native 활성 thread 수는 미검증이다.
- 앱에 사진1장, 빨간 동그라미/가위표/세모 후보, 찍음·안 품 수동 지정, 정확도 검증 중, 수식 LaTeX 원문 표시를 명시했다. adapter 최대20장을 UI 지원으로 표시하지 않는다. 명시적 교정/확정 전 저장과 원장 계약을 바꾸지 않았다.

CPU45초/worker wall50초/Edge55초, 4MiB/12M pixels/단일frame/응답256000 bytes/동시성1, process group 회수, cleanup 실패 후 입장 차단을 유지했다. DB v5 전체 암호화/v3·v4 이전/잘못된 키·0바이트 보호, owner/epoch/동의·삭제 경합, 사진30일·공유24시간 정책, 판독 quota와 OCR 포인트 분리, 비용unknown·공유 월30만원 상한·공개OFF도 그대로다. 새 migration/공용 API schema 변경은 없다.

## 실제 평가 범위와 미달

[protocol-v2](../evidence/next02b/protocol-v2.json), [manifest](../evidence/next02b/manifest.json), [metrics](../evidence/next02b/metrics.json), [진단 집계](../evidence/next02b/diagnostics-summary.json)를 함께 읽는다. 기존 next02 JSON5개 hash는 모두 동일하다.

한국어의 과거 원본 MPO 거절18회, PNG 전체 v3 7/9·v5 4/9, v2 허용 입력 기준 v3 7/7·v5 4/7을 구분해 보존했다. 초과2개와 EOF3개는 다른 실패다. **이번 원본 PNG27회는0회**다. 이미지/CDN 차단과 과거 raw 부재 때문에 EOF3개의 input hash·실제활성threads·OS/cgroup 종료 원인은 확보하지 못했다. v5 수정 또는 v3 운영 fallback을 주장하거나 도입하지 않았다. 선택 경로 안정성21/21+6/6, 한국어 CER/모집단98%는 UNVERIFIED다.

수식 과거 strict12/60=20%는 **90% 목표 FAIL** 그대로다. 과거 인쇄셋 valid60/60와 p95 19.883049366초는 당시 장비의 개별 관측으로 유지하고 새 cloud 결과로 사용하지 않는다. 기존 raw report expected SHA는 `97b205d0b682e3ca9147846640ccb902b434d520b21762248a00637656e65541`이나 해당 파일은 없다. [불일치 집계](../evidence/next02b/mismatch-summary.json)는 검토0/48, 6개 주원인 counts/합계null이다. 없는 원본을48개 판정불가 검토로 꾸미지 않았다. 재현 출력이 생겨도 과거와 동일성은 별도 확인해야 한다.

[UniMERNet 대조](../evidence/next02b/unimernet-source-audit.json): 공식Git5a2c80d, 고정PyPI0.2.3 wheel 및 실제tiny revision3f09ac4의 metadata/tokenizer5개 hash를 확인했다. 공식tiny YAML/demo와 다운로드한 preprocessor 모두 `[192,672]`; max_seq_len1536도 일치한다. weight load 함수, transform의 PIL margin crop→aspect resize/thumbnail→center padding→gray/normalize→tensor, generation/BOS·eval/inference mode를 대조했다. Git processor에는 새 ndarray 분기가 있으나 사용 중인 PIL 경로의 연산은 소스 검토상 같은 순서다. 실제 tensor 동등성/weight key load/추론은 하지 못했다. 크기나 tiny 명칭만으로 원인을 정하지 않았고 입증되지 않은 모델 변경도 하지 않았다.

새 수식60개는 기존60개를 제외하고 seed20261014의 CPython3.11 shuffle, 이미지hash 중복 제외 규칙을 미리 저장했다. `tool/prepare_next02b_holdout.py`가 고정 ZIP hash를 요구하고 새 경로만 쓴다. **실제 추출/선택 input hash/평가0건**이다. 새 인쇄 표본도 새 필기자 일반화 증거가 아니다. 한국어 실제60영역·5명, 손글씨 수식60영역·3명, 채점표시5종각20 총100개 조건은 미충족이다. CER/F1/precision/문항연결 새 지표는 null이다.

이번 실제 추론 API 호출0건/호출비0원이며, cloud·CI·추론 인프라 전체 원가는 unknown이다. 실패/EOF로 공급자 비용0을 추정하지 않는다.

## 실행한 검증과 증거

[명령·원본 log hash·범위](../evidence/next02b/test-results.json). 원본 logs는 로컬 `/workspace/soongong-state/next02b`에 보관하며 공개 증거에는 원문/사진/credential이 없다.

| 검증 | 이번 실제 로컬 결과 |
|---|---|
| Flutter | **983 tests PASS**; fatal analyze clean; 문구22파일 clean; codegen887 outputs 후 generated/lock diff0 |
| Python worker | **58 tests PASS** (최초 의미있는 commit52 → 평가protocol57 → bounded thread seam58) |
| PostgreSQL | **508 assertions/13파일 PASS**; 격리 PostgreSQL16, Auth/Storage/pg_net shims |
| PL/pgSQL | gate PASS, 기존허용 dynamic-record error2/성능36/security2/warning9/extra1 유지 |
| Edge | **53 tests**,19entrypoints typecheck PASS |
| DB+Edge | **14 tests PASS**; 실제 socket-only PostgreSQL+합성 provider. 호스트 psql wrapper 사용; GITHUB_ACTIONS 가드는 이 격리DB용이며 hosted CI가 아님 |
| 기기/native | 로컬 Android SDK 없음, iOS없음. hosted CI 결과는 최종PR에 별도 연결 |

중간실패도 숨기지 않았다. sandbox localhost socket EPERM6개는 승인된 실행에서 해결했다. worker CPU fixture1개는 동시 Flutter/DB 실행 중 wall timeout을 먼저 만나 실패했고, 무거운 suites 종료 후 **같은 기대값/제한/58테스트**를 단독 실행해11.034초 PASS했다. postgresUID의 bind script 읽기 실패는 기존 테스트helper와 같은 container rootUID로 실행해 해결했다. 테스트 삭제/skip/한도·목표 완화 없음.

## B01~18과 이전 판정

[기계 판정표](../evidence/next02b/acceptance.json)는 모든 행에 item_id/status/scope/expected/actual/code_sha/command/log_or_ci/reason을 담는다. 이 증거 snapshot은 **PASS7 / UNVERIFIED11**이며 B17은 최종 제출 후 CI attestation까지 유보한다. 최종 B17 판정은 네 workflow가 **최종 SHA**에서 모두 성공한 뒤 PR본문/증거 묶음의 final-attestation.json에서 확정한다.

| 항목 | snapshot 판정 | 범위 |
|---|---|---|
| B01/B02/B05/B08 | PASS | 기준보존·안전한 숫자진단·Linux 자원보호 회귀·분모/strict 보존 |
| B03/B04 | UNVERIFIED | 원본 한국어 실패재현 및27회 실제 모델 회귀 |
| B06/B07/B09 | UNVERIFIED | 모델실행 경로·원본48분류·새 실제수식평가; 소스/metadata 대조만 완료 |
| B10/B11 | UNVERIFIED | 실제 한국어·채점표시 품질 자료 없음 |
| B12/B15 | PASS | 앱지원 안내/명시확정·자동계정/동의/삭제 보호 회귀; 실기기와 분리 |
| B13/B14/B16 | UNVERIFIED | 실제앱/K1~K4/모델 성능·인프라 비용 |
| B17 | UNVERIFIED at snapshot | 코드push/로컬검증 완료; 증거커밋후 최종SHA CI 대기 |
| B18 | PASS | 사실에 근거한 인계·Draft/OFF·잔여와 NEXT03 계약 명시 |

이전 A24 자동PASS24, R8의 PASS1/FAIL2/UNVERIFIED5, FD28 과거PASS28, 기존58 PASS13/UNVERIFIED45, RC40 자동PASS40, DEVICE12 UNVERIFIED12를 보존했다. 이번 DBEdge14는 FD21/22의 과거 실제 Supabase Storage 통합을 새로 실행했다는 뜻이 아니다. native Android16/iOS54의 과거결과도 새 CI가 확인되기 전에는 현재결과로 사용하지 않는다.

## 재개 명령과 NEXT-03 입력

`source /workspace/soongong-tools/env.sh` 후 repository에서 실행한다. 아래 모델 명령은 CDN이 허용된 환경에서만 계속한다. snapshot에 있는 작은 metadata의 성공을 완전한 모델 준비로 보지 않는다.

```sh
/workspace/soongong-tools/worker-venv/bin/python services/study_worker/provision_models.py paddle-v5 /workspace/soongong-models/paddle-v5
/workspace/soongong-tools/worker-venv/bin/python services/study_worker/provision_models.py unimernet-tiny /workspace/soongong-models/unimernet-tiny
/workspace/soongong-tools/worker-venv/bin/python tool/prepare_ocr_evaluation.py /workspace/soongong-datasets
/workspace/soongong-tools/worker-venv/bin/python tool/prepare_next02b_holdout.py --archive /workspace/soongong-datasets/UniMER-Test.zip --destination /workspace/soongong-datasets/next02b-fresh60
mkdir -p /workspace/soongong-evaluation/next02b
MODEL_ROOT=/workspace/soongong-models/paddle-v5 WORKER_MODEL_ID=paddle-v5-next02 /workspace/soongong-tools/paddle-venv/bin/python services/study_worker/ocr_evaluation.py --kind text --manifest /workspace/soongong-datasets/korean-notes-first-frame/manifest.json --protocol docs/evidence/next02b/protocol-v2.json --repetitions 3 --output /workspace/soongong-evaluation/next02b/paddle-v5-all27.json
```

실패 hash가 확인되면 해당 허용 입력을 같은 hash로 동결하고 `--paddle-cpu-threads 1`,2,4를 한 요인씩 비교한다. 설정값과 실제 native threads/CPU/RSS/호스트 부하를 구분한다. 최종 후보를 선택한 뒤 전체27회 별도 새파일에 실행한다. v3 비교도 같은 protocol이며 검증 전 운영 fallback은 금지한다. UniMERNet은 기존 math hash lock(CUDA128 build)용 별도 환경과 model manifest 검증이 필요하다. CPU cloud와 과거 RTX5070 장비 성능을 섞지 않는다. 이전 이미지를 받은 뒤 hash가 같으면 CPE5921 전수 mapping 조사를 다시 하지 않는다.

실제 앱 text/math/grading과 K1~K4는 [기기 실행 인계](NEXT-02b-DEVICE.md) 및 [case 양식](../evidence/next02b/device-cases.json)을 사용한다. launcher는 dev패키지만 실제 force-stop/relaunch하며 PID PASS를 복구/원장 PASS로 만들지 않는다. 현재 실제 앱/종료 시도는0이다.

NEXT-03은 동일 request ID·quote/epoch/owner/consent·input provenance·사용자 교정 revision·문서 link, receipt/멱등성·포인트 vs quota·unknown 비용을 입력 계약으로 받는다. K1 전송전 durable request, K2 unknown, K3 기존결과 복구, K4 단일확정 문서를 각각 검증해야 한다. 원본사진 유실·result_expired·계정변경·삭제에서 자동재실행/빈성공/부활을 허용하지 않는다. S13 전체동기화, 사진복원UI, 실제결제, 풀이 공개, 시선 정정, 운영 포인트판매정책은 완료 범위가 아니다.

필요 자원은 공식CDN 허용, 원래 raw GT/예측 파일(지정SHA), 권리·작성자·정답이 있는 실제 필기/채점자료, 승인된 dev Auth/Edge/worker와 시험계정, Android/iPhone 기기다. 비밀키나 개인 원문을 채팅에 제출할 필요는 없다.
