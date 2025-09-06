import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class NotesDB {
  static final NotesDB instance = NotesDB._init();
  static Database? _database;

  NotesDB._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'notes.db');

    // Uncomment during development to reset DB
    // await deleteDatabase(path);

    _database = await openDatabase(
      path,
      version: 4, // incremented for new column
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
    return _database!;
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        isSynced INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS pending_notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        noteId TEXT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        action TEXT NOT NULL DEFAULT 'create'
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      final columns = await db.rawQuery("PRAGMA table_info(pending_notes)");
      final columnNames = columns.map((c) => c['name'] as String).toList();
      if (!columnNames.contains('action')) {
        await db.execute(
          'ALTER TABLE pending_notes ADD COLUMN action TEXT DEFAULT "create"',
        );
      }
      if (!columnNames.contains('noteId')) {
        await db.execute('ALTER TABLE pending_notes ADD COLUMN noteId TEXT');
      }
    }
  }

  // NOTES TABLE METHODS
  Future<int> upsertNote(Map<String, dynamic> note) async {
    final db = await instance.database;
    return await db.insert(
      'notes',
      note,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> fetchNotes() async {
    final db = await instance.database;
    return await db.query('notes');
  }

  Future<int> deleteNoteLocal(String id) async {
    final db = await instance.database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  // PENDING NOTES METHODS
  Future<int> addPendingNote(
    String title,
    String description, {
    String action = "create",
    String? noteId,
  }) async {
    final db = await instance.database;
    return await db.insert('pending_notes', {
      'title': title,
      'description': description,
      'action': action,
      'noteId': noteId,
    });
  }

  Future<List<Map<String, dynamic>>> fetchPendingNotes() async {
    final db = await instance.database;
    return await db.query('pending_notes');
  }

  Future<int> deletePendingNote(int id) async {
    final db = await instance.database;
    return await db.delete('pending_notes', where: 'id = ?', whereArgs: [id]);
  }

  // CLOSE DB
  Future close() async {
    final db = await instance.database;
    await db.close();
  }
}
