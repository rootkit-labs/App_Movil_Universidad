import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

abstract class NotificationPort {
  Future<void> init();

  Future<bool> requestPermission();

  Future<void> scheduleAssessmentReminder({
    required int id,
    required String title,
    required String subject,
    required DateTime when,
  });

  Future<void> schedulePendingSummary({
    required int count,
    required DateTime when,
    required String detail,
  });

  Future<void> cancel(int id);

  Future<void> cancelAll();

  Future<void> showTestNotification();
}

class NotificationService implements NotificationPort {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const String _channelId = 'mi_semestre_recordatorios';
  static const String _channelName = 'Recordatorios académicos';
  static const String _channelDescription =
      'Avisos de entregas, exámenes, proyectos y tareas pendientes';

  static const int testNotificationId = 999999;
  static const int pendingSummaryNotificationId = 900001;

  @override
  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    tz.setLocalLocation(_resolveLocalLocation());
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(settings: settings);
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );
    } catch (_) {}
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    try {
      await init();
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android == null) return true;
      final granted = await android.requestNotificationsPermission();
      return granted ?? true;
    } catch (_) {
      return true;
    }
  }

  NotificationDetails get _details => const NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
    ),
  );

  String _formatWhen(DateTime when) {
    final day = when.day.toString().padLeft(2, '0');
    final month = when.month.toString().padLeft(2, '0');
    final hour = when.hour.toString().padLeft(2, '0');
    final minute = when.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }

  @override
  Future<void> scheduleAssessmentReminder({
    required int id,
    required String title,
    required String subject,
    required DateTime when,
  }) async {
    await init();
    if (!when.isAfter(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id: id,
      title: 'Recordatorio: $title',
      body: '$subject · ${_formatWhen(when)}',
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> schedulePendingSummary({
    required int count,
    required DateTime when,
    required String detail,
  }) async {
    await init();
    if (!when.isAfter(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id: pendingSummaryNotificationId,
      title: count == 1
          ? 'Tienes 1 tarea pendiente'
          : 'Tienes $count tareas pendientes',
      body: detail,
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancel(int id) async {
    await init();
    await _plugin.cancel(id: id);
  }

  @override
  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  @override
  Future<void> showTestNotification() async {
    await init();
    await _plugin.show(
      id: testNotificationId,
      title: 'OrganiU',
      body: 'Las notificaciones funcionan correctamente en tu teléfono.',
      notificationDetails: _details,
    );
  }

  tz.Location _resolveLocalLocation() {
    final offset = DateTime.now().timeZoneOffset;
    final name = DateTime.now().timeZoneName;
    try {
      for (final location in tz.timeZoneDatabase.locations.values) {
        final now = tz.TZDateTime.now(location);
        if (now.timeZoneOffset == offset && now.timeZoneName == name) {
          return location;
        }
      }
    } catch (_) {}
    try {
      for (final location in tz.timeZoneDatabase.locations.values) {
        if (tz.TZDateTime.now(location).timeZoneOffset == offset) {
          return location;
        }
      }
    } catch (_) {}
    return tz.UTC;
  }
}
