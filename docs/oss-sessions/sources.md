# 조사 출처와 고정 기준

확인일: 2026-10-13 KST. 다음 SHA는 **이번 준비 검토에서 읽은 소스 기준**이다. 제품에 전부 적용했거나 이 버전/모델을 배포 대상으로 확정했다는 뜻은 아니다. 구현 세션은 실제 선택한 release·패키지·가중치·빌드 산출물의 해시와 조건을 다시 기록한다.

## 공개 코드

| 후보 | 확인한 commit | 읽거나 확인한 부분 / 예정 역할 |
|---|---|---|
| [PaddleOCR](https://github.com/PaddlePaddle/PaddleOCR) | `dab3fe35379033fdcb2d0e9572fac0b36c9a9ebf` | [README](https://github.com/PaddlePaddle/PaddleOCR/blob/dab3fe35379033fdcb2d0e9572fac0b36c9a9ebf/README.md), 한국어 손글씨 모델 선정·비교 필요 |
| [UniMERNet](https://github.com/opendatalab/UniMERNet) | `5a2c80d96b1d2dba447ff18d873e5fb73ba03c35` | [README](https://github.com/opendatalab/UniMERNet/blob/5a2c80d96b1d2dba447ff18d873e5fb73ba03c35/README.md), 손글씨 포함 수식 인식 후보 |
| [Qwen-Agent](https://github.com/QwenLM/Qwen-Agent) | `31a4d36d123688581a9e9744427272b33ce940e0` | [수학 예제](https://github.com/QwenLM/Qwen-Agent/blob/31a4d36d123688581a9e9744427272b33ce940e0/examples/tir_math.py), [executor](https://github.com/QwenLM/Qwen-Agent/blob/31a4d36d123688581a9e9744427272b33ce940e0/qwen_agent/tools/python_executor.py). 도구 흐름 참고, 비격리 exec 제외 |
| [SymPy](https://github.com/sympy/sympy) | `01f79a5f52d4ec14da9d028f4fe9a7f9627679c5` | 수학 연산 후보. 사용자 입력 parser는 별도 보안 경계 필요 |
| [Math-Verify](https://github.com/huggingface/Math-Verify) | `ba3d3aaff23b3f4cac7a14672b4f6e293d97c98b` | [README](https://github.com/huggingface/Math-Verify/blob/ba3d3aaff23b3f4cac7a14672b4f6e293d97c98b/README.md), gold/answer 순서와 정답 검증 범위 |
| [MediaPipe samples](https://github.com/google-ai-edge/mediapipe-samples) | `9cabe32bfdd0a7457e2cb1d2f29ffcf7dc24195f` | [Face Landmarker Android/iOS](https://github.com/google-ai-edge/mediapipe-samples/tree/9cabe32bfdd0a7457e2cb1d2f29ffcf7dc24195f/examples/face_landmarker), native 수명·입력 변환 참고 |
| [OneEuroFilter](https://github.com/casiez/OneEuroFilter) | `d78925584245597f2aa9c4c01a802eb0f0b77fb9` | 연속 신호 smoothing 후보. boolean 집중 판정기 아님 |
| [SQLite3MultipleCiphers](https://github.com/utelle/SQLite3MultipleCiphers) | `45d4ed3487bc02cb08ac73afff47c031c3f88ee0` | 암호화 codec 후보. 실제 native asset에 포함되는 버전은 따로 확인 |
| [sqlite3.dart](https://github.com/simolus3/sqlite3.dart) | `d300b4664b2c75e4dc5ec6789eb17451438211f8` | [hook 문서](https://github.com/simolus3/sqlite3.dart/blob/d300b4664b2c75e4dc5ec6789eb17451438211f8/sqlite3/doc/hook.md), 기존 고정 패키지 3.5.2 아카이브도 별도 확인 |

이번 문서 작성에서는 위 코드를 복제·설치하지 않았다. 라이선스의 조사 당시 개요는 [기존 적용 원장](../oss-integration.md)에 있다. 실제 부분 차용 전 파일 LICENSE/NOTICE, 전이 의존성, 모델 가중치·학습/평가 데이터의 조건을 각각 확인해야 한다. 코드 레포의 라이선스만으로 모든 모델·데이터 사용 조건이 같다고 간주하지 않는다.

## 공식 기술 문서

- [Drift encryption](https://drift.simonbinder.eu/platforms/encryption/): native assets와 암호화 연결, 기존 평문 DB 이전 참고. 앱별 crash consistency·키 소실·계정 정책은 순공에서 추가 설계한다.
- [sqlite3 3.5.2 패키지 metadata](https://pub.dev/api/packages/sqlite3/versions/3.5.2): 공식 아카이브의 `doc/hook.md`에서 sqlite3mc source 선택을 확인. metadata SHA-256 `4c7fe79840389aaeaf05fd093f795b631b5a98e2bd28d54e555c100f4a9c7a1c`는 현재 `pubspec.lock`과 같다. 이 검토는 빌드/런타임 암호화 검증이 아니다.
- [SymPy parsing](https://docs.sympy.org/latest/modules/parsing.html): 문자열 parser를 신뢰되지 않은 입력에 직접 사용하지 않는 설계 근거.
- [MediaPipe Face Landmarker](https://developers.google.com/edge/mediapipe/solutions/vision/face_landmarker): landmark·얼굴 변환 등 출력과 실행 모드 참고. 정신적 집중도 측정의 근거로 사용하지 않는다.
- [Supabase Edge limits](https://supabase.com/docs/guides/functions/limits): 무거운 모델 추론을 별도 worker로 분리하는 자원 제약 근거. 해당 세션 시작 때 변경 여부 재확인.
- [Supabase changelog](https://supabase.com/changelog): 준비 시 최근 변경 확인. 모델 worker·DB 암호화와 무관한 제품 변경을 함께 도입하지 않는다.
- [SQLite3MultipleCiphers releases](https://github.com/utelle/SQLite3MultipleCiphers/releases): 버전에 따라 WAL/rekey 동작이 달라질 수 있으므로 실제 탑재 codec 기준으로 검증한다.

## 순공의 근거

- [main 기준](https://github.com/byite-co/soongong/tree/c5723529c11c225032f9f9b0038fe05255e1c903), [준비 전 통합 코드](https://github.com/byite-co/soongong/tree/df9f71ca16922e3daa601a3780762ef0162446fb)
- [ReadingEngine](https://github.com/byite-co/soongong/blob/df9f71ca16922e3daa601a3780762ef0162446fb/lib/core/contracts/reading_engine.dart), [SeatEngine](https://github.com/byite-co/soongong/blob/df9f71ca16922e3daa601a3780762ef0162446fb/lib/core/contracts/seat_engine.dart), [DB](https://github.com/byite-co/soongong/blob/df9f71ca16922e3daa601a3780762ef0162446fb/lib/data/db/app_database.dart), [계정 binding](https://github.com/byite-co/soongong/blob/df9f71ca16922e3daa601a3780762ef0162446fb/lib/data/auth/account_binding.dart)
- [PR #8 조사 기준](https://github.com/byite-co/soongong/tree/7472b41f5b52d0a0718833b6eb9d5016e9ab2e40), [S09 인계](https://github.com/byite-co/soongong/blob/7472b41f5b52d0a0718833b6eb9d5016e9ab2e40/docs/handoff/S09.md), [PhotoStore](https://github.com/byite-co/soongong/blob/7472b41f5b52d0a0718833b6eb9d5016e9ab2e40/lib/data/photos/photo_store.dart)
- 로컬 문서: [결정](../decisions.md), [판독 API](../reading-api.md), [S14 인계](../handoff/S14.md). D3/D14/D16/D23/D27과 PR #8의 후속 인계 변경을 함께 읽는다.
