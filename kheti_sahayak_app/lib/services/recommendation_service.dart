import 'package:kheti_sahayak_app/models/recommendation.dart';
import 'package:kheti_sahayak_app/services/field_service.dart';
import 'package:uuid/uuid.dart';

class RecommendationService {
  final FieldService _fieldService = FieldService();
  final Uuid _uuid = const Uuid();

  Future<List<Recommendation>> getRecommendations(int fieldId) async {
    final List<Recommendation> recommendations = [];
    
    try {
      // 1. Fetch Field and Soil Data
      final fields = await _fieldService.getFields();
      final field = fields.firstWhere((f) => f.id == fieldId);
      final soilHistory = await _fieldService.getSoilDataHistory(fieldId);
      
      // 2. Crop Recommendations based on Soil
      if (soilHistory.isNotEmpty) {
        final latestSoil = soilHistory.first;
        
        // pH based rules
        if (latestSoil.pH != null) {
          if (latestSoil.pH! < 6.0) {
            recommendations.add(Recommendation(
              id: _uuid.v4(),
              type: 'Crop',
              title: 'Consider Acid-Tolerant Crops',
              description: 'Your soil pH is low (${latestSoil.pH}). Crops like Potato, Sweet Potato, or Oats may perform better.',
              confidence: 0.85,
              relatedFieldId: fieldId,
              timestamp: DateTime.now(),
            ));
          } else if (latestSoil.pH! > 7.5) {
            recommendations.add(Recommendation(
              id: _uuid.v4(),
              type: 'Crop',
              title: 'Consider Alkaline-Tolerant Crops',
              description: 'Your soil pH is high (${latestSoil.pH}). Crops like Barley, Sugar Beet, or Cotton are more suitable.',
              confidence: 0.80,
              relatedFieldId: fieldId,
              timestamp: DateTime.now(),
            ));
          }
        }

        // Nutrient based rules
        if (latestSoil.nitrogen != null && latestSoil.nitrogen! < 280) { // Low N (< 280 kg/ha)
           recommendations.add(Recommendation(
              id: _uuid.v4(),
              type: 'Input',
              title: 'Nitrogen Deficiency Detected',
              description: 'Soil Nitrogen is low. Apply Urea or Nitrogen-rich fertilizers. Consider planting legumes in the next rotation to fix nitrogen.',
              confidence: 0.90,
              relatedFieldId: fieldId,
              timestamp: DateTime.now(),
            ));
        }
      }

      // 3. General Season-based Recommendations (Mock logic for now)
      final currentMonth = DateTime.now().month;
      if (currentMonth >= 6 && currentMonth <= 9) { // Kharif
         recommendations.add(Recommendation(
            id: _uuid.v4(),
            type: 'Crop',
            title: 'Kharif Season Suggestion',
            description: 'It is Kharif season. Rice, Maize, and Soybean are popular choices. Ensure proper drainage if heavy rains are expected.',
            confidence: 0.75,
            relatedFieldId: fieldId,
            timestamp: DateTime.now(),
          ));
      } else if (currentMonth >= 10 || currentMonth <= 3) { // Rabi
         recommendations.add(Recommendation(
            id: _uuid.v4(),
            type: 'Crop',
            title: 'Rabi Season Suggestion',
            description: 'It is Rabi season. Wheat, Barley, and Mustard are excellent choices for this period.',
            confidence: 0.75,
            relatedFieldId: fieldId,
            timestamp: DateTime.now(),
          ));
      }

    } catch (e) {
      print('Error generating recommendations: $e');
    }

    return recommendations;
  }
}
