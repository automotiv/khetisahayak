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
      version: 2,
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
      await db.execute('CREATE INDEX IF NOT EXISTS idx_cached_products_category ON cached_products(category)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_pending_actions_synced ON pending_actions(synced)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_cached_weather_location ON cached_weather(location)');
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
}
