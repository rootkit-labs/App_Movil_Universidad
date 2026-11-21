import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../app.dart';
import '../services/schedule_share_service.dart';

Future<void> showScheduleShareMenu(BuildContext context) async {
  final action = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.qr_code),
            title: const Text('Mostrar mi horario'),
            subtitle: const Text('Comparte materias y bloques, sin notas'),
            onTap: () => Navigator.of(sheetContext).pop('show'),
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_scanner_outlined),
            title: const Text('Escanear otro horario'),
            subtitle: const Text('Agrega clases sin borrar tus datos'),
            onTap: () => Navigator.of(sheetContext).pop('scan'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (action == 'show' && context.mounted) {
    showScheduleQrSheet(context);
    return;
  }
  if (action == 'scan' && context.mounted) {
    final raw = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const ScheduleScanScreen()),
    );
    if (raw == null || !context.mounted) return;
    await _confirmAndImport(context, raw);
  }
}

Future<void> showScheduleQrSheet(BuildContext context) {
  final state = AppScope.read(context);
  final raw = encodeScheduleQr(subjects: state.subjects, blocks: state.blocks);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Comparte tu horario',
              style: Theme.of(sheetContext).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              '${state.subjects.length} materias · ${state.blocks.length} bloques. '
              'No incluye tareas, notas ni recordatorios.',
              style: Theme.of(sheetContext).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: QrImageView(
                  data: raw,
                  version: QrVersions.auto,
                  size: 240,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: raw));
                if (!sheetContext.mounted) return;
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  const SnackBar(content: Text('Datos del horario copiados')),
                );
              },
              icon: const Icon(Icons.copy_outlined),
              label: const Text('Copiar datos del horario'),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _confirmAndImport(BuildContext context, String raw) async {
  final state = AppScope.read(context);
  SharedSchedule schedule;
  try {
    schedule = parseScheduleQr(raw);
  } on FormatException {
    _showMessage(context, 'El código QR no es válido');
    return;
  }
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Agregar horario'),
      content: Text(
        'Se agregarán ${schedule.subjects.length} materias y '
        '${schedule.blocks.length} bloques que no tengas ya. '
        'Tus tareas y notas se conservan.',
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Agregar'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  try {
    final result = await state.importScheduleQr(raw);
    if (!context.mounted) return;
    _showMessage(
      context,
      'Agregadas ${result.subjectsAdded} materias y ${result.blocksAdded} bloques',
    );
  } catch (_) {
    if (!context.mounted) return;
    _showMessage(context, 'No se pudo importar el horario');
  }
}

void _showMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

class ScheduleScanScreen extends StatefulWidget {
  const ScheduleScanScreen({super.key});

  @override
  State<ScheduleScanScreen> createState() => _ScheduleScanScreenState();
}

class _ScheduleScanScreenState extends State<ScheduleScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: <BarcodeFormat>[BarcodeFormat.qrCode],
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final value = capture.barcodes.firstOrNull?.rawValue;
    if (value == null) return;
    try {
      parseScheduleQr(value);
    } on FormatException {
      return;
    }
    _handled = true;
    await _controller.stop();
    if (!mounted) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear horario')),
      body: Stack(
        children: <Widget>[
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Apunta la cámara al QR de otro estudiante. Solo se usarán '
                  'materias y bloques de horario.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
