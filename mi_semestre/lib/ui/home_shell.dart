import 'package:material_ui/material_ui.dart';

import '../app.dart';
import 'assessment_form_screen.dart';
import 'assessments_screen.dart';
import 'block_form_sheet.dart';
import 'schedule_screen.dart';
import 'settings_screen.dart';
import 'subject_form_screen.dart';
import 'subjects_screen.dart';
import 'today_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const List<String> _titles = <String>[
    'Hoy',
    'Horario',
    'Tareas',
    'Materias',
    'Ajustes',
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (state.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_index],
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: IndexedStack(
        index: _index,
        children: const <Widget>[
          TodayScreen(),
          ScheduleScreen(),
          AssessmentsScreen(),
          SubjectsScreen(),
          SettingsScreen(),
        ],
      ),
      floatingActionButton: _buildFab(context),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Hoy',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Horario',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Tareas',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Materias',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }

  Widget? _buildFab(BuildContext context) {
    if (_index == 4) return null;
    if (_index == 3) {
      return FloatingActionButton.extended(
        onPressed: () => showSubjectForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Materia'),
      );
    }
    if (_index == 1) {
      final hasSubjects = AppScope.read(context).subjects.isNotEmpty;
      return FloatingActionButton.extended(
        onPressed: () {
          if (hasSubjects) {
            showBlockForm(context);
          } else {
            showSubjectForm(context);
          }
        },
        icon: Icon(hasSubjects ? Icons.add : Icons.school_outlined),
        label: Text(hasSubjects ? 'Bloque' : 'Materia'),
      );
    }
    if (_index == 2 || _index == 0) {
      final hasSubjects = AppScope.read(context).subjects.isNotEmpty;
      return FloatingActionButton.extended(
        onPressed: () {
          if (hasSubjects) {
            showAssessmentForm(context);
          } else {
            showSubjectForm(context);
          }
        },
        icon: Icon(hasSubjects ? Icons.add : Icons.school_outlined),
        label: Text(hasSubjects ? 'Tarea' : 'Materia'),
      );
    }
    return null;
  }
}
