# 디자인 토큰 대조표 (S01)

원본: `docs/reference/final-src/soongong-prototype.dc.html` (`.frame{--…}` = 라이트, `[data-theme="b"]` = 다크, `COLORS`/`SUBJ` = 과목색, 인라인 스타일 빈도 집계).
코드: `lib/core/theme/tokens.dart` (원시 토큰) · `lib/core/theme/app_theme.dart` (`AppColors` 시맨틱 + `ThemeData`).
규칙: CLAUDE.md §6 · PRD §8. 프로토타입과 규칙이 충돌하면 규칙이 우선하고 아래 "편차"에 적는다.

## 1. 색 — 시맨틱 (`AppColors`)

| 프로토타입 변수 | 라이트 | 다크 | `AppColors` 필드 | 무채색 스케일 |
|---|---|---|---|---|
| `--bg` | `#F5F5F7` | `#0B0B0F` | `bg` | n100 / n950 |
| `--surface` | `#FFFFFF` | `#141419` | `surface` | — / darkSurface |
| `--surface2` | `#FFFFFF` | `#1A1A21` | `surface2` | — / n800 |
| `--sunk` | `#EFEFF2` | `#101015` | `sunk` | n200 / darkSunk |
| `--tx` | `#111114` | `#F4F4F6` | `tx` | n900 / darkTx |
| `--tx2` | `#4E4E58` | `#B4B4BE` | `tx2` | n700 / darkTx2 |
| `--tx3` | `#6E6E7A` | `#8C8C98` | `tx3` | n600 / darkTx3 |
| `--line` | `#E6E6EB` | `rgba(255,255,255,.08)` | `line` | n300 / — |
| `--pri` | `#3D5AFE` | `#7A8CFF` | `pri` | AppAccent.blue / blueDark |
| `--pri-weak` | `#EEF1FF` | `rgba(122,140,255,.14)` | `priWeak` | |
| `--pri-tx` | `#2F49E0` | `#9DAAFF` | `priTx` | |
| `--pri-faint` | `rgba(61,90,254,.22)` | `rgba(122,140,255,.24)` | `priFaint` | |
| `--acc` | `#FF6B3D` | `#FF7A4D` | `acc` | AppAccent.orange / orangeDark |
| `--acc-weak` | `#FFF1EA` | `rgba(255,122,77,.14)` | `accWeak` | |
| `--acc-tx` | `#B8431A` | `#FFA07A` | `accTx` | |
| (CTA 글자) | `#FFFFFF` on pri · `#1A0E08` on acc | 동일 | `onPri` · `onAcc` | |
| `--ok` | `#12A05C` | `#2BD48A` | `ok` | |
| `--ok-weak` | `#EAF6EF` | `rgba(43,212,138,.12)` | `okWeak` | |
| `--ok-tx` | `#0B7A45` | `#5FE3A8` | `okTx` | |
| `--grid` | `#EBEBEF` | `rgba(255,255,255,.06)` | `grid` | |
| `--skel` / `--skel-hi` | `#EFEFF2` / `#F7F7F9` | `#101015` / `#1B1B22` | `skel` / `skelHi` | n200·n50 / — |
| `--scrim` | `rgba(17,17,20,.42)` | `rgba(0,0,0,.66)` | `scrim` | |
| `--shadow` | `0 1px 2px rgba(0,0,0,.04)` | `none` | `shadow` | |
| `--r1` `--r2` `--r3` `--r4` | `#E4E4E9` `#C9C9D2` `#9D9DAB` `#3D5AFE` | `#1C1C24` `#2A2A36` `#454560` `#7A8CFF` | `ringTrack1..3` · `ringFill` | n400·n500 |
| 토스트 | bg `var(--tx)` · fg `var(--bg)` · 액션 `#8FA0FF` | bg `#F4F4F6` · fg `#0B0B0F` · 액션 **`#2F49E0`**(편차, 7장) | `toastBg` `toastFg` `toastAction` | |

## 2. 무채색 스케일 (`AppNeutral`)

