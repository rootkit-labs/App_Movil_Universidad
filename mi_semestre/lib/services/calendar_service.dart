import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/models.dart';

String buildAssessmentsIcs({
  required List<Assessment> assessments,
  required List<Subject> subjects,
  DateTime? now,
}) {
  final subjectsById = <int, Subject>{
    for (final subject in subjects)
      if (subject.id != null) subject.id!: subject,
  };
  final stamp = _formatStamp(now ?? DateTime.now());
  final lines = <String>[
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//OrganiU//Recordatorios academicos//ES',
    'CALSCALE:GREGORIAN',
    'METHOD:PUBLISH',
  ];
  for (final assessment in assessments) {
    final subject = subjectsById[assessment.subjectId];
    final summary = <String>[
      assessment.title,
      if (subject != null) subject.name,
    ].join(' - ');
    lines
      ..add('BEGIN:VEVENT')
      ..add(
        'UID:mi-semestre-${assessment.id ?? assessment.due.microsecondsSinceEpoch}@mi_semestre',
      )
      ..add('DTSTAMP:$stamp')
      ..add('DTSTART:${_formatLocal(assessment.due)}')
      ..add(
        'DTEND:${_formatLocal(assessment.due.add(const Duration(hours: 1)))}',
      )
      ..add('SUMMARY:${_escape(summary)}')
      ..add('DESCRIPTION:${_escape(assessment.type)}')
      ..add('END:VEVENT');
  }
  lines.add('END:VCALENDAR');
  return lines.join('\r\n');
}

Future<void> shareAssessmentsIcs(String content) async {
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/organiu_entregas.ics');
  await file.writeAsString(content);
  await SharePlus.instance.share(
    ShareParams(
      files: <XFile>[XFile(file.path, mimeType: 'text/calendar')],
      subject: 'Entregas de OrganiU',
      text: 'Mis entregas y exámenes pendientes',
    ),
  );
}

String _pad(int value) => value.toString().padLeft(2, '0');

String _formatLocal(DateTime value) {
  return '${value.year}${_pad(value.month)}${_pad(value.day)}'
      'T${_pad(value.hour)}${_pad(value.minute)}${_pad(value.second)}';
}

String _formatStamp(DateTime value) {
  final utc = value.toUtc();
  return '${utc.year}${_pad(utc.month)}${_pad(utc.day)}'
      'T${_pad(utc.hour)}${_pad(utc.minute)}${_pad(utc.second)}Z';
}

String _escape(String value) {
  return value
      .replaceAll('\\', '\\\\')
      .replaceAll('\n', '\\n')
      .replaceAll(',', '\\,')
      .replaceAll(';', '\\;');
}
