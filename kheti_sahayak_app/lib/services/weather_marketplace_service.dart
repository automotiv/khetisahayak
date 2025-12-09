import 'package:kheti_sahayak_app/models/weather_model.dart';
import 'package:kheti_sahayak_app/models/product.dart';
import 'package:kheti_sahayak_app/services/product_service.dart';

class WeatherMarketplaceService {
  /// Get product recommendations based on current weather conditions
  static Future<List<Product>> getRecommendedProducts(UnifiedWeather weather) async {
    final String condition = weather.condition.toLowerCase();
    final String description = weather.description.toLowerCase();
    final double windSpeed = weather.windSpeed;
    final double temp = weather.temp;

    List<String> searchTerms = [];
    List<String> categories = [];

    // 1. Analyze Weather Condition
    if (condition.contains('rain') || condition.contains('drizzle') || condition.contains('thunderstorm')) {
      searchTerms.add('fungicide');
      searchTerms.add('water pump'); // To drain excess water
      categories.add('Crop Protection');
    } else if (condition.contains('clear') || condition.contains('sunny')) {
      if (temp > 30) {
        searchTerms.add('irrigation');
        searchTerms.add('sprinkler');
        categories.add('Irrigation');
      }
    } else if (condition.contains('snow') || condition.contains('cold')) {
      searchTerms.add('greenhouse');
      searchTerms.add('heater');
    }

    // 2. Analyze Wind
    if (windSpeed > 10.0) { // Strong wind
      searchTerms.add('support'); // Plant support
      searchTerms.add('stake');
    }

    // 3. Fetch Products
    // We'll try to fetch products for each identified category or search term
    // For simplicity in this MVP, we'll take the first relevant category or search term
    
    List<Product> recommendations = [];

    try {
      if (categories.isNotEmpty) {
        // Prioritize category search
        final products = await ProductService.getProducts(category: categories.first, limit: 5);
        recommendations.addAll(products);
      }

      if (searchTerms.isNotEmpty && recommendations.length < 5) {
        // Fallback to search terms if category didn't yield enough or wasn't present
        for (final term in searchTerms) {
          if (recommendations.length >= 5) break;
          final products = await ProductService.getProducts(search: term, limit: 2);
          recommendations.addAll(products);
        }
      }
      
      // Deduplicate
      final ids = <String>{};
      final uniqueRecommendations = <Product>[];
      for (var product in recommendations) {
        if (ids.add(product.id)) {
          uniqueRecommendations.add(product);
        }
      }
      
      return uniqueRecommendations;

    } catch (e) {
      print('Error fetching weather recommendations: $e');
      return [];
    }
  }
}
