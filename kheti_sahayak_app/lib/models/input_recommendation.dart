import 'package:kheti_sahayak_app/models/product.dart';

class InputRecommendation {
  final String cropName;
  final String soilType;
  final List<RecommendedProduct> recommendedSeeds;
  final List<RecommendedProduct> recommendedFertilizers;
  final String expectedYieldImprovement;
  final CostBenefitAnalysis costBenefitAnalysis;

  InputRecommendation({
    required this.cropName,
    required this.soilType,
    required this.recommendedSeeds,
    required this.recommendedFertilizers,
    required this.expectedYieldImprovement,
    required this.costBenefitAnalysis,
  });
}

class RecommendedProduct {
  final Product product;
  final String reason;
  final List<CompetitorProduct> competitorComparison;

  RecommendedProduct({
    required this.product,
    required this.reason,
    this.competitorComparison = const [],
  });
}

class CompetitorProduct {
  final String name;
  final double price;
  final String difference; // e.g., "Lower yield", "Higher cost"

  CompetitorProduct({
    required this.name,
    required this.price,
    required this.difference,
  });
}

class CostBenefitAnalysis {
  final double estimatedCost;
  final double estimatedRevenue;
  final double netProfit;
  final String roi;

  CostBenefitAnalysis({
    required this.estimatedCost,
    required this.estimatedRevenue,
    required this.netProfit,
    required this.roi,
  });
}
