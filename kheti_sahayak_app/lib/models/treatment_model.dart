/// Treatment Model for Crop Disease Treatments
///
/// Represents a treatment recommendation for a crop disease
/// including organic, chemical, and cultural treatment options

class TreatmentModel {
  final int id;
  final int diseaseId;
  final String treatmentType;
  final String treatmentName;
  final String? activeIngredient;
  final String? dosage;
  final String? applicationMethod;
  final String? timing;
  final String? frequency;
  final String? precautions;
  final int? effectivenessRating;
  final String? costEstimate;
  final String? availability;
  final String? notes;

  TreatmentModel({
    required this.id,
    required this.diseaseId,
    required this.treatmentType,
    required this.treatmentName,
    this.activeIngredient,
    this.dosage,
    this.applicationMethod,
    this.timing,
    this.frequency,
    this.precautions,
    this.effectivenessRating,
    this.costEstimate,
    this.availability,
    this.notes,
  });

  factory TreatmentModel.fromJson(Map<String, dynamic> json) {
    return TreatmentModel(
      id: json['id'] as int,
      diseaseId: json['disease_id'] as int,
      treatmentType: json['treatment_type'] as String,
      treatmentName: json['treatment_name'] as String,
      activeIngredient: json['active_ingredient'] as String?,
      dosage: json['dosage'] as String?,
      applicationMethod: json['application_method'] as String?,
      timing: json['timing'] as String?,
      frequency: json['frequency'] as String?,
      precautions: json['precautions'] as String?,
      effectivenessRating: json['effectiveness_rating'] as int?,
      costEstimate: json['cost_estimate'] as String?,
      availability: json['availability'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'disease_id': diseaseId,
      'treatment_type': treatmentType,
      'treatment_name': treatmentName,
      'active_ingredient': activeIngredient,
      'dosage': dosage,
      'application_method': applicationMethod,
      'timing': timing,
      'frequency': frequency,
      'precautions': precautions,
      'effectiveness_rating': effectivenessRating,
      'cost_estimate': costEstimate,
      'availability': availability,
      'notes': notes,
    };
  }

  /// Get treatment type icon based on type
  String get typeIcon {
    switch (treatmentType.toLowerCase()) {
      case 'organic':
        return '🌱';
      case 'chemical':
        return '⚗️';
      case 'cultural':
        return '🌾';
      case 'biological':
        return '🐞';
      default:
        return '💊';
    }
  }

  /// Get availability color based on availability status
  String get availabilityColor {
    switch (availability?.toLowerCase()) {
      case 'easily_available':
        return '#4CAF50'; // Green
      case 'locally_available':
        return '#FF9800'; // Orange
      case 'requires_order':
        return '#F44336'; // Red
      default:
        return '#9E9E9E'; // Grey
    }
  }

  /// Get user-friendly availability text
  String get availabilityText {
    switch (availability?.toLowerCase()) {
      case 'easily_available':
        return 'आसानी से उपलब्ध (Easily Available)';
      case 'locally_available':
        return 'स्थानीय रूप से उपलब्ध (Locally Available)';
      case 'requires_order':
        return 'ऑर्डर की आवश्यकता (Requires Order)';
      default:
        return 'उपलब्धता अज्ञात (Unknown)';
    }
  }
}

/// Disease Information Model
class DiseaseInfo {
  final int id;
  final String name;
  final String? scientificName;
  final String? cropType;
  final String? description;
  final String? symptoms;
  final String? causes;
  final String? prevention;
  final String? severity;

  DiseaseInfo({
    required this.id,
    required this.name,
    this.scientificName,
    this.cropType,
    this.description,
    this.symptoms,
    this.causes,
    this.prevention,
    this.severity,
  });

  factory DiseaseInfo.fromJson(Map<String, dynamic> json) {
    return DiseaseInfo(
      id: json['id'] as int,
      name: json['disease_name'] ?? json['name'] as String,
      scientificName: json['scientific_name'] as String?,
      cropType: json['crop_type'] as String?,
      description: json['description'] as String?,
      symptoms: json['symptoms'] as String?,
      causes: json['causes'] as String?,
      prevention: json['prevention'] as String?,
      severity: json['severity'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'disease_name': name,
      'scientific_name': scientificName,
      'crop_type': cropType,
      'description': description,
      'symptoms': symptoms,
      'causes': causes,
      'prevention': prevention,
      'severity': severity,
    };
  }
}

/// Complete treatment recommendations response
class TreatmentRecommendationsResponse {
  final bool success;
  final int diagnosticId;
  final DiseaseInfo disease;
  final List<TreatmentModel> treatments;

  TreatmentRecommendationsResponse({
    required this.success,
    required this.diagnosticId,
    required this.disease,
    required this.treatments,
  });

  factory TreatmentRecommendationsResponse.fromJson(Map<String, dynamic> json) {
    return TreatmentRecommendationsResponse(
      success: json['success'] as bool? ?? true,
      diagnosticId: json['diagnostic_id'] as int,
      disease: DiseaseInfo.fromJson(json['disease'] as Map<String, dynamic>),
      treatments: (json['treatments'] as List<dynamic>)
          .map((item) => TreatmentModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Get treatments grouped by type
  Map<String, List<TreatmentModel>> get treatmentsByType {
    final Map<String, List<TreatmentModel>> grouped = {};
    for (var treatment in treatments) {
      grouped.putIfAbsent(treatment.treatmentType, () => []).add(treatment);
    }
    return grouped;
  }

  /// Get organic treatments
  List<TreatmentModel> get organicTreatments {
    return treatments.where((t) => t.treatmentType.toLowerCase() == 'organic').toList();
  }

  /// Get chemical treatments
  List<TreatmentModel> get chemicalTreatments {
    return treatments.where((t) => t.treatmentType.toLowerCase() == 'chemical').toList();
  }

  /// Get most effective treatment
  TreatmentModel? get mostEffectiveTreatment {
    if (treatments.isEmpty) return null;
    return treatments.reduce((a, b) =>
      (a.effectivenessRating ?? 0) > (b.effectivenessRating ?? 0) ? a : b
    );
  }
}
