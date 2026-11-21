import 'package:flutter_test/flutter_test.dart';
import 'package:mi_semestre/domain/models.dart';
import 'package:mi_semestre/services/calendar_service.dart';

void main() {
  test('genera un calendario ICS con fechas y texto escapado', () {
    final ics = buildAssessmentsIcs(
      assessments: <Assessment>[
        Assessment(
          id: 7,
          subjectId: 1,
          title: 'Parcial, oral',
          type: 'Examen',
          due: DateTime(2026, 3, 4, 10, 30),
        ),
      ],
      subjects: const <Subject>[
        Subject(id: 1, name: 'Álgebra; Lineal', colorValue: 0xFF4F46E5),
      ],
      now: DateTime.utc(2026, 3, 2, 8),
    );

    expect(ics, contains('BEGIN:VCALENDAR'));
    expect(ics, contains('UID:mi-semestre-7@mi_semestre'));
    expect(ics, contains('DTSTAMP:20260302T080000Z'));
    expect(ics, contains('DTSTART:20260304T103000'));
    expect(ics, contains('DTEND:20260304T113000'));
    expect(ics, contains('SUMMARY:Parcial\\, oral - Álgebra\\; Lineal'));
    expect(ics, contains('END:VCALENDAR'));
  });
}
