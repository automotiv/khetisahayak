import 'package:kheti_sahayak_app/models/input_recommendation.dart';
import 'package:kheti_sahayak_app/models/product.dart';

class InputAdvisorService {
  Future<InputRecommendation> getRecommendations({
    required String cropName,
    required String soilType,
    String? farmHistory,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));

    // Mock Data
    return InputRecommendation(
      cropName: cropName,
      soilType: soilType,
      recommendedSeeds: [
        RecommendedProduct(
          product: Product(
            id: 'seed_1',
            name: 'High Yield $cropName Seed (Hybrid)',
            description: 'Drought resistant, high yield variety.',
            price: 500.0,
            category: 'Seeds',
            createdAt: DateTime.now(),
            imageUrl: 'assets/images/seeds.png', // Placeholder
          ),
          reason: 'Best suited for $soilType soil and current season.',
          competitorComparison: [
            CompetitorProduct(
              name: 'Generic Seed A',
              price: 450.0,
              difference: 'Lower disease resistance',
            ),
            CompetitorProduct(
              name: 'Brand X Seed',
              price: 550.0,
              difference: 'Higher cost, similar yield',
            ),
          ],
        ),
      ],
      recommendedFertilizers: [
        RecommendedProduct(
          product: Product(
            id: 'fert_1',
            name: 'Organic NPK Booster',
            description: 'Balanced nutrition for $cropName.',
            price: 300.0,
            category: 'Fertilizers',
            createdAt: DateTime.now(),
            imageUrl: 'assets/images/fertilizer.png', // Placeholder
          ),
          reason: 'Improves soil health for $soilType.',
          competitorComparison: [
            CompetitorProduct(
              name: 'Chemical Urea',
              price: 200.0,
              difference: 'Harmful to soil long-term',
            ),
          ],
        ),
      ],
      expectedYieldImprovement: '15-20% increase compared to traditional seeds.',
      costBenefitAnalysis: CostBenefitAnalysis(
        estimatedCost: 800.0,
        estimatedRevenue: 2500.0,
        netProfit: 1700.0,
        roi: '212%',
      ),
    );
  }
}
