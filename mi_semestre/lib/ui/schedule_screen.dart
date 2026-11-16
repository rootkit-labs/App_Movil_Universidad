import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../domain/academic_logic.dart';
import '../domain/models.dart';
import 'block_form_sheet.dart';
import 'format.dart';
import 'subject_form_screen.dart';
import 'widgets/common.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _weekday = DateTime.now().weekday;

  DateTime get _selectedDate {
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day);
    return base.subtract(Duration(days: now.weekday - _weekday));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);
    if (state.subjects.isEmpty) {
      return EmptyState(
        icon: Icons.calendar_month_outlined,
        title: 'Tu horario, siempre a mano',
        message:
            'Crea una materia y luego agrega sus bloques de horario. Verás tu semana completa aquí.',
        actionLabel: 'Agregar materia',
        onAction: () => showSubjectForm(context),
      );
    }
    final classes = classesForDay(
      blocks: state.blocks,
      subjects: state.subjects,
      day: _selectedDate,
    );
    var totalMinutes = 0;
    for (final item in classes) {
      totalMinutes += item.block.durationMinutes;
    }

    return Column(
      children: <Widget>[
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: 7,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final weekday = index + 1;
              final selected = weekday == _weekday;
              return ChoiceChip(
                label: Text(weekdayShort(weekday)),
                selected: selected,
                onSelected: (_) => setState(() => _weekday = weekday),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: <Widget>[
              Text(
                weekdayName(_weekday),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${classes.length} ${classes.length == 1 ? 'clase' : 'clases'}'
                ' · ${(totalMinutes / 60).toStringAsFixed(totalMinutes % 60 == 0 ? 0 : 1)} h',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: classes.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No tienes clases el ${weekdayName(_weekday).toLowerCase()}.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemCount: classes.length,
                  itemBuilder: (context, index) {
                    final scheduled = classes[index];
                    return _ScheduleCard(
                      scheduled: scheduled,
                      onTap: () => _showActions(context, scheduled.block),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _showActions(
    BuildContext context,
    ScheduleBlock block,
  ) async {
    final state = AppScope.read(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Editar bloque'),
              onTap: () => Navigator.of(sheetContext).pop('edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Eliminar bloque'),
              onTap: () => Navigator.of(sheetContext).pop('delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (action == 'edit') {
      if (!context.mounted) return;
      await showBlockForm(context, block: block, weekday: _weekday);
    } else if (action == 'delete') {
      if (block.id == null) return;
      await state.deleteBlock(block.id!);
    }
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.scheduled, required this.onTap});

  final ScheduledClass scheduled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subject = scheduled.subject;
    final details = <String>[
      if (scheduled.block.room.isNotEmpty) scheduled.block.room,
      if (subject.teacher.isNotEmpty) subject.teacher,
    ].join(' · ');
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    formatClock(scheduled.start),
                    style: theme.textTheme.titleMedium?.copyWith(
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
              const SizedBox(width: 16),
              Container(
                width: 5,
                height: 42,
                decoration: BoxDecoration(
                  color: Color(subject.colorValue),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 16),
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
                    if (details.isNotEmpty)
                      Text(
                        details,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.more_horiz,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
