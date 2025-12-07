import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:kheti_sahayak_app/utils/constants.dart';

/// Service for external API integrations
/// Uses free public APIs for agricultural data:
/// - Open-Meteo: Agricultural weather (soil moisture, evapotranspiration)
/// - SoilGrids: Soil composition data
/// - Market Prices: Commodity pricing
/// - Agricultural News
/// - Crop Calendar
/// - Pest Alerts
class ExternalApiService {
  static const String _externalBaseUrl = '${AppConstants.baseUrl}/external';

  // ============================================================================
  // Agricultural Weather Data (Open-Meteo API)
  // ============================================================================

  /// Get agricultural weather data including:
  /// - Current weather
  /// - Soil temperature and moisture
  /// - Evapotranspiration
  /// - UV index
  /// - 7-day forecast
  static Future<AgroWeatherData> getAgroWeather({
    required double lat,
    required double lon,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_externalBaseUrl/agro-weather?lat=$lat&lon=$lon'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AgroWeatherData.fromJson(data);
      } else {
        throw Exception('Failed to fetch agricultural weather data');
      }
    } catch (e) {
      // Fallback to direct Open-Meteo API call
      return _fetchDirectAgroWeather(lat, lon);
    }
  }

  /// Direct call to Open-Meteo (fallback if backend unavailable)
  static Future<AgroWeatherData> _fetchDirectAgroWeather(double lat, double lon) async {
    final params = {
      'latitude': lat.toString(),
      'longitude': lon.toString(),
      'current': 'temperature_2m,relative_humidity_2m,precipitation,weather_code,wind_speed_10m',
      'daily': 'temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max',
      'timezone': 'auto',
      'forecast_days': '7',
    };

    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', params);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return AgroWeatherData.fromOpenMeteo(json.decode(response.body));
    }
    throw Exception('Failed to fetch weather data');
  }

  /// Get agricultural weather for current location
  static Future<AgroWeatherData> getAgroWeatherForCurrentLocation() async {
    final position = await _getCurrentPosition();
    return getAgroWeather(lat: position.latitude, lon: position.longitude);
  }

  // ============================================================================
  // Soil Data (SoilGrids API)
  // ============================================================================

  /// Get soil composition data including:
  /// - Clay, sand, silt percentages
  /// - Soil pH
  /// - Organic carbon content
  /// - Nitrogen levels
  static Future<SoilData> getSoilData({
    required double lat,
    required double lon,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_externalBaseUrl/soil-data?lat=$lat&lon=$lon'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SoilData.fromJson(data);
      } else {
        throw Exception('Failed to fetch soil data');
      }
    } catch (e) {
      return SoilData.mock();
    }
  }

  /// Get soil data for current location
  static Future<SoilData> getSoilDataForCurrentLocation() async {
    final position = await _getCurrentPosition();
    return getSoilData(lat: position.latitude, lon: position.longitude);
  }

  // ============================================================================
  // Market Prices
  // ============================================================================

  /// Get commodity market prices
  /// [commodity] - Filter by specific commodity (wheat, rice, etc.)
  /// [state] - Filter by state
  static Future<MarketPriceData> getMarketPrices({
    String? commodity,
    String? state,
  }) async {
    final queryParams = <String, String>{};
    if (commodity != null) queryParams['commodity'] = commodity;
    if (state != null) queryParams['state'] = state;

    final uri = Uri.parse('$_externalBaseUrl/market-prices').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return MarketPriceData.fromJson(data);
    } else {
      throw Exception('Failed to fetch market prices');
    }
  }

  // ============================================================================
  // Agricultural News
  // ============================================================================

  /// Get agricultural news
  /// [category] - Filter by category (crops, weather, policy, technology, markets)
  /// [lang] - Language code (en, hi)
  static Future<AgriNewsData> getAgriNews({
    String? category,
    String lang = 'en',
  }) async {
    final queryParams = <String, String>{'lang': lang};
    if (category != null) queryParams['category'] = category;

    final uri = Uri.parse('$_externalBaseUrl/news').replace(
      queryParameters: queryParams,
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return AgriNewsData.fromJson(data);
    } else {
      throw Exception('Failed to fetch agricultural news');
    }
  }

  // ============================================================================
  // Crop Calendar
  // ============================================================================

  /// Get crop calendar based on location and season
  /// [crop] - Filter by specific crop
  static Future<CropCalendarData> getCropCalendar({
    required double lat,
    required double lon,
    String? crop,
  }) async {
    final queryParams = <String, String>{
      'lat': lat.toString(),
      'lon': lon.toString(),
    };
    if (crop != null) queryParams['crop'] = crop;

    final uri = Uri.parse('$_externalBaseUrl/crop-calendar').replace(
      queryParameters: queryParams,
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return CropCalendarData.fromJson(data);
    } else {
      throw Exception('Failed to fetch crop calendar');
    }
  }

  /// Get crop calendar for current location
  static Future<CropCalendarData> getCropCalendarForCurrentLocation({
    String? crop,
  }) async {
    final position = await _getCurrentPosition();
    return getCropCalendar(
      lat: position.latitude,
      lon: position.longitude,
      crop: crop,
    );
  }

  // ============================================================================
  // Pest Alerts
  // ============================================================================

  /// Get pest and disease alerts based on weather conditions
  /// [crop] - Filter alerts for specific crop
  static Future<PestAlertData> getPestAlerts({
    required double lat,
    required double lon,
    String? crop,
  }) async {
    final queryParams = <String, String>{
      'lat': lat.toString(),
      'lon': lon.toString(),
    };
    if (crop != null) queryParams['crop'] = crop;

    final uri = Uri.parse('$_externalBaseUrl/pest-alerts').replace(
      queryParameters: queryParams,
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return PestAlertData.fromJson(data);
    } else {
      throw Exception('Failed to fetch pest alerts');
    }
  }

  /// Get pest alerts for current location
  static Future<PestAlertData> getPestAlertsForCurrentLocation({
    String? crop,
  }) async {
    final position = await _getCurrentPosition();
    return getPestAlerts(
      lat: position.latitude,
      lon: position.longitude,
      crop: crop,
    );
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  static Future<Position> _getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }
}

