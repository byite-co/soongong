// Consent ② (외부 판독 전송) wording — the D14 data-processing table, one line
// per row, facts only, no promise beyond the table (S05b). Shared by the
// onboarding step 2 (S05), the paywall consent step (S12) and the settings
// "저장 데이터 표" (S09): all three reference these constants, never a copy.
// Checked by tool/check_forbidden_phrases.dart.

abstract final class ConsentStrings {
  /// D14 · 판독 사진 · 기기: 최초 보관일 +30일, 즉시 삭제·로그아웃 삭제.
  static const String readingDevice =
      '판독 사진은 이 기기에 최초 보관일부터 30일 보관됩니다. 즉시 삭제할 수 있고, 로그아웃하면 삭제됩니다.';

  /// D14 · 판독 사진 · 자사 서버: 처리 종료 직후 삭제, 잔여물 업로드 +24시간 내.
  static const String readingServer =
      '자사 서버의 사진은 판독 처리가 끝난 직후 삭제합니다. 잔여분은 업로드 후 24시간 이내에 지웁니다.';

  /// D14 · 판독 사진 · 외부 AI: 전송 사실만. 벤더 보관·학습·로그 정책은 미결(S16).
  static const String readingVendor =
      '판독을 위해 사진이 외부 AI 벤더로 전송됩니다. 벤더의 보관 조건은 확정 전입니다.';

  /// The three lines in table order.
  static const List<String> readingLines = <String>[readingDevice, readingServer, readingVendor];
}
