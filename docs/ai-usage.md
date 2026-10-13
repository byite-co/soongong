# NEXT-01 · AI 포인트와 운영비 원장

CONTRACT-CHANGE / SCHEMA-CHANGE. 운영 상품·가격·공급자를 확정한 문서가 아니다. P01~P13은 decisions.md의 사용자 승인 범위를 따른다. 무료/동등 품질 Gemini 수준 원가 비교, 만14세 이상 공급자 조건 검토와 실제 계측은 NEXT-02/03 입력이다. 실제 결제는 NEXT-06이다.

## 분리된 두 원장

포인트는 정수인 `ai_point_lots`와 append 방식 grant/reserve/settle/release 항목 `ai_point_ledger`다. (owner, source, source_id)로 구독 기간/구매/보정 지급을 멱등 처리한다. 동일 근거를 다른 양·만료일로 보내면 conflict. reservation allocation은 각 lot에 연결되고 available=remaining-reserved, 0≤reserved≤remaining≤granted를 DB 제약으로 보장한다. purge는 지급/사용/잔액을 지우지 않는다. 실제 결제/환불 이벤트 승인·서명·store 권리 연결은 없다.

기존 D18 판독 quota는 수정하지 않는다. 테스트 OCR3/풀이7 등은 fixture 값이고 운영 기본값이 아니다. 정책의 terms_version, integer points, charge_order, 임시결과 TTL, provider/model, 가격/환율/한도는 명시적으로 필요하다. 지원한 charge_order=earliest_expiry는 테스트/선택 가능한 정책 구현이며 운영 채택 결정이 아니다. 이월·만료·순서·구독 종료 후 구매 포인트·환불 조건은 미확정이다. seed 정책/지급은 migration에 없다.

비용은 별도 `ai_costs`다. opaque attempt/job, operation, provider/model, price_version/currency/fx_version/fx_at, 예상/최대/실제 금액, 예산 month, usage allowlist, 정산 ID/시각을 기록한다. 원문·사진·응답 전체·비밀키·user_id는 비용 행에 없다. 계정 삭제 시 job도 user/request/content 연결을 제거한다. 최소 비용 정산·객체 삭제 의무는 남는다. 장기 보유 기간/법적 보관 근거는 별도 정책 검토가 필요하며 이 구현이 법적 보관 의무를 확정한 것은 아니다. 미정이므로 공개 실행은 닫혀 있다.

## 내부 상태와 트랜잭션

`reserved → dispatching → succeeded | failed | cancelled | reconciliation_required`.

1. `ai_reserve`: user lock, 프로필/동의/epoch, 같은 요청의 핵심 입력·quote 일치, 문서 CAS, 포인트 lot 가용량, global AI lock, KST 월 예산, allocation/ledger/job/cost 예약을 한 DB transaction으로 수행한다.
2. `ai_dispatch`: user→global lock, lease/정책/revision 재확인. 첫 claimant만 provider 호출 자격을 얻고 cost를 unknown으로 바꾼다. DB 잠금을 놓은 뒤 Edge가 HTTP를 보낸다.
3. `ai_finish`: user→global lock, 결과 크기/기존 v1 검증/소유권/epoch/revision 검사. 결과 저장과 포인트 settle이 함께 commit 또는 rollback한다. 이미 끝난 작업의 중복 이벤트는 다시 차감하지 않는다. invalid/failed/cancelled는 예약 포인트를 한 번 반환한다.
4. dispatch 이전 취소만 proved-not-dispatched 비용0·예약 해제를 허용한다. 그 외 HTTP 실패·프로세스 종료·lease 만료는 비용0의 증거가 아니다. 사용자 반환과 비용 unknown/예약은 독립적이다.
5. lease가 지난 dispatch는 reconciliation_required, 아직 dispatch되지 않은 예약은 cancelled. 미확정 작업에 자동 provider 재호출은 없다. AI maintenance는 **transaction당 한 사용자**만 다룬다. global lock을 가진 채 다음 사용자의 lock을 얻는 교착 경로를 만들지 않는다.
6. 임시 추론 결과 TTL 만료 시 result를 없애고 result_expired를 반환한다. 같은 요청을 재실행하지 않는다. 사용자 확정 문서 저장과 이 TTL은 별개다.

원문 revision 변경/문서 삭제는 해당 job을 취소하고 기존 임시 결과·digest를 제거한다. purge epoch 변경과 계정 삭제도 같은 경계를 사용한다. 이미 성공 정산한 포인트/실제 비용을 삭제 이유로 되돌리지는 않는다. 늦은 callback은 문서/프로필/지갑을 생성하지 않는다.

내부 예약/정산의 멱등성을 검증했다. 외부 공급자 실행에 exactly-once를 보장하지 않는다. 기존 서버 삭제 ACK 직후 첫 로컬 receipt 기록 전 프로세스 종료, 실제 전원 손실·OS 강제 종료는 이전 UNVERIFIED를 유지한다.

