# EXT-01 — 손글씨 OCR

> 구현 상태 갱신: 이 문서는 사전 계획이다. 순차 적용된 코드·한계는 [EXT-01 인계](../handoff/EXT-01.md), 최신 검증은 [EXT-FINAL](../handoff/EXT-FINAL.md) 참조.

[전체 순서](README.md) · 다음: [EXT-02](02-csat-solver.md)

## 세션 시작 지시문

> 손글씨 OCR을 구현한다. 최신 통합 브랜치와 PR #8의 사진·purge 계약을 먼저 대조하고, 아래 전사 계약과 테스트를 작성한 뒤 모델 어댑터와 교정 화면을 연결한다. 기존 채점 판독 의미를 보존한다. 모델 평가·실제 연결·미완료를 구분해 인계하고 main에는 병합하지 않는다.

## 현재 코드와의 정합성

- `lib/core/contracts/reading_engine.dart`의 `ReadingItem`은 문항 번호·Mark·confidence·box만 갖는다. 손글씨 원문, 문단, LaTeX, 문제 본문 저장 계약은 없다. 여기에 전사 문자열을 채점 결과인 것처럼 끼워 넣지 않는다.
- `lib/features/reading/reading_routes.dart`의 `/reading/capture`는 현재 placeholder다. 기존 `from=planner&itemId=...` 진입을 유지하며 교정→사용자 확정으로 이어지는 실제 화면이 필요하다. 기존 S10 소유 범위와 공용 라우터 변경을 인계한다.
- `supabase/functions/reading-worker/index.ts`의 `callEngine`은 501 stub이다. OCR만 연결해 기존 채점 판독까지 완성됐다고 간주하지 않는다. 이 세션은 별도 전사 작업을 우선 구현하고 채점 엔진의 잔여 범위는 명시한다.
- PR #8의 `lib/data/photos/photo_store.dart`와 사진 보존·purge 경계를 사용한다. 절대 경로·`..` 입력을 거부하고 원본/크롭/임시 이미지가 같은 소유권·삭제 범위에 들어가게 한다.

## 차용할 코드와 실행 위치

| 후보 | 역할 | 통합 조건 |
|---|---|---|
| PaddleOCR | 한국어 텍스트 영역 검출·전사 후보 | 한국어 손글씨 지원 모델을 직접 선택·평가. 최신 PP-OCRv6 README의 언어 목록만으로 한국어 지원을 단정하지 않음 |
| UniMERNet | 수식 크롭 → LaTeX 후보 | 한국어 문장 OCR 대체가 아님. 가중치와 전이 의존성의 배포 조건을 별도로 확인 |
| 기존 Flutter 이미지·수식 UI | 원본 대비 교정·확정 | 렌더러는 유지 상태·라이선스를 확인해 선택. LaTeX 파싱 오류도 원문을 보존 |

별도 Python worker에서 모델을 실행하는 것을 기본 설계로 한다. 모델은 서버에 한 번 로드하고 대기열/동시성/메모리 한도를 둔다. 이미지·URL을 임의 네트워크에서 가져오는 범용 프록시는 만들지 않는다. 경량 온디바이스 실행은 실제 모델 변환·한국어 정확도·기기 성능을 입증할 때만 별도 옵션으로 추가한다.

## 먼저 고정할 새 계약(설계 초안)

새 파일 후보: `lib/core/contracts/transcription_engine.dart`, `lib/features/reading/domain/document_transcription.dart`, `lib/data/engines/transcription/`, `services/ocr_worker/`. 모두 **신규 예정 경로**이며 현재 존재하는 구현이 아니다.

- `TranscriptionJob`: schemaVersion, owner에 귀속된 requestId, sourcePhotoIds, sourceRevision, localeHint, purgeEpoch, 취소 상태. owner는 서버가 인증 토큰에서 결정한다.
- `DocumentTranscription`: 페이지별 크기·회전, 정규화 box 좌표, 읽기 순서, text/math 블록, 원문 후보, text 또는 LaTeX, nullable confidence, 엔진/가중치 버전. confidence를 교차 모델에서 같은 척도라고 가정하지 않는다.
- `ConfirmedDocument`: 사용자가 수정·확정한 revision과 블록. 이 버전을 EXT-02에 넘긴다. 재교정하면 이전 풀이의 연결 버전이 달라졌음을 표시한다.
- 상태: queued/running/succeeded/failed/cancelled/expired, 명시적 오류 코드, 부분 실패한 페이지와 재시도. 앱의 저장 중/성공/실패 입력 유지 규칙을 지킨다.
- 로컬 저장·동기화·export·purge에 어느 필드가 들어가는지 계약표를 만든다. 동기화 대상 엔티티면 기존 stamp/outbox/서버 allowlist/RLS까지 함께 확장한다. local-only 초안과 동기화된 확정본을 구분한다.

