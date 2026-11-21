import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../domain/academic_logic.dart';
import '../domain/models.dart';
import 'format.dart';
import 'widgets/common.dart';

Future<void> showGradeSimulator(BuildContext context, Subject subject) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => GradeSimulatorSheet(subject: subject),
  );
}

class GradeSimulatorSheet extends StatefulWidget {
  const GradeSimulatorSheet({super.key, required this.subject});

  final Subject subject;

  @override
  State<GradeSimulatorSheet> createState() => _GradeSimulatorSheetState();
}

class _GradeSimulatorSheetState extends State<GradeSimulatorSheet> {
  final TextEditingController _target = TextEditingController(text: '6');
  double _scale = 10;

  @override
  void dispose() {
    _target.dispose();
    super.dispose();
  }

  void _changeScale(double scale) {
    setState(() {
      _scale = scale;
      _target.text = scale == 10 ? '6' : '70';
    });
  }

  String? _validateTarget(String? value) {
    final parsed = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
    if (parsed == null) return 'Escribe una nota válida';
    if (parsed < 0 || parsed > _scale) {
      return 'La meta debe estar entre 0 y ${formatGrade(_scale)}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final id = widget.subject.id;
    final assessments = id == null
        ? <Assessment>[]
        : state.assessmentsForSubject(id);
    final target = double.tryParse(_target.text.trim().replaceAll(',', '.'));
    final simulation = id == null || target == null
        ? null
        : simulateFinalGrade(
            assessments: assessments,
            subjectId: id,
            targetGrade: target,
          );

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Simular nota final',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                SubjectDot(colorValue: widget.subject.colorValue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.subject.name,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text('Escala de calificaciones', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: <Widget>[
                ChoiceChip(
                  label: const Text('0 a 10'),
                  selected: _scale == 10,
                  onSelected: (_) => _changeScale(10),
                ),
                ChoiceChip(
                  label: const Text('0 a 100'),
                  selected: _scale == 100,
                  onSelected: (_) => _changeScale(100),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _target,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Nota que quieres alcanzar',
                helperText: 'Elige la escala en la que registraste tus notas',
                suffixText: '/ ${formatGrade(_scale)}',
              ),
              validator: _validateTarget,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 18),
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Promedio actual',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      simulation == null
                          ? '—'
                          : '${formatGrade(simulation.currentAverage)} / ${formatGrade(_scale)}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _SimulationResult(simulation: simulation, scale: _scale),
            const SizedBox(height: 12),
            Text(
              'El cálculo usa las notas y ponderaciones que registraste en esta materia. '
              'Las evaluaciones sin nota se cuentan como pendientes.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimulationResult extends StatelessWidget {
  const _SimulationResult({required this.simulation, required this.scale});

  final GradeSimulation? simulation;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = simulation;
    if (data == null) {
      return const SizedBox.shrink();
    }
    if (data.pendingCount == 0 || data.neededGrade == null) {
      return _Message(
        icon: Icons.check_circle_outline,
        color: theme.colorScheme.primary,
        title: 'Todo está calculado',
        body: 'Ya no hay evaluaciones pendientes en esta materia.',
      );
    }
    final needed = data.neededGrade!;
    if (needed > scale) {
      return _Message(
        icon: Icons.warning_amber_outlined,
        color: theme.colorScheme.error,
        title: 'Meta difícil',
        body:
            'Necesitas ${formatGrade(needed)} en lo que falta, por encima de la escala.',
      );
    }
    if (needed <= 0) {
      return _Message(
        icon: Icons.emoji_events_outlined,
        color: theme.colorScheme.primary,
        title: 'Meta asegurada',
        body: 'Incluso con 0 en lo que falta, ya alcanzas la nota deseada.',
      );
    }
    return _Message(
      icon: Icons.flag_outlined,
      color: theme.colorScheme.tertiary,
      title: 'Necesitas ${formatGrade(needed)}',
      body:
          'Esa es la nota promedio que requieres en ${data.pendingCount} '
          '${data.pendingCount == 1 ? 'evaluación pendiente' : 'evaluaciones pendientes'}.',
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(body, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
