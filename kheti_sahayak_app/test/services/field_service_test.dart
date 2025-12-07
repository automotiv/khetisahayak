import 'package:flutter_test/flutter_test.dart';
import 'package:kheti_sahayak_app/models/crop_rotation.dart';

void main() {
  group('CropRotation Model Logic', () {
    test('should serialize and deserialize correctly', () {
      final rotation = CropRotation(
        id: 1,
        fieldId: 101,
        cropName: 'Wheat',
        season: 'Rabi',
        year: 2023,
        status: 'Planned',
        notes: 'Test notes',
      );

      final map = rotation.toMap();
      expect(map['id'], 1);
      expect(map['field_id'], 101);
      expect(map['crop_name'], 'Wheat');
      expect(map['season'], 'Rabi');
      expect(map['year'], 2023);
      expect(map['status'], 'Planned');
      expect(map['notes'], 'Test notes');

      final newRotation = CropRotation.fromMap(map);
      expect(newRotation.id, 1);
      expect(newRotation.fieldId, 101);
      expect(newRotation.cropName, 'Wheat');
    });
  });
}
