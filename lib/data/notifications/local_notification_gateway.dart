// LocalNotificationGateway (S09): flutter_local_notifications +
// permission_handler behind `NotificationGateway`. Schedules the exact local
// instants the plan computed (`tz.TZDateTime.from(instant, tz.local)` keeps
// the instant whatever zone name `tz.local` resolves to), with inexact
// Android alarms (no SCHEDULE_EXACT_ALARM). Nothing here decides content.

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/contracts/notification_gateway.dart';
import '../../core/logging/app_logger.dart';
import '../../core/strings/settings_strings.dart';

class LocalNotificationGateway implements NotificationGateway {
  LocalNotificationGateway({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String channelId = 'soongong_reminders';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;
  }

  @override
  Future<NotificationPermission> permissionStatus() async {
    try {
      return _map(await ph.Permission.notification.status);
    } on Object catch (e) {
      appLog.w('notification permission status failed', error: e);
      return NotificationPermission.unknown;
    }
  }

  @override
  Future<NotificationPermission> requestPermission() async {
    try {
      return _map(await ph.Permission.notification.request());
    } on Object catch (e) {
      appLog.w('notification permission request failed', error: e);
      return NotificationPermission.unknown;
    }
  }

  @override
  Future<void> replaceAll(List<PlannedNotification> plan) async {
    await _init();
    await _plugin.cancelAll();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        SettingsStrings.channelName,
        channelDescription: SettingsStrings.channelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );
    for (final n in plan) {
      await _plugin.zonedSchedule(
        id: n.id,
        title: n.title,
        body: n.body,
        scheduledDate: tz.TZDateTime.from(n.at, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  @override
  Future<void> cancelAll() async {
    await _init();
    await _plugin.cancelAll();
  }

  @override
  Future<void> openSystemSettings() async {
    await ph.openAppSettings();
  }

  static NotificationPermission _map(ph.PermissionStatus s) => switch (s) {
        ph.PermissionStatus.granted || ph.PermissionStatus.limited || ph.PermissionStatus.provisional =>
          NotificationPermission.granted,
        ph.PermissionStatus.denied || ph.PermissionStatus.permanentlyDenied || ph.PermissionStatus.restricted =>
          NotificationPermission.denied,
      };
}
