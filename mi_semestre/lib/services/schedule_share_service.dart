import 'dart:convert';

import '../domain/models.dart';

const String scheduleQrPrefix = 'MISEMESTRE1:';

class SharedSubject {
  const SharedSubject({
    required this.name,
    required this.teacher,
    required this.room,
    required this.colorValue,
  });

  final String name;
  final String teacher;
  final String room;
  final int colorValue;
}

class SharedBlock {
  const SharedBlock({
    required this.subjectIndex,
    required this.weekday,
    required this.startMinutes,
    required this.endMinutes,
    required this.room,
  });

  final int subjectIndex;
  final int weekday;
  final int startMinutes;
  final int endMinutes;
  final String room;
}

class SharedSchedule {
  const SharedSchedule({required this.subjects, required this.blocks});

  final List<SharedSubject> subjects;
  final List<SharedBlock> blocks;
}

class ScheduleImportResult {
  const ScheduleImportResult({
    required this.subjectsAdded,
    required this.blocksAdded,
  });

  final int subjectsAdded;
  final int blocksAdded;
}

String encodeScheduleQr({
  required List<Subject> subjects,
  required List<ScheduleBlock> blocks,
}) {
  final indexes = <int, int>{};
  final sharedSubjects = <Map<String, Object?>>[];
  for (final subject in subjects) {
    final id = subject.id;
    if (id == null) continue;
    indexes[id] = sharedSubjects.length;
    sharedSubjects.add(<String, Object?>{
      'n': subject.name,
      't': subject.teacher,
      'r': subject.room,
      'c': subject.colorValue,
    });
  }
  final sharedBlocks = <Map<String, Object?>>[];
  for (final block in blocks) {
    final index = indexes[block.subjectId];
    if (index == null) continue;
    sharedBlocks.add(<String, Object?>{
      's': index,
      'w': block.weekday,
      'a': block.startMinutes,
      'b': block.endMinutes,
      'r': block.room,
    });
  }
  return scheduleQrPrefix +
      jsonEncode(<String, Object?>{
        'v': 1,
        's': sharedSubjects,
        'b': sharedBlocks,
      });
}

SharedSchedule parseScheduleQr(String raw) {
  if (!raw.startsWith(scheduleQrPrefix)) {
    throw const FormatException('No es un código QR de OrganiU');
  }
  final Object? decoded;
  try {
    decoded = jsonDecode(raw.substring(scheduleQrPrefix.length));
  } on FormatException {
    throw const FormatException('El código QR está dañado');
  }
  if (decoded is! Map<String, dynamic> || decoded['v'] != 1) {
    throw const FormatException('Formato de horario no compatible');
  }
  final rawSubjects = decoded['s'];
  final rawBlocks = decoded['b'];
  if (rawSubjects is! List || rawBlocks is! List) {
    throw const FormatException('El horario compartido no es válido');
  }
  if (rawSubjects.length > 50 || rawBlocks.length > 200) {
    throw const FormatException('El horario compartido es demasiado grande');
  }

  final subjects = <SharedSubject>[];
  for (final item in rawSubjects) {
    if (item is! Map<String, dynamic>) {
      throw const FormatException('Materia compartida no válida');
    }
    final name = item['n'] as String?;
    if (name == null || name.trim().isEmpty) {
      throw const FormatException('Falta el nombre de una materia');
    }
    subjects.add(
      SharedSubject(
        name: name.trim(),
        teacher: (item['t'] as String?) ?? '',
        room: (item['r'] as String?) ?? '',
        colorValue: _readInt(item['c'], fallback: 0xFF4F46E5),
      ),
    );
  }

  final blocks = <SharedBlock>[];
  for (final item in rawBlocks) {
    if (item is! Map<String, dynamic>) {
      throw const FormatException('Bloque compartido no válido');
    }
    final subjectIndex = _readInt(item['s'], fallback: -1);
    final weekday = _readInt(item['w'], fallback: -1);
    final start = _readInt(item['a'], fallback: -1);
    final end = _readInt(item['b'], fallback: -1);
    if (subjectIndex < 0 ||
        subjectIndex >= subjects.length ||
        weekday < 1 ||
        weekday > 7 ||
        start < 0 ||
        end > 1440 ||
        end <= start) {
      throw const FormatException('Bloque compartido no válido');
    }
    blocks.add(
      SharedBlock(
        subjectIndex: subjectIndex,
        weekday: weekday,
        startMinutes: start,
        endMinutes: end,
        room: (item['r'] as String?) ?? '',
      ),
    );
  }

  return SharedSchedule(subjects: subjects, blocks: blocks);
}

int _readInt(Object? value, {required int fallback}) {
  if (value is int) return value;
  if (value is num) return value.round();
  return fallback;
}
