import '../models/crop_rotation.dart';

class AnalyticsService {
  // --- ROI Calculation ---
  /// Calculates ROI details for a given crop cycle
  /// [yieldAmount] total yield quantity
  /// [pricePerUnit] market price per unit of yield
  /// [totalCost] aggregated expenses for the season
  Map<String, double> calculateROI({
    required double yieldAmount,
    required double pricePerUnit,
    required double totalCost,
  }) {
    final grossRevenue = yieldAmount * pricePerUnit;
    final netProfit = grossRevenue - totalCost;
    final roiPercentage = totalCost > 0 ? (netProfit / totalCost) * 100 : 0.0;

    return {
      'gross_revenue': grossRevenue,
      'net_profit': netProfit,
      'roi_percentage': roiPercentage,
    };
  }

  // --- Yield Trends ---
  /// Aggregates yield data per year for a specific field
  /// Returns a map of Year -> Total Yield
  Map<int, double> getYieldTrends(List<CropRotation> history) {
    Map<int, double> trends = {};

    for (var cycle in history) {
      if (cycle.status == 'Harvested' || cycle.status == 'Completed') {
        if (cycle.yieldAmount != null) {
          trends.update(
            cycle.year,
            (existing) => existing + cycle.yieldAmount!,
            ifAbsent: () => cycle.yieldAmount!,
          );
        }
      }
    }
    
    // Sort by year (optional, but good for charts)
    var sortedKeys = trends.keys.toList()..sort();
    return Map.fromEntries(sortedKeys.map((k) => MapEntry(k, trends[k]!)));
  }
}
