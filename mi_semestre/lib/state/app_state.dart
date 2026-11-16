import 'dart:convert';

import 'package:material_ui/material_ui.dart';

import '../data/repository.dart';
import '../domain/models.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';

class AppState extends ChangeNotifier {
  AppState({
    Repository? repository,
    SettingsService? settings,
    NotificationService? notifications,
  })  : _repository = repository ?? Repository(),
        _settings = settings ?? SettingsService(),
        _notifications = notifications ?? NotificationService.instance;

  final Repository _repository;
  final SettingsService _settings;
  final NotificationService _notifications;

  bool loading = true;
  List<Subject> subjects = <Subject>[];
  List<ScheduleBlock> blocks = <ScheduleBlock>[];
  List<Assessment> assessments = <Assessment>[];
  ThemeMode themeMode = ThemeMode.system;
  int reminderMinutes = 30;
  bool notificationsEnabled = true;

  bool _disposed = false;

  Future<void> init() async {
    final stored = await _settings.load();
    themeMode = stored.themeMode;
    reminderMinutes = stored.reminderMinutes;
    notificationsEnabled = stored.notificationsEnabled;
    await refresh();
    loading = false;
    _notify();
    await _syncNotifications();
  }

  Future<void> refresh() async {
    subjects = await _repository.subjects();
    blocks = await _repository.blocks();
    assessments = await _repository.assessments();
    _notify();
  }

  Subject? subjectById(int id) {
    for (final subject in subjects) {
      if (subject.id == id) return subject;
    }
    return null;
  }

  List<ScheduleBlock> blocksForSubject(int subjectId) =>
      blocks.where((block) => block.subjectId == subjectId).toList();

  List<Assessment> assessmentsForSubject(int subjectId) => assessments
      .where((assessment) => assessment.subjectId == subjectId)
      .toList();

  Future<void> saveSubject(Subject subject) async {
    await _repository.saveSubject(subject);
    await refresh();
  }

  Future<void> deleteSubject(int id) async {
    await _repository.deleteSubject(id);
    await refresh();
    await _syncNotifications();
  }

  Future<void> saveBlock(ScheduleBlock block) async {
    await _repository.saveBlock(block);
    await refresh();
  }

  Future<void> deleteBlock(int id) async {
    await _repository.deleteBlock(id);
    await refresh();
  }

  Future<void> saveAssessment(Assessment assessment) async {
    await _repository.saveAssessment(assessment);
    await refresh();
    await _syncNotifications();
  }

  Future<void> deleteAssessment(int id) async {
    await _repository.deleteAssessment(id);
    await refresh();
    await _syncNotifications();
  }

  Future<void> toggleAssessment(Assessment assessment) async {
    await saveAssessment(assessment.copyWith(done: !assessment.done));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    _notify();
    await _settings.saveThemeMode(mode);
  }

  Future<void> setReminderMinutes(int minutes) async {
    reminderMinutes = minutes;
    _notify();
    await _settings.saveReminderMinutes(minutes);
    await _syncNotifications();
  }

  Future<bool> setNotificationsEnabled(bool enabled) async {
    if (enabled) {
      final granted = await _notifications.requestPermission();
      notificationsEnabled = granted;
    } else {
      notificationsEnabled = false;
      await _notifications.cancelAll();
    }
    _notify();
    await _settings.saveNotificationsEnabled(notificationsEnabled);
    if (notificationsEnabled) {
      await _syncNotifications();
    }
    return notificationsEnabled;
  }

  Future<void> sendTestNotification() async {
    if (!notificationsEnabled) {
      final granted = await _notifications.requestPermission();
      notificationsEnabled = granted;
      await _settings.saveNotificationsEnabled(granted);
      _notify();
    }
    await _notifications.showTestNotification();
  }

  Future<void> _syncNotifications() async {
    if (!notificationsEnabled) return;
    try {
      await _notifications.cancelAll();
      final now = DateTime.now();
      for (final assessment in assessments) {
        if (assessment.done) continue;
        final when =
            assessment.due.subtract(Duration(minutes: reminderMinutes));
        if (!when.isAfter(now)) continue;
        final id = assessment.id;
        if (id == null) continue;
        final subject = subjectById(assessment.subjectId);
        await _notifications.scheduleAssessmentReminder(
          id: id,
          title: assessment.title,
          subject: subject?.name ?? 'Materia',
          when: when,
        );
      }
    } catch (_) {
      // Un fallo al programar no debe romper la aplicación.
    }
  }

  Future<String> exportBackup() async {
    final data = await _repository.exportAll();
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<void> importBackup(String json) async {
    final decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('El respaldo no tiene un formato válido.');
    }
    await _repository.importAll(decoded);
    await refresh();
    await _syncNotifications();
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
