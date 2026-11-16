import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../app.dart';
import 'widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const List<int> _reminderOptions = <int>[
    5,
    10,
    15,
    30,
    60,
    120,
    1440,
  ];

  String _reminderLabel(int minutes) {
    if (minutes >= 1440) {
      final days = minutes ~/ 1440;
      return days == 1 ? '1 día antes' : '$days días antes';
    }
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      return hours == 1 ? '1 hora antes' : '$hours horas antes';
    }
    return '$minutes minutos antes';
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      children: <Widget>[
        const SectionTitle('Apariencia'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: const <ButtonSegment<ThemeMode>>[
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.light,
                      label: Text('Claro'),
                      icon: Icon(Icons.light_mode_outlined, size: 16),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.dark,
                      label: Text('Oscuro'),
                      icon: Icon(Icons.dark_mode_outlined, size: 16),
                    ),
                    ButtonSegment<ThemeMode>(
                      value: ThemeMode.system,
                      label: Text('Sistema'),
                      icon: Icon(Icons.phone_android_outlined, size: 16),
                    ),
                  ],
                  selected: <ThemeMode>{state.themeMode},
                  onSelectionChanged: (selection) =>
                      state.setThemeMode(selection.first),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const SectionTitle('Recordatorios'),
        Card(
          child: Column(
            children: <Widget>[
              SwitchListTile(
                value: state.notificationsEnabled,
                title: const Text('Notificaciones'),
                subtitle: const Text('Avisarte antes de cada entrega o examen'),
                onChanged: (value) async {
                  final enabled = await state.setNotificationsEnabled(value);
                  if (!context.mounted) return;
                  if (value && !enabled) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Permiso denegado. Actívalo desde Ajustes de Android > MiSemestre > Notificaciones.',
                        ),
                      ),
                    );
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Avisar con anticipación'),
                subtitle: Text(_reminderLabel(state.reminderMinutes)),
                trailing: DropdownButton<int>(
                  value: state.reminderMinutes,
                  underline: const SizedBox.shrink(),
                  items: _reminderOptions
                      .map(
                        (minutes) => DropdownMenuItem<int>(
                          value: minutes,
                          child: Text(_reminderLabel(minutes)),
                        ),
                      )
                      .toList(),
                  onChanged: state.notificationsEnabled
                      ? (value) {
                          if (value == null) return;
                          state.setReminderMinutes(value);
                        }
                      : null,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.notification_add_outlined),
                title: const Text('Probar notificación'),
                subtitle: const Text(
                  'Envía una notificación de ejemplo ahora mismo',
                ),
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await state.sendTestNotification();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Notificación enviada. Si no la ves, revisa los permisos.',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const SectionTitle('Respaldo de datos'),
        Card(
          child: Column(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.copy_all_outlined),
                title: const Text('Copiar respaldo'),
                subtitle: const Text(
                  'Copia tus materias y tareas como texto JSON',
                ),
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final data = await state.exportBackup();
                  await Clipboard.setData(ClipboardData(text: data));
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Respaldo copiado al portapapeles'),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.restore_outlined),
                title: const Text('Restaurar respaldo'),
                subtitle: const Text('Pega un respaldo copiado previamente'),
                onTap: () => _restore(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const SectionTitle('Acerca de'),
        Card(
          child: Column(
            children: <Widget>[
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('MiSemestre'),
                subtitle: Text('Versión 1.0.0 · Proyecto de Programación Móvil'),
              ),
              Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'Tus datos se guardan únicamente en este teléfono. La aplicación '
                  'funciona sin internet y no solicita ubicación, cámara ni contactos.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _restore(BuildContext context) async {
    final state = AppScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clipboard?.text?.trim();
    if (text == null || text.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('El portapapeles está vacío')),
      );
      return;
    }
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restaurar respaldo'),
        content: const Text(
          'Se reemplazarán las materias y tareas actuales por las del respaldo. ¿Continuar?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await state.importBackup(text);
      messenger.showSnackBar(
        const SnackBar(content: Text('Respaldo restaurado')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('El texto del portapapeles no es un respaldo válido'),
        ),
      );
    }
  }
}
