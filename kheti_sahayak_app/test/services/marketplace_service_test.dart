import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:kheti_sahayak_app/services/marketplace_service.dart';
import 'package:kheti_sahayak_app/services/database_helper.dart';
import 'package:kheti_sahayak_app/models/product.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Generate mocks
@GenerateMocks([DatabaseHelper, http.Client])
import 'marketplace_service_test.mocks.dart';

void main() {
  late MockDatabaseHelper mockDbHelper;
  late MockClient mockClient;

  setUp(() {
    mockDbHelper = MockDatabaseHelper();
    mockClient = MockClient();
    MarketplaceService.setHelpers(dbHelper: mockDbHelper, client: mockClient);
    SharedPreferences.setMockInitialValues({'auth_token': 'test_token'});
  });

  group('MarketplaceService', () {
    test('getProducts returns list of products from API when successful', () async {
      final mockProducts = [
        {
          'id': '1',
          'name': 'Test Product',
          'price': 100.0,
          'created_at': DateTime.now().toIso8601String(),
        }
      ];

      when(mockClient.get(any, headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response(
                json.encode({'success': true, 'data': mockProducts}),
                200,
              ));

      when(mockDbHelper.cacheProducts(any)).thenAnswer((_) async => {});

      final products = await MarketplaceService.getProducts();

      expect(products, isA<List<Product>>());
      expect(products.length, 1);
      expect(products.first.name, 'Test Product');
      verify(mockDbHelper.cacheProducts(any)).called(1);
    });

    test('getProducts falls back to cache when API fails', () async {
      when(mockClient.get(any, headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response('Error', 500));

      when(mockDbHelper.getCachedProducts(category: anyNamed('category')))
          .thenAnswer((_) async => [
                {
                  'id': '1',
                  'name': 'Cached Product',
                  'price': 100.0,
                  'created_at': DateTime.now().toIso8601String(),
                }
              ]);

      final products = await MarketplaceService.getProducts();

      expect(products, isA<List<Product>>());
      expect(products.first.name, 'Cached Product');
    });
  });
}