## 작업 수명과 보안 연결

1. 서버는 사용자·과목/연결 항목 소유권·동의 버전·purge epoch를 검사한다. 요청 크기·페이지 수·디코딩 후 픽셀 수·형식·timeout을 제한한다. 클라이언트 전달 owner나 경로 prefix만 신뢰하지 않는다.
2. 기존 reading quota와 새 OCR 사용량을 같은 것처럼 차감하지 않는다. 무료/유료/재시도/취소 정책을 먼저 결정 문서의 초안으로 남기고, 운영 원장 변경은 해당 정책이 확정되어야 활성화한다. dev 테스트 한도와 운영 과금은 분리한다.
3. 기존 `reading-photos` 잔여 스캐너는 `reading_requests`와 연결된다. 새 OCR job이 그 원장에 없는데 같은 버킷만 재사용하면 조기 삭제될 수 있다. **새 전사 job 등록부 + 전용 private 버킷**을 우선 설계하고, 기존 삭제 큐/계정 삭제/전수 스캔에 연결하는 마이그레이션과 테스트를 함께 만든다. 다른 설계를 택하면 참조 무결성을 입증한다.
4. 서버 사진은 완료·실패·취소 후 즉시 삭제를 시도하고, 삭제 실패 큐·최대 보관 기한을 기존 D14 기준으로 지킨다. 기기 크롭도 원본 생성 시점의 보관 기한을 상속하며 새 파일 생성으로 30일을 재시작하지 않는다.
5. worker 접근은 짧은 수명의 제한된 입력 권한으로 처리한다. callback은 서명/소유 job/attempt·lease token/epoch를 대조하고 중복·만료 callback은 결과를 덮어쓰지 못한다. 원문·사진·토큰을 로그에 쓰지 않는다.
6. OCR 서버 이미지 삭제 후 EXT-02가 같은 이미지를 다시 요구하지 않도록 확정 텍스트/수식으로 연결한다. 도형 등 추가 이미지가 필요하면 별도 사용자 동의·업로드·삭제 계약을 만든다.

## 구현 순서와 통과 기준

| 단계 | 수행 | 통과 증거 |
|---|---|---|
| 1 | 확정 전사 계약, Fake, serializer, job state machine | Dart↔서버 fixture 왕복, 잘못된 좌표·버전·부분 실패·중복 request 테스트 |
| 2 | PR #8 기반 사진 처리, 인증/소유권/epoch, job 등록 | 타 계정·이전 epoch·철회·취소 후 callback·삭제 실패·재시작 회귀 |
| 3 | 모델/가중치 고정, worker 어댑터 | 재현 가능한 이미지 digest·패키지 lock·모델 해시, 실제 요청 성공/timeout/실패 |
| 4 | 촬영/선택→전사→교정→확정 UI와 저장 | 화면 전환·재진입·오프라인·입력 유지·과목/계획 연결, 원문 대조 |
| 5 | 한국어 필기/수식 평가와 모바일 확인 | 아래 평가 기록 + Android/iOS 사진 수명·메모리 확인 |

평가 데이터는 권리/동의가 확인된 것만 사용한다. 필기자·문서 단위로 개발/holdout을 나누고, 문장/숫자/단위/수식/혼합·흐림/회전/그림자를 구분한다. 텍스트 CER/WER, 수식 정규화 exact match, 페이지 읽기 순서, 수동 교정률, 실패율, p50/p95 지연·메모리를 기록한다. 정규화 규칙은 평가 전에 고정하고 의미가 달라진 수식을 동등하게 처리하지 않는다.

세션 초반 baseline을 얻은 뒤 **개선 전에** 제품 목표·holdout 규모·합격 임계값을 기록한다. 현재 측정하지 않은 정확도 숫자를 합격으로 기재하지 않는다. 기준 미달이면 해당 입력의 지원 제한/교정 필요 상태를 구현하고 완료 범위를 줄여 보고한다.

다음 세션에는 확정 원문 schema/fixture, 모델·가중치·라이선스 명세, job/사진 삭제 규칙, 실제 평가표, 미지원 입력 목록을 인계한다. `docs/handoff/EXT-01.md`를 작성하고 [최종 점검](05-final-integration.md)의 누적 항목을 갱신한다.
