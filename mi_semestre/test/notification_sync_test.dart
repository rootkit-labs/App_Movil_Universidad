import 'package:flutter_test/flutter_test.dart';
import 'package:mi_semestre/domain/models.dart';
import 'package:mi_semestre/services/notification_service.dart';
import 'package:mi_semestre/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

class FakeNotifications implements NotificationPort {
  bool granted = true;
  final List<bool> permissionRequests = <bool>[];
  final List<({int id, String title, DateTime when})> reminders =
      <({int id, String title, DateTime when})>[];
  final List<({int count, DateTime when, String detail})> summaries =
      <({int count, DateTime when, String detail})>[];
  int testNotifications = 0;
  int cancelAllCalls = 0;

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async {
    permissionRequests.add(granted);
    return granted;
  }

  @override
  Future<void> scheduleAssessmentReminder({
    required int id,
    required String title,
    required String subject,
    required DateTime when,
  }) async {
    reminders.add((id: id, title: title, when: when));
  }

  @override
  Future<void> schedulePendingSummary({
    required int count,
    required DateTime when,
    required String detail,
  }) async {
    summaries.add((count: count, when: when, detail: detail));
  }

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
  }

  @override
  Future<void> showTestNotification() async {
    testNotifications++;
  }
}

Future<AppState> _boot(
  InMemoryRepository repository,
  FakeNotifications notifications, {
  Map<String, Object> preferences = const <String, Object>{},
}) async {
  SharedPreferences.setMockInitialValues(preferences);
  final state = AppState(repository: repository, notifications: notifications);
  await state.init();
  return state;
}

void main() {
  test('pide permiso de notificaciones al iniciar', () async {
    final notifications = FakeNotifications();

    await _boot(InMemoryRepository(), notifications);

    expect(notifications.permissionRequests, hasLength(1));
    expect(notifications.permissionRequests.single, isTrue);
  });

  test('programa el recordatorio a la hora de entrega si ya pasó la anticipación',
      () async {
    final repository = InMemoryRepository();
    final notifications = FakeNotifications();
    final due = DateTime.now().add(const Duration(minutes: 10));
    repository.seed(
      subjects: const <Subject>[
        Subject(id: 1, name: 'Álgebra Lineal', colorValue: 0xFF4F46E5),
      ],
      assessments: <Assessment>[
        Assessment(
          id: 7,
          subjectId: 1,
          title: 'Parcial 1',
          type: 'Examen',
          due: due,
        ),
      ],
    );

    await _boot(
      repository,
      notifications,
      preferences: <String, Object>{'reminder_minutes': 30},
    );

    expect(notifications.reminders, hasLength(1));
    expect(notifications.reminders.single.id, 7);
    expect(notifications.reminders.single.when, due);
  });

  test('programa un resumen diario solo con tareas pendientes', () async {
    final repository = InMemoryRepository();
    final notifications = FakeNotifications();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    repository.seed(
      subjects: const <Subject>[
        Subject(id: 1, name: 'Programación Móvil', colorValue: 0xFF4F46E5),
      ],
      assessments: <Assessment>[
        Assessment(
          id: 1,
          subjectId: 1,
          title: 'Examen final',
          type: 'Examen',
          due: tomorrow,
        ),
        Assessment(
          id: 2,
          subjectId: 1,
          title: 'Tarea entregada',
          type: 'Entrega',
          due: tomorrow,
          done: true,
        ),
      ],
    );

    await _boot(repository, notifications);

    expect(notifications.reminders, hasLength(1));
    expect(notifications.summaries, hasLength(1));
    expect(notifications.summaries.single.count, 1);
    expect(notifications.summaries.single.detail, contains('Examen final'));
  });

  test('la notificación de prueba también solicita permiso', () async {
    final notifications = FakeNotifications();
    final state = await _boot(InMemoryRepository(), notifications);
    final requestsBefore = notifications.permissionRequests.length;

    final sent = await state.sendTestNotification();

    expect(sent, isTrue);
    expect(notifications.permissionRequests.length, requestsBefore + 1);
    expect(notifications.testNotifications, 1);
  });

  test('si se deniega el permiso se desactivan los recordatorios', () async {
    final repository = InMemoryRepository();
    final notifications = FakeNotifications()..granted = false;
    repository.seed(
      subjects: const <Subject>[
        Subject(id: 1, name: 'Álgebra Lineal', colorValue: 0xFF4F46E5),
      ],
      assessments: <Assessment>[
        Assessment(
          id: 1,
          subjectId: 1,
          title: 'Parcial 1',
          type: 'Examen',
          due: DateTime.now().add(const Duration(days: 1)),
        ),
      ],
    );

    final state = await _boot(repository, notifications);

    expect(state.notificationsEnabled, isFalse);
    expect(notifications.reminders, isEmpty);
    expect(notifications.summaries, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('notifications_enabled'), isFalse);
  });
}
