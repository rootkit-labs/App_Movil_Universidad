import 'models.dart';

class ScheduledClass {
  const ScheduledClass({
    required this.block,
    required this.subject,
    required this.start,
    required this.end,
  });

  final ScheduleBlock block;
  final Subject subject;
  final DateTime start;
  final DateTime end;

  bool isOngoingAt(DateTime now) => !now.isBefore(start) && now.isBefore(end);

  bool isFinishedAt(DateTime now) => !now.isBefore(end);

  Duration timeUntilStart(DateTime now) => start.difference(now);
}

Subject? subjectOf(List<Subject> subjects, int id) {
  for (final subject in subjects) {
    if (subject.id == id) return subject;
  }
  return null;
}

List<ScheduledClass> classesForDay({
  required List<ScheduleBlock> blocks,
  required List<Subject> subjects,
  required DateTime day,
}) {
  final result = <ScheduledClass>[];
  for (final block in blocks) {
    if (block.weekday != day.weekday) continue;
    final subject = subjectOf(subjects, block.subjectId);
    if (subject == null) continue;
    final base = DateTime(day.year, day.month, day.day);
    result.add(
      ScheduledClass(
        block: block,
        subject: subject,
        start: base.add(Duration(minutes: block.startMinutes)),
        end: base.add(Duration(minutes: block.endMinutes)),
      ),
    );
  }
  result.sort((a, b) => a.start.compareTo(b.start));
  return result;
}

ScheduledClass? currentOrNextClass({
  required List<ScheduleBlock> blocks,
  required List<Subject> subjects,
  required DateTime now,
  int searchDays = 8,
}) {
  for (var offset = 0; offset <= searchDays; offset++) {
    final day = DateTime(now.year, now.month, now.day)
        .add(Duration(days: offset));
    final classes = classesForDay(
      blocks: blocks,
      subjects: subjects,
      day: day,
    ).where((c) => c.end.isAfter(now)).toList();
    if (classes.isNotEmpty) return classes.first;
  }
  return null;
}

List<ScheduledClass> classesBetween({
  required List<ScheduleBlock> blocks,
  required List<Subject> subjects,
  required DateTime from,
  required DateTime to,
}) {
  final result = <ScheduledClass>[];
  var day = DateTime(from.year, from.month, from.day);
  final limit = DateTime(to.year, to.month, to.day);
  while (!day.isAfter(limit)) {
    result.addAll(
      classesForDay(blocks: blocks, subjects: subjects, day: day),
    );
    day = day.add(const Duration(days: 1));
  }
  return result;
}

List<Assessment> upcomingAssessments({
  required List<Assessment> assessments,
  required DateTime now,
  int days = 7,
}) {
  final limit = now.add(Duration(days: days));
  final result = assessments
      .where((a) => !a.done && a.due.isAfter(now) && a.due.isBefore(limit))
      .toList();
  result.sort((a, b) => a.due.compareTo(b.due));
  return result;
}

List<Assessment> overdueAssessments({
  required List<Assessment> assessments,
  required DateTime now,
}) {
  final result =
      assessments.where((a) => !a.done && a.due.isBefore(now)).toList();
  result.sort((a, b) => b.due.compareTo(a.due));
  return result;
}

List<Assessment> pendingAssessments({
  required List<Assessment> assessments,
  required DateTime now,
}) {
  final result = assessments.where((a) => !a.done).toList();
  result.sort((a, b) => a.due.compareTo(b.due));
  return result;
}

List<Assessment> completedAssessments({
  required List<Assessment> assessments,
}) {
  final result = assessments.where((a) => a.done).toList();
  result.sort((a, b) => b.due.compareTo(a.due));
  return result;
}

List<Assessment> assessmentsForSubject({
  required List<Assessment> assessments,
  required int subjectId,
}) {
  final result =
      assessments.where((a) => a.subjectId == subjectId).toList();
  result.sort((a, b) => a.due.compareTo(b.due));
  return result;
}

double averageGrade({
  required List<Assessment> assessments,
  required int subjectId,
}) {
  final graded = assessments
      .where((a) => a.subjectId == subjectId && a.grade != null)
      .toList();
  if (graded.isEmpty) return 0;
  var weightedSum = 0.0;
  var weightSum = 0.0;
  var simpleSum = 0.0;
  for (final assessment in graded) {
    final grade = assessment.grade ?? 0;
    simpleSum += grade;
    if (assessment.weight > 0) {
      weightedSum += grade * assessment.weight;
      weightSum += assessment.weight;
    }
  }
  if (weightSum > 0) return weightedSum / weightSum;
  return simpleSum / graded.length;
}
