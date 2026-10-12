// NotificationGateway (S09): the seam between the app and local device
// notifications. The app decides WHAT to show (`NotificationPlan`, pure
// Dart: 복습 큐 시각 · 반복 일정 10분 전 — nothing that urges studying,
// CLAUDE.md §1); the gateway only asks for permission and schedules the
// given instants. The real implementation wraps flutter_local_notifications
// (`data/notifications/`); tests use the Fake.

/// One scheduled local notification. [id] is stable for the same source so
/// re-planning replaces instead of duplicating.
class PlannedNotification {
  const PlannedNotification({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
  });

  final int id;

  /// Local instant to fire at.
  final DateTime at;
  final String title;
  final String body;

  @override
  String toString() => 'PlannedNotification($id @ $at · $title)';
}

enum NotificationPermission {
  granted,
  denied,

  /// Not asked yet (or not determinable on this platform).
  unknown,
}

abstract class NotificationGateway {
  Future<NotificationPermission> permissionStatus();

  /// Prompts the OS dialog when possible; returns the resulting status.
  Future<NotificationPermission> requestPermission();

  /// Cancels every pending notification of the app and schedules [plan].
  Future<void> replaceAll(List<PlannedNotification> plan);

  Future<void> cancelAll();

  /// Opens the OS app-settings page (`nfDenied` → 기기 설정 열기).
  Future<void> openSystemSettings();
}
