import 'package:sqflite/sqflite.dart';

import '../domain/models.dart';
import '../services/schedule_share_service.dart';
import 'app_database.dart';

class Repository {
  static const Map<String, Set<String>> _columns = <String, Set<String>>{
    'subjects': <String>{'id', 'name', 'teacher', 'room', 'color'},
    'schedule_blocks': <String>{
      'id',
      'subject_id',
      'weekday',
      'start_minutes',
      'end_minutes',
      'room',
    },
    'assessments': <String>{
      'id',
      'subject_id',
      'title',
      'type',
      'due',
      'done',
      'grade',
      'weight',
    },
  };

  Future<Database> get _db async => AppDatabase.instance.database;

  Future<List<Subject>> subjects() async {
    final db = await _db;
    final rows = await db.query('subjects', orderBy: 'name COLLATE NOCASE');
    return rows.map(Subject.fromMap).toList();
  }

  Future<int> saveSubject(Subject subject) async {
    final db = await _db;
    final map = subject.toMap()..remove('id');
    final id = subject.id;
    if (id == null) {
      return db.insert('subjects', map);
    }
    await db.update('subjects', map, where: 'id = ?', whereArgs: [id]);
    return id;
  }

  Future<void> deleteSubject(int id) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('assessments', where: 'subject_id = ?', whereArgs: [id]);
      await txn.delete(
        'schedule_blocks',
        where: 'subject_id = ?',
        whereArgs: [id],
      );
      await txn.delete('subjects', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<ScheduleBlock>> blocks() async {
    final db = await _db;
    final rows = await db.query(
      'schedule_blocks',
      orderBy: 'weekday ASC, start_minutes ASC',
    );
    return rows.map(ScheduleBlock.fromMap).toList();
  }

  Future<int> saveBlock(ScheduleBlock block) async {
    final db = await _db;
    final map = block.toMap()..remove('id');
    final id = block.id;
    if (id == null) {
      return db.insert('schedule_blocks', map);
    }
    await db.update('schedule_blocks', map, where: 'id = ?', whereArgs: [id]);
    return id;
  }

  Future<void> deleteBlock(int id) async {
    final db = await _db;
    await db.delete('schedule_blocks', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Assessment>> assessments() async {
    final db = await _db;
    final rows = await db.query('assessments', orderBy: 'due ASC');
    return rows.map(Assessment.fromMap).toList();
  }

  Future<int> saveAssessment(Assessment assessment) async {
    final db = await _db;
    final map = assessment.toMap()..remove('id');
    final id = assessment.id;
    if (id == null) {
      return db.insert('assessments', map);
    }
    await db.update('assessments', map, where: 'id = ?', whereArgs: [id]);
    return id;
  }

  Future<void> deleteAssessment(int id) async {
    final db = await _db;
    await db.delete('assessments', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, Object?>> exportAll() async {
    final db = await _db;
    return <String, Object?>{
      'app': 'mi_semestre',
      'version': 1,
      'subjects': await db.query('subjects'),
      'blocks': await db.query('schedule_blocks'),
      'assessments': await db.query('assessments'),
    };
  }

  Future<void> importAll(Map<String, dynamic> data) async {
    final db = await _db;
    final subjects = (data['subjects'] as List?) ?? const [];
    final blocks = (data['blocks'] as List?) ?? const [];
    final assessments = (data['assessments'] as List?) ?? const [];
    await db.transaction((txn) async {
      await txn.delete('assessments');
      await txn.delete('schedule_blocks');
      await txn.delete('subjects');
      for (final row in subjects) {
        await _insertRow(txn, 'subjects', row);
      }
      for (final row in blocks) {
        await _insertRow(txn, 'schedule_blocks', row);
      }
      for (final row in assessments) {
        await _insertRow(txn, 'assessments', row);
      }
    });
  }

  Future<ScheduleImportResult> mergeSharedSchedule(
    SharedSchedule schedule,
  ) async {
    final db = await _db;
    final nameToId = <String, int>{
      for (final row in await db.query(
        'subjects',
        columns: <String>['id', 'name'],
      ))
        (row['name'] as String).toLowerCase(): row['id'] as int,
    };
    final existingBlocks = await db.query(
      'schedule_blocks',
      columns: <String>[
        'subject_id',
        'weekday',
        'start_minutes',
        'end_minutes',
        'room',
      ],
    );
    final blockKeys = existingBlocks
        .map(
          (row) => _blockKey(
            subjectId: row['subject_id'] as int,
            weekday: row['weekday'] as int,
            startMinutes: row['start_minutes'] as int,
            endMinutes: row['end_minutes'] as int,
            room: (row['room'] as String?) ?? '',
          ),
        )
        .toSet();
    final resolved = <int, int>{};
    var subjectsAdded = 0;
    var blocksAdded = 0;

    await db.transaction((txn) async {
      for (var index = 0; index < schedule.subjects.length; index++) {
        final shared = schedule.subjects[index];
        final key = shared.name.toLowerCase();
        final existingId = nameToId[key];
        if (existingId != null) {
          resolved[index] = existingId;
          continue;
        }
        final id = await txn.insert('subjects', <String, Object?>{
          'name': shared.name,
          'teacher': shared.teacher,
          'room': shared.room,
          'color': shared.colorValue,
        });
        nameToId[key] = id;
        resolved[index] = id;
        subjectsAdded++;
      }
      for (final block in schedule.blocks) {
        final subjectId = resolved[block.subjectIndex];
        if (subjectId == null) continue;
        final key = _blockKey(
          subjectId: subjectId,
          weekday: block.weekday,
          startMinutes: block.startMinutes,
          endMinutes: block.endMinutes,
          room: block.room,
        );
        if (blockKeys.contains(key)) continue;
        await txn.insert('schedule_blocks', <String, Object?>{
          'subject_id': subjectId,
          'weekday': block.weekday,
          'start_minutes': block.startMinutes,
          'end_minutes': block.endMinutes,
          'room': block.room,
        });
        blockKeys.add(key);
        blocksAdded++;
      }
    });

    return ScheduleImportResult(
      subjectsAdded: subjectsAdded,
      blocksAdded: blocksAdded,
    );
  }

  String _blockKey({
    required int subjectId,
    required int weekday,
    required int startMinutes,
    required int endMinutes,
    required String room,
  }) {
    return '$subjectId|$weekday|$startMinutes|$endMinutes|${room.toLowerCase()}';
  }

  Future<void> _insertRow(
    DatabaseExecutor txn,
    String table,
    Object? row,
  ) async {
    if (row is! Map) return;
    final allowed = _columns[table] ?? const <String>{};
    final values = row.map<String, Object?>(
      (key, value) => MapEntry(key.toString(), value),
    );
    values.removeWhere((key, value) => !allowed.contains(key));
    await txn.insert(table, values);
  }
}
