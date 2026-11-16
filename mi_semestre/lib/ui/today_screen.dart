import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../domain/academic_logic.dart';
import 'assessment_form_screen.dart';
import 'format.dart';
import 'subject_form_screen.dart';
import 'widgets/common.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (state.subjects.isEmpty) {
      return EmptyState(
        icon: Icons.waving_hand_outlined,
        title: 'Bienvenido a MiSemestre',
        message:
            'Agrega tu primera materia para ver tu horario, tus tareas y recibir recordatorios.',
        actionLabel: 'Agregar materia',
        onAction: () => showSubjectForm(context),
      );
    }
    final now = DateTime.now();
    final theme = Theme.of(context);
    final todayClasses = classesForDay(
      blocks: state.blocks,
      subjects: state.subjects,
      day: now,
    );
    final nextClass = currentOrNextClass(
      blocks: state.blocks,
      subjects: state.subjects,
      now: now,
    );
    final upcoming = upcomingAssessments(
      assessments: state.assessments,
      now: now,
      days: 7,
    );
    final overdue = overdueAssessments(
      assessments: state.assessments,
      now: now,
    );

    final children = <Widget>[
      Text(
        formatFullDate(now),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 12),
      if (nextClass != null) _NextClassCard(nextClass: nextClass, now: now),
      const SizedBox(height: 8),
      const SectionTitle('Clases de hoy'),
      if (todayClasses.isEmpty)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.free_breakfast_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                const Expanded(child: Text('Hoy no tienes clases registradas.')),
              ],
            ),
          ),
        )
      else
        ...todayClasses.map(
          (scheduled) => _TodayClassTile(scheduled: scheduled, now: now),
        ),
      const SizedBox(height: 16),
      SectionTitle(
        'Próximas entregas',
        trailing: Text(
          '7 días',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      if (upcoming.isEmpty)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.check_circle_outline,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('No hay entregas en los próximos 7 días.'),
                ),
              ],
            ),
          ),
        )
      else
        ...upcoming.map(
          (assessment) => AssessmentTile(
            assessment: assessment,
            subject: state.subjectById(assessment.subjectId),
            onToggle: () => state.toggleAssessment(assessment),
            onTap: () => showAssessmentForm(context, assessment: assessment),
          ),
        ),
      if (overdue.isNotEmpty) ...<Widget>[
        const SizedBox(height: 16),
        const SectionTitle('Vencidas'),
        ...overdue.map(
          (assessment) => AssessmentTile(
            assessment: assessment,
            subject: state.subjectById(assessment.subjectId),
            onToggle: () => state.toggleAssessment(assessment),
            onTap: () => showAssessmentForm(context, assessment: assessment),
          ),
        ),
      ],
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      children: children,
    );
  }
}

class _NextClassCard extends StatelessWidget {
  const _NextClassCard({required this.nextClass, required this.now});

  final ScheduledClass nextClass;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ongoing = nextClass.isOngoingAt(now);
    final subject = nextClass.subject;
    final details = <String>[
      '${formatClock(nextClass.start)} – ${formatClock(nextClass.end)}',
      if (nextClass.block.room.isNotEmpty) nextClass.block.room,
      if (subject.teacher.isNotEmpty) subject.teacher,
    ].join(' · ');
    return Card(
      color: theme.colorScheme.primaryContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  ongoing ? Icons.play_circle_outline : Icons.upcoming_outlined,
                  size: 18,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 6),
                Text(
                  ongoing ? 'EN CURSO' : 'PRÓXIMA CLASE',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                Text(
                  ongoing
                      ? 'termina ${formatClock(nextClass.end)}'
                      : countdownLabel(nextClass.timeUntilStart(now)),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              subject.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              details,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayClassTile extends StatelessWidget {
  const _TodayClassTile({required this.scheduled, required this.now});

  final ScheduledClass scheduled;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ongoing = scheduled.isOngoingAt(now);
    final finished = scheduled.isFinishedAt(now);
    final color = Color(scheduled.subject.colorValue);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  formatClock(scheduled.start),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  formatClock(scheduled.end),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Container(
              width: 4,
              height: 38,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    scheduled.subject.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: finished
                          ? theme.colorScheme.onSurfaceVariant
                          : null,
                    ),
                  ),
                  if (scheduled.block.room.isNotEmpty)
                    Text(
                      scheduled.block.room,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (ongoing)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Ahora',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
