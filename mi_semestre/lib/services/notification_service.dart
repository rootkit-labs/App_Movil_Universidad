import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const String _channelId = 'mi_semestre_recordatorios';
  static const String _channelName = 'Recordatorios académicos';
  static const String _channelDescription =
      'Avisos de entregas, exámenes y proyectos';

  static const int testNotificationId = 999999;

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    tz.setLocalLocation(_resolveLocalLocation());
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return false;
    try {
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

  Future<void> cancel(int id) async {
    await init();
    await _plugin.cancel(id: id);
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  Future<void> showTestNotification() async {
    await init();
    await _plugin.show(
      id: testNotificationId,
      title: 'MiSemestre',
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
    } catch (_) {
      // Ignorar y continuar con la siguiente estrategia.
    }
    try {
      for (final location in tz.timeZoneDatabase.locations.values) {
        if (tz.TZDateTime.now(location).timeZoneOffset == offset) {
          return location;
        }
      }
    } catch (_) {
      // Ignorar y usar UTC como último recurso.
    }
    return tz.UTC;
  }
}
