# EXT-01 — OCR 연결 구현

2026-10-13 KST. 통합 PR #9, main 미병합.

- 선행 S09 `7472b41`의 사진/계정/purge 코드를 통합 브랜치에 반영했다. main에 PR #8을 별도로 병합하지 않았다. `docs/decisions.md`의 두 append 절은 모두 보존했다.
- 신규 TranscriptionEngine v1, PaddleOCR/UniMERNet worker 어댑터, Supabase 인증·동의·epoch 재확인 gateway, 촬영/선택→교정→확정 저장 화면을 구현했다. 기존 채점 Mark/ReadingEngine Fake와 별도다.
- SCHEMA-CHANGE: 로컬 v3 `study_documents`는 수동 SQL migration으로 만든 local-only 테이블이다. syncTables에는 넣지 않고 JSON export, LocalPurge, account wipe에 명시적으로 포함했다. 사용자 확정 전 원문은 DB에 쓰지 않는다. revision 변경 시 과거 풀이를 무효화한다.
- 준비안 조정: 초기 allowlisted pilot은 제한 시간 내 동기 요청, 사진 메모리 처리로 구현했다. 서버 job/Storage 버킷을 만들지 않아 별도 사진 삭제 원장을 우회하지 않는다. 성공·실패 후 모델 프로세스는 종료한다. 범용 대기열/과금은 미구현이고 기존 판독 quota는 차감하지 않는다. 일반 공개 활성화는 별도 사용량 정책이 필요하다.
- 서버 미설정·모델 미설치 시 실패를 반환한다. `STUDY_AI_ENABLED`와 사용자 allowlist, 모델 해시 manifest가 필요하다. 실제 GPU/모델 배포, 한국어 손글씨 평가, Android/iOS 실제 촬영은 미검증이다. 모델/전이 의존성의 배포 lock과 가중치 권리 검토도 남아 있다.
- 자동 검사: Python 이미지/모델 manifest 경계 3건 로컬 통과. 최초 통합 SHA `55d06af`의 [서버 검사](https://github.com/byite-co/soongong/actions/runs/38313972478)와 [worker 검사](https://github.com/byite-co/soongong/actions/runs/38313972534) 통과. Flutter 검사 및 후속 수정 결과는 최신 PR checks로 갱신한다.
- EXT-02는 확정 document id/revision/text만 전달한다. 원본 사진을 다시 요구하지 않는다. 기존 S13 동기화가 Fake라는 한계는 유지한다.

변경 공용 파일: AppDatabase(schema v3), LocalPurge, ExportService, reading routes, Supabase config, 신규 계약·worker·gateway·UI 및 회귀 테스트. 운영 배포 없음.
