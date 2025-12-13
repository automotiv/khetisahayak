import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  static Database? _database;

  factory LocalDatabaseService() => _instance;

  LocalDatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'kheti_sahayak.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Users Table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id TEXT UNIQUE,
        name TEXT,
        email TEXT,
        phone TEXT,
        synced_at TEXT
      )
    ''');

    // 2. Farms Table
    await db.execute('''
      CREATE TABLE farms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id TEXT UNIQUE,
        name TEXT,
        area REAL,
        crop_type TEXT,
        location TEXT,
        boundaries TEXT, -- JSON string
        soil_type TEXT,
        irrigation_source TEXT,
        is_active INTEGER,
        synced_at TEXT
      )
    ''');

    // 3. Farm Activities Table
    await db.execute('''
      CREATE TABLE farm_activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id TEXT UNIQUE,
        field_id INTEGER,
        activity_type TEXT,
        timestamp TEXT,
        cost REAL,
        metadata TEXT, -- JSON string
        synced_at TEXT,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    // 4. Sync Queue Table
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT,
        action TEXT, -- create, update, delete
        payload TEXT, -- JSON payload to send to server
        created_at TEXT,
        retry_count INTEGER DEFAULT 0
      )
    ''');
  }

  // --- Generic CRUD Methods ---

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    return await db.query(table, where: where, whereArgs: whereArgs);
  }

  Future<int> update(String table, Map<String, dynamic> data, String where, List<dynamic> whereArgs) async {
    final db = await database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(String table, String where, List<dynamic> whereArgs) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }
}
