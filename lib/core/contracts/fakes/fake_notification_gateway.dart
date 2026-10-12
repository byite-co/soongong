// Fake NotificationGateway (S09): records what the app scheduled; the
// permission is scripted by tests (default granted).

import '../notification_gateway.dart';

class FakeNotificationGateway implements NotificationGateway {
  FakeNotificationGateway({this.permission = NotificationPermission.granted});

  NotificationPermission permission;

  /// What a request would turn the permission into (null = unchanged).
  NotificationPermission? requestResult;

  List<PlannedNotification> scheduled = const <PlannedNotification>[];
  int replaceCalls = 0;
  int cancelCalls = 0;
  int requestCalls = 0;
  int openSettingsCalls = 0;

  @override
  Future<NotificationPermission> permissionStatus() async => permission;

  @override
  Future<NotificationPermission> requestPermission() async {
    requestCalls++;
    final r = requestResult;
    if (r != null) permission = r;
    return permission;
  }

  @override
  Future<void> replaceAll(List<PlannedNotification> plan) async {
    replaceCalls++;
    scheduled = List<PlannedNotification>.unmodifiable(plan);
  }

  @override
  Future<void> cancelAll() async {
    cancelCalls++;
    scheduled = const <PlannedNotification>[];
  }

  @override
  Future<void> openSystemSettings() async {
    openSettingsCalls++;
  }
}
