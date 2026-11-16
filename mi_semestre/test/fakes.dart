import 'package:mi_semestre/data/repository.dart';
import 'package:mi_semestre/domain/models.dart';

class InMemoryRepository extends Repository {
  InMemoryRepository();

  final List<Subject> _subjects = <Subject>[];
  final List<ScheduleBlock> _blocks = <ScheduleBlock>[];
  final List<Assessment> _assessments = <Assessment>[];

  int _nextSubjectId = 1;
  int _nextBlockId = 1;
  int _nextAssessmentId = 1;

  void seed({
    List<Subject> subjects = const <Subject>[],
    List<ScheduleBlock> blocks = const <ScheduleBlock>[],
    List<Assessment> assessments = const <Assessment>[],
  }) {
    _subjects.addAll(subjects);
    _blocks.addAll(blocks);
    _assessments.addAll(assessments);
    for (final subject in subjects) {
      final id = subject.id;
      if (id != null && id >= _nextSubjectId) _nextSubjectId = id + 1;
    }
    for (final block in blocks) {
      final id = block.id;
      if (id != null && id >= _nextBlockId) _nextBlockId = id + 1;
    }
    for (final assessment in assessments) {
      final id = assessment.id;
      if (id != null && id >= _nextAssessmentId) _nextAssessmentId = id + 1;
    }
  }

  @override
  Future<List<Subject>> subjects() async =>
      List<Subject>.of(_subjects)
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  @override
  Future<int> saveSubject(Subject subject) async {
    if (subject.id == null) {
      final id = _nextSubjectId++;
      _subjects.add(subject.copyWith(id: id));
      return id;
    }
    final index = _subjects.indexWhere((item) => item.id == subject.id);
    if (index >= 0) {
      _subjects[index] = subject;
    } else {
      _subjects.add(subject);
    }
    return subject.id!;
  }

  @override
  Future<void> deleteSubject(int id) async {
    _subjects.removeWhere((subject) => subject.id == id);
    _blocks.removeWhere((block) => block.subjectId == id);
    _assessments.removeWhere((assessment) => assessment.subjectId == id);
  }

  @override
  Future<List<ScheduleBlock>> blocks() async => List<ScheduleBlock>.of(_blocks)
    ..sort((a, b) {
      final byDay = a.weekday.compareTo(b.weekday);
      if (byDay != 0) return byDay;
      return a.startMinutes.compareTo(b.startMinutes);
    });

  @override
  Future<int> saveBlock(ScheduleBlock block) async {
    if (block.id == null) {
      final id = _nextBlockId++;
      _blocks.add(block.copyWith(id: id));
      return id;
    }
    final index = _blocks.indexWhere((item) => item.id == block.id);
    if (index >= 0) {
      _blocks[index] = block;
    } else {
      _blocks.add(block);
    }
    return block.id!;
  }

  @override
  Future<void> deleteBlock(int id) async {
    _blocks.removeWhere((block) => block.id == id);
  }

  @override
  Future<List<Assessment>> assessments() async =>
      List<Assessment>.of(_assessments)
        ..sort((a, b) => a.due.compareTo(b.due));

  @override
  Future<int> saveAssessment(Assessment assessment) async {
    if (assessment.id == null) {
      final id = _nextAssessmentId++;
      _assessments.add(assessment.copyWith(id: id));
      return id;
    }
    final index =
        _assessments.indexWhere((item) => item.id == assessment.id);
    if (index >= 0) {
      _assessments[index] = assessment;
    } else {
      _assessments.add(assessment);
    }
    return assessment.id!;
  }

  @override
  Future<void> deleteAssessment(int id) async {
    _assessments.removeWhere((assessment) => assessment.id == id);
  }

  @override
  Future<Map<String, Object?>> exportAll() async => <String, Object?>{
        'app': 'mi_semestre',
        'version': 1,
        'subjects': _subjects.map((subject) => subject.toMap()).toList(),
        'blocks': _blocks.map((block) => block.toMap()).toList(),
        'assessments':
            _assessments.map((assessment) => assessment.toMap()).toList(),
      };

  @override
  Future<void> importAll(Map<String, dynamic> data) async {
    _subjects.clear();
    _blocks.clear();
    _assessments.clear();
    for (final row in (data['subjects'] as List?) ?? const <Object?>[]) {
      if (row is Map) {
        _subjects.add(Subject.fromMap(row.cast<String, Object?>()));
      }
    }
    for (final row in (data['blocks'] as List?) ?? const <Object?>[]) {
      if (row is Map) {
        _blocks.add(ScheduleBlock.fromMap(row.cast<String, Object?>()));
      }
    }
    for (final row in (data['assessments'] as List?) ?? const <Object?>[]) {
      if (row is Map) {
        _assessments.add(Assessment.fromMap(row.cast<String, Object?>()));
      }
    }
  }
}
