import 'package:flutter_test/flutter_test.dart';
import 'package:kheti_sahayak_app/models/field.dart';
import 'package:kheti_sahayak_app/models/activity_record.dart';
import 'package:kheti_sahayak_app/models/crop_rotation.dart';
import 'package:kheti_sahayak_app/services/analytics_service.dart';
import 'package:kheti_sahayak_app/services/crop_planning_service.dart';
import 'package:kheti_sahayak_app/services/farm_management_service.dart';

void main() {
  group('Farm Management Service Tests', () {
    final service = FarmManagementService();

    test('Create and Fetch Fields', () async {
      final field = Field(
        name: 'North Plot',
        area: 2.5,
        cropType: 'Wheat',
        location: 'Sector 4',
        soilType: 'Loamy',
      );

      final created = await service.createField(field);
      expect(created.id, isNotNull);
      expect(created.name, 'North Plot');
      expect(created.boundaries, isEmpty); // Default
      
      final fetch = await service.getFieldById(created.id!);
      expect(fetch?.soilType, 'Loamy');
    });

    test('Bulk Log Activity', () async {
      // Setup: Create 2 fields
      final f1 = await service.createField(Field(name: 'F1', area: 1, cropType: 'Rice', location: 'L1'));
      final f2 = await service.createField(Field(name: 'F2', area: 1, cropType: 'Rice', location: 'L2'));

      final template = ActivityRecord(
        activityType: 'Fertilizing',
        timestamp: DateTime.now(),
        timezoneOffset: '+05:30',
        cost: 500,
      );

      final records = await service.bulkLogActivity([f1.id!, f2.id!], template);
      
      expect(records.length, 2);
      expect(records[0].fieldId, f1.id);
      expect(records[1].fieldId, f2.id);
      expect(records[0].cost, 500);
    });
  });

  group('Analytics Service Tests', () {
    final service = AnalyticsService();

    test('ROI Calculation', () {
      final result = service.calculateROI(
        yieldAmount: 100, // 100 tons
        pricePerUnit: 2000, // 2000 per ton
        totalCost: 150000, // Total cost
      );

      // Revenue = 200,000. Profit = 50,000. ROI = 33.33%
      expect(result['gross_revenue'], 200000);
      expect(result['net_profit'], 50000);
      expect(result['roi_percentage'], closeTo(33.33, 0.01));
    });

    test('Yield Trend Aggregation', () {
      final history = [
        CropRotation(id: 1, fieldId: 1, cropName: 'Rice', season: 'Kharif', year: 2023, status: 'Harvested', yieldAmount: 50),
        CropRotation(id: 2, fieldId: 1, cropName: 'Wheat', season: 'Rabi', year: 2023, status: 'Harvested', yieldAmount: 40),
        CropRotation(id: 3, fieldId: 1, cropName: 'Rice', season: 'Kharif', year: 2024, status: 'Harvested', yieldAmount: 55),
      ];

      final trends = service.getYieldTrends(history);
      
      expect(trends[2023], 90); // 50 + 40
      expect(trends[2024], 55);
    });
  });

  group('Crop Planning Service Tests', () {
    final service = CropPlanningService();

    test('Rotation Rules', () {
      // Rice (Cereal) -> Chickpea (Legume) should be SAFE
      expect(service.isRotationSafe('Rice', 'Chickpea'), true);

      // Rice (Cereal) -> Wheat (Cereal) should be UNSAFE/NOT RECOMMENDED
      expect(service.isRotationSafe('Rice', 'Wheat'), false);
    });

    test('Recommendations', () {
      final suggestions = service.getRecommendations('Rice');
      expect(suggestions, contains('Chickpea'));
      expect(suggestions, contains('Soybean'));
      expect(suggestions, isNot(contains('Wheat')));
    });
  });
}
