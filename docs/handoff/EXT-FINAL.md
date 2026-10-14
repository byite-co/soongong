# EXT-01~04 순차 적용 · 통합 인계

> 후속 검토에서 확인된 고유 결함 10건의 수정·회귀·잔여 조건은 [EXT-FIX-01](EXT-FIX-01.md)을 따른다. 아래 CI와 커밋 기록은 당시 증거이며 후속 코드의 검증으로 재사용하지 않는다.

2026-10-13 KST. 통합 브랜치 `feat/s14-oss-integration`, [Draft PR #9](https://github.com/byite-co/soongong/pull/9). **main 미병합, 운영 미배포.**

## 적용 결과

| 단계 | 실제 연결 | 상태 / 남은 조건 |
|---|---|---|
| EXT-01 손글씨 OCR | 촬영/선택 → 전송 동의 → 인증·동의·epoch gateway → PaddleOCR/UniMERNet worker 어댑터 → 교정 → 로컬 확정 저장 | 코드 구현. 기본 OFF + 사용자 allowlist. 실제 모델 설치/배포·한국어 필기/수식 평가 미완료 |
| EXT-02 수학 풀이 | 확정 원문/revision → 제한된 모델 도구 루프 → 격리 SymPy 계산 → Math-Verify 수치 대조 → 사용자 확인 저장 | 코드 구현. 실제 수학 모델 endpoint/가중치 미설정. 수능 정확도 평가 미완료; 정답 없으면 inconclusive |
| EXT-03 시선 관측 | MediaPipe 1.1.0 Android/iOS 브리지 → 눈 좌표 → One Euro 수식 → 보정 → dev 관측 화면 | 코드 구현. 기기 안에서만 처리. 정신적 집중/성적/순공시간 판정에 미사용. 실기기 평가 미완료 |
| EXT-04 DB 전체 암호화 | sqlite3mc → 기기 보안 키 → 사본 검증/교체 → 중단 복구 → 암호화 Drift opener | 코드 및 자동 이전/복구 검증. 기기 SQLite 전체 기준; 서버 DB·사진·사용자 export 암호화는 범위 아님 |

상세: [EXT-01](EXT-01.md), [EXT-02](EXT-02.md), [EXT-03](EXT-03.md), [EXT-04](EXT-04.md). 사전 정합성 검토는 [세션 준비 문서](../oss-sessions/README.md), 전체 후보별 적용/미적용은 [적용 원장](../oss-integration.md).

## 커밋 순서

1. `55d06af` — 검토한 S09 PR #8 HEAD `7472b41`를 추가 부모로 통합, OCR 기반 구현.
2. `9d69ccf` — 로컬 스키마 이전 원자성/사진 선택 계정 경계 수정.
3. `8773c6d` — 풀이·정답 대조·확인 저장, export widget의 가상 시간 테스트 분리. Flutter/서버/worker 통과.
4. `0ffbebe` — 실제 온디바이스 시선 브리지/보정/실험 화면과 모델 해시 검증.
5. `81f3b94` — 전체 DB 암호화/키/중단 복구/backup 정책/보호 화면.
6. `b96461c` — 통합 정적 검사 수정, 실제 격리 계산 테스트와 전송 경계 보강. 아래 자동 검사 통과.
7. 최종 보강 — 사진 선택 늦은 완료와 새 입력 간 경합 차단, purge 진행 중 전송 거부, 풀이 저장의 문서/revision 재검증, 암호화 준비 화면, 인계 갱신. 이 변경을 포함한 최종 SHA/검사 링크는 PR #9 본문과 checks에 기록한다.

## 확인한 자동 검사

검증 기준 `b96461c44d6a587eb30c890e72da5e96cb91a4ef`:

| 검사 | 결과 | 증거 |
|---|---|---|
| Flutter | 678/678, codegen clean-tree, analyze --fatal-infos, 금지 문구 통과 | [analyze-test](https://github.com/byite-co/soongong/actions/runs/38317482015) |
| PostgreSQL | pgTAP 404/404, SQL 진단 신규 오류 gate 통과 | [server-tests](https://github.com/byite-co/soongong/actions/runs/38317481932) |
| Edge | Deno 33/33, 함수 타입 검사 통과 | 같은 server-tests |
| Worker | Python 8/8, 실제 격리 CAS 프로세스 포함 | [study-worker](https://github.com/byite-co/soongong/actions/runs/38317481916) |

암호화 회귀: 전체 schema/user_version/custom table/binary outbox 내용 보존, 키 없는 평문 조회 거부, 잘못된 키로 파일 불변, copying/verified/original-renamed/installed/cleaned 중단 후 복구, checkpoint되지 않은 WAL 보존, 신규 파일의 첫 쓰기 이전 암호화.

Android 네이티브 시선 빌드는 `0ffbebe`에서 통과했다. 같은 실행의 iOS는 기존 ML Kit 최소 버전 15.5와 프로젝트 15.0 불일치를 발견했고 후속 커밋에서 고쳤다. **최종 Android/iOS 빌드 결과는 PR #9 checks를 확인한다.** 빌드는 카메라/키체인의 실기기 동작 검증을 대신하지 않는다.

로컬 Flutter는 이전 자동 승인 검토가 metadata 주소 접근을 거절한 뒤 실행하지 않았다. Flutter/네이티브 결과는 GitHub Actions의 결과다. Python 계산/이미지 경계 8건은 로컬과 CI에서 실행했다.

## 병합 전 남은 점검

- 모델: 운영자가 검토한 OCR/수학 모델의 정확한 가중치·라이선스·전이 dependency lock·container digest·호스팅 설정. 권리가 확인된 한국어 손글씨/수식/수능 수학 평가셋에서 정확도·실패율·지연·비용 검증. 현재 가짜 정확도 수치나 모델 완료 주장은 없다.
- 사진: image_picker가 앱 임시 파일을 만든다. 자동 압축/리사이즈를 끄고 반환 파일은 읽은 뒤 삭제, 실패 표시. 픽커가 완료되기 전 프로세스가 종료된 고아 캐시/Android lost-data 및 계정·일괄 삭제 연동은 실기기 검증·보강이 필요하다. 사진이 기기 디스크에 전혀 기록되지 않는 경로는 아니다.
- 시선: 안경/조명/기기 방향/머리 움직임/종이·폰 자세별 관측 불가 비율·오검출·발열/전력 측정. 아직 검증된 집중 판독기가 아니다.
- 암호화: Android/iOS **release** 바이너리의 실제 codec/ML Kit·MediaPipe 공존, 키체인 잠금·기기 이전·백업 복구, 저용량·강제 종료·전원 손실, 기기별 시작/조회 지연. 프로세스 중단 회귀와 전원 손실의 저장장치 내구성은 다르다.
- 기존 S13 SyncEngine과 Mark ReadingEngine은 Fake다. 새 전사/풀이 저장은 local-only. OS 백업/기기 이전 제외에 따른 미동기화 데이터 보존 한계를 제품에서 다뤄야 한다.
- 일반 공개 사용량/비용 정책 및 큐는 미구현. pilot은 기본 비활성화 + 명시적 사용자 allowlist. 운영 Edge/worker/DB 배포 없음.

## 재현 / 다음 작업

`python3 tool/fetch_gaze_model.py` → `flutter pub get` → 기존 analyze-test 명령. 모델 SHA 검증 실패는 빌드 중단. worker 테스트는 `services/study_worker/README.md` 참고. 새 key/원문/사진을 로그나 PR에 남기지 않는다.

최종 병합은 최신 main/PR #8 변동을 재확인하고, 이 문서의 미검증 조건을 해소한 뒤 **PR #9 한 번으로** 진행한다. 암호화 이후 이전 평문 전용 앱으로 되돌리거나 키를 재생성하지 않는다. 복구는 호환 버전으로 roll-forward한다.

후속 iOS 빌드: 최소 버전 수정 이후 Pods_Runner framework 연결 실패를 확인했다. 명시적 iOS 15.5 Podfile, dev/prod의 Debug/Profile/Release 구성 매핑, workspace의 Pods 프로젝트 참조를 고정하고 재검증한다. 개인정보 화면에는 OS 백업/기기 이전 제외와 내보내기 안내를 추가했다.

첫 iOS 시뮬레이터 빌드 제한: MLKitVision 10.0.0의 공식 podspec은 arm64 simulator를 제외한다. Flutter 3.47.5는 Pods가 없는 첫 빌드에서 Generated.xcconfig를 pod install 전에 생성하므로, 이 제한을 보지 못해 앱/Pods의 architecture가 어긋날 수 있다. 모든 앱 xcconfig에서 Generated 뒤에 `MLKitSimulator.xcconfig`를 읽어 기기 arm64는 유지하고 simulator arm64만 제외한다. iOS 26의 arm64 전용 시뮬레이터는 지원하지 않으며, x86_64 지원 simulator 또는 실기기가 필요하다. 최종 통과 여부는 PR checks에 기록한다.

후속 네이티브 증거 (`ee97d22`, Actions `38321101810`): 시뮬레이터 아키텍처 정합성을 맞춘 뒤 Pods_Runner 오류는 사라졌다. 그러나 MediaPipe 1.1.0의 `MediaPipeTaskGraphs_library.a`가 arm64만 제공해 x86_64 링크에서 `MPPFaceLandmarker`/`MPPImage`가 누락됐다. **현재 ML Kit + MediaPipe 조합은 시뮬레이터에 공통 지원 아키텍처가 없다.** 앞 문단의 x86_64 simulator 안내는 ML Kit 단독의 제한 설명이며 전체 앱 실행 안내가 아니다. 전체 앱은 iPhone ARM64 대상으로 빌드·검증한다. native-check의 iOS gate를 실제 기기 대상 Release/no-codesign으로 변경했다. 이는 설치/서명/배포/실기기 동작 검증을 뜻하지 않는다. 시뮬레이터 지원에는 SDK 교체 또는 별도의 검토된 빌드가 필요하며, 오류를 숨기는 가짜 브리지는 넣지 않았다.
