import 'package:kheti_sahayak_app/services/api_service.dart';
import 'package:kheti_sahayak_app/models/diagnostic.dart';
import 'package:kheti_sahayak_app/models/crop_recommendation.dart';
import 'dart:io';

class DiagnosticService {
  // Get user's diagnostic history with filtering and pagination
  static Future<Map<String, dynamic>> getUserDiagnostics({
    int page = 1,
    int limit = 10,
    String? status,
    String? cropType,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (status != null && status != 'All') queryParams['status'] = status.toLowerCase();
      if (cropType != null && cropType != 'All') queryParams['crop_type'] = cropType.toLowerCase();

      final response = await ApiService.get('diagnostics', queryParams: queryParams);
      
      // Handle both response formats for backward compatibility
      if (response.containsKey('data') && response['data'] is List) {
        return {
          'diagnostics': (response['data'] as List)
              .map((diagnosticJson) => Diagnostic.fromJson(diagnosticJson))
              .toList(),
          'pagination': response['pagination'] ?? {'total': response['data'].length, 'page': page, 'limit': limit},
        };
      } else {
        // Fallback to direct array response
        return {
          'diagnostics': (response as List)
              .map((diagnosticJson) => Diagnostic.fromJson(diagnosticJson))
              .toList(),
          'pagination': {'total': response.length, 'page': 1, 'limit': response.length},
        };
      }
    } catch (e) {
      print('Error in getUserDiagnostics: $e');
      rethrow;
    }
  }

  // Get a specific diagnostic by ID
  static Future<Diagnostic> getDiagnosticById(String id) async {
    final response = await ApiService.get('diagnostics/$id');
    return Diagnostic.fromJson(response['diagnostic']);
  }

  // Upload image for diagnosis
  static Future<Map<String, dynamic>> uploadForDiagnosis({
    required File imageFile,
    required String cropType,
    required String issueDescription,
  }) async {
    final formData = {
      'image': imageFile,
      'crop_type': cropType,
      'issue_description': issueDescription,
    };

    final response = await ApiService.postMultipart('diagnostics/upload', formData);
    
    return {
      'diagnostic': Diagnostic.fromJson(response['diagnostic']),
      'aiAnalysis': response['aiAnalysis'],
    };
  }

  // Request expert review
  static Future<Map<String, dynamic>> requestExpertReview(String diagnosticId) async {
    final response = await ApiService.post('diagnostics/$diagnosticId/expert-review', {});
    
    return {
      'diagnostic': Diagnostic.fromJson(response['diagnostic']),
      'assignedExpert': response['assigned_expert'],
    };
  }

  // Get expert's assigned diagnostics (for expert users)
  static Future<Map<String, dynamic>> getExpertAssignedDiagnostics({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    
    if (status != null) queryParams['status'] = status;

    final response = await ApiService.get('diagnostics/expert/assigned', queryParams: queryParams);
    
    return {
      'diagnostics': (response['diagnostics'] as List)
          .map((diagnosticJson) => Diagnostic.fromJson(diagnosticJson))
          .toList(),
      'pagination': response['pagination'],
    };
  }

  // Submit expert review (for expert users)
  static Future<Diagnostic> submitExpertReview({
    required String diagnosticId,
    required String expertDiagnosis,
    required String expertRecommendations,
    String? severityLevel,
    String? treatmentPlan,
  }) async {
    final data = {
      'expert_diagnosis': expertDiagnosis,
      'expert_recommendations': expertRecommendations,
      if (severityLevel != null) 'severity_level': severityLevel,
      if (treatmentPlan != null) 'treatment_plan': treatmentPlan,
    };

    final response = await ApiService.put('diagnostics/$diagnosticId/expert-review', data);
    return Diagnostic.fromJson(response['diagnostic']);
  }

  // Get crop recommendations
  static Future<List<CropRecommendation>> getCropRecommendations({
    String? season,
    String? soilType,
    String? climateZone,
    String? waterAvailability,
  }) async {
    final queryParams = <String, String>{};
    
    if (season != null) queryParams['season'] = season;
    if (soilType != null) queryParams['soil_type'] = soilType;
    if (climateZone != null) queryParams['climate_zone'] = climateZone;
    if (waterAvailability != null) queryParams['water_availability'] = waterAvailability;

    final response = await ApiService.get('diagnostics/recommendations', queryParams: queryParams);
    
    return (response['recommendations'] as List)
        .map((recommendationJson) => CropRecommendation.fromJson(recommendationJson))
        .toList();
  }

  // Get diagnostic statistics
  static Future<Map<String, dynamic>> getDiagnosticStats() async {
    final response = await ApiService.get('diagnostics/stats');
    return response['stats'];
  }
}