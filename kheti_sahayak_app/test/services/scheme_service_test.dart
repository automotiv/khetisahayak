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
  });
}