| 스톱 | 값 | 출처 |
|---|---|---|
| 50 | `#F7F7F9` | skel-hi (라이트) |
| 100 | `#F5F5F7` | bg (라이트) |
| 200 | `#EFEFF2` | sunk / skel (라이트) |
| 300 | `#E6E6EB` | line (라이트) |
| 400 | `#C9C9D2` | r2 (라이트) |
| 500 | `#9D9DAB` | r3 (라이트) |
| 600 | `#6E6E7A` | tx3 (라이트) |
| 700 | `#4E4E58` | tx2 (라이트) |
| 800 | `#1A1A21` | surface2 (다크) |
| 900 | `#111114` | tx (라이트) |
| 950 | `#0B0B0F` | bg (다크) — 50~900 밖이라 별도 스톱으로 추가 |

다크 전용 중간값(`#101015` `#141419` `#F4F4F6` `#B4B4BE` `#8C8C98`)은 스케일에 억지로 맞추지 않고 `AppNeutral.dark*` 로 둔다.

## 3. 과목색 8 (`AppSubjectColors`)

프로토타입 `COLORS` 배열(라이트, 색각 이상 검증본). 다크는 프로토타입에 정의가 없어 **S01에서 파생**: 같은 색상(hue)·채도를 유지하고 명도만 올려 다크 배경 `#0B0B0F`·`#141419` 대비 ≥ 4.5:1 을 만족하는 첫 값. 검증: `test/unit/tokens_test.dart`.

| # | 이름 | 라이트 | 대비(흰 배경) | 다크 | 대비(다크 배경) | 프로토타입 기본 과목 |
|---|---|---|---|---|---|---|
| 0 | indigo | `#4059F0` | 5.38 | `#6176F3` | 5.05 | 수학 |
| 1 | pink | `#D6428F` | 4.17 | `#D74691` | 4.84 | 영어 |
| 2 | green | `#45A52C` | 3.15 | `#45A52C` | 6.24 | 국어 |
| 3 | brown | `#9A5505` | 5.71 | `#C26B06` | 5.05 | 과학 |
| 4 | teal | `#1E8A9E` | 4.05 | `#1E8A9E` | 4.85 | 사회 |
| 5 | slate | `#79809E` | 3.89 | `#79809E` | 5.05 | 기타 |
| 6 | purple | `#7A3FCF` | 6.11 | `#9668D9` | 4.94 | — |
| 7 | red | `#C0392B` | 5.44 | `#D65548` | 4.91 | — |

과목색은 점·미터·오답 표시에만 쓰고 **항상 이름 라벨을 동반**한다(`SubjectChip` 은 `name` 필수).

## 4. 간격 · 반경 · 크기

| 종류 | 프로토타입 빈도 상위 | 토큰 |
|---|---|---|
| gap | 8(121) 12(111) 4(49) 6(25) 10(21) 16 32 | `AppSpacing.s2…s44` |
| 페이지 좌우 여백 | `padding: 0 20px` (51) · 헤더 `4px 20px 16px` | `AppSpacing.page = 20` |
| 시트 패딩 | `8px 20px 44px` | `AppSheet` · `AppSpacing.sheetBottom = 44` |
| CTA 바 | `32px 20px 44px` | — (S05 이후 화면에서 사용) |
| border-radius | 14(152) 20(89) 16(55) 999(51) 10(49) 12(48) 8(32) 22 26 | `AppRadius.r8…r26` · `pill` |
| 카드 | 14 | `AppRadius.card` |
| 버튼 | 14 (54/46 높이) · 12 (42 높이) · 10 (32 높이 칩 버튼) | `AppRadius.button` · `buttonSmall` · `chip` |
| 시트 | `20px 20px 0 0` (태블릿 26, 폭 520) | `AppRadius.sheet` · `sheetTablet` · `AppLayout.sheetTabletWidth` |
| 확인창 | 20 · `padding 24px 20px` · 좌우 inset 32 · max 420 | `AppRadius.dialog` · `AppLayout.dialog*` |
| 토스트 | 16 · `padding 12px 14px` · 좌우 20 | `AppRadius.toast` |
| 버튼 높이 | 54 / 46 / 42 (터치 타깃 44 보장) | `AppLayout.buttonLarge/Medium/Small` |
| 링 | 152 · 바깥 r70 stroke4 · 안쪽 r58 stroke10 · 눈금 r2.2 · 바늘 3.5(halo 7) · 중앙 84 | `AppRing.*` |
| 태블릿 분기 | 프로토타입 `data-device^="tablet"` | `AppLayout.tabletBreakpoint = 600` |

