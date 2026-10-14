# NEXT-02 · 모델·자료 권리와 재현

실행 기준일2026-10-13. 원본/예측 전문은 로컬에만 두었다. 테스트·공식 공개 모델 다운로드 외 외부 AI API 전송은 없다. 데이터/모델의 실제 파일 SHA256은 [models manifests](../../services/study_worker/models/)와 [자료 inventory](../evidence/next02/datasets.json)에 있다. 예시 hash는 없다.

## 모델 선택과 권리

| 개발 profile | 실제 고정 값/선택 |
|---|---|
| paddle-v3 | PaddleOCR3.7.0/PaddlePaddle3.3.1 **라이브러리**, PP-OCRv3 mobile detector + Korean PP-OCRv3 mobile recognizer **가중치 세대**. manifest10개 약12.7MB. 공개9개 파생본 유효7/9로 v5보다 나아 한국어 비교 baseline을 유지한다. 품질 승인 아님. |
| paddle-v5 | 같은 라이브러리, PP-OCRv5 mobile detector + Korean PP-OCRv5 mobile recognizer. manifest10개 약18.8MB. 합성 인쇄 문장 및 채점표시 개발 smoke 사용, 공개 파생본 유효4/9여서 실제 필기 기본 품질 개선으로 채택하지 않는다. |
| unimernet-tiny | UniMERNet0.2.3 + tiny model/tokenizer6개 약432.2MB. RTX5070/CUDA12.8 실제 실행 가능. 인쇄 수식 strict EM20%로 품질 목표 미달. 더 큰 모델 자동 fallback이나 재호출 없음. |

