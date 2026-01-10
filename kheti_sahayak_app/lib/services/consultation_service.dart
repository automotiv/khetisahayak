import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kheti_sahayak_app/models/expert.dart';
import 'package:kheti_sahayak_app/models/consultation.dart';
import 'package:kheti_sahayak_app/services/auth_service.dart';
import 'package:kheti_sahayak_app/utils/constants.dart';

/// Consultation Service
/// 
/// Handles all consultation-related API operations including
/// expert listing, booking, and consultation management

class ConsultationService {
  static const String baseUrl = '${AppConstants.baseUrl}/api';

  // ==================== EXPERTS ====================

  /// Get list of experts with optional filters
  static Future<List<Expert>> getExperts({
    String? specialization,
    String? language,
    double? minRating,
    double? maxFee,
    String? sortBy,
    String? searchQuery,
  }) async {
    try {
      final token = await AuthService.getToken();
      
      final queryParams = <String, String>{};
      if (specialization != null) queryParams['specialization'] = specialization;
      if (language != null) queryParams['language'] = language;
      if (minRating != null) queryParams['min_rating'] = minRating.toString();
      if (maxFee != null) queryParams['max_fee'] = maxFee.toString();
      if (sortBy != null) queryParams['sort_by'] = sortBy;
      if (searchQuery != null) queryParams['search'] = searchQuery;

      final uri = Uri.parse('$baseUrl/experts').replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> items = data['data'];
          return items.map((item) => Expert.fromJson(item)).toList();
        }
      }
      
