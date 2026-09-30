# 유저플로우 노드 목록 (soongong-userflow.dc.html 에서 추출)

> v2 보정(S00 v2.2): `imp impFile impConflict impRunning impBad impVer impDupe impSave impN` 9개는 **폐기**(D1). `ageGate`(생년월일 입력)·`ageBlocked`(가입 불가) 2개 **신설**(D6). 하단 탭은 홈/플래너/타임테이블/통계 4개, 설정은 홈 헤더 기어.

노드 ID | 화면군 | 제목
---|---|---
`login` | login | 로그인 · Apple / Google / 카카오 / 이메일
`ob1` | onboard | 온보딩 1 · 순공 측정
`ob2` | onboard | 온보딩 2 · 판독 동의 (3문장)
`ob3` | onboard | 온보딩 3 · 카메라 권한
`homeEmpty` | home | 홈 · 빈 상태
`lgEmail` | login | 이메일 입력 → 기존/신규 판별
`lgPw` | login | 비밀번호 · 기존 계정 · 재설정 링크
`lgSignup` | login | 비밀번호 · 새 계정 만들기
`lgBusy` | login | 로그인 중
`lgFail` | login | 로그인 실패 · 다시 시도 / 다른 방법
`lgReset` | login | 재설정 메일 발송 안내
`acctLogout` | settings | 로그아웃 확인 · 사진은 기기에서 삭제
`acctDelete` | settings | 계정 삭제 확인 · 동기화 기록 전체 삭제
`home` | home | 홈 (무료)
`setupOn` | setup | 집중 시작 준비 · 카메라 ON
`focus` | focus | 집중 중 · 착석 (일시정지 ↔ 이어서는 같은 화면)
`summary` | summary | 집중 기록
`setupDen` | setup | 준비 · 권한 거부
`errCam` | setup | 오류 · 카메라 점유
`away` | focus | 자리 비움 감지 → 복귀 시 자동 재개(집중 중)
`awayLong` | focus | 5분 초과 · 계속하기 / 종료하기 제안
`toast` | summary | 감도 조정 토스트 → 정정 이력
`planner` | planner | 플래너 · 월간
`planFold` | planner | 플래너 · 접힘 + 날짜 상세
`addSheet` | planner | 등록 시트 · 공부/할 일/자습/일정
`datePick` | planner | 날짜 선택 미니 달력
`plan3d` | planner | 플래너 · 3D 시간 보기
`repeatSheet` | planner | 반복 일정 · 요일·시간·종료
`tt` | timetable | 타임테이블 · 주간 24시
`session` | session | 세션 상세
`sessDel` | session | 기록 삭제 확인 모달
`suggest` | planner | 제안 받기 시트 → 플래너에 추가 + 토스트
`capture` | capture | 촬영 · 선택 수 배지
`photos` | photos | 사진 확인 · 현재/목록 · 과목·범위
`sending` | photos | 전송 중 · 전송 취소
`reading` | reading | 판독 중 · N장
`paywall` | home | 페이월 시트 → 7일 무료 → 촬영
`pwConsent` | home | 페이월 · 동의 단계 (온보딩 건너뜀)
`capDenied` | capture | 카메라 권한 꺼짐 → 앨범 / 기기 설정 → 복귀 재확인
`answer` | capture | 정답지 · 곧 제공 시트
`phEmpty` | photos | 사진 없음 → 촬영 / 앨범
`phMissing` | photos | 범위 비어 있음 → 요청 불가 안내
`phPlanner` | photos | 플래너 진입 · 할 일·과목·범위 이어받음
`quota` | capture | 판독 소진 → 요금제 / 닫기
`errOff` | photos | 오프라인 · 다시 시도(연결 재확인) / 사진 두고 나중에
`sendFail` | photos | 전송 실패 · 사진·입력 유지 · 다시 보내기 / 닫기
`rd1` | reading | 판독 중
`rdResult` | result | 판독 결과 확인 (새 결과)
`rdLong` | reading | 오래 걸림 안내 · 닫아도 요청 유지
`rdFail` | reading | 판독 실패 · 다시 찍기(촬영) / 취소(사진 확인) · 횟수 미차감
`hbReading` | home | 홈 · 판독 진행 중 카드
`hbDone` | home | 홈 · 확인 대기 결과 카드 · 저장 전
`rdCancel` | reading | 취소 확인 · 사진·입력은 사진 확인에 남음
`rs1` | result | 결과 확인 · 확인 필요 3 · 저장 불가
`rs2` | result | 결과 · 저장 가능
`rsSaving` | result | 저장 중
`wrongDetail` | wrongdetail | 오답 상세 (저장됨)
`rsMulti` | result | 2페이지 · 탭 전환 · 확인 필요 점
`rsZoom` | result | 원본 확대 · 페이지 이동 · 확인 필요 테두리
`rsZero` | result | 오답 0개 · 이력만 저장 · 큐 추가 없음
`rsSaveFail` | result | 저장 실패 · 마크 유지 · 다시 저장
`rsLeave` | result | 저장 전 이탈 · 계속 / 나중에(홈 카드) / 버리기
`rsEdit` | result | 결과 수정 모드 · 변경 저장 / 변경 취소
`rsEditCancel` | result | 변경 취소 확인 → 원본 유지 · 상세로
`wdDelRes` | wrongdetail | 영향 범위 확인 · 오답 7 · 큐 3 · 재풀이 2 / 사진·세션은 남음
`wdRere` | wrongdetail | 이미 판독한 범위 · 새 회차 / 기존 결과 수정
`rv1` | review | 복습 큐
`rr1` | reviewrun | 복습 진행 · 문항 · 이전 기록 · 선택 전
`rr2` | reviewrun | 선택 후 · 기록하고 다음
`rrDone` | reviewrun | 복습 완료 · 처리 수 · 큐 변화
`rvEmpty` | review | 복습할 것 없음 · 다음 예정 · 촬영 안내
`rrFail` | reviewrun | 기록 저장 실패 · 선택 유지 · 다시 시도
`rrExit` | reviewrun | 중간 종료 확인 · 저장된 N문항 유지 · 현재 선택은 미기록
`rtEdit` | wrongdetail | 재풀이 기록 수정 · 변경 저장 / 닫기(원본 유지)
`rtVoid` | wrongdetail | 기록 취소 확인 → 미해결로 · 큐 재계산
`rtSaving` | wrongdetail | 기록 저장 중
`rtFail` | wrongdetail | 저장 실패 · 선택 유지 · 다시 시도
`phBusy` | privacy | 삭제 중
`phFail` | privacy | 실패 · 다시 시도 버튼
`phBulk` | privacy | 일부 실패 · 남은 사진 표시 · 재시도
`plPending` | plan | 요금제 · 승인 대기 행 · 상태 확인
`plDenied` | plan | 승인되지 않음 · 다시 요청
`impConflict` | privacy | 가져올 내용 · 새 기록 / 완전히 같은 기록 / 같은 날짜 다른 기록(유지)
`impRunning` | privacy | 합치는 중 · 중복 실행 방지
`review` | review | 복습 큐
`retry` | review | 재풀이 기록 시트
`statsP` | stats | 통계 · 프리미엄 (오답 섹션)
`cross` | stats | 시간 × 성취 교차 뷰
`statsF` | stats | 통계 · 무료 (오답 티저)
`settings` | settings | 설정 (무료)
`goal` | settings | 목표 시간 시트
`week` | settings | 주 시작 요일 시트
`notif` | settings | 알림 설정 시트
`planP` | plan | 요금제 · 구독 중
`cancelSub` | plan | 해지 확인 → 종료일까지 유지 (해지 예약)
`cancelled` | plan | 요금제 · 해지 예약 · 해지 취소 가능
`planF` | plan | 요금제 · 무료 → 7일 무료
`help` | help | 도움말 · 문의
`expired` | settings | 체험 만료 시트
`payfail` | settings | 결제 실패 시트 · 기록은 보존 · 재시도는 구매 흐름
`subjects` | subjects | 과목 관리
`subjEdit` | subjects | 과목 편집 시트
`subjAdd` | subjects | 과목 추가 시트
`subjDel` | subjects | 과목 삭제 확인 모달
`privOn` | privacy | 개인정보 · 카메라 ON
`corr` | corrections | 정정 이력
`privOff` | privacy | 개인정보 · OFF (수동)
`delPhotos` | privacy | 사진 삭제 확인 모달
`delDlg` | privacy | 모든 기록 삭제 확인
`expSheet` | privacy | 내보내기 시트 · CSV/JSON
`imp` | privacy | 가져오기 시트
`impFile` | privacy | 파일 확인 → 가져오기
`pwC` | home | 페이월 · 동의 단계
`quotaN` | capture | 판독 소진 시트 · 닫기 → 촬영으로 / 요금제 보기
`camBusyN` | setup | 오류 · 수동 타이머로 → 수동 모드 준비 상태 (닫기만 아님)
`impN` | privacy | 가져오기 · 파일 확인 → 합치기
`cancelN` | plan | 해지 확인 → 종료일까지 유지 (레인 06과 동일 규칙)
`subjDelN` | subjects | 삭제 확인 → 기록은 기타로
`photoDel` | wrongdetail | "삭제됨" 표시 · 오답 유지
`editItem` | planner | 등록 시트 · 편집 모드
`editCancel` | planner | 변경 취소 확인 · 원본 유지
`editDelete` | planner | 이 항목 삭제 확인
`bandEdit` | planner | 기간 일정 수정 · 시작/끝 · 삭제
`discard` | planner | 작성 내용 버리기 확인
`evEdit` | timetable | 반복 일정 수정 · 요일·시간
`evScope` | timetable | 전체 적용 확인 (수정) / 전체 삭제 확인 → 5초 되돌리기 · 첫 출시는 전체 단위만
`recover` | home | 세션 복구 · 바깥 탭 = 유지하고 닫기
`recoverConfirm` | home | 버리기 → 확인 · 취소 시 복구 화면으로
`sumDiscard` | summary | 기록 버리기 확인 → 홈
`sumEdit` | summary | 집중 기록 · 정정 모드 (변경 저장 / 변경 취소)
`sumEditCancel` | summary | 변경 취소 확인 → 세션 상세 · 원본 유지
`lost` | focus | 측정 중단 · 재연결 / 수동 / 종료
`lostFail` | focus | No → 재연결 실패 · 중단 유지 · 수동/종료만
`nfDenied` | settings | 기기 알림 권한 꺼짐 → 기기 설정 → 복귀 갱신
`buying` | home | 구매 진행 중 · 중복 클릭 방지
`pending` | home | 승인 대기 (보호자 승인) → 무료 유지 · 승인 시 자동 전환
`pwFail` | home | 결제 실패 · 청구 없음 → 다시 시도(출발 화면으로) / 닫기
`restoreOk` | plan | 복원 성공 → 프리미엄 · 기록 이어짐
`restoreNone` | plan | 복원할 구매 없음 → 무료 유지
`restoreErr` | plan | 확인 실패 · 다시 결제하지 말 것 · [다시 복원] → 조회 재실행
`impBad` | privacy | 형식 오류 → 다른 파일 고르기 (1단계)
`impVer` | privacy | 새 버전 파일 → App Store 이동 (OS) / 닫기
`impDupe` | privacy | 중복 파일 → 2단계 + 안내 배너 · 버튼 재탭 필요
`impSave` | privacy | 저장 실패 → 같은 파일로 합치기 재실행 · 기존 기록 유지
`expFail` | privacy | 실패 토스트 → [다시 시도] 같은 형식으로 저장 재실행
`hpFail` | help | 문의 전송 실패 · 내용 유지 · 대체 메일
`crEmpty` | corrections | 정정 이력 없음 · 다음 행동
`ttEmpty` | timetable | 타임테이블 기록 없음 · 집중 시작 / 반복 일정
`delAllDlg` | privacy | 삭제 범위 명시 · 세션/플래너/오답/사진/과목/설정 · 구독 유지
`delAll` | home | 완료 → 홈 빈 상태 (측정 중엔 진입 불가)
`roWrongs` | wrongs | 오답 누적 · 읽기 전용 배지 · 재구독 링크
`roDetail` | wrongdetail | 오답 상세 · 해결 버튼 없음(미해결 표시)
`roPhotos` | privacy | 보관 사진 · 확인·삭제 가능
`resub` | wrongs | 재구독 안내 · 가능/불가 목록 · 성공 시 원래 시트로 복귀
`roPlan` | plan | 요금제 · 구독 종료 · 가능/불가 목록 · 월 4,900원 재구독
`roHome` | home | 홈 카드 · 기존 오답 보기 · 읽기 전용
`roSettings` | settings | 설정 · 무료 · 오답 23문항 읽기 전용
`t1` | stats | 통계 · 오답 | 순공·과목·패턴
`t2` | result | 판독 결과 · 원본 사진 | 문항 격자
`t3` | wrongdetail | 오답 상세 · 문항 | 연결·다음 단계
`t4` | onboard | 온보딩 · 600px 가운데
`t5` | home | 홈 · 링 | 목록
`t6` | timetable | 타임테이블 · 주간 | 반복 일정
`t7` | planner | 플래너 · 넓은 달력
`s1` | home | 홈 · 목표 초과 (자습)
`s2` | home | 홈 · 할 일 없음
`s3` | home | 홈 · 로딩
`s4` | home | 홈 · 다크
`s5` | setup | 준비 · 수동 모드
`s6` | focus | 집중 중 · 일시정지
`s7` | focus | 집중 중 · 목표 달성
`s8` | summary | 기록 · 3분 미만
`s9` | summary | 기록 · 구간 수정 시트
`s10` | planner | 플래너 · 다크
`s11` | stats | 통계 · 3일 미만
`s12` | stats | 통계 · 로딩
`s13` | settings | 설정 · 프리미엄
`s14` | home | 홈 · 프리미엄

총 178개 노드. 원본 흐름(액션·조건·엣지)은 reference/final-src/soongong-userflow.dc.html 을 브라우저로 열어 확인.