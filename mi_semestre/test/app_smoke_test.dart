import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mi_semestre/app.dart';
import 'package:mi_semestre/domain/models.dart';
import 'package:mi_semestre/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

Finder _navIcon(IconData icon) => find.descendant(
  of: find.byType(NavigationBar),
  matching: find.byIcon(icon),
);

Future<AppState> _boot(
  WidgetTester tester,
  InMemoryRepository repository,
) async {
  final state = AppState(repository: repository);
  await state.init();
  await tester.pumpWidget(OrganiUApp(state: state));
  await tester.pumpAndSettle();
  return state;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('arranca en Hoy y navega por las cinco pestañas', (tester) async {
    await _boot(tester, InMemoryRepository());

    expect(find.text('Bienvenido a OrganiU'), findsOneWidget);
    expect(find.text('Hoy'), findsWidgets);
    expect(find.text('Asistencia de Clases'), findsOneWidget);

    await tester.tap(_navIcon(Icons.calendar_month_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Tu horario, siempre a mano'), findsOneWidget);

    await tester.tap(_navIcon(Icons.checklist_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Organiza tus entregas'), findsOneWidget);

    await tester.tap(_navIcon(Icons.school_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Aún no hay materias'), findsOneWidget);

    await tester.tap(_navIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Apariencia'), findsOneWidget);
    expect(find.text('Recordatorios'), findsOneWidget);
    expect(find.text('Respaldo de datos'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Propietario: Rooney M. Mayorga'),
      300,
    );
    expect(find.text('Propietario: Rooney M. Mayorga'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('crea una materia desde el formulario', (tester) async {
    final repository = InMemoryRepository();
    final state = await _boot(tester, repository);

    await tester.tap(_navIcon(Icons.school_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Nueva materia'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Álgebra Lineal');
    await tester.tap(find.text('Guardar materia'));
    await tester.pumpAndSettle();

    expect(state.subjects, hasLength(1));
    expect(state.subjects.single.name, 'Álgebra Lineal');
    expect(find.text('Álgebra Lineal'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('muestra la próxima clase y las entregas pendientes', (
    tester,
  ) async {
    final repository = InMemoryRepository();
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    repository.seed(
      subjects: const <Subject>[
        Subject(id: 1, name: 'Álgebra Lineal', colorValue: 0xFF4F46E5),
      ],
      blocks: <ScheduleBlock>[
        ScheduleBlock(
          id: 1,
          subjectId: 1,
          weekday: tomorrow.weekday,
          startMinutes: 9 * 60,
          endMinutes: 11 * 60,
          room: 'Aula 204',
        ),
      ],
      assessments: <Assessment>[
        Assessment(
          id: 1,
          subjectId: 1,
          title: 'Parcial 1',
          type: 'Examen',
          due: now.add(const Duration(days: 2)),
        ),
      ],
    );

    await _boot(tester, repository);

    expect(find.text('Álgebra Lineal'), findsWidgets);
    expect(find.text('Parcial 1'), findsWidgets);
    expect(find.text('Clases de hoy'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