      // Return mock data for development
      return _getMockExperts();
    } catch (e) {
      print('Error fetching experts: $e');
      return _getMockExperts();
    }
  }

  /// Get expert by ID
  static Future<Expert?> getExpertById(String expertId) async {
    try {
      final token = await AuthService.getToken();
      
      final response = await http.get(
        Uri.parse('$baseUrl/experts/$expertId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Expert.fromJson(data['data']);
        }
      }
      
      // Return mock data
      final experts = _getMockExperts();
      return experts.firstWhere((e) => e.id == expertId, orElse: () => experts.first);
    } catch (e) {
      print('Error fetching expert: $e');
      return null;
    }
  }

  /// Get expert availability for a specific date
  static Future<List<TimeSlot>> getAvailability(String expertId, DateTime date) async {
    try {
      final token = await AuthService.getToken();
      
      final response = await http.get(
        Uri.parse('$baseUrl/experts/$expertId/availability?date=${date.toIso8601String().split('T')[0]}'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['slots'] != null) {
          final List<dynamic> slots = data['slots'];
          return slots.map((s) => TimeSlot.fromJson(s)).toList();
        }
      }
      
      // Return mock slots
      return _getMockTimeSlots(date);
    } catch (e) {
      print('Error fetching availability: $e');
      return _getMockTimeSlots(date);
    }
  }

  // ==================== CONSULTATIONS ====================

  /// Book a consultation
  static Future<Consultation?> bookConsultation({
    required String expertId,
    required DateTime scheduledAt,
    required ConsultationType type,
    required double fee,
    String? issueDescription,
    List<String>? attachedImages,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Not authenticated');
      
      final response = await http.post(
        Uri.parse('$baseUrl/consultations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'expert_id': expertId,
          'scheduled_at': scheduledAt.toIso8601String(),
          'type': type.value,
          'fee': fee,
          'issue_description': issueDescription,
          'attached_images': attachedImages,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Consultation.fromJson(data['data']);
        }
      }
      
      throw Exception('Failed to book consultation');
    } catch (e) {
      print('Error booking consultation: $e');
      return null;
    }
  }

  /// Get user's consultations
  static Future<List<Consultation>> getMyConsultations({
    ConsultationStatus? status,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return [];
      
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status.value;

      final uri = Uri.parse('$baseUrl/consultations/my').replace(
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> items = data['data'];
          return items.map((item) => Consultation.fromJson(item)).toList();
        }
      }
      
      return _getMockConsultations();
    } catch (e) {
      print('Error fetching consultations: $e');
      return _getMockConsultations();
    }
  }

  /// Get consultation by ID
  static Future<Consultation?> getConsultationById(String consultationId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;
      
      final response = await http.get(
        Uri.parse('$baseUrl/consultations/$consultationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Consultation.fromJson(data['data']);
        }
      }
      
      return null;
    } catch (e) {
      print('Error fetching consultation: $e');
      return null;
    }
  }

  /// Cancel a consultation
  static Future<bool> cancelConsultation(String consultationId, {String? reason}) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;
      
      final response = await http.post(
        Uri.parse('$baseUrl/consultations/$consultationId/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'reason': reason}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error cancelling consultation: $e');
      return false;
    }
  }

  /// Start a consultation call
  static Future<String?> startCall(String consultationId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;
      
      final response = await http.post(
        Uri.parse('$baseUrl/consultations/$consultationId/start'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['meeting_link'];
      }
      
      return null;
    } catch (e) {
      print('Error starting call: $e');
      return null;
    }
  }

  /// Complete a consultation
  static Future<bool> completeConsultation(String consultationId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;
      
      final response = await http.post(
        Uri.parse('$baseUrl/consultations/$consultationId/complete'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error completing consultation: $e');
      return false;
    }
  }

  /// Add review for a consultation
  static Future<bool> addReview({
    required String consultationId,
    required int rating,
    String? comment,
    required bool wasHelpful,
    required bool wouldRecommend,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;
      
      final response = await http.post(
        Uri.parse('$baseUrl/consultations/$consultationId/review'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'rating': rating,
          'comment': comment,
          'was_helpful': wasHelpful,
          'would_recommend': wouldRecommend,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error adding review: $e');
      return false;
    }
  }

  // ==================== MOCK DATA ====================

  static List<Expert> _getMockExperts() {
    return [
      Expert(
        id: '1',
        name: 'Dr. Rajesh Sharma',
        specialization: 'Crop Disease',
        qualification: 'PhD in Plant Pathology',
        experienceYears: 15,
        rating: 4.8,
        reviewCount: 245,
        totalConsultations: 1200,
        isOnline: true,
        isVerified: true,
        bio: 'Expert in diagnosing and treating crop diseases with 15 years of experience in agricultural research. Specialized in rice, wheat, and cotton diseases.',
        expertiseAreas: ['Crop Disease', 'Plant Pathology', 'Pest Control', 'Organic Farming'],
        languages: ['Hindi', 'English', 'Marathi'],
        consultationFee: 300,
        responseTimeMinutes: 15,
      ),
      Expert(
        id: '2',
        name: 'Dr. Priya Patel',
        specialization: 'Soil Health',
        qualification: 'MSc in Soil Science',
        experienceYears: 10,
        rating: 4.6,
        reviewCount: 189,
        totalConsultations: 850,
        isOnline: true,
        isVerified: true,
        bio: 'Soil health specialist helping farmers optimize their soil for maximum yield. Expert in soil testing and nutrient management.',
        expertiseAreas: ['Soil Health', 'Nutrient Management', 'Composting', 'Water Conservation'],
        languages: ['Hindi', 'English', 'Gujarati'],
        consultationFee: 250,
        responseTimeMinutes: 20,
      ),
      Expert(
        id: '3',
        name: 'Kisan Expert Amit',
        specialization: 'Irrigation',
        qualification: 'BTech in Agricultural Engineering',
        experienceYears: 8,
        rating: 4.5,
        reviewCount: 156,
        totalConsultations: 620,
        isOnline: false,
        isVerified: true,
        bio: 'Irrigation and water management expert. Helps farmers design efficient irrigation systems for water conservation.',
        expertiseAreas: ['Irrigation', 'Drip Systems', 'Water Management', 'Farm Mechanization'],
        languages: ['Hindi', 'English'],
        consultationFee: 200,
        responseTimeMinutes: 30,
      ),
      Expert(
        id: '4',
        name: 'Dr. Sunita Devi',
        specialization: 'Organic Farming',
        qualification: 'PhD in Organic Agriculture',
        experienceYears: 12,
        rating: 4.9,
        reviewCount: 312,
        totalConsultations: 1500,
        isOnline: true,
        isVerified: true,
        bio: 'Pioneer in organic farming practices. Helping farmers transition to sustainable and chemical-free agriculture.',
        expertiseAreas: ['Organic Farming', 'Natural Pesticides', 'Composting', 'Certification'],
        languages: ['Hindi', 'English', 'Telugu'],
        consultationFee: 350,
        responseTimeMinutes: 10,
      ),
      Expert(
        id: '5',
        name: 'Agronomist Vikram Singh',
        specialization: 'Crop Planning',
        qualification: 'MSc in Agronomy',
        experienceYears: 7,
        rating: 4.4,
        reviewCount: 98,
        totalConsultations: 420,
        isOnline: true,
        isVerified: false,
        bio: 'Crop planning and rotation specialist. Helps farmers maximize yield through scientific crop selection and planning.',
        expertiseAreas: ['Crop Planning', 'Seed Selection', 'Rotation', 'Market Analysis'],
        languages: ['Hindi', 'English', 'Punjabi'],
        consultationFee: 180,
        responseTimeMinutes: 25,
      ),
    ];
  }

  static List<TimeSlot> _getMockTimeSlots(DateTime date) {
    final slots = <TimeSlot>[];
    final baseDate = DateTime(date.year, date.month, date.day);
    
    for (int hour = 9; hour <= 18; hour++) {
      if (hour != 13) { // Skip lunch hour
        slots.add(TimeSlot(
          id: '${baseDate.toIso8601String()}_$hour',
          startTime: baseDate.add(Duration(hours: hour)),
          endTime: baseDate.add(Duration(hours: hour, minutes: 30)),
          isAvailable: hour % 3 != 0, // Some slots unavailable for demo
        ));
      }
    }
    
    return slots;
  }

  static List<Consultation> _getMockConsultations() {
    final now = DateTime.now();
    return [
      Consultation(
        id: 'c1',
        farmerId: 'f1',
        expertId: '1',
        expertName: 'Dr. Rajesh Sharma',
        expertSpecialization: 'Crop Disease',
        scheduledAt: now.add(const Duration(days: 2, hours: 10)),
        type: ConsultationType.video,
        status: ConsultationStatus.confirmed,
        fee: 300,
        issueDescription: 'My cotton crop has developed yellow spots on leaves',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Consultation(
        id: 'c2',
        farmerId: 'f1',
        expertId: '2',
        expertName: 'Dr. Priya Patel',
        expertSpecialization: 'Soil Health',
        scheduledAt: now.subtract(const Duration(days: 5)),
        type: ConsultationType.audio,
        status: ConsultationStatus.completed,
        fee: 250,
        issueDescription: 'Need advice on improving soil fertility',
        expertNotes: 'Recommended adding organic compost and performing soil pH test.',
        recommendations: ['Add organic compost', 'Test soil pH', 'Use green manure crops'],
        createdAt: now.subtract(const Duration(days: 7)),
        completedAt: now.subtract(const Duration(days: 5)),
      ),
      Consultation(
        id: 'c3',
        farmerId: 'f1',
        expertId: '4',
        expertName: 'Dr. Sunita Devi',
        expertSpecialization: 'Organic Farming',
        scheduledAt: now.subtract(const Duration(days: 10)),
        type: ConsultationType.video,
        status: ConsultationStatus.cancelled,
        fee: 350,
        issueDescription: 'Want to transition to organic farming',
        createdAt: now.subtract(const Duration(days: 12)),
      ),
    ];
  }
}
