class CropRecommendation {
  final String id;
  final String cropName;
  final String? season;
  final String? soilType;
  final String? climateZone;
  final String? waterRequirement;
  final int? growthDuration;
  final double? yieldPerHectare;
  final Map<String, dynamic>? marketPriceRange;
  final String? description;
  final DateTime createdAt;

  CropRecommendation({
    required this.id,
    required this.cropName,
    this.season,
    this.soilType,
    this.climateZone,
    this.waterRequirement,
    this.growthDuration,
    this.yieldPerHectare,
    this.marketPriceRange,
    this.description,
    required this.createdAt,
  });

  factory CropRecommendation.fromJson(Map<String, dynamic> json) {
    return CropRecommendation(
      id: json['id'],
      cropName: json['crop_name'],
      season: json['season'],
      soilType: json['soil_type'],
      climateZone: json['climate_zone'],
      waterRequirement: json['water_requirement'],
      growthDuration: json['growth_duration'],
      yieldPerHectare: json['yield_per_hectare']?.toDouble(),
      marketPriceRange: json['market_price_range'] != null 
          ? Map<String, dynamic>.from(json['market_price_range'])
          : null,
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'crop_name': cropName,
      'season': season,
      'soil_type': soilType,
      'climate_zone': climateZone,
      'water_requirement': waterRequirement,
      'growth_duration': growthDuration,
      'yield_per_hectare': yieldPerHectare,
      'market_price_range': marketPriceRange,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper methods
  String get waterRequirementDisplay {
    switch (waterRequirement?.toLowerCase()) {
      case 'low':
        return 'Low Water';
      case 'moderate':
        return 'Moderate Water';
      case 'high':
        return 'High Water';
      case 'very high':
        return 'Very High Water';
      default:
        return 'Unknown';
    }
  }

  String get seasonDisplay {
    switch (season?.toLowerCase()) {
      case 'spring':
        return 'Spring';
      case 'summer':
        return 'Summer';
      case 'autumn':
      case 'fall':
        return 'Autumn';
      case 'winter':
        return 'Winter';
      case 'year-round':
        return 'Year Round';
      default:
        return 'Unknown';
    }
  }

  double? get minPrice => marketPriceRange?['min']?.toDouble();
  double? get maxPrice => marketPriceRange?['max']?.toDouble();
  String get priceRangeDisplay {
    if (minPrice != null && maxPrice != null) {
      return '₹${minPrice!.toStringAsFixed(0)} - ₹${maxPrice!.toStringAsFixed(0)}/quintal';
    }
    return 'Price not available';
  }
} 