// ============================================================================
// Data Models
// ============================================================================

/// Agricultural weather data with soil and evapotranspiration info
class AgroWeatherData {
  final double? lat;
  final double? lon;
  final String? timezone;
  final AgroCurrentWeather? current;
  final List<AgroDailyForecast> daily;
  final List<AgroInsight> insights;
  final String source;

  AgroWeatherData({
    this.lat,
    this.lon,
    this.timezone,
    this.current,
    required this.daily,
    required this.insights,
    required this.source,
  });

  factory AgroWeatherData.fromJson(Map<String, dynamic> json) {
    return AgroWeatherData(
      lat: json['location']?['lat']?.toDouble(),
      lon: json['location']?['lon']?.toDouble(),
      timezone: json['location']?['timezone'],
      current: json['current'] != null
          ? AgroCurrentWeather.fromJson(json['current'])
          : null,
      daily: (json['daily'] as List?)
              ?.map((d) => AgroDailyForecast.fromJson(d))
              .toList() ??
          [],
      insights: (json['agriculturalInsights'] as List?)
              ?.map((i) => AgroInsight.fromJson(i))
              .toList() ??
          [],
      source: json['source'] ?? 'Unknown',
    );
  }

  factory AgroWeatherData.fromOpenMeteo(Map<String, dynamic> json) {
    return AgroWeatherData(
      lat: json['latitude']?.toDouble(),
      lon: json['longitude']?.toDouble(),
      timezone: json['timezone'],
      current: json['current'] != null
          ? AgroCurrentWeather(
              temperature: json['current']['temperature_2m']?.toDouble(),
              humidity: json['current']['relative_humidity_2m']?.toDouble(),
              precipitation: json['current']['precipitation']?.toDouble(),
              weatherCode: json['current']['weather_code'],
              windSpeed: json['current']['wind_speed_10m']?.toDouble(),
            )
          : null,
      daily: [],
      insights: [],
      source: 'Open-Meteo',
    );
  }
}

