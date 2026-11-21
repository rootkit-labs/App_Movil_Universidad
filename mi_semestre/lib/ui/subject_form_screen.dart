import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../domain/models.dart';
import '../theme.dart';

Future<void> showSubjectForm(BuildContext context, {Subject? subject}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => SubjectFormScreen(subject: subject),
    ),
  );
}

class SubjectFormScreen extends StatefulWidget {
  const SubjectFormScreen({super.key, this.subject});

  final Subject? subject;

  @override
  State<SubjectFormScreen> createState() => _SubjectFormScreenState();
}

class _SubjectFormScreenState extends State<SubjectFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _teacher;
  late final TextEditingController _room;
  late int _colorValue;
  bool _saving = false;

  bool get _isEditing => widget.subject != null;

  @override
  void initState() {
    super.initState();
    final subject = widget.subject;
    _name = TextEditingController(text: subject?.name ?? '');
    _teacher = TextEditingController(text: subject?.teacher ?? '');
    _room = TextEditingController(text: subject?.room ?? '');
    _colorValue = subject?.colorValue ?? kSubjectPalette.first;
  }

  @override
  void dispose() {
    _name.dispose();
    _teacher.dispose();
    _room.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final state = AppScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    final subject = Subject(
      id: widget.subject?.id,
      name: _name.text.trim(),
      teacher: _teacher.text.trim(),
      room: _room.text.trim(),
      colorValue: _colorValue,
    );
    await state.saveSubject(subject);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(_isEditing ? 'Materia actualizada' : 'Materia agregada'),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar materia' : 'Nueva materia'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: <Widget>[
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nombre de la materia',
                hintText: 'Ej. Programación Móvil',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Escribe el nombre de la materia';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _teacher,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Docente (opcional)',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _room,
              decoration: const InputDecoration(labelText: 'Aula (opcional)'),
            ),
            const SizedBox(height: 24),
            Text('Color', style: theme.textTheme.titleSmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: kSubjectPalette.map((value) {
                final selected = value == _colorValue;
                return InkWell(
                  onTap: () => setState(() => _colorValue = value),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Color(value),
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(
                              color: theme.colorScheme.onSurface,
                              width: 3,
                            )
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              'Después de guardar la materia podrás agregar sus bloques de horario desde la pestaña Horario.',
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
                : const Text('Guardar materia'),
          ),
        ),
      ),
    );
  }
}
