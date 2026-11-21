import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../domain/academic_logic.dart';
import '../domain/models.dart';
import '../services/calendar_service.dart';
import 'assessment_form_screen.dart';
import 'format.dart';
import 'subject_form_screen.dart';
import 'widgets/common.dart';

class AssessmentsScreen extends StatefulWidget {
  const AssessmentsScreen({super.key});

  @override
  State<AssessmentsScreen> createState() => _AssessmentsScreenState();
}

class _AssessmentsScreenState extends State<AssessmentsScreen> {
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);
    if (state.subjects.isEmpty) {
      return EmptyState(
        icon: Icons.checklist_outlined,
        title: 'Organiza tus entregas',
        message: 'Registra exámenes, tareas y proyectos con su fecha para no olvidar nada.',
        actionLabel: 'Agregar materia',
        onAction: () => showSubjectForm(context),
      );
    }
    final now = DateTime.now();
    final pending = pendingAssessments(
      assessments: state.assessments,
      now: now,
    );
    final completed = completedAssessments(assessments: state.assessments);
    final all = <Assessment>[...state.assessments]
      ..sort((a, b) => a.due.compareTo(b.due));
    final items = _filter == 0
        ? pending
        : _filter == 1
        ? completed
        : all;

    final tiles = <Widget>[];
    String? lastLabel;
    for (final assessment in items) {
      final label = assessment.done
          ? 'Completadas'
          : dayLabel(assessment.due, now);
      if (label != lastLabel) {
        tiles.add(SectionTitle(label));
        lastLabel = label;
      }
      tiles.add(
        AssessmentTile(
          assessment: assessment,
          subject: state.subjectById(assessment.subjectId),
          onToggle: () => state.toggleAssessment(assessment),
          onTap: () => showAssessmentForm(context, assessment: assessment),
        ),
      );
    }

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 12, 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: <Widget>[
                      ChoiceChip(
                        label: Text('Pendientes (${pending.length})'),
                        selected: _filter == 0,
                        onSelected: (_) => setState(() => _filter = 0),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text('Hechas (${completed.length})'),
                        selected: _filter == 1,
                        onSelected: (_) => setState(() => _filter = 1),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Todas'),
                        selected: _filter == 2,
                        onSelected: (_) => setState(() => _filter = 2),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Exportar pendientes a calendario',
                icon: const Icon(Icons.ios_share_outlined),
                onPressed: pending.isEmpty
                    ? null
                    : () => _exportCalendar(pending, state.subjects),
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      _filter == 0
                          ? 'No tienes tareas pendientes. ¡Buen trabajo!'
                          : 'No hay tareas en esta lista.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  children: tiles,
                ),
        ),
      ],
    );
  }

  Future<void> _exportCalendar(
    List<Assessment> assessments,
    List<Subject> subjects,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final content = buildAssessmentsIcs(
        assessments: assessments,
        subjects: subjects,
      );
      await shareAssessmentsIcs(content);
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo compartir el calendario')),
      );
    }
  }
}
