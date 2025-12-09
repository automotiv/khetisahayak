import 'package:kheti_sahayak_app/models/scheme.dart';
import 'package:kheti_sahayak_app/models/user.dart';
import 'package:kheti_sahayak_app/models/field.dart';

enum EligibilityStatus {
  eligible,
  notEligible,
  uncertain,
}

class EligibilityResult {
  final EligibilityStatus status;
  final double confidence;
  final List<String> missingCriteria;
  final List<String> suggestions;

  EligibilityResult({
    required this.status,
    required this.confidence,
    this.missingCriteria = const [],
    this.suggestions = const [],
  });
}

class EligibilityService {
  static EligibilityResult checkEligibility(
    Scheme scheme,
    User? user,
    List<Field> fields,
  ) {
    if (user == null) {
      return EligibilityResult(
        status: EligibilityStatus.uncertain,
        confidence: 0.0,
        suggestions: ['Please log in to check eligibility.'],
      );
    }

    final criteria = scheme.eligibilityCriteria;
    if (criteria.isEmpty) {
      // If no structured criteria, we can't automatically evaluate
      return EligibilityResult(
        status: EligibilityStatus.uncertain,
        confidence: 0.5,
        suggestions: ['Please read the eligibility details manually.'],
      );
    }

    final missingCriteria = <String>[];
    final suggestions = <String>[];
    bool isEligible = true;

    // 1. Check Land Area
    if (criteria.containsKey('min_land_area')) {
      final minArea = criteria['min_land_area'] as num;
      final totalArea = fields.fold<double>(0, (sum, field) => sum + field.area);
      
      if (totalArea < minArea) {
        isEligible = false;
        missingCriteria.add('Minimum land area required: $minArea acres (You have ${totalArea.toStringAsFixed(1)} acres)');
        suggestions.add('This scheme requires a larger land holding.');
      }
    }

    if (criteria.containsKey('max_land_area')) {
      final maxArea = criteria['max_land_area'] as num;
      final totalArea = fields.fold<double>(0, (sum, field) => sum + field.area);
      
      if (totalArea > maxArea) {
        isEligible = false;
        missingCriteria.add('Maximum land area allowed: $maxArea acres (You have ${totalArea.toStringAsFixed(1)} acres)');
        suggestions.add('This scheme is for small/marginal farmers.');
      }
    }

    // 2. Check Crop Type
    if (criteria.containsKey('allowed_crops')) {
      final allowedCrops = (criteria['allowed_crops'] as List).map((e) => e.toString().toLowerCase()).toList();
      final userCrops = fields.map((f) => f.cropType.toLowerCase()).toSet();
      
      final hasAllowedCrop = userCrops.any((crop) => allowedCrops.contains(crop));
      
      if (!hasAllowedCrop) {
        isEligible = false;
        missingCriteria.add('Required crops: ${allowedCrops.join(", ")}');
        suggestions.add('Consider diversifying your crops to include eligible varieties.');
      }
    }

    // 3. Check Location (State/District) - Mock logic as User model has simple address string
    if (criteria.containsKey('allowed_states')) {
      final allowedStates = (criteria['allowed_states'] as List).map((e) => e.toString().toLowerCase()).toList();
      // Simple check if address contains state name
      final userAddress = (user.address ?? '').toLowerCase();
      final isInAllowedState = allowedStates.any((state) => userAddress.contains(state));
      
      if (!isInAllowedState && userAddress.isNotEmpty) {
        isEligible = false;
        missingCriteria.add('Eligible states: ${allowedStates.join(", ")}');
        suggestions.add('This scheme is not available in your region.');
      } else if (userAddress.isEmpty) {
         // Uncertain if address is missing
         missingCriteria.add('Location check failed (Address missing)');
         suggestions.add('Update your profile with your full address.');
         return EligibilityResult(
           status: EligibilityStatus.uncertain,
           confidence: 0.4,
           missingCriteria: missingCriteria,
           suggestions: suggestions,
         );
      }
    }

    return EligibilityResult(
      status: isEligible ? EligibilityStatus.eligible : EligibilityStatus.notEligible,
      confidence: 1.0, // High confidence as we checked against data
      missingCriteria: missingCriteria,
      suggestions: suggestions,
    );
  }
  
  // Helper to get color for status
  static int getStatusColor(EligibilityStatus status) {
    switch (status) {
      case EligibilityStatus.eligible:
        return 0xFF4CAF50; // Green
      case EligibilityStatus.notEligible:
        return 0xFFF44336; // Red
      case EligibilityStatus.uncertain:
        return 0xFFFFC107; // Amber
    }
  }
  
  // Helper to get text for status
  static String getStatusText(EligibilityStatus status) {
    switch (status) {
      case EligibilityStatus.eligible:
        return 'Eligible';
      case EligibilityStatus.notEligible:
        return 'Not Eligible';
      case EligibilityStatus.uncertain:
        return 'Check Eligibility';
    }
  }
}
