# EXT-02 — 수능 문제풀이

이전: [EXT-01](01-handwriting-ocr.md) · 다음: [EXT-03](03-gaze-inference.md)

## 세션 시작 지시문

> EXT-01이 확정한 원문 계약 위에 수능 문제풀이를 구현한다. 첫 검증 범위는 수학으로 설계하고 다른 과목을 지원한다고 표시하지 않는다. 풀이 생성·도구 계산·정답 검증·사용자 확정 저장을 분리한다. 임의 코드 실행 없는 worker와 평가를 먼저 확보하고, main 병합 없이 구현·평가 범위를 인계한다.

수학부터 시작하는 것은 SymPy/Math-Verify 후보와 현재 계약에 맞춘 준비안이다. 국어·영어·탐구로 넓히려면 과목별 근거·채점·데이터 계약을 추가한다. “수능 수준”은 모델 이름으로 판정하지 않고, 과목/연도/배점/난이도별 실제 평가로 표시한다.

## 현재 코드와의 정합성

- 기존 ReadingEngine은 채점 표시 판독이다. 풀이 job과 `Solution`을 별도 계약으로 만들고 `Mark.correct`에 모델의 추측을 대입하지 않는다.
- 입력은 EXT-01의 사용자가 확정한 revision이다. OCR 원문이 바뀌면 이전 풀이를 현재 답으로 재사용하지 않는다. 오답 저장도 사용자가 확정해야 한다.
- 기존 `reading-worker` claim/lease/재시도/원장 정산은 참고할 수 있지만 동일한 job kind·quota로 무단 재사용하지 않는다. 기존 3분 lease와 10분 deadline은 새 추론 시간 보장이 아니다. 새 job 시간/heartbeat/attempt/취소·정산 계약을 별도로 정한다.
- Supabase Edge에 Paddle/Torch/대형 LLM이나 오래 걸리는 CAS를 올리지 않는다. Edge는 인증·접수·상태, 별도 worker는 제한된 추론·계산을 담당한다.

## 후보별 적용 범위

| 후보 | 가져올 부분 | 제외/주의 |
|---|---|---|
| Qwen-Agent | 도구 호출 루프·구조화된 응답·수학 예제의 흐름 참고 | `python_executor.py`는 샌드박스가 없는 exec 구현. 제품에 복사·노출하지 않음 |
| 수학 추론 모델 | provider 어댑터 뒤에서 풀이 후보 생성 | Qwen 예제의 원격 모델 이름을 현재 권장/허용 모델이라고 간주하지 않음. 실제 가중치·라이선스·하드웨어·보관 정책 고정 |
| SymPy | 제한된 수식 정규화·해/대입·정확 계산 | 임의 Python, 문자열 eval, 무제한 parse_expr를 사용자/모델 입력에 노출하지 않음 |
| Math-Verify | 정답 형식 파싱·동치 확인 | `verify(gold, answer)` 순서 유지. 정답 동치와 해설의 논리 타당성을 구분 |
| KCSAT-ML | 평가 축·분류 참고 | 제품 데이터/코드 복사는 보류. 코드와 시험 콘텐츠의 별도 조건을 해결하지 않은 채 가져오지 않음 |

## 새 계약(예정 파일)

후보: `lib/core/contracts/problem_solver.dart`, `lib/features/reading/domain/problem_solution.dart`, `services/math_worker/`, `supabase/functions/solution-submit/`. 기존 기능이 아니다.

