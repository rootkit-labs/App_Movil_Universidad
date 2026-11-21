class Subject {
  const Subject({
    this.id,
    required this.name,
    this.teacher = '',
    this.room = '',
    required this.colorValue,
  });

  final int? id;
  final String name;
  final String teacher;
  final String room;
  final int colorValue;

  Subject copyWith({
    int? id,
    String? name,
    String? teacher,
    String? room,
    int? colorValue,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      teacher: teacher ?? this.teacher,
      room: room ?? this.room,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'teacher': teacher,
      'room': room,
      'color': colorValue,
    };
  }

  factory Subject.fromMap(Map<String, Object?> map) {
    return Subject(
      id: map['id'] as int?,
      name: (map['name'] as String?) ?? 'Materia',
      teacher: (map['teacher'] as String?) ?? '',
      room: (map['room'] as String?) ?? '',
      colorValue: (map['color'] as int?) ?? 0xFF4F46E5,
    );
  }
}

class ScheduleBlock {
  const ScheduleBlock({
    this.id,
    required this.subjectId,
    required this.weekday,
    required this.startMinutes,
    required this.endMinutes,
    this.room = '',
  });

  final int? id;
  final int subjectId;
  final int weekday;
  final int startMinutes;
  final int endMinutes;
  final String room;

  int get durationMinutes => endMinutes - startMinutes;

  ScheduleBlock copyWith({
    int? id,
    int? subjectId,
    int? weekday,
    int? startMinutes,
    int? endMinutes,
    String? room,
  }) {
    return ScheduleBlock(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      weekday: weekday ?? this.weekday,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
      room: room ?? this.room,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'subject_id': subjectId,
      'weekday': weekday,
      'start_minutes': startMinutes,
      'end_minutes': endMinutes,
      'room': room,
    };
  }

  factory ScheduleBlock.fromMap(Map<String, Object?> map) {
    return ScheduleBlock(
      id: map['id'] as int?,
      subjectId: (map['subject_id'] as int?) ?? 0,
      weekday: (map['weekday'] as int?) ?? 1,
      startMinutes: (map['start_minutes'] as int?) ?? 0,
      endMinutes: (map['end_minutes'] as int?) ?? 0,
      room: (map['room'] as String?) ?? '',
    );
  }
}

class Assessment {
  const Assessment({
    this.id,
    required this.subjectId,
    required this.title,
    required this.type,
    required this.due,
    this.done = false,
    this.grade,
    this.weight = 0,
  });

  final int? id;
  final int subjectId;
  final String title;
  final String type;
  final DateTime due;
  final bool done;
  final double? grade;
  final double weight;

  bool get isOverdue => !done && due.isBefore(DateTime.now());

  Assessment copyWith({
    int? id,
    int? subjectId,
    String? title,
    String? type,
    DateTime? due,
    bool? done,
    double? grade,
    double? weight,
  }) {
    return Assessment(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      type: type ?? this.type,
      due: due ?? this.due,
      done: done ?? this.done,
      grade: grade ?? this.grade,
      weight: weight ?? this.weight,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'subject_id': subjectId,
      'title': title,
      'type': type,
      'due': due.toIso8601String(),
      'done': done ? 1 : 0,
      'grade': grade,
      'weight': weight,
    };
  }

  factory Assessment.fromMap(Map<String, Object?> map) {
    return Assessment(
      id: map['id'] as int?,
      subjectId: (map['subject_id'] as int?) ?? 0,
      title: (map['title'] as String?) ?? 'Sin título',
      type: (map['type'] as String?) ?? 'Otro',
      due: DateTime.tryParse((map['due'] as String?) ?? '') ?? DateTime.now(),
      done: ((map['done'] as int?) ?? 0) == 1,
      grade: (map['grade'] as num?)?.toDouble(),
      weight: (map['weight'] as num?)?.toDouble() ?? 0,
    );
  }
}

const List<String> kAssessmentTypes = <String>[
  'Examen',
  'Entrega',
  'Proyecto',
  'Exposición',
  'Otro',
];

const List<String> kWeekdayNames = <String>[
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

const List<String> kWeekdayShort = <String>[
  'Lun',
  'Mar',
  'Mié',
  'Jue',
  'Vie',
  'Sáb',
  'Dom',
];

String weekdayName(int weekday) {
  if (weekday < 1 || weekday > 7) return '';
  return kWeekdayNames[weekday - 1];
}

String weekdayShort(int weekday) {
  if (weekday < 1 || weekday > 7) return '';
  return kWeekdayShort[weekday - 1];
}
