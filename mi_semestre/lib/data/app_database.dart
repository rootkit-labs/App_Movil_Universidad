import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) return existing;
    final path = p.join(await getDatabasesPath(), 'mi_semestre.db');
    final db = await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE subjects (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            teacher TEXT NOT NULL DEFAULT '',
            room TEXT NOT NULL DEFAULT '',
            color INTEGER NOT NULL,
            credits INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE schedule_blocks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            subject_id INTEGER NOT NULL,
            weekday INTEGER NOT NULL,
            start_minutes INTEGER NOT NULL,
            end_minutes INTEGER NOT NULL,
            room TEXT NOT NULL DEFAULT '',
            FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE assessments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            subject_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            type TEXT NOT NULL,
            due TEXT NOT NULL,
            done INTEGER NOT NULL DEFAULT 0,
            grade REAL,
            weight REAL NOT NULL DEFAULT 0,
            FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_blocks_subject ON schedule_blocks (subject_id)',
        );
        await db.execute(
          'CREATE INDEX idx_assessments_subject ON assessments (subject_id)',
        );
      },
    );
    _database = db;
    return db;
  }

  Future<void> close() async {
    final db = _database;
    if (db == null) return;
    await db.close();
    _database = null;
  }
}
