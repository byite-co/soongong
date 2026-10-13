# NEXT-01 · study API v2 (CONTRACT-CHANGE)

2026-10-13 사용자 승인. 구현/자동 실행 증거는 `handoff/NEXT-01.md`에서 관리한다.
S13 scheduler와 실제 엔진·사진 업로드 UI는 이 계약과 별도다. 현재 local-only 안내를 유지한다.

## 경계

- 기존 OCR/풀이 **결과** schema_version=1과 새 AI **요청 봉투** version=2를 구분한다.
- 요청 ID는 계정별 UUID, epoch 및 입력 digest에 고정한다. quote는 서버 정책 버전을 고정하며 포인트를 클라이언트가 정하지 않는다.
- 구형 요청·알 수 없는 필드는 거절한다. 응답은 job 상태/재조회 ID/내부 결과로 구성한다. 외부 호출의 실행 불명은 재호출 허가가 아니다.
- `study_metadata_v1`은 title(최대 80자), kind, revision, 존재 상태와 seq만 반환한다. 별도의 사용자별 seq 커서이며 D2 sync_tables에 본문을 등록하지 않는다.
- 모든 메타데이터 변경과 pull은 기존 `user_lock`을 공유하고 그 아래 `next_server_seq`를 발급한다. cursor는 반환한 마지막 행까지만 이동한다. 본문은 `study_body_v1`로 선택한 문서/revision 하나만 조회한다.
- `study_save_v1`은 사용자 확정 본문만 저장하며 expected revision CAS와 영구 tombstone으로 부활을 차단한다. AI 임시 결과는 별도 private job 결과이며 자동으로 확정 문서가 되지 않는다.
- 서버·로컬의 account/epoch/revision을 재검증한다. cache missing/loading/available/error는 빈 확정 원문과 다르다.
- 사진은 복원용 private bucket과 opaque object ID를 사용한다. 최초 서버 시각 +30일 후 새 접근 불가. 삭제 worker가 Storage API 성공을 확인해야 완료다. metadata SQL 삭제를 bytes 삭제로 세지 않는다.

## 현재 계약과의 관계

D2 12개 테이블의 push/pull/receipt/fullResync는 유지한다. D14 처리 임시 사진과 RC 공유 파일 수명도 그대로다. 로컬 v3 → v4 이전은 기존 기록/관계/내용을 보존하고 메타데이터만 있는 행을 표현한다. 본문 목록 선로딩은 없다.

## 공식 문서 대조

Supabase CLI 2.120.0의 `migration new`로 새 파일 생성(기존 0001~0013 불변). 실제 Postgres 테스트는 일회용 CI DB에서 실행한다. 운영 프로젝트 접근 없음.
[함수 권한](https://supabase.com/docs/guides/database/functions), [RLS](https://supabase.com/docs/guides/database/postgres/row-level-security), [Storage 권한](https://supabase.com/docs/guides/storage/security/access-control)을 대조했다.
2026-10-13 changelog 확인: [TLS CBC 제거 예정](https://supabase.com/changelog/cbc-tls-ciphers-deprecated)은 후속 최소 OS/TLS 실기기 확인 대상. [PG 보안 업데이트](https://supabase.com/changelog/postgres-15-19-17-11-breaking-changes)의 ltree/legacy PGP/btree_gist/custom operator는 이번 새 스키마에 도입하지 않는다.
