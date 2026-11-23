import 'package:material_ui/material_ui.dart';

import 'services/notification_service.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'ui/home_shell.dart';

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

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

class OrganiUApp extends StatefulWidget {
  const OrganiUApp({super.key, this.state});

  final AppState? state;

  @override
  State<OrganiUApp> createState() => _OrganiUAppState();
}

class _OrganiUAppState extends State<OrganiUApp> with WidgetsBindingObserver {
  late final AppState _state;
  late final bool _ownsState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ownsState = widget.state == null;
    _state = widget.state ?? AppState();
    if (_ownsState) {
      _state.init();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_ownsState) {
      _state.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _ownsState) {
      _state.resyncNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: AnimatedBuilder(
        animation: _state,
        builder: (context, _) {
          return MaterialApp(
            title: 'OrganiU',
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
