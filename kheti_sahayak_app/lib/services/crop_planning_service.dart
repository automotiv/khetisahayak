import '../models/crop_rotation.dart';

class CropPlanningService {
  // Simple rules engine for demonstration
  // Format: Family -> [Compatible Next Families]
  static const Map<String, List<String>> _rotationRules = {
    'Legume': ['Cereal', 'Vegetable_Leafy', 'Vegetable_Fruiting'],
    'Cereal': ['Legume', 'Vegetable_Root'],
    'Vegetable_Solanaceous': ['Legume', 'Cereal'], // Tomato, Potato -> heavy feeders
    'Vegetable_Cruciferous': ['Legume', 'Cereal'], // Cabbage -> average feeders
    'Unknown': ['Legume', 'Cereal'],
  };

  // Format: CropName -> Family
  static const Map<String, String> _cropFamilies = {
    'Rice': 'Cereal',
    'Wheat': 'Cereal',
    'Maize': 'Cereal',
    'Soybean': 'Legume',
    'Chickpea': 'Legume',
    'Tomato': 'Vegetable_Solanaceous',
    'Potato': 'Vegetable_Solanaceous',
    'Cabbage': 'Vegetable_Cruciferous',
  };

  String getFamily(String cropName) => _cropFamilies[cropName] ?? 'Unknown';

  /// Suggests compatible crops based on the previous crop
  List<String> getRecommendations(String previousCropName) {
    final previousFamily = getFamily(previousCropName);
    final compatibleFamilies = _rotationRules[previousFamily] ?? [];

    List<String> suggestions = [];
    _cropFamilies.forEach((crop, family) {
      if (compatibleFamilies.contains(family)) {
        suggestions.add(crop);
      }
    });

    return suggestions;
  }

  /// Checks if a proposed crop is suitable after the previous crop
  bool isRotationSafe(String previousCropName, String nextCropName) {
    final previousFamily = getFamily(previousCropName);
    final nextFamily = getFamily(nextCropName);
    
    // Rule 1: Avoid same family back-to-back (basic rule)
    if (previousFamily != 'Unknown' && previousFamily == nextFamily) {
      return false;
    }

    return true;
  }
}
