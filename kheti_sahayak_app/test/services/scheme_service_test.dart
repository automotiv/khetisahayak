import 'package:flutter_test/flutter_test.dart';
import 'package:kheti_sahayak_app/services/scheme_service.dart';
import 'package:kheti_sahayak_app/services/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for SQLite in tests
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('SchemeService Tests', () {
    test('Cache and Retrieve Schemes', () async {
      // Mock data
      final schemes = [
        {
          'id': 1,
          'name': 'PM Kisan',
          'description': 'Income support',
          'benefits': '6000 per year',
          'eligibility': 'Small farmers',
          'category': 'Central',
          'link': 'https://pmkisan.gov.in'
        },
        {
          'id': 2,
          'name': 'Fasal Bima Yojana',
          'description': 'Crop insurance',
          'benefits': 'Insurance cover',
          'eligibility': 'All farmers',
          'category': 'Insurance',
          'link': 'https://pmfby.gov.in'
        }
      ];

      // Cache schemes manually (simulating API fetch)
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.cacheSchemes(schemes);

      // Retrieve from cache via Service (offline mode simulation)
      // Note: We can't easily mock connectivity here without extra setup, 
      // but we can test the search functionality which uses cache.
      
      final results = await SchemeService.searchSchemes('Kisan');
      expect(results.length, 1);
      expect(results.first.name, 'PM Kisan');
      
      final all = await SchemeService.searchSchemes(''); // Empty query returns all? No, searchSchemes returns filtered.
      // Let's check getSchemes fallback logic if we could mock http/connectivity.
      // Instead, let's test getCachedSchemes directly from helper to verify DB logic.
      
      final cached = await dbHelper.getCachedSchemes();
      expect(cached.length, 2);
    });

    test('Recent Schemes Logic', () async {
      final dbHelper = DatabaseHelper.instance;
      
      // Mark ID 2 as accessed
      await SchemeService.markSchemeAccessed(2);
      
      final recent = await SchemeService.getRecentSchemes();
      expect(recent.length, 1);
      expect(recent.first.id, 2);
    });
    test('Filter Schemes Locally', () async {
      final dbHelper = DatabaseHelper.instance;
      
      final schemes = [
        {
          'id': 3,
          'name': 'Small Farm Scheme',
          'description': 'For small farms',
          'min_farm_size': 0.0,
          'max_farm_size': 2.0,
          'crops': jsonEncode(['Wheat']),
        },
        {
          'id': 4,
          'name': 'Large Farm Scheme',
          'description': 'For large farms',
          'min_farm_size': 5.0,
          'max_farm_size': 100.0,
          'crops': jsonEncode(['Rice']),
        }
      ];
      
      await dbHelper.cacheSchemes(schemes);
      
      // Test farm size filter
      final small = await SchemeService.getSchemes(farmSize: 1.0);
      expect(small.length, 1);
      expect(small.first.name, 'Small Farm Scheme');
      
      final large = await SchemeService.getSchemes(farmSize: 10.0);
      expect(large.length, 1);
      expect(large.first.name, 'Large Farm Scheme');
      
      // Test crop filter
      final wheat = await SchemeService.getSchemes(crop: 'Wheat');
      expect(wheat.length, 1);
      expect(wheat.first.name, 'Small Farm Scheme');
    });
  });
}