## 5. 타이포그래피 (6단계, `AppTypography`)

프로토타입 `font-size` 빈도: 12(291) 13(173) 15(144) 14(105) 17(37) 22(26) 18(26) 28(23). 크기별 지배 weight·letter-spacing 을 그대로 채택.

| 단계 | 크기 | weight | letter-spacing | line-height | 프로토타입 용례 |
|---|---|---|---|---|---|
| display | 28 | 700 | -0.03em | 1.25 | 순공시간 큰 숫자 |
| title | 22 | 700 | -0.03em | 1.25 | 화면 제목 |
| heading | 17 | 600 | -0.028em | 1.4 | 섹션·확인창 제목 |
| body | 15 | 500 (버튼 600) | -0.02em | 1.6 | 본문·리스트 행 |
| label | 13 | 500 (강조 600) | 0 | 1.5 | 보조 문구·확인창 본문·토스트 |
| caption | 12 | 500 (칩 600) | 0 | 1.5 | 메타·캡션·칩 |

- 글꼴: Pretendard Variable 1.3.9 번들(`assets/fonts/`, OFL-1.1), weight 는 `wght` 축(`FontVariation.weight`)으로 적용. 폴백: Apple SD Gothic Neo → Noto Sans KR → sans-serif.
- 숫자: 시간·카운터는 `AppTypography.tabularFigures` (프로토타입 `font-variant-numeric: tabular-nums`).
- 6단계 밖의 프로토타입 크기(18/20 · 14 · 11 · 10)는 각 화면에서 `copyWith(fontSize:)` 로 파생한다(링 라벨 10/600 은 `RingClock` 내부).

## 6. 그림자 · 모션 · 아이콘

| 항목 | 값 | 토큰 |
|---|---|---|
| 카드 그림자 | 라이트 `0 1px 2px rgba(0,0,0,.04)` · 다크 없음 | `AppShadow.card` / `AppColors.shadow` |
| 시트 등장 | 280ms `cubic-bezier(0,.9,.3,1)` | `AppMotion.sheetIn` · `sheetCurve` |
| 토스트 등장 | 220ms | `AppMotion.toastIn` |
| 페이드 / 팝 | 160ms / 200ms | `AppMotion.fade` · `pop` |
| 미터 | 320ms `cubic-bezier(.2,.8,.25,1)` | `AppMotion.meter` · `meterCurve` |
| 링 sweep | 600ms | `AppMotion.ringIn` |
| 되돌리기 창 | 5s (D22) | `AppMotion.undoWindow` |
| reduced-motion | `MediaQuery.disableAnimations` | `AppMotion.reduced(context)` |
| 아이콘 | Lucide 24px, 작은 16px | `AppIcon.size` · `sizeSmall` · `LucideIcon` |

## 7. 편차 (규칙 > 프로토타입)

| 항목 | 프로토타입 | 적용 | 근거 |
|---|---|---|---|
| 확인창 그림자 | `0 24px 60px -18px rgba(5,8,25,.5)` | 없음(스크림만) | CLAUDE.md §6 그림자 ≤ `0 1px 2px` |
| Lucide stroke | 1.75 (SVG) | 폰트 고유 2px | 아이콘 폰트는 stroke 조절 불가. `AppIcon.strokeWidth = 1.75` 는 직접 그리는 아이콘(링 바늘 등)에 적용 |
| 과목색 다크 | 없음 | 파생값(3장) | 다크 테마 필수 |
| 작은 버튼 42px | 42 | 시각 42 + 히트 44 | 터치 타깃 44 |
| 다크 주 버튼 글자 | `#FFFFFF` on `#7A8CFF` (2.6:1) | `#0B0B0F` on `#7A8CFF` (6.6:1) — `AppColors.dark.onPri` | 텍스트 대비 4.5:1 |
| 다크 토스트 액션 | `#8FA0FF` on `#F4F4F6` (2.3:1) | `#2F49E0` on `#F4F4F6` (6.1:1) — `AppColors.dark.toastAction` [S01b] | 텍스트 대비 4.5:1 |
| 작은 버튼·토스트 액션 탭 영역 | 시각 42 · 텍스트만 | 탭 위젯 자체가 44×44 이상(시각 요소는 그대로) [S01b] | 터치 타깃 44 |
