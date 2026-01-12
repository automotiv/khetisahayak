import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kheti_sahayak_app/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ComparisonAttribute {
  final String key;
  final String label;
  final String type;
  final bool isSpec;

  ComparisonAttribute({
    required this.key,
    required this.label,
    required this.type,
    this.isSpec = false,
  });

  factory ComparisonAttribute.fromJson(Map<String, dynamic> json) {
    return ComparisonAttribute(
      key: json['key'] ?? '',
      label: json['label'] ?? '',
      type: json['type'] ?? 'text',
      isSpec: json['isSpec'] ?? false,
    );
  }
}

class ComparisonSummary {
  final double lowestPrice;
  final double highestRating;
  final int productCount;

  ComparisonSummary({
    required this.lowestPrice,
    required this.highestRating,
    required this.productCount,
  });

  factory ComparisonSummary.fromJson(Map<String, dynamic> json) {
    return ComparisonSummary(
      lowestPrice: (json['lowest_price'] ?? 0).toDouble(),
      highestRating: (json['highest_rating'] ?? 0).toDouble(),
      productCount: json['product_count'] ?? 0,
    );
  }
}

class ComparisonResult {
  final List<Map<String, dynamic>> products;
  final List<ComparisonAttribute> attributes;
  final ComparisonSummary summary;

  ComparisonResult({
    required this.products,
    required this.attributes,
    required this.summary,
  });

  factory ComparisonResult.fromJson(Map<String, dynamic> json) {
    return ComparisonResult(
      products: List<Map<String, dynamic>>.from(json['products'] ?? []),
      attributes: (json['attributes'] as List?)
              ?.map((a) => ComparisonAttribute.fromJson(a))
              .toList() ??
          [],
      summary: ComparisonSummary.fromJson(json['comparison_summary'] ?? {}),
    );
  }
}

class ProductComparisonService {
  static http.Client _client = http.Client();
  static const int maxCompareProducts = 5;
  static const String _comparisonKey = 'comparison_product_ids';

  static void setClient(http.Client client) {
    _client = client;
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<List<String>> getComparisonList() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_comparisonKey) ?? [];
  }

  static Future<bool> addToComparison(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_comparisonKey) ?? [];

    if (list.contains(productId)) {
      return false;
    }

    if (list.length >= maxCompareProducts) {
      return false;
    }

    list.add(productId);
    await prefs.setStringList(_comparisonKey, list);
    return true;
  }

  static Future<void> removeFromComparison(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_comparisonKey) ?? [];
    list.remove(productId);
    await prefs.setStringList(_comparisonKey, list);
  }

  static Future<void> clearComparison() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_comparisonKey);
  }

  static Future<bool> isInComparison(String productId) async {
    final list = await getComparisonList();
    return list.contains(productId);
  }

  static Future<int> getComparisonCount() async {
    final list = await getComparisonList();
    return list.length;
  }

  static Future<ComparisonResult?> compareProducts(
      List<String> productIds) async {
    if (productIds.length < 2) {
      throw ArgumentError('At least 2 products required for comparison');
    }

    if (productIds.length > maxCompareProducts) {
      throw ArgumentError('Maximum $maxCompareProducts products can be compared');
    }

    try {
      final token = await _getToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await _client.post(
        Uri.parse('${Constants.baseUrl}/api/marketplace/compare'),
        headers: headers,
        body: json.encode({'product_ids': productIds}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return ComparisonResult.fromJson(data);
        }
      }

      return null;
    } catch (e) {
      print('Error comparing products: $e');
      return null;
    }
  }
}
