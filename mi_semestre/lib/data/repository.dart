import 'package:sqflite/sqflite.dart';

import '../domain/models.dart';
import 'app_database.dart';

class Repository {
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
      await txn.delete('schedule_blocks',
          where: 'subject_id = ?', whereArgs: [id]);
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

  Future<void> _insertRow(
    DatabaseExecutor txn,
    String table,
    Object? row,
  ) async {
    if (row is! Map) return;
    final values = row.map<String, Object?>(
      (key, value) => MapEntry(key.toString(), value),
    );
    await txn.insert(table, values);
  }
}
