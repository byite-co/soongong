# EXT-FINAL — 최종 통합 점검과 한 번의 병합

[전체 순서](README.md)

사용자의 순서에 따라 EXT-01 → 02 → 03 → 04를 끝낸 뒤 수행한다. 이 문서는 미래 점검표이며 체크가 비어 있는 항목은 통과하지 않은 것이다. **현재는 준비 문서만 작성했으며 main에 병합하지 않았다.**

## 병합 대상 고정

- [ ] PR #8의 최종 상태와 통합 근거, main의 최신 HEAD를 다시 확인한다. 미검토 선행 변경을 조용히 끼워 넣지 않는다.
- [ ] 네 세션 결과와 기존 S14를 `feat/s14-oss-integration`에 모은다. 세션별 변경을 main에 따로 병합하지 않는다.
- [ ] main 최신 변경과 충돌을 해결한 **최종 통합 SHA**를 고정한다. 같은 SHA로 아래 검증을 수행하고 결과를 PR #9에 연결한다.
- [ ] 이후 코드·의존성·마이그레이션·모델 설정이 바뀌면 영향받는 검증을 다시 실행한다. 모델 artifact도 SHA/해시로 고정한다.

## 계약과 데이터

- [ ] OCR 확정 revision → 풀이 입력 → 검사 결과 → 사용자 확정 저장 → 오답/복습 연결이 동일한 계약을 사용한다. 채점 Mark와 OCR/풀이의 확신도를 혼합하지 않는다.
- [ ] 신규 엔티티의 owner/stamp/epoch/outbox/server allowlist/RLS/export/purge/계정 삭제를 모두 대조한다. local-only 자료는 그 상태를 명시한다.
- [ ] 새 job·버킷과 기존 사진 삭제 큐/잔여 스캔이 맞물린다. 완료/실패/취소/동의 철회/로그아웃·계정 삭제 뒤 원문/사진/결과가 부활하지 않는다.
- [ ] 중복 요청·expired lease·이전 attempt callback·서버 지연·재시도로 결과나 원장 차감이 두 번 생기지 않는다.
- [ ] 모든 새 SQL 마이그레이션을 빈 DB와 기존 버전에서 실행한다. 이미 적용된 파일 수정이나 PR #8의 번호 충돌이 없다.
- [ ] DB 암호화가 syncTables뿐 아니라 신규 테이블·outbox·메타데이터까지 보존한다. 실제 로그아웃 보존 정책과 키 수명이 일치한다.
- [ ] 시선 관측을 켜도 기존 순공시간 회귀가 없다. 시간 정책 변경이 있다면 결정·명시적 계약·실측과 오판 대응을 별도로 검증한다.

## 자동 검증

- [ ] GitHub Actions Flutter 의존성 설치, codegen 후 clean-tree, `flutter analyze --fatal-infos`, 금지 문구, 전체 테스트.
- [ ] pgTAP 전체 + 신규 RLS/원장/job/purge 검사, Deno 테스트/타입 검사, plpgsql_check 진단. 기존 baseline 이외 새 오류를 검토 없이 면제하지 않는다.
- [ ] OCR/solver worker lock·단위/통합·악성 입력/timeout·취소·중복 callback 검증. fixture와 모델 버전이 보고서와 일치한다.
- [ ] Android와 iOS release 빌드에서 native camera/MediaPipe/SQLite codec 충돌 없이 패키징된다. 모델/폰트/라이선스 고지가 배포물에 포함된다.
- [ ] 계약 serializer와 state machine에 의미 있는 회귀를 추가한다. 구현을 그대로 베낀 테스트나 문서 편집만을 위한 불필요한 테스트를 늘리지 않는다.

준비 전 `df9f71c`의 기존 [Flutter CI](https://github.com/byite-co/soongong/actions/runs/38226250649) 및 [서버 CI](https://github.com/byite-co/soongong/actions/runs/38226250202)는 비교 기준일 뿐, 최종 통합 SHA의 통과 증거로 재사용하지 않는다.

현재 작업 환경에서는 앞선 로컬 Flutter 실행이 클라우드 메타데이터 접근 시도로 자동 승인 검토에서 거절되었다. 그 실행을 우회·반복하지 않는다. 허용된 GitHub Actions 또는 별도로 준비된 정상 개발 환경에서 검증하고 실행 환경을 명시한다.

## 실제 동작·평가

- [ ] Android/iOS에서 촬영→교정→풀이→확정 저장→동기화→내보내기 전체 흐름을 확인한다.
- [ ] 필기·수식 holdout 평가와 수능 수학 배점/유형별 평가를 기록한다. 미지원·실패·무응답을 숨기지 않는다.
- [ ] 시선의 참여자/환경별 오탐·unknown·지연, 실제 장시간 배터리/발열, OCR 촬영과 카메라 전환을 확인한다.
- [ ] 평문 DB의 모든 이전 단계에서 장애 주입 후 데이터 손실·중복·새 빈 DB로의 대체가 없다. 미동기화 행과 PR #8 purge 상태가 보존된다.
- [ ] 이전 후 plain DB/WAL/temp/backup 잔여, OS backup/key restore, 계정 전환·로그아웃·잠금·복구를 실기기에서 확인한다.
- [ ] 기존 로그인/PKCE/tombstone, 측정·플래너·시간표·통계·export 회귀와 접근성/다크 모드/입력 유지 상태를 확인한다.

## 출처·운영·병합 판단

- [ ] 가져온 파일/부분 차용/패키지/전이 의존성/모델 가중치별 버전·라이선스·NOTICE를 기록한다. 조사 목록 전체를 설치했다는 식으로 보고하지 않는다.
- [ ] 기능 플래그와 지원 범위, 비용/속도 한도, 동의 문구, 운영 원장·사진 보관·장애 대응을 기록한다. 원문/프레임/키/토큰이 로그·CI artifact·오류 수집에 없다.
- [ ] `CONTRACT-CHANGE`, `SCHEMA-CHANGE`, `PRINCIPLE-CONFLICT`, 이번 세션별 작업/단일 PR 예외를 PR 본문에 설명한다. 미결 사항과 실기기 미검증을 숨기지 않는다.
- [ ] `docs/oss-integration.md`, `docs/handoff/EXT-01.md`~`EXT-04.md`, 최종 인계 `docs/handoff/EXT-FINAL.md`를 실제 결과로 갱신한다(인계 파일들은 아직 생성 전).
- [ ] 사용자에게 최종 변경·검증·남은 제한·복구 절차와 정확한 merge 대상 SHA를 제시한다. 검증 미완료라면 네 기능 전체 완료로 보고하지 않고 Draft를 유지한다.
- [ ] 사용자가 정한 최종 병합 시점에 **PR #9를 main으로 한 번 squash merge**한다. GitHub 병합 응답과 main HEAD를 확인하고 기록한다. 준비 세션이나 중간 구현 세션에서는 실행하지 않는다.

병합과 운영 배포는 별개다. 서버 migration/worker 배포/앱 배포 순서와 이전 버전 호환 기간은 최종 계약에 맞춰 별도 실행 계획으로 남긴다. DB 암호화 후 평문 전용 앱으로의 단순 rollback이 불가능한 점을 배포 계획에 포함한다.
