import 'package:flutter_test/flutter_test.dart';
import 'package:mi_semestre/domain/models.dart';
import 'package:mi_semestre/services/schedule_share_service.dart';

void main() {
  test('codifica y decodifica materias y bloques sin perder datos', () {
    final raw = encodeScheduleQr(
      subjects: const <Subject>[
        Subject(
          id: 1,
          name: 'Álgebra Lineal',
          teacher: 'Prof. Pérez',
          room: 'Aula 204',
          colorValue: 0xFF4F46E5,
        ),
      ],
      blocks: const <ScheduleBlock>[
        ScheduleBlock(
          subjectId: 1,
          weekday: 1,
          startMinutes: 8 * 60,
          endMinutes: 10 * 60,
          room: 'Aula 204',
        ),
      ],
    );

    final result = parseScheduleQr(raw);

    expect(result.subjects, hasLength(1));
    expect(result.subjects.single.name, 'Álgebra Lineal');
    expect(result.blocks, hasLength(1));
    expect(result.blocks.single.subjectIndex, 0);
    expect(result.blocks.single.startMinutes, 8 * 60);
    expect(raw, isNot(contains('Examen')));
  });

  test('rechaza códigos que no son de OrganiU', () {
    expect(
      () => parseScheduleQr('OTRO:{"v":1,"s":[],"b":[]}'),
      throwsFormatException,
    );
  });

  test('rechaza bloques con horas inválidas', () {
    final raw =
        '$scheduleQrPrefix{"v":1,"s":[{"n":"Mate","c":1,"cr":3}],'
        '"b":[{"s":0,"w":1,"a":600,"b":500,"r":""}]}';
    expect(() => parseScheduleQr(raw), throwsFormatException);
  });
}
