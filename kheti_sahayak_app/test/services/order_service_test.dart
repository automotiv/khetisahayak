
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:kheti_sahayak_app/services/order_service.dart';
import 'package:kheti_sahayak_app/services/database_helper.dart'; // To access cacheCart
import 'package:kheti_sahayak_app/services/offline_service.dart';
import 'package:kheti_sahayak_app/services/cart_service.dart';

void main() {
  late DatabaseHelper dbHelper;

  setUpAll(() {
    // Initialize FFI
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbHelper = DatabaseHelper.instance;
    // We can't easily reset singleton DatabaseHelper's db connection 
    // but we can clear tables. 
    // However, DatabaseHelper initializes a REAL path by default in its constructor or init.
    // In test environment with FFI, getDatabasesPath often returns a local dir.
    // For unit testing DatabaseHelper, it's better if we could inject the db path as inMemoryDatabasePath.
    // But DatabaseHelper is a singleton with hardcoded _initDatabase.
    
    // workaround: We'll just define the path before or rely on it creating a file in .dart_tool
    
    // Clear tables before each test
    // We need to ensure DB is initialized first
    final db = await dbHelper.database;
    await db.delete('cached_orders');
    await db.delete('cached_order_items');
    await db.delete('sync_queue');
    await db.delete('cached_cart');
    await db.delete('cached_cart_items');
  });

  test('createOrderFromCart offline should cache order and queue sync', () async {
    // 1. Setup Offline Mode
    final offlineService = OfflineService();
    offlineService.setOnlineStatusForTest(false);

    // 2. Setup Cached Cart (Pre-requisite)
    final cartData = {
      'id': 'cart_123',
      'user_id': 1,
      'subtotal': 100.0,
      'delivery_charge': 0.0,
      'discount': 0.0,
      'total': 100.0,
      'items': [
        {
          'id': 'item_1',
          'product_id': 'prod_1',
          'quantity': 2,
          'unit_price': 50.0,
          'total_price': 100.0,
          'product_name': 'Test Product',
          'product_image': null,
        }
      ]
    };
    await dbHelper.cacheCart(cartData);

    // 3. Action: Create Order
    final order = await OrderService.createOrderFromCart(
      shippingAddress: '123 Farm Lane',
      paymentMethod: 'cash_on_delivery',
    );

    // 4. Verification
    expect(order.id, isNotEmpty);
    expect(order.totalAmount, 100.0);
    expect(order.status, contains('Offline')); // "Pending (Offline)"

    // Verify DB Cache
    final cachedOrders = await dbHelper.getCachedOrders();
    expect(cachedOrders.length, 1);
    expect(cachedOrders.first['id'], order.id);
    expect(cachedOrders.first['status'], 'pending_sync');

    // Verify Sync Queue
    final db = await dbHelper.database;
    final queueItems = await db.query('sync_queue');
    expect(queueItems.length, 1);
    expect(queueItems.first['entity_type'], 'order');
    expect(queueItems.first['action'], 'create');
  });
}
