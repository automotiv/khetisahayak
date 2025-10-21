class Disease {
  final int id;
  final String name;
  final String? symptoms;
  final String? prevention;

  Disease({
    required this.id,
    required this.name,
    this.symptoms,
    this.prevention,
  });

  factory Disease.fromJson(Map<String, dynamic> json) {
    return Disease(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown Disease',
      symptoms: json['symptoms'],
      prevention: json['prevention'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'symptoms': symptoms,
      'prevention': prevention,
    };
  }
}

class Treatment {
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
  final DateTime createdAt;

  Treatment({
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
    required this.createdAt,
  });

  factory Treatment.fromJson(Map<String, dynamic> json) {
    return Treatment(
      id: json['id'] ?? 0,
      diseaseId: json['disease_id'] ?? 0,
      treatmentType: json['treatment_type'] ?? '',
      treatmentName: json['treatment_name'] ?? '',
      activeIngredient: json['active_ingredient'],
      dosage: json['dosage'],
      applicationMethod: json['application_method'],
      timing: json['timing'],
      frequency: json['frequency'],
      precautions: json['precautions'],
      effectivenessRating: json['effectiveness_rating'],
      costEstimate: json['cost_estimate'],
      availability: json['availability'],
      notes: json['notes'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
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
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper method to get treatment type display name
  String get treatmentTypeDisplay {
    switch (treatmentType.toLowerCase()) {
      case 'organic':
        return 'Organic';
      case 'chemical':
        return 'Chemical';
      case 'cultural':
        return 'Cultural Practice';
      case 'biological':
        return 'Biological';
      default:
        return treatmentType;
    }
  }

  // Helper method to get availability display
  String get availabilityDisplay {
    switch (availability?.toLowerCase()) {
      case 'easily_available':
        return 'Easily Available';
      case 'locally_available':
        return 'Locally Available';
      case 'requires_order':
        return 'Requires Order';
      default:
        return availability ?? 'Unknown';
    }
  }

  // Helper method to get effectiveness stars
  String get effectivenessStars {
    if (effectivenessRating == null) return '';
    return '⭐' * effectivenessRating!;
  }
}

class TreatmentResponse {
  final bool success;
  final int diagnosticId;
  final Disease? disease;
  final List<Treatment> treatments;
  final String? message;

  TreatmentResponse({
    required this.success,
    required this.diagnosticId,
    this.disease,
    required this.treatments,
    this.message,
  });

  factory TreatmentResponse.fromJson(Map<String, dynamic> json) {
    return TreatmentResponse(
      success: json['success'] ?? false,
      diagnosticId: json['diagnostic_id'] ?? 0,
      disease: json['disease'] != null ? Disease.fromJson(json['disease']) : null,
      treatments: (json['treatments'] as List<dynamic>?)
              ?.map((t) => Treatment.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      message: json['message'],
    );
  }

  // Helper to get treatments by type
  List<Treatment> getTreatmentsByType(String type) {
    return treatments
        .where((t) => t.treatmentType.toLowerCase() == type.toLowerCase())
        .toList();
  }

  // Helper to get organic treatments
  List<Treatment> get organicTreatments => getTreatmentsByType('organic');

  // Helper to get chemical treatments
  List<Treatment> get chemicalTreatments => getTreatmentsByType('chemical');

  // Helper to get cultural treatments
  List<Treatment> get culturalTreatments => getTreatmentsByType('cultural');
}
