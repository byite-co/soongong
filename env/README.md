# env/ — 클라이언트 설정 (D12 · CLAUDE.md §7)

- `app.<flavor>.json` 은 `flutter run --flavor dev --dart-define-from-file=env/app.dev.json` 으로 주입한다.
- 실제 파일(`app.dev.json`, `app.prod.json`)은 `.gitignore` 대상. `*.example.json` 만 커밋한다.
- 여기에는 **공개 키만** 둔다: Supabase URL · anon key · RevenueCat 공개 키. service role 키 자리 자체가 없다.
- 서버 비밀은 `supabase/.env`(S03)로 완전히 분리된다. 앱 코드에서 참조 자체가 금지.
- 읽는 곳: `lib/core/config/app_config.dart` (`String.fromEnvironment` / `bool.fromEnvironment`).

시작하기:

```sh
cp env/app.dev.example.json env/app.dev.json   # 값 채우기
flutter run --flavor dev --dart-define-from-file=env/app.dev.json
```
