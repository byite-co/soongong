# NEXT-02b v2 · 진행 중 인계

기준 PR #9 head `c345c7335058affbc2c8a0adf7c31f186d241aab`, 대상 `feat/s14-oss-integration`. 사용자 NEXT-02b v2의 명시적 구현·동일 PR 반영 지시를 적용한다. 과거 review-only 역할 규칙보다 이번 지시가 우선한다. 기존 작업을 보존하고 새 커밋을 누적한다. 병합·배포·공개 활성화·유료 API 호출은 하지 않는다.

## 첫 구현 단위

- 4MiB 바이트 검증과 이미지 유효성 검증을 분리했다. base64/빈 입력/형식/프레임/손상/12M pixel 거절 사유는 내부 고정 코드이며 공개 `invalid_image` 및 HTTP 오류 계약은 유지한다. 모델 검증/로드 전에 거절한다.
- 선택적 요청별 진단은 고정 크기 숫자 shared buffer를 사용한다. decode/model validation/load/recognition/serialization/IPC/cleanup 단계를 monotonic 시각으로 기록한다. Paddle 공개 API가 합쳐 실행하는 detect/recognize를 가상의 독립 단계로 나누지 않는다. 원문·예외 메시지·경로·키·모델 stdout/stderr를 수집하지 않는다. 네트워크/파일 로그 출력도 없다.
- 부모 정리 신호 이전의 종료 상태는 Linux `waitid(WNOWAIT)`로 관측한다. multiprocessing이 자식을 join/reap하는 소유권을 유지한다. 부모 SIGTERM/SIGKILL의 시각·이유·전달 여부, 결과 수신 여부, 정리 후 exitcode는 별도 필드다. SIGKILL/EOF만으로 OOM/모델 장애를 확정하지 않는다.
- 자식 `RUSAGE_SELF`의 RSS/CPU를 단계 경계와 target 반환 시 측정한다. Linux KiB→bytes, macOS bytes, 그 외 단위 미상은 null이다. 자손/GPU는 포함하지 않는다. 강제 종료 때문에 최종 표본이 없으면 관측 최고값은 불완전하다. 부모 `RUSAGE_CHILDREN`은 누적 waited-for children 통계로만 남기고 CPU 차분과 RSS 누적 최고값을 구분한다. 과거 RSS 보고서는 요청별 RSS가 아니었다는 범위 정정을 새 평가기에 명시하며 원본을 덮어쓰지 않는다.
- CPU45초/worker50초/Edge55초, 바이트·pixel·응답·동시성 한도, 그룹 정리, cleanup 실패 시 입장 차단, 비용·포인트 계약을 유지한다. 진단만으로 비용을0원으로 정산하지 않는다.

Python3.11.17에서 `python -m unittest discover -s services/study_worker -v`: **52 tests PASS**. 이미지 상한과 EXIF, 보고된 초과 크기2종×3(합성 바이트, 실제 사진 아님), 선종료/EOF, 민감 예외, 큰/절단 IPC, deadline, 부모 정리, cleanup 실패 시 다음 HTTP429, 순차 큰/작은 자식 RSS, 기존 실제 CAS 자원·취소·고아 회귀를 실행했다. 처음 sandbox 실행의 localhost socket EPERM6건은 승인된 실행 경로로 재실행하여 해결했다. 삭제/skip/기대값 완화 없음.

## 환경과 현재 한계

작업 폴더 및 Git metadata 쓰기/읽기/삭제 PASS. Git HTTPS 프록시 읽기/fetch PASS. GitHub API GraphQL/REST는 `Forbidden`; public model-card `huggingface.co` 및 공식 Python 문서도 CONNECT403. JSR HTTP403. Flutter SDK 완성본·Android/iOS 실행기·GPU·이전 장비의 모델/원본/예측 파일은 아직 없다. 읽기 성공을 push 성공으로 보지 않으며 첫 실제 push 결과와 최종 CI는 후속 증거에 기록한다.

이 파일은 중간 구현 단위의 인계다. 실제 모델 21회+6회, v5 EOF3건 원인, 과거 수식48개 분류, 새 수식평가, 실제 앱/K1~K4는 아직 실행하지 않았다. 기존 strict12/60=20%, 전체 PNG v3 7/9·v5 4/9, 허용 입력 기준7/7·4/7과 MPO 거절18회는 구분해 보존한다. 전체 완료 또는 품질 합격 선언이 아니다.