class AgroCurrentWeather {
  final double? temperature;
  final double? humidity;
  final double? precipitation;
  final int? weatherCode;
  final double? windSpeed;
  final double? soilTemperature;
  final double? soilMoisture;

  AgroCurrentWeather({
    this.temperature,
    this.humidity,
    this.precipitation,
    this.weatherCode,
    this.windSpeed,
    this.soilTemperature,
    this.soilMoisture,
  });

  factory AgroCurrentWeather.fromJson(Map<String, dynamic> json) {
    return AgroCurrentWeather(
      temperature: json['temperature']?.toDouble(),
      humidity: json['humidity']?.toDouble(),
      precipitation: json['precipitation']?.toDouble(),
      weatherCode: json['weatherCode'],
      windSpeed: json['windSpeed']?.toDouble(),
      soilTemperature: json['soilTemperature']?.toDouble(),
      soilMoisture: json['soilMoisture']?.toDouble(),
    );
  }

  String get weatherDescription {
    switch (weatherCode) {
      case 0:
        return 'Clear sky';
      case 1:
      case 2:
      case 3:
        return 'Partly cloudy';
      case 45:
      case 48:
        return 'Foggy';
      case 51:
      case 53:
      case 55:
        return 'Drizzle';
      case 61:
      case 63:
      case 65:
        return 'Rain';
      case 71:
      case 73:
      case 75:
        return 'Snow';
      case 95:
        return 'Thunderstorm';
      default:
        return 'Unknown';
    }
  }
}

class AgroDailyForecast {
  final String date;
  final double? tempMax;
  final double? tempMin;
  final double? precipitationSum;
  final double? precipitationProbability;
  final double? evapotranspiration;
  final double? uvIndexMax;

  AgroDailyForecast({
    required this.date,
    this.tempMax,
    this.tempMin,
    this.precipitationSum,
    this.precipitationProbability,
    this.evapotranspiration,
    this.uvIndexMax,
  });

  factory AgroDailyForecast.fromJson(Map<String, dynamic> json) {
    return AgroDailyForecast(
      date: json['date'] ?? '',
      tempMax: json['tempMax']?.toDouble(),
      tempMin: json['tempMin']?.toDouble(),
      precipitationSum: json['precipitationSum']?.toDouble(),
      precipitationProbability: json['precipitationProbability']?.toDouble(),
      evapotranspiration: json['evapotranspiration']?.toDouble(),
      uvIndexMax: json['uvIndexMax']?.toDouble(),
    );
  }
}

class AgroInsight {
  final String type;
  final String severity;
  final String message;
  final String? messageHi;

  AgroInsight({
    required this.type,
    required this.severity,
    required this.message,
    this.messageHi,
  });

  factory AgroInsight.fromJson(Map<String, dynamic> json) {
    return AgroInsight(
      type: json['type'] ?? '',
      severity: json['severity'] ?? 'low',
      message: json['message'] ?? '',
      messageHi: json['message_hi'],
    );
  }
}

/// Soil composition data
class SoilData {
  final double? lat;
  final double? lon;
  final Map<String, dynamic> soilProperties;
  final List<String> recommendations;
  final String source;
  final bool isMock;

  SoilData({
    this.lat,
    this.lon,
    required this.soilProperties,
    required this.recommendations,
    required this.source,
    this.isMock = false,
  });

  factory SoilData.fromJson(Map<String, dynamic> json) {
    return SoilData(
      lat: json['location']?['lat']?.toDouble(),
      lon: json['location']?['lon']?.toDouble(),
      soilProperties: json['soilProperties'] ?? {},
      recommendations: List<String>.from(json['recommendations'] ?? []),
      source: json['source'] ?? 'Unknown',
      isMock: json['isMock'] ?? false,
    );
  }

  factory SoilData.mock() {
    return SoilData(
      soilProperties: {
        'clay': {'0-5cm': {'value': 25, 'unit': '%'}},
        'sand': {'0-5cm': {'value': 40, 'unit': '%'}},
        'silt': {'0-5cm': {'value': 35, 'unit': '%'}},
        'ph': {'0-5cm': {'value': 6.5, 'unit': 'pH'}},
        'soilType': 'Loamy Soil',
        'suitableCrops': ['Wheat', 'Rice', 'Vegetables', 'Pulses'],
      },
      recommendations: [
        'Test soil pH before planting season',
        'Add organic matter to improve soil structure',
      ],
      source: 'Estimated data',
      isMock: true,
    );
  }

