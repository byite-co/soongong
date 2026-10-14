# EXT-02 — 수학 풀이 연결

2026-10-13 KST. main 미병합, 운영 배포 없음.

- EXT-01 확정 문서 id/revision/text를 입력으로 쓰는 ProblemSolver v1, Edge operation, 원격 모델+SymPy 도구 루프, Math-Verify 숫자 답 대조, 풀이 확인/저장 화면을 추가했다. 저장된 텍스트를 누르면 풀이 화면으로 이동한다.
- Qwen-Agent 수학 도구 호출 흐름을 참고하되 PythonExecutor/exec/eval은 도입하지 않았다. 실제 모델은 HTTPS compatible endpoint와 고정 model ID로 설정한다. 임의 Python 대신 깊이/노드/지수 제한 AST를 SymPy 객체로 구성한다. CAS는 별도 프로세스의 CPU/메모리/벽시계 제한과 비밀 제거를 사용한다.
- 정답 대조는 사용자가 독립적으로 제공한 정수/분수/소수에 한정한다. gold는 모델 입력에서 제외하며 Math-Verify에는 제한 문법에서 생성한 LaTeX만 전달한다. gold가 없으면 inconclusive, 범위 밖이면 unsupported다. 해설 전체 검증·수능 만점 보장이 아니다.
- 새 원문 revision을 저장하면 이전 풀이를 지우고, 늦은 풀이 저장은 revision/계정/purge generation으로 거부한다. 사용자가 풀이 저장을 눌러야 DB에 보존하며 오답 자동 생성은 하지 않는다.
- SymPy 1.14.0 / Math-Verify 0.9.0 및 전이 의존성 3개를 공식 PyPI wheel 해시로 lock했다. 로컬 Python 7건(계산/입력 공격/정답 비노출/검증/이미지/manifest) 통과. 원격 모델 자체 추론·수능 holdout·비용/성능·실기기 평가는 아직 수행하지 않았다.
- EXT-01의 최초 Flutter 검사에서 발견한 DB migration rollback은 수정 후 통과했다. 남은 설정 export widget의 fake-async/isolate 충돌은 test harness에서 동일 인코더를 inline 실행하도록 주입했다. 실제 서비스 기본값과 unit tests는 background isolate를 계속 사용한다. 최신 통합 SHA에서 다시 검증한다.

변경: 신규 solver 계약·어댑터·UI, study gateway union schema, worker/math tools, 테스트와 worker dependency lock. DB 추가 변경 없음. 운영 기능은 allowlist/default-off 상태다.
