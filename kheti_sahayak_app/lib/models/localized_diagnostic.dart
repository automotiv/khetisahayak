/// Localized diagnostic models for multilingual disease detection reports
/// Supports offline translation for: Hindi, Marathi, Tamil, Kannada, Telugu, Gujarati

/// Localized disease information with translations
class LocalizedDisease {
  final int id;
  final String diseaseKey;
  final Map<String, String> names;
  final Map<String, String> descriptions;
  final Map<String, String> symptoms;
  final Map<String, String> causes;
  final Map<String, String> prevention;
  final String severity;
  final List<String> affectedCrops;

  LocalizedDisease({
    required this.id,
    required this.diseaseKey,
    required this.names,
    this.descriptions = const {},
    this.symptoms = const {},
    this.causes = const {},
    this.prevention = const {},
    this.severity = 'medium',
    this.affectedCrops = const [],
  });

  /// Get localized name for the specified language code
  String getName(String languageCode) {
    return names[languageCode] ?? names['en'] ?? diseaseKey;
  }

  /// Get localized description
  String getDescription(String languageCode) {
    return descriptions[languageCode] ?? descriptions['en'] ?? '';
  }

  /// Get localized symptoms
  String getSymptoms(String languageCode) {
    return symptoms[languageCode] ?? symptoms['en'] ?? '';
  }

  /// Get localized causes
  String getCauses(String languageCode) {
    return causes[languageCode] ?? causes['en'] ?? '';
  }

  /// Get localized prevention
  String getPrevention(String languageCode) {
    return prevention[languageCode] ?? prevention['en'] ?? '';
  }