  String get soilType {
    return soilProperties['soilType'] ?? 'Unknown';
  }

  List<String> get suitableCrops {
    return List<String>.from(soilProperties['suitableCrops'] ?? []);
  }

  double? get ph {
    return soilProperties['ph']?['0-5cm']?['value']?.toDouble();
  }
}

/// Market price data
class MarketPriceData {
  final String currency;
  final String unit;
  final List<CommodityPrice> prices;
  final MarketTrends? trends;
  final String source;

  MarketPriceData({
    required this.currency,
    required this.unit,
    required this.prices,
    this.trends,
    required this.source,
  });

  factory MarketPriceData.fromJson(Map<String, dynamic> json) {
    return MarketPriceData(
      currency: json['currency'] ?? 'INR',
      unit: json['unit'] ?? 'per quintal',
      prices: (json['prices'] as List?)
              ?.map((p) => CommodityPrice.fromJson(p))
              .toList() ??
          [],
      trends: json['marketTrends'] != null
          ? MarketTrends.fromJson(json['marketTrends'])
          : null,
      source: json['source'] ?? 'Unknown',
    );
  }
}

class CommodityPrice {
  final String commodity;
  final String? variety;
  final double minPrice;
  final double maxPrice;
  final double modalPrice;
  final String? market;
  final String? state;
  final String? trend;
  final double? changePercent;
  final String? lastUpdated;

  CommodityPrice({
    required this.commodity,
    this.variety,
    required this.minPrice,
    required this.maxPrice,
    required this.modalPrice,
    this.market,
    this.state,
    this.trend,
    this.changePercent,
    this.lastUpdated,
  });

  factory CommodityPrice.fromJson(Map<String, dynamic> json) {
    return CommodityPrice(
      commodity: json['commodity'] ?? '',
      variety: json['variety'],
      minPrice: (json['minPrice'] ?? 0).toDouble(),
      maxPrice: (json['maxPrice'] ?? 0).toDouble(),
      modalPrice: (json['modalPrice'] ?? 0).toDouble(),
      market: json['market'],
      state: json['state'],
      trend: json['trend'],
      changePercent: json['changePercent']?.toDouble(),
      lastUpdated: json['lastUpdated'],
    );
  }

  String get priceRange => '$minPrice - $maxPrice';
  bool get isUp => trend == 'up';
}

class MarketTrends {
  final List<CommodityPrice> topGainers;
  final List<CommodityPrice> topLosers;
  final String? advice;

  MarketTrends({
    required this.topGainers,
    required this.topLosers,
    this.advice,
  });

  factory MarketTrends.fromJson(Map<String, dynamic> json) {
    return MarketTrends(
      topGainers: (json['topGainers'] as List?)
              ?.map((p) => CommodityPrice.fromJson(p))
              .toList() ??
          [],
      topLosers: (json['topLosers'] as List?)
              ?.map((p) => CommodityPrice.fromJson(p))
              .toList() ??
          [],
      advice: json['advice'],
    );
  }
}

/// Agricultural news data
class AgriNewsData {
  final String category;
  final String language;
  final List<NewsArticle> articles;
  final List<String> relatedTopics;
  final String source;

  AgriNewsData({
    required this.category,
    required this.language,
    required this.articles,
    required this.relatedTopics,
    required this.source,
  });

  factory AgriNewsData.fromJson(Map<String, dynamic> json) {
    return AgriNewsData(
      category: json['category'] ?? 'general',
      language: json['language'] ?? 'en',
      articles: (json['articles'] as List?)
              ?.map((a) => NewsArticle.fromJson(a))
              .toList() ??
          [],
      relatedTopics: List<String>.from(json['relatedTopics'] ?? []),
      source: json['source'] ?? 'Unknown',
    );
  }
}

