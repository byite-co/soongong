# env/ — 클라이언트 설정 (D12 · CLAUDE.md §7)

- `app.<flavor>.json` 은 `flutter run --flavor dev --dart-define-from-file=env/app.dev.json` 으로 주입한다.
- 실제 파일(`app.dev.json`, `app.prod.json`)은 `.gitignore` 대상. `*.example.json` 만 커밋한다.
- 여기에는 **공개 키만** 둔다: Supabase URL · anon key · RevenueCat 공개 키 · `CHECK_EMAIL_APP_KEY`(check-email 남용 억제용 앱 키, 비밀 아님) · 소셜 로그인 클라이언트 id(`GOOGLE_SERVER_CLIENT_ID`(웹 클라이언트 id, id_token 발급용) · `GOOGLE_IOS_CLIENT_ID` · `KAKAO_NATIVE_APP_KEY`, S05 — 비어 있으면 그 제공자 버튼은 "이 빌드에서 쓸 수 없음"으로 동작). service role 키 자리 자체가 없다.
- 서버 비밀은 `supabase/.env`(S03)로 완전히 분리된다. 앱 코드에서 참조 자체가 금지.
- 읽는 곳: `lib/core/config/app_config.dart` (`String.fromEnvironment` / `bool.fromEnvironment`).

시작하기:

```sh
cp env/app.dev.example.json env/app.dev.json   # 값 채우기
flutter run --flavor dev --dart-define-from-file=env/app.dev.json
```