## 정확한 월 비용 예약

UTC timestamptz 저장, 예산 월은 예약 당시 Asia/Seoul 월의 첫 날짜(기술 기본값). 정산이 다음 달이어도 원래 월만 해제/증액한다.

예약 상한(KRW) = ceil((max_input_tokens × input_price + max_output_tokens × output_price + fixed_price) × max_attempts × krw_per_currency × 10^8) / 10^8.

input/output_price는 **토큰1개당 원통화**, fixed_price는 attempt당 원통화다. 가격표가100만 토큰 단위라면 설정 전에 명시적으로 변환한다. 값은 Postgres numeric이며 부동소수 누적을 쓰지 않는다. 원통화 정산은 소수10자리, KRW 예산 설정은 소수8자리까지다. 더 정밀한 입력은 조용히 반올림하지 않고 거절하여 재전송 비교와 정산액이 갈라지지 않게 한다. (20,8) KRW 예약 단위에서 항상 올림. 검증 호출까지 max_attempts에 포함해야 한다. 검증할 수 없는 provider의 tokenizer/hidden reasoning/cache/재시도 과금 상한을 임의로0으로 가정하지 않는다.

승인 조건: spent_krw + reserved_krw + infrastructure_krw + 이번 상한 ≤ limit_krw ≤300000. 사용자 간 global advisory lock으로 경쟁을 막는다. 추론 서버 월 고정/예약비는 infrastructure_krw로 먼저 배정한다. 경고 비율은 명시적 warning_ratio, 알림 서비스 연결은 후속이다. 예산이 없으면 무제한이 아니라 budget_unavailable. 월 하한10만원 지출 강제 없음. 개발비/기타 서비스 비용을 이 한도에 몰래 포함하지 않는다.

`ai_reconcile(job, settlement UUID, actual 원통화 numeric, usage JSON)`은 실제 공급자 정산 증거를 확보한 신뢰된 서버 작업만 호출한다. usage는 input_tokens/output_tokens/cached_tokens/reasoning_tokens/requests의 비음수 정수만 허용한다. 없는 usage를0원으로 확정하지 않는다. 같은 settlement+금액+usage는 멱등, 다른 값은 conflict. 실제 초과 청구는 숨기지 않고 기록하여 이후 예약을 차단한다. 환율·과금 지연·외부 호스트 요금까지 절대 한도를 보장하지 않는다.

## 불명 실행의 조정 절차

- status의 job ID와 서버 cost attempt ID를 사용한다. 원문/사진을 비용 티켓이나 로그에 복사하지 않는다.
- provider의 문서화된 조회/idempotency 기능 또는 확정 사용 명세로 실행·금액을 확인한다. 이 공급자 연결은 현재 없다.
- 실행 안 됨이 입증되지 않으면 예약을0으로 해제하거나 재실행하지 않는다. 사용자 취소는 포인트만 반환할 수 있다.
- actual/usage를 확인하면 `ai_reconcile`로 원래 월에 정산한다. 금액을 모르면 unknown을 유지한다. 별도 사용 이벤트는 동일 정산 키를 보존한다.
- 결과를 확보했더라도 epoch/revision/동의가 바뀌었으면 사용자 결과는 폐기한다. 비용은 계속 정산한다.

## 현재 실행 설정과 후속 입력

플래그 기본 OFF, allowlist, HTTPS private endpoint(redirect/query/userinfo 금지),32자 이상 공유 비밀키, 프로필/동의/epoch, 명시적 policy, 해당 월 budget와 points lot, 앱 quote 승인까지 있어야 진행할 수 있다. 실제 생성·배포한 설정은 없다.

현재 worker HTTP는 v2와 provider=local/설정된 WORKER_MODEL_ID의 일치만 허용한다. 기존 solver/CAS helper는 유지·회귀 검사하지만 유료 remote solve HTTP는 billing_adapter_unconfigured로 닫았다. 정확한 tokenizer/최대 출력·검증 호출/usage·가격 상한을 보장할 provider adapter가 없기 때문이다. 실제 엔진·가격을 이번에 선정하지 않는다. worker는 사용자의 포인트나 service_role을 받지 않는다.

다음 세션은 실제 모델·가중치 권리/고정 해시·컨테이너와 tokenizer, 공급자 연령/보관/지역/가격 문서, 권리가 확인된 한국어 필기·수식/수능 평가셋, 정답·실패율·지연·재시도 포함 건당 비용 기준을 준비한다. approved quote 진입점 `RemoteAiJobs`와 provider transport v2를 사용하고, 실제 HTTP/Storage/OS 검증 전에는 공개 플래그를 켜지 않는다.
