import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class ProfileDB {
  static final ProfileDB instance = ProfileDB._init();
  static Database? _database;

  ProfileDB._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'profile.db');

    _database = await openDatabase(path, version: 1, onCreate: _createDB);
    return _database!;
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT,
        imagePath TEXT
      )
    ''');
  }

  // Save or update the avatar image path
  Future<int> saveImagePath(String path) async {
    final db = await instance.database;
    final existing = await db.query('profile', limit: 1);
    if (existing.isNotEmpty) {
      return await db.update(
        'profile',
        {'imagePath': path},
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      return await db.insert('profile', {'imagePath': path});
    }
  }

  Future<String?> getImagePath() async {
    final db = await instance.database;
    final data = await db.query('profile', limit: 1);
    if (data.isNotEmpty) return data.first['imagePath'] as String?;
    return null;
  }
}
