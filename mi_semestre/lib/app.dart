import 'package:material_ui/material_ui.dart';

import 'services/notification_service.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'ui/home_shell.dart';

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope no encontrado en el árbol de widgets');
    return scope!.notifier!;
  }

  static AppState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope no encontrado en el árbol de widgets');
    return scope!.notifier!;
  }
}

class MiSemestreApp extends StatefulWidget {
  const MiSemestreApp({super.key, this.state});

  final AppState? state;

  @override
  State<MiSemestreApp> createState() => _MiSemestreAppState();
}

class _MiSemestreAppState extends State<MiSemestreApp> {
  late final AppState _state;
  late final bool _ownsState;

  @override
  void initState() {
    super.initState();
    _ownsState = widget.state == null;
    _state = widget.state ?? AppState();
    if (_ownsState) {
      _state.init();
    }
  }

  @override
  void dispose() {
    if (_ownsState) {
      _state.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: AnimatedBuilder(
        animation: _state,
        builder: (context, _) {
          return MaterialApp(
            title: 'MiSemestre',
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(Brightness.light),
            darkTheme: buildAppTheme(Brightness.dark),
            themeMode: _state.themeMode,
            locale: const Locale('es'),
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            supportedLocales: const <Locale>[Locale('es'), Locale('en')],
            home: const HomeShell(),
          );
        },
      ),
    );
  }
}

Future<void> bootstrapNotifications() async {
  try {
    await NotificationService.instance.init();
  } catch (_) {
    // Si el servicio de notificaciones falla, la app debe seguir funcionando.
  }
}