- `ProblemInput`: schemaVersion, confirmedDocumentId/revision, subject, 문제 문장, 수식, 객관식 선택지/답 형식, 변수·정의역·조건. 신뢰되지 않은 사용자/OCR 문장을 시스템 지시와 분리한다.
- `SolutionJob`: owner-scoped ID, 입력 revision/hash, epoch, idempotency key, engine version, attempt/lease generation, queued/running/succeeded/failed/cancelled/expired. 재접속·중복 제출·late callback을 명시한다.
- `SolutionCandidate`: 답, 설명 단계, 도구 계산의 구조화 결과, 적용한 가정, 모델/설정 버전. 읽기 쉬운 근거를 제공하며 모델 내부 사고 과정 수집을 기능 요구로 삼지 않는다.
- `Verification`: verified/contradicted/inconclusive/unsupported, 검사 종류, 정답 출처 유무, domain 제약. 신뢰할 수 있는 gold가 없을 때 “정답 검증 완료”로 표시하지 않는다. 수식 일부를 확인한 경우 검사 범위만 표시한다.
- `AcceptedSolution`: 사용자 확정 값·revision. 기존 오답/복습 항목에 연결할 때 소유권·과목·삭제·sync 계약을 함께 검증한다.

## 계산 실행 경계

1. 허용 함수와 연산자, 숫자/표현식 깊이·길이·지수·행렬 크기를 제한한 수식 AST를 만든다. SymPy 객체는 이 AST에서 구성한다. import/속성 접근/파일/네트워크/프로세스 실행 도구는 제공하지 않는다.
2. SymPy/Math-Verify 파서 자체도 신뢰 경계 밖 worker에 둔다. 비특권 OS 사용자, 읽기 전용 파일 시스템, 비밀 없는 환경, 외부 통신 차단, CPU/메모리/프로세스 수·wall timeout과 전체 작업 프로세스 종료를 적용한다. timeout 데코레이터 하나를 보안 샌드박스라고 부르지 않는다.
3. SSRF·프롬프트 주입으로 도구/외부 URL/서버 비밀을 요청하는 입력을 테스트한다. 입력 문제나 해설에 들어 있는 “지시문”은 문서 데이터다.
4. 로그/추적에는 원문·학생 필기·사진·토큰을 남기지 않는다. 관측은 오류 코드·버전·소요 시간·크기·익명 집계 중심으로 한다. 외부 모델 제공자 사용 시 목적·보관·학습 이용 여부를 서비스 계약과 동의에 반영한다.

## 구현·검증 순서

| 단계 | 완료 증거 |
|---|---|
| 계약·Fake·입출력 fixture | 원문 revision 변경, 선택지 누락, 미지원 도형/과목, 부분 결과, 취소/재시도 화면 |
| 제한된 계산 worker | 악성 문자열, 매우 큰 지수, 무한 계산, parser timeout, 잘못된 정의역, 분모 0, 무연근 테스트 |
| 모델 provider 연결 | 정확한 모델·가중치/endpoint 정책·lock, 재현 설정, timeout/retry 비용 제한, 실제 요청 기록(원문 비노출) |
| 서버 job/소유권·사용량 | 타 계정 결과 조회·이전 epoch callback 차단, 이중 정산 없음, 철회/삭제 후 결과 부활 없음 |
| 사용자 흐름 | 교정 원문→풀이→검사 범위 표시→사용자 확정→오답/복습 연결; 오프라인 실패 시 입력 유지 |
| 수능 난도 평가 | 권리가 확인된 held-out 문제의 배점/유형별 정답률·무응답률·오답 확신·검사 불일치·지연·비용 |

평가에서는 정답을 추론 입력에 섞지 않는다. 객관식/단답형, 함수/미적분/확률통계/기하 등 지원 영역을 나누고, OCR 오류와 solver 오류를 별도로 집계한다. 정답 동치 검사와 사람의 해설 검토를 함께 기록한다. baseline 후 튜닝 전에 합격 목표와 holdout을 고정한다. 실패·미지원 문제도 분모에 포함하고 시험 콘텐츠를 허가 없이 레포에 커밋하지 않는다.

실제 난도 평가가 없으면 “수능 문제풀이 완성”이 아닌 “풀이 연결 구현, 수능 평가 미완료”로 인계한다. `docs/handoff/EXT-02.md`에 OCR→풀이 호환 fixture와 새 테이블/마이그레이션 목록을 남겨 EXT-04가 모두 이전하게 한다.