class NewsArticle {
  final String title;
  final String? description;
  final String? url;
  final String? image;
  final String? publishedAt;
  final String? sourceName;

  NewsArticle({
    required this.title,
    this.description,
    this.url,
    this.image,
    this.publishedAt,
    this.sourceName,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? '',
      description: json['description'],
      url: json['url'],
      image: json['image'],
      publishedAt: json['publishedAt'],
      sourceName: json['source'],
    );
  }
}

/// Crop calendar data
class CropCalendarData {
  final String climateZone;
  final String currentSeason;
  final String currentMonth;
  final List<CropCalendarEntry> crops;
  final List<String> recommendations;

  CropCalendarData({
    required this.climateZone,
    required this.currentSeason,
    required this.currentMonth,
    required this.crops,
    required this.recommendations,
  });

  factory CropCalendarData.fromJson(Map<String, dynamic> json) {
    final calendar = json['calendar'] ?? {};
    return CropCalendarData(
      climateZone: json['location']?['climateZone'] ?? calendar['climateZone'] ?? '',
      currentSeason: json['location']?['currentSeason'] ?? calendar['season'] ?? '',
      currentMonth: json['currentMonth'] ?? '',
      crops: (calendar['crops'] as List?)
              ?.map((c) => CropCalendarEntry.fromJson(c))
              .toList() ??
          [],
      recommendations: List<String>.from(json['recommendations'] ?? []),
    );
  }
}

class CropCalendarEntry {
  final String name;
  final String sowingStart;
  final String sowingEnd;
  final String harvestStart;
  final String harvestEnd;
  final String status;

  CropCalendarEntry({
    required this.name,
    required this.sowingStart,
    required this.sowingEnd,
    required this.harvestStart,
    required this.harvestEnd,
    required this.status,
  });

  factory CropCalendarEntry.fromJson(Map<String, dynamic> json) {
    return CropCalendarEntry(
      name: json['name'] ?? '',
      sowingStart: json['sowingStart'] ?? '',
      sowingEnd: json['sowingEnd'] ?? '',
      harvestStart: json['harvestStart'] ?? '',
      harvestEnd: json['harvestEnd'] ?? '',
      status: json['status'] ?? 'Unknown',
    );
  }

  bool get isSowingTime => status == 'Sowing Time';
  bool get isHarvestTime => status == 'Harvest Time';
  bool get isGrowing => status == 'Growing';
}

/// Pest alert data
class PestAlertData {
  final double? lat;
  final double? lon;
  final Map<String, dynamic> currentConditions;
  final List<PestAlert> alerts;
  final List<String> preventiveMeasures;
  final String source;

  PestAlertData({
    this.lat,
    this.lon,
    required this.currentConditions,
    required this.alerts,
    required this.preventiveMeasures,
    required this.source,
  });

  factory PestAlertData.fromJson(Map<String, dynamic> json) {
    return PestAlertData(
      lat: json['location']?['lat']?.toDouble(),
      lon: json['location']?['lon']?.toDouble(),
      currentConditions: json['currentConditions'] ?? {},
      alerts: (json['alerts'] as List?)
              ?.map((a) => PestAlert.fromJson(a))
              .toList() ??
          [],
      preventiveMeasures: List<String>.from(json['preventiveMeasures'] ?? []),
      source: json['source'] ?? 'Unknown',
    );
  }

  bool get hasHighRiskAlerts => alerts.any((a) => a.risk == 'High');
}

class PestAlert {
  final String pest;
  final String risk;
  final String message;
  final String? messageHi;
  final List<String> affectedCrops;

  PestAlert({
    required this.pest,
    required this.risk,
    required this.message,
    this.messageHi,
    required this.affectedCrops,
  });

  factory PestAlert.fromJson(Map<String, dynamic> json) {
    return PestAlert(
      pest: json['pest'] ?? '',
      risk: json['risk'] ?? 'Low',
      message: json['message'] ?? '',
      messageHi: json['message_hi'],
      affectedCrops: List<String>.from(json['affectedCrops'] ?? []),
    );
  }

  bool get isHighRisk => risk == 'High';
  bool get isMediumRisk => risk == 'Medium';
}
