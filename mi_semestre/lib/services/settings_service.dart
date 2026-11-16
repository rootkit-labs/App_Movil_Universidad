import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.reminderMinutes = 30,
    this.notificationsEnabled = true,
  });

  final ThemeMode themeMode;
  final int reminderMinutes;
  final bool notificationsEnabled;
}

class SettingsService {
  static const _themeKey = 'theme_mode';
  static const _reminderKey = 'reminder_minutes';
  static const _notificationsKey = 'notifications_enabled';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.system.index;
    final themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.index == themeIndex,
      orElse: () => ThemeMode.system,
    );
    return AppSettings(
      themeMode: themeMode,
      reminderMinutes: prefs.getInt(_reminderKey) ?? 30,
      notificationsEnabled: prefs.getBool(_notificationsKey) ?? true,
    );
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  Future<void> saveReminderMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reminderKey, minutes);
  }

  Future<void> saveNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);
  }
}