  factory LocalizedDisease.fromJson(Map<String, dynamic> json) {
    return LocalizedDisease(
      id: json['id'] ?? 0,
      diseaseKey: json['disease_key'] ?? '',
      names: Map<String, String>.from(json['names'] ?? {}),
      descriptions: Map<String, String>.from(json['descriptions'] ?? {}),
      symptoms: Map<String, String>.from(json['symptoms'] ?? {}),
      causes: Map<String, String>.from(json['causes'] ?? {}),
      prevention: Map<String, String>.from(json['prevention'] ?? {}),
      severity: json['severity'] ?? 'medium',
      affectedCrops: List<String>.from(json['affected_crops'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'disease_key': diseaseKey,
      'names': names,
      'descriptions': descriptions,
      'symptoms': symptoms,
      'causes': causes,
      'prevention': prevention,
      'severity': severity,
      'affected_crops': affectedCrops,
    };
  }
}

/// Localized treatment information with translations
class LocalizedTreatment {
  final int id;
  final String treatmentKey;
  final String treatmentType;
  final Map<String, String> names;
  final Map<String, String> descriptions;
  final Map<String, String> applicationMethods;
  final Map<String, String> dosages;
  final Map<String, String> timings;
  final Map<String, String> frequencies;
  final Map<String, String> precautions;
  final Map<String, String> notes;
  final String? activeIngredient;
  final String? costEstimate;
  final String? availability;
  final int? effectivenessRating;
  final List<String> relatedDiseases;

  LocalizedTreatment({
    required this.id,
    required this.treatmentKey,
    required this.treatmentType,
    required this.names,
    this.descriptions = const {},
    this.applicationMethods = const {},
    this.dosages = const {},
    this.timings = const {},
    this.frequencies = const {},
    this.precautions = const {},
    this.notes = const {},
    this.activeIngredient,
    this.costEstimate,
    this.availability,
    this.effectivenessRating,
    this.relatedDiseases = const [],
  });

  /// Get localized name
  String getName(String languageCode) {
    return names[languageCode] ?? names['en'] ?? treatmentKey;
  }

  /// Get localized description
  String getDescription(String languageCode) {
    return descriptions[languageCode] ?? descriptions['en'] ?? '';
  }

  /// Get localized application method
  String getApplicationMethod(String languageCode) {
    return applicationMethods[languageCode] ?? applicationMethods['en'] ?? '';
  }

  /// Get localized dosage
  String getDosage(String languageCode) {
    return dosages[languageCode] ?? dosages['en'] ?? '';
  }

  /// Get localized timing
  String getTiming(String languageCode) {
    return timings[languageCode] ?? timings['en'] ?? '';
  }

  /// Get localized frequency
  String getFrequency(String languageCode) {
    return frequencies[languageCode] ?? frequencies['en'] ?? '';
  }

  /// Get localized precautions
  String getPrecautions(String languageCode) {
    return precautions[languageCode] ?? precautions['en'] ?? '';
  }

  /// Get localized notes
  String getNotes(String languageCode) {
    return notes[languageCode] ?? notes['en'] ?? '';
  }

  /// Get localized treatment type display name
  String getTreatmentTypeDisplay(String languageCode) {
    return _treatmentTypeTranslations[treatmentType.toLowerCase()]?[languageCode] ??
        _treatmentTypeTranslations[treatmentType.toLowerCase()]?['en'] ??
        treatmentType;
  }

  /// Get localized availability display
  String getAvailabilityDisplay(String languageCode) {
    if (availability == null) return '';
    return _availabilityTranslations[availability!.toLowerCase()]?[languageCode] ??
        _availabilityTranslations[availability!.toLowerCase()]?['en'] ??
        availability!;
  }

  factory LocalizedTreatment.fromJson(Map<String, dynamic> json) {
    return LocalizedTreatment(
      id: json['id'] ?? 0,
      treatmentKey: json['treatment_key'] ?? '',
      treatmentType: json['treatment_type'] ?? 'general',
      names: Map<String, String>.from(json['names'] ?? {}),
      descriptions: Map<String, String>.from(json['descriptions'] ?? {}),
      applicationMethods: Map<String, String>.from(json['application_methods'] ?? {}),
      dosages: Map<String, String>.from(json['dosages'] ?? {}),
      timings: Map<String, String>.from(json['timings'] ?? {}),
      frequencies: Map<String, String>.from(json['frequencies'] ?? {}),
      precautions: Map<String, String>.from(json['precautions'] ?? {}),
      notes: Map<String, String>.from(json['notes'] ?? {}),
      activeIngredient: json['active_ingredient'],
      costEstimate: json['cost_estimate'],
      availability: json['availability'],
      effectivenessRating: json['effectiveness_rating'],
      relatedDiseases: List<String>.from(json['related_diseases'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'treatment_key': treatmentKey,
      'treatment_type': treatmentType,
      'names': names,
      'descriptions': descriptions,
      'application_methods': applicationMethods,
      'dosages': dosages,
      'timings': timings,
      'frequencies': frequencies,
      'precautions': precautions,
      'notes': notes,
      'active_ingredient': activeIngredient,
      'cost_estimate': costEstimate,
      'availability': availability,
      'effectiveness_rating': effectivenessRating,
      'related_diseases': relatedDiseases,
    };
  }

  /// Static translations for treatment types
  static const Map<String, Map<String, String>> _treatmentTypeTranslations = {
    'organic': {
      'en': 'Organic',
      'hi': 'जैविक',
      'mr': 'सेंद्रिय',
      'ta': 'இயற்கை',
      'kn': 'ಸಾವಯವ',
      'te': 'సేంద్రీయ',
      'gu': 'જૈવિક',
    },
    'chemical': {
      'en': 'Chemical',
      'hi': 'रासायनिक',
      'mr': 'रासायनिक',
      'ta': 'இரசாயன',
      'kn': 'ರಾಸಾಯನಿಕ',
      'te': 'రసాయన',
      'gu': 'રાસાયણિક',
    },
    'cultural': {
      'en': 'Cultural Practice',
      'hi': 'कृषि पद्धति',
      'mr': 'कृषी पद्धती',
      'ta': 'பண்பாட்டு முறை',
      'kn': 'ಸಾಂಸ್ಕೃತಿಕ ಅಭ್ಯಾಸ',
      'te': 'సాంస్కృతిక అభ్యాసం',
      'gu': 'ખેતી પદ્ધતિ',
    },
    'biological': {
      'en': 'Biological',
      'hi': 'जैविक नियंत्रण',
      'mr': 'जैविक नियंत्रण',
      'ta': 'உயிரியல்',
      'kn': 'ಜೈವಿಕ',
      'te': 'జీవ',
      'gu': 'જૈવિક નિયંત્રણ',
    },
  };

  /// Static translations for availability
  static const Map<String, Map<String, String>> _availabilityTranslations = {
    'easily_available': {
      'en': 'Easily Available',
      'hi': 'आसानी से उपलब्ध',
      'mr': 'सहज उपलब्ध',
      'ta': 'எளிதில் கிடைக்கும்',
      'kn': 'ಸುಲಭವಾಗಿ ಲಭ್ಯ',
      'te': 'సులభంగా అందుబాటులో',
      'gu': 'સહેલાઈથી ઉપલબ્ધ',
    },
    'locally_available': {
      'en': 'Locally Available',
      'hi': 'स्थानीय रूप से उपलब्ध',
      'mr': 'स्थानिक उपलब्ध',
      'ta': 'உள்ளூரில் கிடைக்கும்',
      'kn': 'ಸ್ಥಳೀಯವಾಗಿ ಲಭ್ಯ',
      'te': 'స్థానికంగా అందుబాటులో',
      'gu': 'સ્થાનિક ઉપલબ્ધ',
    },
    'requires_order': {
      'en': 'Requires Order',
      'hi': 'ऑर्डर आवश्यक',
      'mr': 'ऑर्डर आवश्यक',
      'ta': 'ஆர்டர் செய்ய வேண்டும்',
      'kn': 'ಆರ್ಡರ್ ಅಗತ್ಯ',
      'te': 'ఆర్డర్ అవసరం',
      'gu': 'ઓર્ડર જરૂરી',
    },
  };
}

/// Localized diagnostic result combining disease and treatments
class LocalizedDiagnosticResult {
  final String diagnosticId;
  final LocalizedDisease? disease;
  final List<LocalizedTreatment> treatments;
  final double? confidenceScore;
  final String cropType;
  final DateTime analyzedAt;

  LocalizedDiagnosticResult({
    required this.diagnosticId,
    this.disease,
    this.treatments = const [],
    this.confidenceScore,
    required this.cropType,
    required this.analyzedAt,
  });

  /// Get treatments by type
  List<LocalizedTreatment> getTreatmentsByType(String type) {
    return treatments
        .where((t) => t.treatmentType.toLowerCase() == type.toLowerCase())
        .toList();
  }

  /// Get organic treatments
  List<LocalizedTreatment> get organicTreatments =>
      getTreatmentsByType('organic');

  /// Get chemical treatments
  List<LocalizedTreatment> get chemicalTreatments =>
      getTreatmentsByType('chemical');

  /// Get cultural treatments
  List<LocalizedTreatment> get culturalTreatments =>
      getTreatmentsByType('cultural');

  /// Get biological treatments
  List<LocalizedTreatment> get biologicalTreatments =>
      getTreatmentsByType('biological');

  factory LocalizedDiagnosticResult.fromJson(Map<String, dynamic> json) {
    return LocalizedDiagnosticResult(
      diagnosticId: json['diagnostic_id'] ?? '',
      disease: json['disease'] != null
          ? LocalizedDisease.fromJson(json['disease'])
          : null,
      treatments: (json['treatments'] as List<dynamic>?)
              ?.map((t) => LocalizedTreatment.fromJson(t))
              .toList() ??
          [],
      confidenceScore: json['confidence_score']?.toDouble(),
      cropType: json['crop_type'] ?? '',
      analyzedAt: json['analyzed_at'] != null
          ? DateTime.parse(json['analyzed_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'diagnostic_id': diagnosticId,
      'disease': disease?.toJson(),
      'treatments': treatments.map((t) => t.toJson()).toList(),
      'confidence_score': confidenceScore,
      'crop_type': cropType,
      'analyzed_at': analyzedAt.toIso8601String(),
    };
  }
}

/// Common diagnostic UI strings translations
class DiagnosticStrings {
  static const Map<String, Map<String, String>> strings = {
    'analysis_results': {
      'en': 'Analysis Results',
      'hi': 'विश्लेषण परिणाम',
      'mr': 'विश्लेषण निकाल',
      'ta': 'பகுப்பாய்வு முடிவுகள்',
      'kn': 'ವಿಶ್ಲೇಷಣೆ ಫಲಿತಾಂಶಗಳು',
      'te': 'విశ్లేషణ ఫలితాలు',
      'gu': 'વિશ્લેષણ પરિણામો',
    },
    'disease_detected': {
      'en': 'Disease Detected',
      'hi': 'रोग का पता चला',
      'mr': 'रोग आढळला',
      'ta': 'நோய் கண்டறியப்பட்டது',
      'kn': 'ರೋಗ ಪತ್ತೆಯಾಗಿದೆ',
      'te': 'వ్యాధి గుర్తించబడింది',
      'gu': 'રોગ મળી આવ્યો',
    },
    'healthy_crop': {
      'en': 'Healthy Crop',
      'hi': 'स्वस्थ फसल',
      'mr': 'निरोगी पीक',
      'ta': 'ஆரோக்கியமான பயிர்',
      'kn': 'ಆರೋಗ್ಯಕರ ಬೆಳೆ',
      'te': 'ఆరోగ్యకరమైన పంట',
      'gu': 'તંદુરસ્ત પાક',
    },
    'confidence': {
      'en': 'Confidence',
      'hi': 'विश्वसनीयता',
      'mr': 'विश्वासार्हता',
      'ta': 'நம்பகத்தன்மை',
      'kn': 'ವಿಶ್ವಾಸಾರ್ಹತೆ',
      'te': 'విశ్వసనీయత',
      'gu': 'વિશ્વસનીયતા',
    },
    'symptoms': {
      'en': 'Symptoms',
      'hi': 'लक्षण',
      'mr': 'लक्षणे',
      'ta': 'அறிகுறிகள்',
      'kn': 'ರೋಗ ಲಕ್ಷಣಗಳು',
      'te': 'లక్షణాలు',
      'gu': 'લક્ષણો',
    },
    'causes': {
      'en': 'Causes',
      'hi': 'कारण',
      'mr': 'कारणे',
      'ta': 'காரணங்கள்',
      'kn': 'ಕಾರಣಗಳು',
      'te': 'కారణాలు',
      'gu': 'કારણો',
    },
    'prevention': {
      'en': 'Prevention',
      'hi': 'रोकथाम',
      'mr': 'प्रतिबंध',
      'ta': 'தடுப்பு',
      'kn': 'ತಡೆಗಟ್ಟುವಿಕೆ',
      'te': 'నివారణ',
      'gu': 'નિવારણ',
    },
    'treatment_recommendations': {
      'en': 'Treatment Recommendations',
      'hi': 'उपचार सिफारिशें',
      'mr': 'उपचार शिफारसी',
      'ta': 'சிகிச்சை பரிந்துரைகள்',
      'kn': 'ಚಿಕಿತ್ಸೆ ಶಿಫಾರಸುಗಳು',
      'te': 'చికిత్స సిఫార్సులు',
      'gu': 'સારવાર ભલામણો',
    },
    'active_ingredient': {
      'en': 'Active Ingredient',
      'hi': 'सक्रिय तत्व',
      'mr': 'सक्रिय घटक',
      'ta': 'செயலில் உள்ள பொருள்',
      'kn': 'ಸಕ್ರಿಯ ಘಟಕ',
      'te': 'సక్రియ పదార్ధం',
      'gu': 'સક્રિય ઘટક',
    },
    'dosage': {
      'en': 'Dosage',
      'hi': 'खुराक',
      'mr': 'डोस',
      'ta': 'அளவு',
      'kn': 'ಪ್ರಮಾಣ',
      'te': 'మోతాదు',
      'gu': 'માત્રા',
    },
    'application_method': {
      'en': 'Application Method',
      'hi': 'उपयोग विधि',
      'mr': 'वापर पद्धत',
      'ta': 'பயன்படுத்தும் முறை',
      'kn': 'ಬಳಸುವ ವಿಧಾನ',
      'te': 'వాడే పద్ధతి',
      'gu': 'વાપરવાની રીત',
    },
    'timing': {
      'en': 'Timing',
      'hi': 'समय',
      'mr': 'वेळ',
      'ta': 'நேரம்',
      'kn': 'ಸಮಯ',
      'te': 'సమయం',
      'gu': 'સમય',
    },
    'frequency': {
      'en': 'Frequency',
      'hi': 'आवृत्ति',
      'mr': 'वारंवारता',
      'ta': 'அதிர்வெண்',
      'kn': 'ಆವರ್ತನ',
      'te': 'పునరావృతం',
      'gu': 'આવૃત્તિ',
    },
    'precautions': {
      'en': 'Precautions',
      'hi': 'सावधानियां',
      'mr': 'सावधगिरी',
      'ta': 'முன்னெச்சரிக்கைகள்',
      'kn': 'ಮುನ್ನೆಚ್ಚರಿಕೆಗಳು',
      'te': 'జాగ్రత్తలు',
      'gu': 'સાવધાનીઓ',
    },
    'notes': {
      'en': 'Notes',
      'hi': 'टिप्पणियां',
      'mr': 'टिपा',
      'ta': 'குறிப்புகள்',
      'kn': 'ಟಿಪ್ಪಣಿಗಳು',
      'te': 'గమనికలు',
      'gu': 'નોંધ',
    },
    'availability': {
      'en': 'Availability',
      'hi': 'उपलब्धता',
      'mr': 'उपलब्धता',
      'ta': 'கிடைக்கும் தன்மை',
      'kn': 'ಲಭ್ಯತೆ',
      'te': 'లభ్యత',
      'gu': 'ઉપલબ્ધતા',
    },
    'cost_estimate': {
      'en': 'Cost Estimate',
      'hi': 'अनुमानित लागत',
      'mr': 'अंदाजे खर्च',
      'ta': 'செலவு மதிப்பீடு',
      'kn': 'ವೆಚ್ಚದ ಅಂದಾಜು',
      'te': 'ఖర్చు అంచనా',
      'gu': 'અંદાજિત ખર્ચ',
    },
    'effectiveness': {
      'en': 'Effectiveness',
      'hi': 'प्रभावशीलता',
      'mr': 'परिणामकारकता',
      'ta': 'செயல்திறன்',
      'kn': 'ಪರಿಣಾಮಕಾರಿತ್ವ',
      'te': 'సమర్థత',
      'gu': 'અસરકારકતા',
    },
    'view_treatment_details': {
      'en': 'View Treatment Details',
      'hi': 'उपचार विवरण देखें',
      'mr': 'उपचार तपशील पहा',
      'ta': 'சிகிச்சை விவரங்களைக் காண்க',
      'kn': 'ಚಿಕಿತ್ಸೆ ವಿವರಗಳನ್ನು ನೋಡಿ',
      'te': 'చికిత్స వివరాలు చూడండి',
      'gu': 'સારવાર વિગતો જુઓ',
    },
    'all': {
      'en': 'All',
      'hi': 'सभी',
      'mr': 'सर्व',
      'ta': 'அனைத்தும்',
      'kn': 'ಎಲ್ಲಾ',
      'te': 'అన్నీ',
      'gu': 'બધું',
    },
    'no_treatments_available': {
      'en': 'No treatments available',
      'hi': 'कोई उपचार उपलब्ध नहीं',
      'mr': 'उपचार उपलब्ध नाही',
      'ta': 'சிகிச்சைகள் இல்லை',
      'kn': 'ಚಿಕಿತ್ಸೆಗಳು ಲಭ್ಯವಿಲ್ಲ',
      'te': 'చికిత్సలు అందుబాటులో లేవు',
      'gu': 'સારવાર ઉપલબ્ધ નથી',
    },
    'severity': {
      'en': 'Severity',
      'hi': 'गंभीरता',
      'mr': 'तीव्रता',
      'ta': 'தீவிரம்',
      'kn': 'ತೀವ್ರತೆ',
      'te': 'తీవ్రత',
      'gu': 'તીવ્રતા',
    },
    'high': {
      'en': 'High',
      'hi': 'उच्च',
      'mr': 'उच्च',
      'ta': 'அதிக',
      'kn': 'ಹೆಚ್ಚು',
      'te': 'అధిక',
      'gu': 'ઊંચી',
    },
    'medium': {
      'en': 'Medium',
      'hi': 'मध्यम',
      'mr': 'मध्यम',
      'ta': 'நடுத்தர',
      'kn': 'ಮಧ್ಯಮ',
      'te': 'మధ్యస్థ',
      'gu': 'મધ્યમ',
    },
    'low': {
      'en': 'Low',
      'hi': 'कम',
      'mr': 'कमी',
      'ta': 'குறைவு',
      'kn': 'ಕಡಿಮೆ',
      'te': 'తక్కువ',
      'gu': 'ઓછી',
    },
    'ask_expert': {
      'en': 'Ask Expert',
      'hi': 'विशेषज्ञ से पूछें',
      'mr': 'तज्ञांना विचारा',
      'ta': 'நிபுணரிடம் கேளுங்கள்',
      'kn': 'ತಜ್ಞರನ್ನು ಕೇಳಿ',
      'te': 'నిపుణుడిని అడగండి',
      'gu': 'નિષ્ણાતને પૂછો',
    },
    'buy_treatment': {
      'en': 'Buy Treatment',
      'hi': 'उपचार खरीदें',
      'mr': 'उपचार खरेदी करा',
      'ta': 'சிகிச்சை வாங்குங்கள்',
      'kn': 'ಚಿಕಿತ್ಸೆ ಖರೀದಿಸಿ',
      'te': 'చికిత్స కొనండి',
      'gu': 'સારવાર ખરીદો',
    },
  };

  /// Get localized string
  static String get(String key, String languageCode) {
    return strings[key]?[languageCode] ?? strings[key]?['en'] ?? key;
  }
}
