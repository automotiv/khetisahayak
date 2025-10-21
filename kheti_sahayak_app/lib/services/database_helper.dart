import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kheti_sahayak.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Pending diagnostics table - stores diagnostics waiting to be uploaded
    await db.execute('''
      CREATE TABLE pending_diagnostics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        local_image_path TEXT NOT NULL,
        crop_type TEXT NOT NULL,
        issue_description TEXT NOT NULL,
        created_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        sync_attempts INTEGER DEFAULT 0,
        last_sync_attempt TEXT,
        error_message TEXT
      )
    ''');

    // Cached diagnostics table - stores downloaded diagnostic history for offline viewing
    await db.execute('''
      CREATE TABLE cached_diagnostics (
        id INTEGER NOT NULL PRIMARY KEY,
        user_id INTEGER NOT NULL,
        crop_type TEXT,
        issue_description TEXT,
        image_urls TEXT,
        diagnosis_result TEXT,
        recommendations TEXT,
        confidence_score REAL,
        status TEXT,
        created_at TEXT,
        updated_at TEXT,
        cached_at TEXT NOT NULL
      )
    ''');

    // Cached images table - stores image data for offline access
    await db.execute('''
      CREATE TABLE cached_images (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        diagnostic_id INTEGER NOT NULL,
        image_url TEXT NOT NULL,
        local_path TEXT NOT NULL,
        cached_at TEXT NOT NULL,
        file_size INTEGER,
        FOREIGN KEY (diagnostic_id) REFERENCES cached_diagnostics (id) ON DELETE CASCADE
      )
    ''');

    // Sync log table - tracks synchronization history
    await db.execute('''
      CREATE TABLE sync_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sync_type TEXT NOT NULL,
        started_at TEXT NOT NULL,
        completed_at TEXT,
        status TEXT NOT NULL,
        items_synced INTEGER DEFAULT 0,
        error_message TEXT
      )
    ''');

    // Create indexes for faster queries
    await db.execute('CREATE INDEX idx_pending_synced ON pending_diagnostics(synced)');
    await db.execute('CREATE INDEX idx_cached_created ON cached_diagnostics(created_at DESC)');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here when schema changes
    if (oldVersion < 2) {
      // Example: Add new column in future version
      // await db.execute('ALTER TABLE pending_diagnostics ADD COLUMN new_field TEXT');
    }
  }

  // ================== PENDING DIAGNOSTICS OPERATIONS ==================

  /// Insert a pending diagnostic (for offline upload)
  Future<int> insertPendingDiagnostic({
    required String localImagePath,
    required String cropType,
    required String issueDescription,
  }) async {
    final db = await database;
    return await db.insert('pending_diagnostics', {
      'local_image_path': localImagePath,
      'crop_type': cropType,
      'issue_description': issueDescription,
      'created_at': DateTime.now().toIso8601String(),
      'synced': 0,
    });
  }

  /// Get all pending diagnostics (not yet synced)
  Future<List<Map<String, dynamic>>> getPendingDiagnostics() async {
    final db = await database;
    return await db.query(
      'pending_diagnostics',
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'created_at ASC',
    );
  }

  /// Mark diagnostic as synced
  Future<int> markDiagnosticSynced(int id) async {
    final db = await database;
    return await db.update(
      'pending_diagnostics',
      {
        'synced': 1,
        'last_sync_attempt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update sync attempt
  Future<int> updateSyncAttempt(int id, {String? errorMessage}) async {
    final db = await database;
    final pending = await db.query(
      'pending_diagnostics',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (pending.isEmpty) return 0;

    final attempts = (pending.first['sync_attempts'] as int?) ?? 0;

    return await db.update(
      'pending_diagnostics',
      {
        'sync_attempts': attempts + 1,
        'last_sync_attempt': DateTime.now().toIso8601String(),
        'error_message': errorMessage,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete a pending diagnostic
  Future<int> deletePendingDiagnostic(int id) async {
    final db = await database;
    return await db.delete(
      'pending_diagnostics',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get count of pending diagnostics
  Future<int> getPendingCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM pending_diagnostics WHERE synced = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ================== CACHED DIAGNOSTICS OPERATIONS ==================

  /// Cache a diagnostic for offline viewing
  Future<int> cacheDiagnostic(Map<String, dynamic> diagnostic) async {
    final db = await database;

    final data = {
      'id': diagnostic['id'],
      'user_id': diagnostic['user_id'],
      'crop_type': diagnostic['crop_type'],
      'issue_description': diagnostic['issue_description'],
      'image_urls': diagnostic['image_urls']?.join(','),
      'diagnosis_result': diagnostic['diagnosis_result'],
      'recommendations': diagnostic['recommendations'],
      'confidence_score': diagnostic['confidence_score'],
      'status': diagnostic['status'],
      'created_at': diagnostic['created_at'],
      'updated_at': diagnostic['updated_at'],
      'cached_at': DateTime.now().toIso8601String(),
    };

    return await db.insert(
      'cached_diagnostics',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all cached diagnostics
  Future<List<Map<String, dynamic>>> getCachedDiagnostics({
    String? status,
    String? cropType,
  }) async {
    final db = await database;
    String where = '';
    List<dynamic> whereArgs = [];

    if (status != null) {
      where = 'status = ?';
      whereArgs.add(status);
    }

    if (cropType != null) {
      where += where.isEmpty ? '' : ' AND ';
      where += 'crop_type LIKE ?';
      whereArgs.add('%$cropType%');
    }

    return await db.query(
      'cached_diagnostics',
      where: where.isEmpty ? null : where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'created_at DESC',
    );
  }

  /// Get a specific cached diagnostic
  Future<Map<String, dynamic>?> getCachedDiagnostic(int id) async {
    final db = await database;
    final results = await db.query(
      'cached_diagnostics',
      where: 'id = ?',
      whereArgs: [id],
    );

    return results.isNotEmpty ? results.first : null;
  }

  /// Clear old cached diagnostics (older than N days)
  Future<int> clearOldCache({int daysToKeep = 30}) async {
    final db = await database;
    final cutoffDate = DateTime.now()
        .subtract(Duration(days: daysToKeep))
        .toIso8601String();

    return await db.delete(
      'cached_diagnostics',
      where: 'cached_at < ?',
      whereArgs: [cutoffDate],
    );
  }

  // ================== SYNC LOG OPERATIONS ==================

  /// Start a sync operation
  Future<int> startSyncLog(String syncType) async {
    final db = await database;
    return await db.insert('sync_log', {
      'sync_type': syncType,
      'started_at': DateTime.now().toIso8601String(),
      'status': 'in_progress',
    });
  }

  /// Complete a sync operation
  Future<int> completeSyncLog({
    required int id,
    required String status,
    int itemsSynced = 0,
    String? errorMessage,
  }) async {
    final db = await database;
    return await db.update(
      'sync_log',
      {
        'completed_at': DateTime.now().toIso8601String(),
        'status': status,
        'items_synced': itemsSynced,
        'error_message': errorMessage,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get recent sync logs
  Future<List<Map<String, dynamic>>> getSyncLogs({int limit = 10}) async {
    final db = await database;
    return await db.query(
      'sync_log',
      orderBy: 'started_at DESC',
      limit: limit,
    );
  }

  // ================== DATABASE MAINTENANCE ==================

  /// Get database size
  Future<int> getDatabaseSize() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'kheti_sahayak.db');
    final file = File(path);

    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  /// Clear all data (for logout or reset)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('pending_diagnostics');
    await db.delete('cached_diagnostics');
    await db.delete('cached_images');
    await db.delete('sync_log');
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
