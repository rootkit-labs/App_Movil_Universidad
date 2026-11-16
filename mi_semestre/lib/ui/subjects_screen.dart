import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../domain/academic_logic.dart';
import '../domain/models.dart';
import 'block_form_sheet.dart';
import 'format.dart';
import 'subject_form_screen.dart';
import 'widgets/common.dart';

class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);
    if (state.subjects.isEmpty) {
      return EmptyState(
        icon: Icons.school_outlined,
        title: 'Aún no hay materias',
        message:
            'Agrega las materias de tu semestre con su docente, aula y color.',
        actionLabel: 'Agregar materia',
        onAction: () => showSubjectForm(context),
      );
    }
    final totalCredits = state.subjects.fold<int>(
      0,
      (sum, subject) => sum + subject.credits,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      children: <Widget>[
        Text(
          '${state.subjects.length} ${state.subjects.length == 1 ? 'materia' : 'materias'}'
          '${totalCredits > 0 ? ' · $totalCredits créditos' : ''}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        ...state.subjects.map((subject) => _SubjectCard(subject: subject)),
      ],
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.subject});

  final Subject subject;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);
    final id = subject.id;
    final blocks = id == null ? 0 : state.blocksForSubject(id).length;
    final assessments =
        id == null ? <Assessment>[] : state.assessmentsForSubject(id);
    final pending = assessments.where((a) => !a.done).length;
    final hasGrades = assessments.any((a) => a.grade != null);
    final average =
        id == null ? 0.0 : averageGrade(assessments: assessments, subjectId: id);

    final details = <String>[
      if (subject.teacher.isNotEmpty) subject.teacher,
      if (subject.credits > 0) '${subject.credits} créditos',
      '$blocks ${blocks == 1 ? 'bloque' : 'bloques'}',
      if (pending > 0) '$pending pendientes',
    ];

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => showSubjectForm(context, subject: subject),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Color(subject.colorValue).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: SubjectDot(colorValue: subject.colorValue, size: 16),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      subject.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      details.join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasGrades)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Column(
                    children: <Widget>[
                      Text(
                        formatGrade(average),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        'prom.',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              PopupMenuButton<String>(
                tooltip: 'Opciones',
                onSelected: (value) async {
                  if (value == 'edit') {
                    await showSubjectForm(context, subject: subject);
                    return;
                  }
                  if (value == 'block') {
                    await showBlockForm(context);
                    return;
                  }
                  if (value == 'delete' && id != null) {
                    await _confirmDelete(context, id);
                  }
                },
                itemBuilder: (_) => const <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('Editar'),
                  ),
                  PopupMenuItem<String>(
                    value: 'block',
                    child: Text('Agregar bloque de horario'),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Eliminar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, int id) async {
    final state = AppScope.read(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar materia'),
        content: Text(
          'Se eliminarán también los bloques de horario y las tareas de "${subject.name}".',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await state.deleteSubject(id);
  }
}
