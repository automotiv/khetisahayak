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
      version: 11,
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

    // ================== ADDITIONAL TABLES FOR V2 ==================

    // Cached products table - for offline product browsing
    await db.execute('''
      CREATE TABLE cached_products (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        category TEXT,
        image_url TEXT,
        stock_quantity INTEGER DEFAULT 0,
        seller_id INTEGER,
        seller_name TEXT,
        rating REAL,
        review_count INTEGER DEFAULT 0,
        data TEXT NOT NULL,
        cached_at TEXT NOT NULL
      )
    ''');

    // Cached cart table - for offline cart persistence
    await db.execute('''
      CREATE TABLE cached_cart (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        product_image TEXT,
        quantity INTEGER NOT NULL,
        price REAL NOT NULL,
        seller_id INTEGER,
        updated_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        UNIQUE(product_id)
      )
    ''');

    // Pending actions table - queue for sync operations
    await db.execute('''
      CREATE TABLE pending_actions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action_type TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id INTEGER,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        last_retry TEXT,
        error_message TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');

    // User preferences table - local settings storage
    await db.execute('''
      CREATE TABLE user_preferences (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Cached weather data - for offline weather viewing
    await db.execute('''
      CREATE TABLE cached_weather (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        location TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        current_data TEXT,
        forecast_data TEXT,
        cached_at TEXT NOT NULL,
        expires_at TEXT NOT NULL,
        UNIQUE(location)
      )
    ''');

    // Create additional indexes
    await db.execute('CREATE INDEX idx_cached_products_category ON cached_products(category)');
    await db.execute('CREATE INDEX idx_pending_actions_synced ON pending_actions(synced)');
    await db.execute('CREATE INDEX idx_cached_weather_location ON cached_weather(location)');

    // Cached schemes table - for offline access
    await db.execute('''
      CREATE TABLE cached_schemes (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        benefits TEXT,
        eligibility TEXT,
        category TEXT,
        link TEXT,
        last_accessed TEXT,
        cached_at TEXT NOT NULL
      )
    ''');
    
    await db.execute('CREATE INDEX idx_cached_schemes_name ON cached_schemes(name)');
    await db.execute('CREATE INDEX idx_cached_schemes_last_accessed ON cached_schemes(last_accessed DESC)');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here when schema changes
    if (oldVersion < 2) {
      // Add new tables for version 2
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cached_products (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          price REAL NOT NULL,
          category TEXT,
          image_url TEXT,
          stock_quantity INTEGER DEFAULT 0,
          seller_id INTEGER,
          seller_name TEXT,
          rating REAL,
          review_count INTEGER DEFAULT 0,
          data TEXT NOT NULL,
          cached_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS cached_cart (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          product_id INTEGER NOT NULL,
          product_name TEXT NOT NULL,
          product_image TEXT,
          quantity INTEGER NOT NULL,
          price REAL NOT NULL,
          seller_id INTEGER,
          updated_at TEXT NOT NULL,
          synced INTEGER DEFAULT 0,
          UNIQUE(product_id)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS pending_actions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          action_type TEXT NOT NULL,
          entity_type TEXT NOT NULL,
          entity_id INTEGER,
          payload TEXT NOT NULL,
          created_at TEXT NOT NULL,
          retry_count INTEGER DEFAULT 0,
          last_retry TEXT,
          error_message TEXT,
          synced INTEGER DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_preferences (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS cached_weather (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          location TEXT NOT NULL,
          latitude REAL,
          longitude REAL,
          current_data TEXT,
          forecast_data TEXT,
          cached_at TEXT NOT NULL,
          expires_at TEXT NOT NULL,
          UNIQUE(location)
        )
      ''');

      // Create indexes
      await db.execute('CREATE INDEX IF NOT EXISTS idx_cached_weather_location ON cached_weather(location)');
    }

    if (oldVersion < 3) {
      // Add pending tasks table for version 3
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pending_tasks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          image_paths TEXT, -- JSON list of local file paths
          created_at TEXT NOT NULL,
          synced INTEGER DEFAULT 0,
          sync_attempts INTEGER DEFAULT 0,
          last_sync_attempt TEXT,
          error_message TEXT
        )
      ''');
      
      await db.execute('CREATE INDEX IF NOT EXISTS idx_pending_tasks_synced ON pending_tasks(synced)');
    }

    if (oldVersion < 4) {
      // Add activity records table for version 4
      await db.execute('''
        CREATE TABLE IF NOT EXISTS activity_records (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          activity_type TEXT NOT NULL,
          timestamp TEXT NOT NULL,
          metadata TEXT, -- JSON string
          synced INTEGER DEFAULT 0
        )
      ''');
      
      await db.execute('CREATE INDEX IF NOT EXISTS idx_activity_records_synced ON activity_records(synced)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_activity_records_synced ON activity_records(synced)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_activity_records_timestamp ON activity_records(timestamp DESC)');
    }

    if (oldVersion < 5) {
      // Add timezone_offset column to activity_records for version 5
      // Since SQLite doesn't support ALTER TABLE ADD COLUMN IF NOT EXISTS easily, we check if table exists first
      // But here we assume it was created in v4 or we are upgrading.
      // If upgrading from <4, the v4 block runs first creating the table without the column.
      // So we need to handle this carefully.
      
      // Actually, if we are upgrading from <4, the v4 block creates the table.
      // If we are upgrading from 4, we need to add the column.
      
      // To be safe and simple:
      // If table exists, try to add column. If it fails (column exists), ignore.
      // Or better: check if column exists.
      
      // Simplified approach:
      try {
        await db.execute('ALTER TABLE activity_records ADD COLUMN timezone_offset TEXT DEFAULT ""');
      } catch (e) {
        // Column might already exist or table might not exist (unlikely if v4 ran)
        print('Error adding timezone_offset column: $e');
      }
    }

    if (oldVersion < 6) {
      // Add fields table for version 6
      await db.execute('''
        CREATE TABLE IF NOT EXISTS fields (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          area REAL NOT NULL,
          crop_type TEXT NOT NULL,
          location TEXT NOT NULL
        )
      ''');

      // Add field_id column to activity_records
      try {
        await db.execute('ALTER TABLE activity_records ADD COLUMN field_id INTEGER');
      } catch (e) {
        print('Error adding field_id column: $e');
      }
    }

    if (oldVersion < 7) {
      // Add crop_rotations table for version 7
      await db.execute('''
        CREATE TABLE IF NOT EXISTS crop_rotations (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          field_id INTEGER NOT NULL,
          crop_name TEXT NOT NULL,
          season TEXT NOT NULL,
          year INTEGER NOT NULL,
          status TEXT NOT NULL,
          notes TEXT,
          FOREIGN KEY (field_id) REFERENCES fields(id) ON DELETE CASCADE
        )
      ''');
      
      await db.execute('CREATE INDEX IF NOT EXISTS idx_crop_rotations_field ON crop_rotations(field_id)');
    }

    if (oldVersion < 8) {
      // Add yield_records table for version 8
      await db.execute('''
        CREATE TABLE IF NOT EXISTS yield_records (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          field_id INTEGER NOT NULL,
          crop_name TEXT NOT NULL,
          harvest_date TEXT NOT NULL,
          yield_amount REAL NOT NULL,
          unit TEXT NOT NULL,
          notes TEXT,
          FOREIGN KEY (field_id) REFERENCES fields(id) ON DELETE CASCADE
        )
      ''');
      
      await db.execute('CREATE INDEX IF NOT EXISTS idx_yield_records_field ON yield_records(field_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_yield_records_date ON yield_records(harvest_date)');
    }

    if (oldVersion < 9) {
      // Add cost to activity_records and market_price to yield_records for version 9
      try {
        await db.execute('ALTER TABLE activity_records ADD COLUMN cost REAL DEFAULT 0.0');
      } catch (e) {
        print('Error adding cost column: $e');
      }

      try {
        await db.execute('ALTER TABLE yield_records ADD COLUMN market_price REAL DEFAULT 0.0');
      } catch (e) {
        print('Error adding market_price column: $e');
      }
    }

    if (oldVersion < 10) {
      // Add photo and GPS support to activity_records for version 10
      try {
        await db.execute('ALTER TABLE activity_records ADD COLUMN photo_paths TEXT');
      } catch (e) {
        print('Error adding photo_paths column: $e');
      }

      try {
        await db.execute('ALTER TABLE activity_records ADD COLUMN latitude REAL');
      } catch (e) {
        print('Error adding latitude column: $e');
      }

      try {
        await db.execute('ALTER TABLE activity_records ADD COLUMN longitude REAL');
      } catch (e) {
        print('Error adding longitude column: $e');
      }

      try {
        await db.execute('ALTER TABLE activity_records ADD COLUMN location_accuracy REAL');
      } catch (e) {
        print('Error adding location_accuracy column: $e');
      }
    }

    if (oldVersion < 11) {
      // Add cached_schemes table for version 11
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cached_schemes (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT NOT NULL,
          benefits TEXT,
          eligibility TEXT,
          category TEXT,
          link TEXT,
          last_accessed TEXT,
          cached_at TEXT NOT NULL
        )
      ''');
      
      await db.execute('CREATE INDEX IF NOT EXISTS idx_cached_schemes_name ON cached_schemes(name)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_cached_schemes_last_accessed ON cached_schemes(last_accessed DESC)');
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

  // ================== PENDING TASKS OPERATIONS ==================

  /// Insert a pending task
  Future<int> insertPendingTask(Map<String, dynamic> task) async {
    final db = await database;
    return await db.insert('pending_tasks', {
      'title': task['title'],
      'description': task['description'],
      'image_paths': task['image_paths'], // JSON string
      'created_at': DateTime.now().toIso8601String(),
      'synced': 0,
    });
  }

  /// Get all pending tasks
  Future<List<Map<String, dynamic>>> getPendingTasks() async {
    final db = await database;
    return await db.query(
      'pending_tasks',
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'created_at ASC',
    );
  }

  /// Mark task as synced
  Future<int> markTaskSynced(int id) async {
    final db = await database;
    return await db.update(
      'pending_tasks',
      {
        'synced': 1,
        'last_sync_attempt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete a pending task
  Future<int> deletePendingTask(int id) async {
    final db = await database;
    return await db.delete(
      'pending_tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update task sync attempt
  Future<int> updateTaskSyncAttempt(int id, {String? errorMessage}) async {
    final db = await database;
    final pending = await db.query(
      'pending_tasks',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (pending.isEmpty) return 0;

    final attempts = (pending.first['sync_attempts'] as int?) ?? 0;

    return await db.update(
      'pending_tasks',
      {
        'sync_attempts': attempts + 1,
        'last_sync_attempt': DateTime.now().toIso8601String(),
        'error_message': errorMessage,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
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

  // ================== CACHED PRODUCTS OPERATIONS ==================

  /// Cache a product for offline browsing
  Future<int> cacheProduct(Map<String, dynamic> product) async {
    final db = await database;
    return await db.insert(
      'cached_products',
      {
        'id': product['id'],
        'name': product['name'],
        'description': product['description'],
        'price': product['price'],
        'category': product['category'],
        'image_url': product['image_url'] ?? product['imageUrl'],
        'stock_quantity': product['stock_quantity'] ?? product['stockQuantity'] ?? 0,
        'seller_id': product['seller_id'] ?? product['sellerId'],
        'seller_name': product['seller_name'] ?? product['sellerName'],
        'rating': product['rating'],
        'review_count': product['review_count'] ?? product['reviewCount'] ?? 0,
        'data': product.toString(),
        'cached_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Cache multiple products
  Future<void> cacheProducts(List<Map<String, dynamic>> products) async {
    final db = await database;
    final batch = db.batch();
    for (final product in products) {
      batch.insert(
        'cached_products',
        {
          'id': product['id'],
          'name': product['name'],
          'description': product['description'],
          'price': product['price'],
          'category': product['category'],
          'image_url': product['image_url'] ?? product['imageUrl'],
          'stock_quantity': product['stock_quantity'] ?? product['stockQuantity'] ?? 0,
          'seller_id': product['seller_id'] ?? product['sellerId'],
          'seller_name': product['seller_name'] ?? product['sellerName'],
          'rating': product['rating'],
          'review_count': product['review_count'] ?? product['reviewCount'] ?? 0,
          'data': product.toString(),
          'cached_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Get cached products
  Future<List<Map<String, dynamic>>> getCachedProducts({
    String? category,
    String? searchQuery,
    int? limit,
  }) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;

    if (category != null || searchQuery != null) {
      final conditions = <String>[];
      whereArgs = [];

      if (category != null) {
        conditions.add('category = ?');
        whereArgs.add(category);
      }
      if (searchQuery != null) {
        conditions.add('(name LIKE ? OR description LIKE ?)');
        whereArgs.add('%$searchQuery%');
        whereArgs.add('%$searchQuery%');
      }
      where = conditions.join(' AND ');
    }

    return await db.query(
      'cached_products',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'cached_at DESC',
      limit: limit,
    );
  }

  /// Get a cached product by ID
  Future<Map<String, dynamic>?> getCachedProduct(int id) async {
    final db = await database;
    final results = await db.query(
      'cached_products',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Clear old cached products
  Future<int> clearOldCachedProducts({int daysToKeep = 7}) async {
    final db = await database;
    final cutoffDate = DateTime.now()
        .subtract(Duration(days: daysToKeep))
        .toIso8601String();

    return await db.delete(
      'cached_products',
      where: 'cached_at < ?',
      whereArgs: [cutoffDate],
    );
  }

  // ================== CACHED SCHEMES OPERATIONS ==================

  /// Cache a scheme
  Future<int> cacheScheme(Map<String, dynamic> scheme) async {
    final db = await database;
    return await db.insert(
      'cached_schemes',
      {
        'id': scheme['id'],
        'name': scheme['name'],
        'description': scheme['description'],
        'benefits': scheme['benefits'],
        'eligibility': scheme['eligibility'],
        'category': scheme['category'],
        'link': scheme['link'],
        'last_accessed': DateTime.now().toIso8601String(),
        'cached_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Cache multiple schemes
  Future<void> cacheSchemes(List<Map<String, dynamic>> schemes) async {
    final db = await database;
    final batch = db.batch();
    for (final scheme in schemes) {
      batch.insert(
        'cached_schemes',
        {
          'id': scheme['id'],
          'name': scheme['name'],
          'description': scheme['description'],
          'benefits': scheme['benefits'],
          'eligibility': scheme['eligibility'],
          'category': scheme['category'],
          'link': scheme['link'],
          'cached_at': DateTime.now().toIso8601String(),
          // Preserve last_accessed if exists, otherwise null (will be updated on view)
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Get cached schemes with optional search
  Future<List<Map<String, dynamic>>> getCachedSchemes({
    String? query,
    int? limit,
  }) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;

    if (query != null && query.isNotEmpty) {
      where = 'name LIKE ? OR description LIKE ? OR category LIKE ?';
      whereArgs = ['%$query%', '%$query%', '%$query%'];
    }

    return await db.query(
      'cached_schemes',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
      limit: limit,
    );
  }

  /// Update last accessed time for a scheme
  Future<int> updateSchemeLastAccessed(int id) async {
    final db = await database;
    return await db.update(
      'cached_schemes',
      {'last_accessed': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get recently accessed schemes
  Future<List<Map<String, dynamic>>> getRecentSchemes({int limit = 50}) async {
    final db = await database;
    return await db.query(
      'cached_schemes',
      where: 'last_accessed IS NOT NULL',
      orderBy: 'last_accessed DESC',
      limit: limit,
    );
  }
    final db = await database;
    final cutoffDate = DateTime.now()
        .subtract(Duration(days: daysToKeep))
        .toIso8601String();
    return await db.delete(
      'cached_products',
      where: 'cached_at < ?',
      whereArgs: [cutoffDate],
    );
  }

  // ================== CACHED CART OPERATIONS ==================

  /// Add or update item in cached cart
  Future<int> upsertCartItem({
    required int productId,
    required String productName,
    String? productImage,
    required int quantity,
    required double price,
    int? sellerId,
  }) async {
    final db = await database;
    return await db.insert(
      'cached_cart',
      {
        'product_id': productId,
        'product_name': productName,
        'product_image': productImage,
        'quantity': quantity,
        'price': price,
        'seller_id': sellerId,
        'updated_at': DateTime.now().toIso8601String(),
        'synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all cached cart items
  Future<List<Map<String, dynamic>>> getCachedCart() async {
    final db = await database;
    return await db.query('cached_cart', orderBy: 'updated_at DESC');
  }

  /// Update cart item quantity
  Future<int> updateCartItemQuantity(int productId, int quantity) async {
    final db = await database;
    return await db.update(
      'cached_cart',
      {
        'quantity': quantity,
        'updated_at': DateTime.now().toIso8601String(),
        'synced': 0,
      },
      where: 'product_id = ?',
      whereArgs: [productId],
    );
  }

  /// Remove item from cached cart
  Future<int> removeFromCachedCart(int productId) async {
    final db = await database;
    return await db.delete(
      'cached_cart',
      where: 'product_id = ?',
      whereArgs: [productId],
    );
  }

  /// Clear cached cart
  Future<int> clearCachedCart() async {
    final db = await database;
    return await db.delete('cached_cart');
  }

  /// Mark cart as synced
  Future<void> markCartSynced() async {
    final db = await database;
    await db.update('cached_cart', {'synced': 1});
  }

  /// Get unsynced cart items
  Future<List<Map<String, dynamic>>> getUnsyncedCartItems() async {
    final db = await database;
    return await db.query(
      'cached_cart',
      where: 'synced = ?',
      whereArgs: [0],
    );
  }

  // ================== PENDING ACTIONS OPERATIONS ==================

  /// Queue a pending action for sync
  Future<int> queuePendingAction({
    required String actionType,
    required String entityType,
    int? entityId,
    required String payload,
  }) async {
    final db = await database;
    return await db.insert('pending_actions', {
      'action_type': actionType,
      'entity_type': entityType,
      'entity_id': entityId,
      'payload': payload,
      'created_at': DateTime.now().toIso8601String(),
      'synced': 0,
    });
  }

  /// Get pending actions
  Future<List<Map<String, dynamic>>> getPendingActions({String? entityType}) async {
    final db = await database;
    return await db.query(
      'pending_actions',
      where: entityType != null ? 'entity_type = ? AND synced = ?' : 'synced = ?',
      whereArgs: entityType != null ? [entityType, 0] : [0],
      orderBy: 'created_at ASC',
    );
  }

  /// Mark action as synced
  Future<int> markActionSynced(int id) async {
    final db = await database;
    return await db.update(
      'pending_actions',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update action retry count
  Future<int> updateActionRetry(int id, {String? errorMessage}) async {
    final db = await database;
    final action = await db.query('pending_actions', where: 'id = ?', whereArgs: [id]);
    if (action.isEmpty) return 0;

    final retryCount = (action.first['retry_count'] as int?) ?? 0;

    return await db.update(
      'pending_actions',
      {
        'retry_count': retryCount + 1,
        'last_retry': DateTime.now().toIso8601String(),
        'error_message': errorMessage,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ================== ACTIVITY RECORDS OPERATIONS ==================

  /// Insert an activity record
  Future<int> insertActivityRecord(Map<String, dynamic> record) async {
    final db = await database;
    return await db.insert('activity_records', {
      'field_id': record['field_id'],
      'activity_type': record['activity_type'],
      'timestamp': record['timestamp'],
      'timezone_offset': record['timezone_offset'],
      'metadata': record['metadata'], // JSON string
      'synced': 0,
      'cost': record['cost'] ?? 0.0,
    });
  }

  /// Get all activity records
  Future<List<Map<String, dynamic>>> getActivityRecords({int? limit, int? offset}) async {
    final db = await database;
    return await db.query(
      'activity_records',
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
  }

  /// Delete an activity record
  Future<int> deleteActivityRecord(int id) async {
    final db = await database;
    return await db.delete(
      'activity_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get unsynced activity records
  Future<List<Map<String, dynamic>>> getUnsyncedActivityRecords() async {
    final db = await database;
    return await db.query(
      'activity_records',
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'timestamp ASC',
    );
  }

  /// Mark activity record as synced
  Future<int> markActivityRecordSynced(int id) async {
    final db = await database;
    return await db.update(
      'activity_records',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }




  /// Delete synced actions
  Future<int> deleteSyncedActions() async {
    final db = await database;
    return await db.delete('pending_actions', where: 'synced = ?', whereArgs: [1]);
  }

  // ================== USER PREFERENCES OPERATIONS ==================

  /// Set a user preference
  Future<int> setPreference(String key, String value) async {
    final db = await database;
    return await db.insert(
      'user_preferences',
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get a user preference
  Future<String?> getPreference(String key) async {
    final db = await database;
    final results = await db.query(
      'user_preferences',
      where: 'key = ?',
      whereArgs: [key],
    );
    return results.isNotEmpty ? results.first['value'] as String : null;
  }

  /// Delete a user preference
  Future<int> deletePreference(String key) async {
    final db = await database;
    return await db.delete('user_preferences', where: 'key = ?', whereArgs: [key]);
  }

  /// Get all user preferences
  Future<Map<String, String>> getAllPreferences() async {
    final db = await database;
    final results = await db.query('user_preferences');
    return Map.fromEntries(
      results.map((r) => MapEntry(r['key'] as String, r['value'] as String)),
    );
  }

  // ================== CACHED WEATHER OPERATIONS ==================

  /// Cache weather data for a location
  Future<int> cacheWeather({
    required String location,
    double? latitude,
    double? longitude,
    String? currentData,
    String? forecastData,
    Duration cacheExpiry = const Duration(hours: 3),
  }) async {
    final db = await database;
    final now = DateTime.now();
    return await db.insert(
      'cached_weather',
      {
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'current_data': currentData,
        'forecast_data': forecastData,
        'cached_at': now.toIso8601String(),
        'expires_at': now.add(cacheExpiry).toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get cached weather for a location
  Future<Map<String, dynamic>?> getCachedWeather(String location) async {
    final db = await database;
    final results = await db.query(
      'cached_weather',
      where: 'location = ? AND expires_at > ?',
      whereArgs: [location, DateTime.now().toIso8601String()],
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Clear expired weather cache
  Future<int> clearExpiredWeatherCache() async {
    final db = await database;
    return await db.delete(
      'cached_weather',
      where: 'expires_at < ?',
      whereArgs: [DateTime.now().toIso8601String()],
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
    await db.delete('cached_products');
    await db.delete('cached_cart');
    await db.delete('pending_actions');
    await db.delete('user_preferences');
    await db.delete('cached_weather');
  }

  /// Get database stats
  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;
    final stats = <String, int>{};

    final tables = [
      'pending_diagnostics',
      'cached_diagnostics',
      'cached_images',
      'sync_log',
      'cached_products',
      'cached_cart',
      'pending_actions',
      'user_preferences',
      'cached_weather',
    ];

    for (final table in tables) {
      try {
        final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
        stats[table] = Sqflite.firstIntValue(result) ?? 0;
      } catch (e) {
        stats[table] = 0;
      }
    }

    return stats;
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  // ================== FIELD OPERATIONS ==================

  /// Insert a field
  Future<int> insertField(Map<String, dynamic> field) async {
    final db = await database;
    return await db.insert('fields', {
      'name': field['name'],
      'area': field['area'],
      'crop_type': field['crop_type'],
      'location': field['location'],
    });
  }

  /// Get all fields
  Future<List<Map<String, dynamic>>> getFields() async {
    final db = await database;
    return await db.query('fields');
  }

  // ================== CROP ROTATION OPERATIONS ==================

  /// Insert a crop rotation
  Future<int> insertCropRotation(Map<String, dynamic> rotation) async {
    final db = await database;
    return await db.insert('crop_rotations', {
      'field_id': rotation['field_id'],
      'crop_name': rotation['crop_name'],
      'season': rotation['season'],
      'year': rotation['year'],
      'status': rotation['status'],
      'notes': rotation['notes'],
    });
  }

  /// Get crop rotations for a field
  Future<List<Map<String, dynamic>>> getCropRotations(int fieldId) async {
    final db = await database;
    return await db.query(
      'crop_rotations',
      where: 'field_id = ?',
      whereArgs: [fieldId],
      orderBy: 'year DESC, season DESC',
    );
  }

  /// Update a crop rotation
  Future<int> updateCropRotation(int id, Map<String, dynamic> rotation) async {
    final db = await database;
    return await db.update(
      'crop_rotations',
      {
        'crop_name': rotation['crop_name'],
        'season': rotation['season'],
        'year': rotation['year'],
        'status': rotation['status'],
        'notes': rotation['notes'],
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete a crop rotation
  Future<int> deleteCropRotation(int id) async {
    final db = await database;
    return await db.delete(
      'crop_rotations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ================== YIELD RECORD OPERATIONS ==================

  /// Insert a yield record
  /// Insert a yield record
  Future<int> insertYieldRecord(Map<String, dynamic> record) async {
    final db = await database;
    return await db.insert('yield_records', {
      'field_id': record['field_id'],
      'crop_name': record['crop_name'],
      'harvest_date': record['harvest_date'],
      'yield_amount': record['yield_amount'],
      'unit': record['unit'],
      'notes': record['notes'],
      'market_price': record['market_price'] ?? 0.0,
    });
  }

  /// Get yield records with optional filtering
  Future<List<Map<String, dynamic>>> getYieldRecords({
    int? fieldId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String where = '';
    List<dynamic> whereArgs = [];

    if (fieldId != null) {
      where = 'field_id = ?';
      whereArgs.add(fieldId);
    }

    if (startDate != null) {
      where += where.isEmpty ? '' : ' AND ';
      where += 'harvest_date >= ?';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      where += where.isEmpty ? '' : ' AND ';
      where += 'harvest_date <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    return await db.query(
      'yield_records',
      where: where.isEmpty ? null : where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'harvest_date DESC',
    );
  }

  /// Get aggregated yield data grouped by year and crop
  Future<List<Map<String, dynamic>>> getYieldAggregates({
    int? fieldId,
    int years = 5,
  }) async {
    final db = await database;
    final startDate = DateTime.now().subtract(Duration(days: 365 * years));
    
    String whereClause = 'harvest_date >= ?';
    List<dynamic> args = [startDate.toIso8601String()];

    if (fieldId != null) {
      whereClause += ' AND field_id = ?';
      args.add(fieldId);
    }

    // Extract year from harvest_date string (YYYY-MM-DD...)
    // SQLite's substr(harvest_date, 1, 4) gets the year
    return await db.rawQuery('''
      SELECT 
        substr(harvest_date, 1, 4) as year,
        crop_name,
        SUM(yield_amount) as total_yield,
        unit
      FROM yield_records
      WHERE $whereClause
      GROUP BY year, crop_name, unit
      ORDER BY year DESC, crop_name ASC
    ''', args);
  }


  /// Get ROI metrics for a field
  Future<Map<String, double>> getROIMetrics(int fieldId) async {
    final db = await database;

    // 1. Calculate Total Investment (Sum of costs from activity_records)
    final costResult = await db.rawQuery(
      'SELECT SUM(cost) as total_cost FROM activity_records WHERE field_id = ?',
      [fieldId],
    );
    final totalInvestment = (costResult.first['total_cost'] as num?)?.toDouble() ?? 0.0;

    // 2. Calculate Total Return (Sum of yield_amount * market_price from yield_records)
    final returnResult = await db.rawQuery(
      'SELECT SUM(yield_amount * market_price) as total_return FROM yield_records WHERE field_id = ?',
      [fieldId],
    );
    final totalReturn = (returnResult.first['total_return'] as num?)?.toDouble() ?? 0.0;

    // 3. Calculate Net Profit and ROI
    final netProfit = totalReturn - totalInvestment;
    final roi = totalInvestment > 0 ? (netProfit / totalInvestment) * 100 : 0.0;

    return {
      'total_investment': totalInvestment,
      'total_return': totalReturn,
      'net_profit': netProfit,
      'roi_percentage': roi,
    };
  }
}

