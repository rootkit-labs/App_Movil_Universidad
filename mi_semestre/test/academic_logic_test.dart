import 'package:flutter_test/flutter_test.dart';
import 'package:mi_semestre/domain/academic_logic.dart';
import 'package:mi_semestre/domain/models.dart';

const Subject programacion = Subject(
  id: 1,
  name: 'Programación Móvil',
  colorValue: 0xFF4F46E5,
);

const Subject calculo = Subject(
  id: 2,
  name: 'Cálculo II',
  colorValue: 0xFF0EA5E9,
);

const List<Subject> subjects = <Subject>[programacion, calculo];

final List<ScheduleBlock> blocks = <ScheduleBlock>[
  const ScheduleBlock(
    id: 1,
    subjectId: 1,
    weekday: 1,
    startMinutes: 7 * 60,
    endMinutes: 9 * 60,
    room: 'Aula 302',
  ),
  const ScheduleBlock(
    id: 2,
    subjectId: 2,
    weekday: 1,
    startMinutes: 9 * 60,
    endMinutes: 11 * 60,
    room: 'Aula 105',
  ),
  const ScheduleBlock(
    id: 3,
    subjectId: 2,
    weekday: 3,
    startMinutes: 14 * 60,
    endMinutes: 16 * 60,
  ),
];

void main() {
  group('classesForDay', () {
    test('devuelve solo las clases del día y las ordena por hora', () {
      final monday = DateTime(2026, 3, 2);
      final result = classesForDay(
        blocks: blocks,
        subjects: subjects,
        day: monday,
      );
      expect(result, hasLength(2));
      expect(result.first.subject.name, 'Programación Móvil');
      expect(result.last.subject.name, 'Cálculo II');
      expect(result.first.start, DateTime(2026, 3, 2, 7));
      expect(result.first.end, DateTime(2026, 3, 2, 9));
    });

    test('ignora bloques de materias que ya no existen', () {
      final monday = DateTime(2026, 3, 2);
      final result = classesForDay(
        blocks: blocks,
        subjects: const <Subject>[programacion],
        day: monday,
      );
      expect(result, hasLength(1));
      expect(result.single.subject.name, 'Programación Móvil');
    });
  });

  group('currentOrNextClass', () {
    test('detecta la clase en curso', () {
      final monday = DateTime(2026, 3, 2);
      final now = DateTime(2026, 3, 2, 7, 30);
      final result = currentOrNextClass(
        blocks: blocks,
        subjects: subjects,
        now: now,
      );
      expect(result, isNotNull);
      expect(result!.subject.name, 'Programación Móvil');
      expect(result.isOngoingAt(now), isTrue);
      expect(result.start.weekday, monday.weekday);
    });

    test('devuelve la siguiente clase del mismo día', () {
      final now = DateTime(2026, 3, 2, 8, 30);
      final gapBlocks = <ScheduleBlock>[
        const ScheduleBlock(
          id: 10,
          subjectId: 1,
          weekday: 1,
          startMinutes: 7 * 60,
          endMinutes: 8 * 60,
        ),
        const ScheduleBlock(
          id: 11,
          subjectId: 2,
          weekday: 1,
          startMinutes: 10 * 60,
          endMinutes: 12 * 60,
        ),
      ];
      final result = currentOrNextClass(
        blocks: gapBlocks,
        subjects: subjects,
        now: now,
      );
      expect(result, isNotNull);
      expect(result!.subject.name, 'Cálculo II');
      expect(result.timeUntilStart(now), const Duration(minutes: 90));
      expect(result.isOngoingAt(now), isFalse);
    });

    test('busca en los días siguientes cuando ya terminaron las clases', () {
      final now = DateTime(2026, 3, 2, 20);
      final result = currentOrNextClass(
        blocks: blocks,
        subjects: subjects,
        now: now,
      );
      expect(result, isNotNull);
      expect(result!.start, DateTime(2026, 3, 4, 14));
    });

    test('devuelve null si no hay bloques', () {
      final result = currentOrNextClass(
        blocks: const <ScheduleBlock>[],
        subjects: subjects,
        now: DateTime(2026, 3, 2, 8),
      );
      expect(result, isNull);
    });
  });

  group('upcomingAssessments y overdueAssessments', () {
    final now = DateTime(2026, 3, 2, 8);
    final assessments = <Assessment>[
      Assessment(
        id: 1,
        subjectId: 1,
        title: 'Examen parcial',
        type: 'Examen',
        due: DateTime(2026, 3, 4, 10),
      ),
      Assessment(
        id: 2,
        subjectId: 2,
        title: 'Tarea 1',
        type: 'Entrega',
        due: DateTime(2026, 3, 1, 23),
      ),
      Assessment(
        id: 3,
        subjectId: 1,
        title: 'Proyecto final',
        type: 'Proyecto',
        due: DateTime(2026, 3, 20, 23),
      ),
      Assessment(
        id: 4,
        subjectId: 2,
        title: 'Quiz',
        type: 'Otro',
        due: DateTime(2026, 3, 3, 9),
        done: true,
      ),
    ];

    test('incluye solo pendientes dentro de los próximos 7 días', () {
      final result = upcomingAssessments(
        assessments: assessments,
        now: now,
        days: 7,
      );
      expect(result.map((a) => a.id), <int>[1]);
    });

    test('ordenan las próximas por fecha ascendente', () {
      final result = upcomingAssessments(
        assessments: assessments,
        now: now,
        days: 30,
      );
      expect(result.map((a) => a.id).toList(), <int>[1, 3]);
    });

    test('detecta vencidas sin completar', () {
      final result = overdueAssessments(assessments: assessments, now: now);
      expect(result.map((a) => a.id), <int>[2]);
    });

    test('las completadas no aparecen en pendientes', () {
      final result = pendingAssessments(assessments: assessments, now: now);
      expect(result.map((a) => a.id).toList(), <int>[2, 1, 3]);
    });
  });

  group('averageGrade', () {
    test('promedia con ponderación cuando existe', () {
      final assessments = <Assessment>[
        Assessment(
          id: 1,
          subjectId: 1,
          title: 'Examen 1',
          type: 'Examen',
          due: DateTime(2026, 3, 1),
          grade: 80,
          weight: 40,
        ),
        Assessment(
          id: 2,
          subjectId: 1,
          title: 'Examen 2',
          type: 'Examen',
          due: DateTime(2026, 4, 1),
          grade: 90,
          weight: 60,
        ),
      ];
      final result = averageGrade(assessments: assessments, subjectId: 1);
      expect(result, closeTo(86, 0.001));
    });

    test('devuelve 0 cuando no hay notas', () {
      final result = averageGrade(
        assessments: const <Assessment>[],
        subjectId: 1,
      );
      expect(result, 0);
    });
  });
}
