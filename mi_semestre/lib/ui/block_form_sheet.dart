import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../domain/academic_logic.dart';
import '../domain/models.dart';
import '../state/app_state.dart';
import 'format.dart';
import 'subject_form_screen.dart';

Future<void> showBlockForm(
  BuildContext context, {
  ScheduleBlock? block,
  int? weekday,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => BlockFormSheet(block: block, weekday: weekday),
  );
}

class BlockFormSheet extends StatefulWidget {
  const BlockFormSheet({super.key, this.block, this.weekday});

  final ScheduleBlock? block;
  final int? weekday;

  @override
  State<BlockFormSheet> createState() => _BlockFormSheetState();
}

class _BlockFormSheetState extends State<BlockFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _room;
  int? _subjectId;
  late int _weekday;
  late int _startMinutes;
  late int _endMinutes;
  bool _saving = false;
  bool _initializedDefaults = false;

  bool get _isEditing => widget.block != null;

  @override
  void initState() {
    super.initState();
    final block = widget.block;
    _room = TextEditingController(text: block?.room ?? '');
    _subjectId = block?.subjectId;
    _weekday = block?.weekday ?? widget.weekday ?? DateTime.now().weekday;
    _startMinutes = block?.startMinutes ?? 7 * 60;
    _endMinutes = block?.endMinutes ?? 9 * 60;
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
    _room.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final current = isStart ? _startMinutes : _endMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked == null) return;
    setState(() {
      final minutes = minutesFromTimeOfDay(picked.hour, picked.minute);
      if (isStart) {
        _startMinutes = minutes;
        if (_endMinutes <= minutes) _endMinutes = minutes + 60;
      } else {
        _endMinutes = minutes;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_subjectId == null) return;
    if (_endMinutes <= _startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La hora de fin debe ser mayor al inicio'),
        ),
      );
      return;
    }
    final state = AppScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final candidate = ScheduleBlock(
      id: widget.block?.id,
      subjectId: _subjectId!,
      weekday: _weekday,
      startMinutes: _startMinutes,
      endMinutes: _endMinutes,
      room: _room.text.trim(),
    );
    final conflicts = conflictingBlocks(
      blocks: state.blocks,
      candidate: candidate,
    );
    if (conflicts.isNotEmpty) {
      final accepted = await _confirmConflicts(context, state, conflicts);
      if (!accepted) return;
    }
    setState(() => _saving = true);
    await state.saveBlock(candidate);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(_isEditing ? 'Bloque actualizado' : 'Bloque agregado'),
      ),
    );
    navigator.pop();
  }

  Future<bool> _confirmConflicts(
    BuildContext context,
    AppState state,
    List<ScheduleBlock> conflicts,
  ) async {
    final descriptions = conflicts
        .map(
          (block) =>
              '${state.subjectById(block.subjectId)?.name ?? 'Materia'} · '
              '${formatMinutesOfDay(block.startMinutes)}–${formatMinutesOfDay(block.endMinutes)}',
        )
        .join('\n');
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Horario solapado'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Este bloque se cruza con:'),
              const SizedBox(height: 8),
              Text(descriptions),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Guardar de todos modos'),
          ),
        ],
      ),
    );
    return accepted == true;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    if (state.subjects.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('Primero crea una materia para asignarle un horario.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                showSubjectForm(context);
              },
              child: const Text('Crear materia'),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                _isEditing ? 'Editar bloque' : 'Nuevo bloque de horario',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
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
              DropdownButtonFormField<int>(
                initialValue: _weekday,
                decoration: const InputDecoration(labelText: 'Día'),
                items: List<DropdownMenuItem<int>>.generate(
                  7,
                  (index) => DropdownMenuItem<int>(
                    value: index + 1,
                    child: Text(weekdayName(index + 1)),
                  ),
                ),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _weekday = value);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickTime(isStart: true),
                      icon: const Icon(Icons.login_outlined, size: 18),
                      label: Text(
                        'Inicio ${formatMinutesOfDay(_startMinutes)}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickTime(isStart: false),
                      icon: const Icon(Icons.logout_outlined, size: 18),
                      label: Text('Fin ${formatMinutesOfDay(_endMinutes)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _room,
                decoration: const InputDecoration(labelText: 'Aula (opcional)'),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? 'Guardar cambios' : 'Agregar bloque'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
