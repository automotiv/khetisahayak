import '../models/field.dart';
import '../models/activity_record.dart';

// Mock database interactions for now
class FarmManagementService {
  final List<Field> _fields = []; // In-memory store placeholder
  final List<ActivityRecord> _activities = [];

  // --- Field Management ---
  Future<Field> createField(Field field) async {
    // In real app: Insert into DB
    final newField = Field(
      id: _fields.length + 1, // Simple ID gen
      name: field.name,
      area: field.area,
      cropType: field.cropType,
      location: field.location,
      boundaries: field.boundaries,
      soilType: field.soilType,
      irrigationSource: field.irrigationSource,
      isActive: field.isActive,
    );
    _fields.add(newField);
    return newField;
  }

  Future<void> updateField(Field field) async {
    final index = _fields.indexWhere((f) => f.id == field.id);
    if (index != -1) {
      _fields[index] = field;
    }
  }

  Future<void> deleteField(int id) async {
    _fields.removeWhere((f) => f.id == id);
  }

  Future<List<Field>> getAllFields() async {
    return _fields;
  }

  Future<Field?> getFieldById(int id) async {
    try {
      return _fields.firstWhere((f) => f.id == id);
    } catch (e) {
      return null;
    }
  }

  // --- Bulk Operations ---
  /// Logs the same activity for multiple fields
  Future<List<ActivityRecord>> bulkLogActivity(List<int> fieldIds, ActivityRecord templateRecord) async {
    List<ActivityRecord> createdRecords = [];

    for (var fieldId in fieldIds) {
      // Create a unique record for this field based on the template
      final record = ActivityRecord(
        id: _activities.length + 1 + createdRecords.length,
        fieldId: fieldId,
        activityType: templateRecord.activityType,
        timestamp: templateRecord.timestamp,
        timezoneOffset: templateRecord.timezoneOffset,
        metadata: templateRecord.metadata,
        cost: templateRecord.cost, // Assuming cost is per-field or split? For now copying.
        photoPaths: templateRecord.photoPaths,
        latitude: templateRecord.latitude,
        longitude: templateRecord.longitude,
      );
      
      _activities.add(record);
      createdRecords.add(record);
    }

    return createdRecords;
  }
}
