import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../domain/models.dart';
import 'format.dart';
import 'subject_form_screen.dart';
import 'widgets/common.dart';

Future<void> showAssessmentForm(
  BuildContext context, {
  Assessment? assessment,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => AssessmentFormScreen(assessment: assessment),
    ),
  );
}

class AssessmentFormScreen extends StatefulWidget {
  const AssessmentFormScreen({super.key, this.assessment});

  final Assessment? assessment;

  @override
  State<AssessmentFormScreen> createState() => _AssessmentFormScreenState();
}

class _AssessmentFormScreenState extends State<AssessmentFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _weight;
  late final TextEditingController _grade;
  int? _subjectId;
  late String _type;
  late DateTime _due;
  late bool _done;
  bool _saving = false;
  bool _initializedDefaults = false;

  bool get _isEditing => widget.assessment != null;

  @override
  void initState() {
    super.initState();
    final assessment = widget.assessment;
    _title = TextEditingController(text: assessment?.title ?? '');
    _weight = TextEditingController(
      text: assessment == null || assessment.weight == 0
          ? ''
          : formatGrade(assessment.weight),
    );
    _grade = TextEditingController(text: formatGrade(assessment?.grade));
    _subjectId = assessment?.subjectId;
    _type = assessment?.type ?? kAssessmentTypes.first;
    _done = assessment?.done ?? false;
    final now = DateTime.now();
    _due = assessment?.due ??
        DateTime(now.year, now.month, now.day, 8).add(const Duration(days: 1));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initializedDefaults) return;
    _initializedDefaults = true;
    final subjects = AppScope.read(context).subjects;
    if (_subjectId == null && subjects.isNotEmpty) {
      _subjectId = subjects.first.id;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _weight.dispose();
    _grade.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('es'),
    );
    if (picked == null) return;
    setState(() {
      _due = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _due.hour,
        _due.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_due),
    );
    if (picked == null) return;
    setState(() {
      _due = DateTime(
        _due.year,
        _due.month,
        _due.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_subjectId == null) return;
    final state = AppScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    final assessment = Assessment(
      id: widget.assessment?.id,
      subjectId: _subjectId!,
      title: _title.text.trim(),
      type: _type,
      due: _due,
      done: _done,
      grade: double.tryParse(_grade.text.trim().replaceAll(',', '.')),
      weight: double.tryParse(_weight.text.trim().replaceAll(',', '.')) ?? 0,
    );
    await state.saveAssessment(assessment);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(_isEditing ? 'Tarea actualizada' : 'Tarea agregada'),
      ),
    );
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final state = AppScope.read(context);
    final assessment = widget.assessment;
    if (assessment?.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: const Text('¿Seguro que deseas eliminar esta tarea?'),
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
    await state.deleteAssessment(assessment!.id!);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);
    if (state.subjects.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nueva tarea')),
        body: EmptyState(
          icon: Icons.school_outlined,
          title: 'Primero crea una materia',
          message:
              'Las tareas y exámenes pertenecen a una materia. Crea una para continuar.',
          actionLabel: 'Crear materia',
          onAction: () {
            Navigator.of(context).pop();
            showSubjectForm(context);
          },
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar tarea' : 'Nueva tarea'),
        actions: <Widget>[
          if (_isEditing)
            IconButton(
              tooltip: 'Eliminar',
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: <Widget>[
            TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Título',
                hintText: 'Ej. Examen parcial 1',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Escribe un título';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _subjectId,
              decoration: const InputDecoration(labelText: 'Materia'),
              items: state.subjects
                  .map(
                    (subject) => DropdownMenuItem<int>(
                      value: subject.id,
                      child: Text(subject.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _subjectId = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: kAssessmentTypes
                  .map(
                    (type) => DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _type = value);
              },
            ),
            const SizedBox(height: 16),
            Text('Fecha y hora de entrega', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text(formatShortDate(_due)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule_outlined, size: 18),
                    label: Text(formatClock(_due)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    controller: _grade,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Nota (opcional)',
                    ),
                    validator: _validateOptionalNumber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _weight,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: '% ponderación',
                    ),
                    validator: _validateOptionalNumber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Completada'),
              subtitle: const Text('Marca la tarea como terminada'),
              value: _done,
              onChanged: (value) => setState(() => _done = value),
            ),
            const SizedBox(height: 8),
            Text(
              'Recibirás un recordatorio ${state.reminderMinutes} minutos antes si las notificaciones están activas.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar tarea'),
          ),
        ),
      ),
    );
  }

  String? _validateOptionalNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    if (parsed == null) return 'Número inválido';
    if (parsed < 0) return 'No puede ser negativo';
    return null;
  }
}