Paddle 공식 model-card/code는 Apache-2.0, [UniMERNet 공식 코드](https://github.com/opendatalab/UniMERNet)와 [tiny model card](https://huggingface.co/wanderkid/unimernet_tiny)는 Apache-2.0로 표시한다. tokenizer/config도 동일 고정 revision에서 내려받아 hash 대상에 포함했다. 각 profile manifest에는 저장소와 실제 commit이 있다. Paddle 코드 배포물은 PyPI 고정 wheel의 hash로 식별한다. 향후 모델/토크나이저의 upstream 변경은 별도 검증한다.

전이 의존성70(Paddle)/88(math)의 설치 배포물 버전·license metadata는 [Paddle inventory](../evidence/next02/environment-paddle.json), [math inventory](../evidence/next02/environment-math.json)로 남겼다. Python/Pillow/Numpy/Paddle/Torch와 NVIDIA CUDA 배포물의 조건을 각각 유지한다. `crc32c`, `python-bidi`에 LGPL metadata가 있다. metadata가 없는 패키지를 임의로 Apache로 표기하지 않는다. 이는 로컬 실행 inventory이며 public image/binary 재배포의 포괄적 법률 승인이 아니다. 재배포 전 각 배포물 LICENSE/NOTICE 및 NVIDIA 조건을 확인해야 한다. 모델 root 안의 README/license metadata도 hash로 보존한다.

## 환경 재현

두 환경을 분리한다. Ubuntu/WSL Linux, Python3.11.17. `libgomp1`, `libglib2.0-0t64`, GL 런타임 필요. uv0.13.0으로 설치했으며 앱 런타임이 모델을 내려받지 않는다. hash lock은 실제 설치된 전체 배포물 freeze를 기반으로 생성했다. math의 NumPy1.26.4와 PyArrow14.0.2 조합은 실제 검증했다(최신 PyArrow26 ABI 조합은 실패해 사용하지 않는다).

```sh
uv venv --python 3.11.17 /var/tmp/soongong-next02-paddle
uv pip install --python /var/tmp/soongong-next02-paddle/bin/python --require-hashes -r services/study_worker/requirements-ocr.lock
uv venv --python 3.11.17 /var/tmp/soongong-next02-math
uv pip install --python /var/tmp/soongong-next02-math/bin/python --require-hashes --extra-index-url https://download.pytorch.org/whl/cu128 -r services/study_worker/requirements-math-ocr.lock
python services/study_worker/provision_models.py paddle-v3 ../next02-models/paddle-v3
python services/study_worker/provision_models.py paddle-v5 ../next02-models/paddle-v5
python services/study_worker/provision_models.py unimernet-tiny ../next02-models/unimernet-tiny
```

Paddle CPU4threads/MKLDNN OFF. Torch2.8.0+cu128, torchvision0.23.0+cu128, transformers4.42.4. Paddle/Transformers/HF offline 옵션과 명시적 local model 경로만 사용한다. `checked_models`는 누락·추가 파일·변조·symlink 탈출·ID불일치를 거절한다. 4MiB/12M pixels/단일 frame, CPU45초, 요청50초/Edge55초, process group cleanup, semaphore1을 그대로 사용했다. container digest 대신 위 hash lock/모델 manifest/환경 JSON/재현 명령을 제공한다.

실제 root:
`C:\Users\testos_01\Documents\Codex\2026-10-13\pr-9-58-ocr-0-verified\work\next02-models`

## 확보 자료

공통 root:
`C:\Users\testos_01\Documents\Codex\2026-10-13\pr-9-58-ocr-0-verified\work\next02-datasets`

- `korean-notes`: [HumynLabs/Korean_Handwritten_Notes_Dataset](https://huggingface.co/datasets/HumynLabs/Korean_Handwritten_Notes_Dataset/blob/425a7a3cb6b8dd00ffb4b4cf998d37f4509ab154/README.md), commit425a7a3cb6b8dd00ffb4b4cf998d37f4509ab154. 카드CC-BY4.0, 개인 필체 상업적 재사용 제한 등 본문 조건 보존. 공개9개와 README를 다운로드했다. 실제/모사 혼합이며 이미지별 구분·정답·필기자/문서 ID가 없어 모두 unknown/null이다. 원본은 JPEG 확장자지만 MPO로 확인돼 제품 입력에서 거절된다. `korean-notes-first-frame`은 명시적으로0번 frame을 RGB PNG로 바꾼 연구 파생본이다. original hash/변환/동일 source split을 기록했다. 실제 손글씨 CER 표본으로 계산하지 않는다. local OCR 연구만, 재배포/외부 API 전송/필체 재사용 없음.
- `UniMER-Test.zip`, `unimer-cpe-60`: [UniMER Dataset](https://huggingface.co/datasets/wanderkid/UniMER_Dataset), commit2343ddd963290469da36ca83e3a56c66e068add9. archive146,727,503bytes, SHA256`9bf370b8cac868fee84835f40dec26c477430611253e3feb681356a8149a3a90`. 카드Apache2.0; CPE/SCE는 저자 수집/정답 작성, HWE는 CROHME/HME100K 기반이다. 이번에는 CPE60개 **인쇄**만 사용했다. 이미지번호0~5920과 cpe.txt5921행의 연속성을 검사하고 사전 선택한 첫60개를 해당 제공 정답 행에 연결했다. 없는 writer/document ID는 null. 출판 원문별 권리가 별도로 제공된 것은 아니므로 로컬 평가만, 원본 재배포/외부 API 전송 없음. 공개 모델의 평가셋이고 학습 오염/필기자 독립성을 입증하지 못했으므로 독립된 학생 일반화 성능으로 확대하지 않는다.
- 실제5종 채점표시+문항 번호 정답을 가진100개 자료는 확보하지 못했다. `synthetic-grading.png`는 직접 그린 기능 smoke5문항으로 별도 분류한다. real 표본 수에 포함하지 않는다.

데이터 재현은 `python tool/prepare_ocr_evaluation.py ../next02-datasets-new`로 저장소 밖에 준비한다(Pillow 필요). pinned source와 archive hash를 검증하며 path traversal을 막는다. 최초 실행 당시 실제 절대경로/파일 hash는 inventory가 정본이다. 재다운로드시 target 절대경로가 달라 manifest hash 자체는 달라질 수 있다. 원본 image hash로 동일성을 대조한다.

권한이 필요한 후속 후보: [AIHub 이용정책](https://www.aihub.or.kr/intrcn/guid/usagepolicy.do?currMenu=151&topMenu=105)에 따른 한국어 글자체/손글씨 자료 다운로드 계정·데이터 이용 신청 및 해당 제품 평가 범위 확인이 필요하다. [Google MathWriting](https://github.com/google-research/google-research/blob/master/mathwriting/archive_readme.md)은 CC-BY-NC-SA4.0이며 상업 제품 개발 평가 허용을 추정하지 않았다. 해당 권리자의 허용 또는 적합한 별도 연구 범위 확인이 필요하다. HME100K는 UniMER 설명에서 원 저작권 출처의 별도 다운로드를 요구하므로 재호스팅된 HWE 전체의 포괄적 사용허가로 해석하지 않았다. 신규 서비스 가입·자료 신청·권리자 연락은 수행하지 않았다.

## 평가 재현

```sh
MODEL_ROOT=../next02-models/paddle-v3 WORKER_MODEL_ID=paddle-v3-next02 /var/tmp/soongong-next02-paddle/bin/python services/study_worker/ocr_evaluation.py --manifest ../next02-datasets/korean-notes-first-frame/manifest.json --protocol docs/evidence/next02/protocol.json --output ../next02-evaluation/korean-v3-repeat.json --kind text
MODEL_ROOT=../next02-models/unimernet-tiny WORKER_MODEL_ID=unimernet-tiny-next02 /var/tmp/soongong-next02-math/bin/python services/study_worker/ocr_evaluation.py --manifest ../next02-datasets/unimer-cpe-60/manifest.json --protocol docs/evidence/next02/protocol.json --output ../next02-evaluation/math-repeat.json --kind math
MODEL_ROOT=../next02-models/paddle-v5 WORKER_MODEL_ID=paddle-v5-next02 /var/tmp/soongong-next02-paddle/bin/python tool/next02_model_smoke.py --kind grading
MODEL_ROOT=../next02-models/unimernet-tiny WORKER_MODEL_ID=unimernet-tiny-next02 /var/tmp/soongong-next02-math/bin/python tool/next02_model_smoke.py --kind math
```

평가 실행 당시 파일명 `evaluate.py`는 이후 `ocr_evaluation.py`로 바꾸어 HuggingFace evaluate 모듈 이름과 충돌하지 않게 했다. 모델 추론 함수/가중치는 동일하다. cold60개 평가 코드 기준은 b4e06cc540175834f27701b540f89b53052d3ff3, 실제 HTTP grading 재검증은2559e09 기준이며 최종까지 worker/paddle/unimernet 추론 파일 변경 없음. 이후 평가 지표 도구와 안전 경계 변경은 최종 CI로 검증한다.

보고서 root는 위 work 아래 `next02-evaluation`이다. raw report는 정답/예측 전문을 포함하므로 로컬에만 둔다. Git에는 summary·입력 hash·source·null metadata·protocol을 넣었다. timeout/EOF/빈 결과를 분모에서 제외하지 않는다. writer/document/source/hash split 검사와5종Mark metrics를 구현했으나 자료 없는 수치는 null이다. 주관적인 주요 수학 의미 오류율은 별도 전문가 검토가 필요하다.

사후 KaTeX 호환성 probe는 MIT KaTeX0.16.22 tarball, SHA256`e9e0d167db3175481cbadaff38e8d90b130f6a3ddb451a47e43c577fd511f365`를 npm integrity와 대조했다. `node tool/next02_latex_check.cjs <절대 katex.js 경로> <raw report> <로컬 render report>`로 실행한다. 정답도2개 거절되므로 이 지표를 수학적 오답률로 사용하지 않는다.

개발 앱 활성화는 `DEV_OCR_ENABLED=true`와 실제 backend 설정이 모두 필요하며 prod에서 강제OFF다. Edge `STUDY_AI_ENABLED/USER_IDS`, `READING_AI_ENABLED/USER_IDS`, `STUDY_WORKER_URL`(Paddle text), `STUDY_MATH_OCR_WORKER_URL`(별도 UniMERNet 환경), `READING_WORKER_URL`(Paddle grading), `STUDY_WORKER_SECRET`, 각 worker의 `MODEL_ROOT/WORKER_MODEL_ID`, 명시적인 fixture policy/month budget/기존 reading entitlement 또는 AI points lot가 필요하다. 비밀값은 문서/앱/worker 입력/공개 artifact에 넣지 않는다. 앱에 Supabase service_role을 주지 않는다. 개발 HTTPS endpoint와 정책·권리는 이번 로컬 모델 평가와 별개이며 실제 앱 설치 연결은 NEXT-07 미검증이다.
