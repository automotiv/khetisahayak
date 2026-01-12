import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kheti_sahayak_app/models/localized_diagnostic.dart';
import 'package:kheti_sahayak_app/models/diagnostic.dart';
import 'package:kheti_sahayak_app/models/treatment.dart';

/// Service for managing offline diagnostic translations
/// Provides localized disease names, descriptions, and treatment recommendations
class DiagnosticTranslationService {
  static DiagnosticTranslationService? _instance;
  static DiagnosticTranslationService get instance {
    _instance ??= DiagnosticTranslationService._();
    return _instance!;
  }

  DiagnosticTranslationService._();

  bool _isInitialized = false;
  Map<String, LocalizedDisease> _diseases = {};
  Map<String, LocalizedTreatment> _treatments = {};

  /// Initialize the translation service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // First, try to load cached translations from SharedPreferences
      await _loadCachedTranslations();

      // If no cached data, load from bundled assets
      if (_diseases.isEmpty) {
        await _loadBundledTranslations();
      }

      _isInitialized = true;
    } catch (e) {
      print('Error initializing DiagnosticTranslationService: $e');
      // Load default translations if everything fails
      _loadDefaultTranslations();
      _isInitialized = true;
    }
  }

  /// Load translations from SharedPreferences cache
  Future<void> _loadCachedTranslations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final diseasesJson = prefs.getString('cached_disease_translations');
      final treatmentsJson = prefs.getString('cached_treatment_translations');

      if (diseasesJson != null) {
        final Map<String, dynamic> data = json.decode(diseasesJson);
        _diseases = data.map((key, value) =>
            MapEntry(key, LocalizedDisease.fromJson(value)));
      }

      if (treatmentsJson != null) {
        final Map<String, dynamic> data = json.decode(treatmentsJson);
        _treatments = data.map((key, value) =>
            MapEntry(key, LocalizedTreatment.fromJson(value)));
      }
    } catch (e) {
      print('Error loading cached translations: $e');
    }
  }

  /// Load translations from bundled asset files
  Future<void> _loadBundledTranslations() async {
    try {
      // Load from assets/translations/diseases.json
      final diseasesString = await rootBundle.loadString(
          'assets/translations/diseases.json');
      final Map<String, dynamic> diseasesData = json.decode(diseasesString);
      _diseases = diseasesData.map((key, value) =>
          MapEntry(key, LocalizedDisease.fromJson(value)));

      // Load from assets/translations/treatments.json
      final treatmentsString = await rootBundle.loadString(
          'assets/translations/treatments.json');
      final Map<String, dynamic> treatmentsData = json.decode(treatmentsString);
      _treatments = treatmentsData.map((key, value) =>
          MapEntry(key, LocalizedTreatment.fromJson(value)));

      // Cache the loaded translations
      await _cacheTranslations();
    } catch (e) {
      print('Error loading bundled translations: $e');
      // Load defaults if bundled files don't exist
      _loadDefaultTranslations();
    }
  }

  /// Cache translations to SharedPreferences
  Future<void> _cacheTranslations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final diseasesJson = json.encode(
          _diseases.map((key, value) => MapEntry(key, value.toJson())));
      await prefs.setString('cached_disease_translations', diseasesJson);

      final treatmentsJson = json.encode(
          _treatments.map((key, value) => MapEntry(key, value.toJson())));
      await prefs.setString('cached_treatment_translations', treatmentsJson);
    } catch (e) {
      print('Error caching translations: $e');
    }
  }

  /// Load default hardcoded translations
  void _loadDefaultTranslations() {
    _diseases = _getDefaultDiseases();
    _treatments = _getDefaultTreatments();
  }

  /// Get localized disease by key or name
  LocalizedDisease? getDisease(String diseaseKey) {
    // Try exact match first
    if (_diseases.containsKey(diseaseKey.toLowerCase())) {
      return _diseases[diseaseKey.toLowerCase()];
    }

    // Try partial match
    for (final entry in _diseases.entries) {
      if (entry.value.names['en']?.toLowerCase() == diseaseKey.toLowerCase()) {
        return entry.value;
      }
    }

    return null;
  }

  /// Get localized treatment by key
  LocalizedTreatment? getTreatment(String treatmentKey) {
    return _treatments[treatmentKey.toLowerCase()];
  }

  /// Get all treatments for a disease
  List<LocalizedTreatment> getTreatmentsForDisease(String diseaseKey) {
    return _treatments.values
        .where((t) => t.relatedDiseases.contains(diseaseKey.toLowerCase()))
        .toList();
  }

  /// Convert API Diagnostic to LocalizedDiagnosticResult
  LocalizedDiagnosticResult localizeResult(
    Diagnostic diagnostic,
    TreatmentResponse? treatmentResponse,
    String languageCode,
  ) {
    LocalizedDisease? localizedDisease;
    List<LocalizedTreatment> localizedTreatments = [];

    // Try to find localized disease
    if (diagnostic.diagnosisResult != null) {
      localizedDisease = getDisease(diagnostic.diagnosisResult!);
      
      // If not found, create a basic localized disease from API data
      if (localizedDisease == null && treatmentResponse?.disease != null) {
        localizedDisease = LocalizedDisease(
          id: treatmentResponse!.disease!.id,
          diseaseKey: diagnostic.diagnosisResult!.toLowerCase().replaceAll(' ', '_'),
          names: {'en': treatmentResponse.disease!.name},
          symptoms: treatmentResponse.disease!.symptoms != null
              ? {'en': treatmentResponse.disease!.symptoms!}
              : {},
          prevention: treatmentResponse.disease!.prevention != null
              ? {'en': treatmentResponse.disease!.prevention!}
              : {},
        );
      }
    }

    // Try to find localized treatments
    if (treatmentResponse != null) {
      for (final treatment in treatmentResponse.treatments) {
        final localized = getTreatment(treatment.treatmentName.toLowerCase().replaceAll(' ', '_'));
        if (localized != null) {
          localizedTreatments.add(localized);
        } else {
          // Create basic localized treatment from API data
          localizedTreatments.add(LocalizedTreatment(
            id: treatment.id,
            treatmentKey: treatment.treatmentName.toLowerCase().replaceAll(' ', '_'),
            treatmentType: treatment.treatmentType,
            names: {'en': treatment.treatmentName},
            dosages: treatment.dosage != null ? {'en': treatment.dosage!} : {},
            applicationMethods: treatment.applicationMethod != null
                ? {'en': treatment.applicationMethod!}
                : {},
            timings: treatment.timing != null ? {'en': treatment.timing!} : {},
            frequencies: treatment.frequency != null
                ? {'en': treatment.frequency!}
                : {},
            precautions: treatment.precautions != null
                ? {'en': treatment.precautions!}
                : {},
            notes: treatment.notes != null ? {'en': treatment.notes!} : {},
            activeIngredient: treatment.activeIngredient,
            costEstimate: treatment.costEstimate,
            availability: treatment.availability,
            effectivenessRating: treatment.effectivenessRating,
          ));
        }
      }
    }

    return LocalizedDiagnosticResult(
      diagnosticId: diagnostic.id,
      disease: localizedDisease,
      treatments: localizedTreatments,
      confidenceScore: diagnostic.confidenceScore,
      cropType: diagnostic.cropType,
      analyzedAt: diagnostic.createdAt,
    );
  }

  /// Get UI string translation
  String getString(String key, String languageCode) {
    return DiagnosticStrings.get(key, languageCode);
  }

  /// Default disease translations (bundled)
  Map<String, LocalizedDisease> _getDefaultDiseases() {
    return {
      'late_blight': LocalizedDisease(
        id: 1,
        diseaseKey: 'late_blight',
        names: {
          'en': 'Late Blight',
          'hi': 'लेट ब्लाइट (आलू का झुलसा)',
          'mr': 'उशिरा करपा',
          'ta': 'தாமதமான கருகல் நோய்',
          'kn': 'ತಡವಾದ ಕೊಳೆ',
          'te': 'ఆలస్య తెగులు',
          'gu': 'મોડું ઝાંખું',
        },
        descriptions: {
          'en': 'Late blight is a devastating disease affecting potatoes and tomatoes, caused by the oomycete pathogen Phytophthora infestans.',
          'hi': 'लेट ब्लाइट एक विनाशकारी बीमारी है जो आलू और टमाटर को प्रभावित करती है, जो फाइटोफ्थोरा इन्फेस्टन्स नामक रोगज़नक़ के कारण होती है।',
          'mr': 'उशिरा करपा हा बटाटा आणि टोमॅटो वर परिणाम करणारा विनाशकारी रोग आहे.',
          'ta': 'தாமதமான கருகல் நோய் உருளைக்கிழங்கு மற்றும் தக்காளியை பாதிக்கும் அழிவுகரமான நோய்.',
          'kn': 'ತಡವಾದ ಕೊಳೆ ಆಲೂಗಡ್ಡೆ ಮತ್ತು ಟೊಮೆಟೊಗಳ ಮೇಲೆ ಪರಿಣಾಮ ಬೀರುವ ವಿನಾಶಕಾರಿ ರೋಗ.',
          'te': 'ఆలస్య తెగులు బంగాళాదుంపలు మరియు టమోటాలను ప్రభావితం చేసే వినాశకరమైన వ్యాధి.',
          'gu': 'મોડું ઝાંખું બટાકા અને ટામેટાંને અસર કરતો વિનાશક રોગ છે.',
        },
        symptoms: {
          'en': 'Water-soaked lesions on leaves that turn brown/black. White fungal growth on leaf undersides in humid conditions. Rapid plant death.',
          'hi': 'पत्तियों पर पानी से भीगे घाव जो भूरे/काले हो जाते हैं। आर्द्र परिस्थितियों में पत्ती के निचले हिस्से पर सफेद फफूंदी। तेजी से पौधों की मृत्यु।',
          'mr': 'पानाच्या पानावर पाण्याने भिजलेले जखम जे तपकिरी/काळे होतात. आर्द्र परिस्थितीत पानाच्या खालच्या बाजूला पांढरी बुरशी वाढ.',
          'ta': 'இலைகளில் நீர் நனைந்த புண்கள் பழுப்பு/கருப்பு நிறமாக மாறும். ஈரப்பதமான நிலைகளில் இலையின் அடிப்பகுதியில் வெள்ளை பூஞ்சை வளர்ச்சி.',
          'kn': 'ಎಲೆಗಳಲ್ಲಿ ನೀರು ಒಂದಿದ ಗಾಯಗಳು ಕಂದು/ಕಪ್ಪಾಗುತ್ತವೆ. ತೇವಾಂಶ ಪರಿಸ್ಥಿತಿಗಳಲ್ಲಿ ಎಲೆಯ ಕೆಳಭಾಗದಲ್ಲಿ ಬಿಳಿ ಶಿಲೀಂಧ್ರ ಬೆಳವಣಿಗೆ.',
          'te': 'ఆకులపై నీటిలో తడిసిన గాయాలు గోధుమ/నలుపు రంగులోకి మారుతాయి. తేమ పరిస్థితులలో ఆకు అడుగు భాగంలో తెల్ల శిలీంధ్ర పెరుగుదల.',
          'gu': 'પાંદડા પર પાણીથી ભીંજાયેલા ઘા જે ભૂરા/કાળા થાય છે. ભેજવાળી પરિસ્થિતિમાં પાંદડાની નીચેની બાજુ સફેદ ફૂગની વૃદ્ધિ.',
        },
        prevention: {
          'en': 'Use certified disease-free seed. Maintain good air circulation. Remove infected plants. Apply preventive fungicides.',
          'hi': 'प्रमाणित रोग-मुक्त बीज का उपयोग करें। अच्छा वायु संचार बनाए रखें। संक्रमित पौधों को हटाएं। निवारक फफूंदनाशकों का प्रयोग करें।',
          'mr': 'प्रमाणित रोगमुक्त बियाणे वापरा. चांगले वायु परिसंचरण राखा. संक्रमित झाडे काढा. प्रतिबंधात्मक बुरशीनाशकांचा वापर करा.',
          'ta': 'சான்றளிக்கப்பட்ட நோயற்ற விதையைப் பயன்படுத்தவும். நல்ல காற்று சுழற்சியை பராமரிக்கவும். பாதிக்கப்பட்ட தாவரங்களை அகற்றவும்.',
          'kn': 'ಪ್ರಮಾಣಿತ ರೋಗ-ಮುಕ್ತ ಬೀಜವನ್ನು ಬಳಸಿ. ಉತ್ತಮ ಗಾಳಿ ಪ್ರಸರಣವನ್ನು ಕಾಪಾಡಿ. ಸೋಂಕಿತ ಸಸ್ಯಗಳನ್ನು ತೆಗೆದುಹಾಕಿ.',
          'te': 'ధృవీకరించబడిన వ్యాధి-రహిత విత్తనాలను ఉపయోగించండి. మంచి గాలి ప్రసరణను కొనసాగించండి. సోకిన మొక్కలను తొలగించండి.',
          'gu': 'પ્રમાણિત રોગ-મુક્ત બીજનો ઉપયોગ કરો. સારું હવા પરિભ્રમણ જાળવો. ચેપગ્રસ્ત છોડ દૂર કરો.',
        },
        severity: 'high',
        affectedCrops: ['potato', 'tomato'],
      ),
      'powdery_mildew': LocalizedDisease(
        id: 2,
        diseaseKey: 'powdery_mildew',
        names: {
          'en': 'Powdery Mildew',
          'hi': 'चूर्णिल आसिता (पाउडरी मिल्ड्यू)',
          'mr': 'भुरी',
          'ta': 'பொடி பூஞ்சை நோய்',
          'kn': 'ಬೂದು ಶಿಲೀಂಧ್ರ',
          'te': 'బూడిద తెగులు',
          'gu': 'ભૂકી ફૂગ',
        },
        descriptions: {
          'en': 'Powdery mildew is a fungal disease that affects a wide range of plants, causing a distinctive white powdery coating on leaves.',
          'hi': 'चूर्णिल आसिता एक फफूंद रोग है जो पौधों की एक विस्तृत श्रृंखला को प्रभावित करता है, जिससे पत्तियों पर एक विशिष्ट सफेद पाउडर जैसी परत बन जाती है।',
          'mr': 'भुरी हा बुरशीजन्य रोग आहे जो अनेक वनस्पतींवर परिणाम करतो, पानांवर पांढरी पावडर सारखी परत तयार होते.',
          'ta': 'பொடி பூஞ்சை நோய் பல்வேறு தாவரங்களை பாதிக்கும் பூஞ்சை நோய், இலைகளில் வெள்ளை பொடி போன்ற பூச்சு உருவாகும்.',
          'kn': 'ಬೂದು ಶಿಲೀಂಧ್ರವು ವ್ಯಾಪಕ ಶ್ರೇಣಿಯ ಸಸ್ಯಗಳ ಮೇಲೆ ಪರಿಣಾಮ ಬೀರುವ ಶಿಲೀಂಧ್ರ ರೋಗ.',
          'te': 'బూడిద తెగులు అనేక మొక్కలను ప్రభావితం చేసే శిలీంధ్ర వ్యాధి, ఆకులపై తెల్ల పొడి లాంటి పూత ఏర్పడుతుంది.',
          'gu': 'ભૂકી ફૂગ એ ફૂગનો રોગ છે જે છોડની વિશાળ શ્રેણીને અસર કરે છે, પાંદડા પર સફેદ પાવડર જેવી આવરણ બનાવે છે.',
        },
        symptoms: {
          'en': 'White to gray powdery spots on leaves, stems, and sometimes fruits. Leaves may curl, yellow, and drop prematurely.',
          'hi': 'पत्तियों, तनों और कभी-कभी फलों पर सफेद से भूरे पाउडर जैसे धब्बे। पत्तियां मुड़ सकती हैं, पीली हो सकती हैं और समय से पहले गिर सकती हैं।',
          'mr': 'पाने, देठ आणि कधीकधी फळांवर पांढरे ते राखाडी पावडर सारखे डाग. पाने वाकू शकतात, पिवळी होऊ शकतात.',
          'ta': 'இலைகள், தண்டுகள் மற்றும் சில நேரங்களில் பழங்களில் வெள்ளை முதல் சாம்பல் பொடி புள்ளிகள். இலைகள் சுருண்டு, மஞ்சள் நிறமாகலாம்.',
          'kn': 'ಎಲೆಗಳು, ಕಾಂಡಗಳು ಮತ್ತು ಕೆಲವೊಮ್ಮೆ ಹಣ್ಣುಗಳ ಮೇಲೆ ಬಿಳಿಯಿಂದ ಬೂದು ಪುಡಿ ಚುಕ್ಕೆಗಳು.',
          'te': 'ఆకులు, కాండాలు మరియు కొన్నిసార్లు పండ్లపై తెల్ల నుండి బూడిద పొడి మచ్చలు.',
          'gu': 'પાંદડા, દાંડી અને ક્યારેક ફળો પર સફેદથી રાખોડી પાવડર જેવા ડાઘ. પાંદડા વળી શકે છે, પીળા થઈ શકે છે.',
        },
        prevention: {
          'en': 'Ensure good air circulation. Avoid overhead watering. Remove and destroy infected plant parts. Use resistant varieties.',
          'hi': 'अच्छा वायु संचार सुनिश्चित करें। ऊपर से पानी देने से बचें। संक्रमित पौधों के हिस्सों को हटाएं और नष्ट करें। प्रतिरोधी किस्मों का उपयोग करें।',
          'mr': 'चांगले वायु परिसंचरण सुनिश्चित करा. वरून पाणी देणे टाळा. संक्रमित वनस्पती भाग काढून टाका.',
          'ta': 'நல்ல காற்று சுழற்சியை உறுதிப்படுத்தவும். மேலே இருந்து நீர் ஊற்றுவதைத் தவிர்க்கவும். பாதிக்கப்பட்ட தாவர பாகங்களை அகற்றவும்.',
          'kn': 'ಉತ್ತಮ ಗಾಳಿ ಪ್ರಸರಣವನ್ನು ಖಚಿತಪಡಿಸಿ. ಮೇಲಿನಿಂದ ನೀರುಣಿಸುವುದನ್ನು ತಪ್ಪಿಸಿ.',
          'te': 'మంచి గాలి ప్రసరణను నిర్ధారించండి. పైనుండి నీరు పోయడం మానుకోండి. సోకిన మొక్క భాగాలను తొలగించండి.',
          'gu': 'સારું હવા પરિભ્રમણ સુનિશ્ચિત કરો. ઉપરથી પાણી આપવાનું ટાળો. ચેપગ્રસ્ત છોડના ભાગો દૂર કરો.',
        },
        severity: 'medium',
        affectedCrops: ['wheat', 'grapes', 'cucumber', 'pumpkin', 'peas'],
      ),
      'bacterial_leaf_blight': LocalizedDisease(
        id: 3,
        diseaseKey: 'bacterial_leaf_blight',
        names: {
          'en': 'Bacterial Leaf Blight',
          'hi': 'जीवाणु झुलसा (बैक्टीरियल लीफ ब्लाइट)',
          'mr': 'जिवाणू करपा',
          'ta': 'பாக்டீரியா இலை கருகல்',
          'kn': 'ಬ್ಯಾಕ್ಟೀರಿಯಾ ಎಲೆ ಕೊಳೆ',
          'te': 'బ్యాక్టీరియా ఆకు తెగులు',
          'gu': 'બેક્ટેરિયલ પાન ઝાંખું',
        },
        descriptions: {
          'en': 'Bacterial leaf blight is a serious disease of rice caused by Xanthomonas oryzae. It can cause significant yield losses.',
          'hi': 'जीवाणु झुलसा धान की एक गंभीर बीमारी है जो ज़ैंथोमोनास ओराइज़े के कारण होती है। इससे उपज में भारी नुकसान हो सकता है।',
          'mr': 'जिवाणू करपा हा भाताचा गंभीर रोग आहे. यामुळे उत्पादनात मोठे नुकसान होऊ शकते.',
          'ta': 'பாக்டீரியா இலை கருகல் அரிசியின் தீவிர நோய். இது கணிசமான மகசூல் இழப்பை ஏற்படுத்தும்.',
          'kn': 'ಬ್ಯಾಕ್ಟೀರಿಯಾ ಎಲೆ ಕೊಳೆ ಭತ್ತದ ಗಂಭೀರ ರೋಗ. ಇದು ಗಮನಾರ್ಹ ಇಳುವರಿ ನಷ್ಟಕ್ಕೆ ಕಾರಣವಾಗಬಹುದು.',
          'te': 'బ్యాక్టీరియా ఆకు తెగులు వరి యొక్క తీవ్రమైన వ్యాధి. ఇది గణనీయమైన దిగుబడి నష్టానికి కారణమవుతుంది.',
          'gu': 'બેક્ટેરિયલ પાન ઝાંખું ડાંગરનો ગંભીર રોગ છે. તે નોંધપાત્ર ઉપજ નુકસાનનું કારણ બની શકે છે.',
        },
        symptoms: {
          'en': 'Water-soaked lesions on leaf margins that turn yellow and eventually grayish-white. Lesions may exude bacterial ooze.',
          'hi': 'पत्ती के किनारों पर पानी से भीगे घाव जो पीले और अंततः भूरे-सफेद हो जाते हैं। घावों से जीवाणु रिसाव हो सकता है।',
          'mr': 'पानाच्या कडांवर पाण्याने भिजलेले जखम जे पिवळे आणि नंतर राखाडी-पांढरे होतात.',
          'ta': 'இலை விளிம்புகளில் நீர் நனைந்த புண்கள் மஞ்சள் பின்னர் சாம்பல்-வெள்ளை நிறமாக மாறும்.',
          'kn': 'ಎಲೆಯ ಅಂಚುಗಳಲ್ಲಿ ನೀರು ಒಂದಿದ ಗಾಯಗಳು ಹಳದಿ ಮತ್ತು ಅಂತಿಮವಾಗಿ ಬೂದು-ಬಿಳಿಯಾಗುತ್ತವೆ.',
          'te': 'ఆకు అంచులపై నీటిలో తడిసిన గాయాలు పసుపు మరియు చివరికి బూడిద-తెలుపు అవుతాయి.',
          'gu': 'પાંદડાના કિનારે પાણીથી ભીંજાયેલા ઘા જે પીળા અને પછી રાખોડી-સફેદ થાય છે.',
        },
        prevention: {
          'en': 'Use resistant varieties. Avoid excessive nitrogen fertilization. Ensure proper drainage. Use disease-free seeds.',
          'hi': 'प्रतिरोधी किस्मों का उपयोग करें। अत्यधिक नाइट्रोजन उर्वरक से बचें। उचित जल निकासी सुनिश्चित करें। रोग-मुक्त बीज का उपयोग करें।',
          'mr': 'प्रतिरोधक वाण वापरा. जास्त नायट्रोजन खत टाळा. योग्य निचरा सुनिश्चित करा. रोगमुक्त बियाणे वापरा.',
          'ta': 'எதிர்ப்புத் திறன் உள்ள இரகங்களைப் பயன்படுத்தவும். அதிக நைட்ரஜன் உரமிடுவதைத் தவிர்க்கவும்.',
          'kn': 'ನಿರೋಧಕ ತಳಿಗಳನ್ನು ಬಳಸಿ. ಅಧಿಕ ಸಾರಜನಕ ರಸಗೊಬ್ಬರವನ್ನು ತಪ್ಪಿಸಿ.',
          'te': 'నిరోధక రకాలను ఉపయోగించండి. అధిక నత్రజని ఎరువులను నివారించండి.',
          'gu': 'પ્રતિરોધક જાતોનો ઉપયોગ કરો. વધુ પડતા નાઇટ્રોજન ખાતરને ટાળો. યોગ્ય ડ્રેનેજ સુનિશ્ચિત કરો.',
        },
        severity: 'high',
        affectedCrops: ['rice'],
      ),
      'rust': LocalizedDisease(
        id: 4,
        diseaseKey: 'rust',
        names: {
          'en': 'Rust Disease',
          'hi': 'गेरुआ रोग (रस्ट)',
          'mr': 'गंज रोग',
          'ta': 'துரு நோய்',
          'kn': 'ತುಕ್ಕು ರೋಗ',
          'te': 'తుప్పు వ్యాధి',
          'gu': 'કાટ રોગ',
        },
        descriptions: {
          'en': 'Rust is a fungal disease causing orange-brown pustules on plant surfaces. Common in wheat and other cereals.',
          'hi': 'गेरुआ एक फफूंद रोग है जो पौधों की सतह पर नारंगी-भूरे रंग के दाने पैदा करता है। गेहूं और अन्य अनाजों में आम है।',
          'mr': 'गंज हा बुरशीजन्य रोग आहे ज्यामुळे वनस्पतींच्या पृष्ठभागावर नारंगी-तपकिरी फोड येतात.',
          'ta': 'துரு நோய் தாவர மேற்பரப்பில் ஆரஞ்சு-பழுப்பு புண்களை ஏற்படுத்தும் பூஞ்சை நோய்.',
          'kn': 'ತುಕ್ಕು ಸಸ್ಯ ಮೇಲ್ಮೈಯಲ್ಲಿ ಕಿತ್ತಳೆ-ಕಂದು ಕುದುರುಗಳನ್ನು ಉಂಟುಮಾಡುವ ಶಿಲೀಂಧ್ರ ರೋಗ.',
          'te': 'తుప్పు మొక్కల ఉపరితలాలపై నారింజ-గోధుమ పుస్ట్యూల్స్ కలిగించే శిలీంధ్ర వ్యాధి.',
          'gu': 'કાટ એ ફૂગનો રોગ છે જે છોડની સપાટી પર નારંગી-ભૂરા દાણા ઉત્પન્ન કરે છે.',
        },
        symptoms: {
          'en': 'Orange-brown powdery pustules on leaves and stems. Yellow streaks surrounding pustules. Reduced plant vigor.',
          'hi': 'पत्तियों और तनों पर नारंगी-भूरे पाउडर जैसे दाने। दानों के चारों ओर पीली धारियां। पौधे की शक्ति में कमी।',
          'mr': 'पाने आणि देठांवर नारंगी-तपकिरी पावडरयुक्त फोड. फोडांभोवती पिवळे पट्टे. झाडांची शक्ती कमी होते.',
          'ta': 'இலைகள் மற்றும் தண்டுகளில் ஆரஞ்சு-பழுப்பு பொடி புண்கள். புண்களைச் சுற்றி மஞ்சள் கோடுகள்.',
          'kn': 'ಎಲೆಗಳು ಮತ್ತು ಕಾಂಡಗಳ ಮೇಲೆ ಕಿತ್ತಳೆ-ಕಂದು ಪುಡಿ ಕುದುರುಗಳು. ಕುದುರುಗಳ ಸುತ್ತ ಹಳದಿ ಗೆರೆಗಳು.',
          'te': 'ఆకులు మరియు కాండాలపై నారింజ-గోధుమ పొడి పుస్ట్యూల్స్. పుస్ట్యూల్స్ చుట్టూ పసుపు చారలు.',
          'gu': 'પાંદડા અને દાંડી પર નારંગી-ભૂરા પાવડર જેવા દાણા. દાણાની આસપાસ પીળા પટ્ટા.',
        },
        prevention: {
          'en': 'Plant resistant varieties. Apply fungicides preventively. Remove volunteer plants. Practice crop rotation.',
          'hi': 'प्रतिरोधी किस्में लगाएं। निवारक रूप से फफूंदनाशक लगाएं। स्वयंसेवी पौधों को हटाएं। फसल चक्र अपनाएं।',
          'mr': 'प्रतिरोधक वाण लावा. प्रतिबंधात्मक बुरशीनाशक फवारा. स्वयंसेवी झाडे काढा. पीक फेरपालट करा.',
          'ta': 'எதிர்ப்பு இரகங்களை நடவு செய்யுங்கள். தடுப்பு பூஞ்சைக்கொல்லிகளைப் பயன்படுத்துங்கள்.',
          'kn': 'ನಿರೋಧಕ ತಳಿಗಳನ್ನು ನೆಡಿ. ತಡೆಗಟ್ಟುವ ಶಿಲೀಂಧ್ರನಾಶಕಗಳನ್ನು ಅನ್ವಯಿಸಿ.',
          'te': 'నిరోధక రకాలను నాటండి. నివారణ శిలీంధ్రనాశకాలను వర్తింపజేయండి.',
          'gu': 'પ્રતિરોધક જાતો વાવો. નિવારક ફૂગનાશકો લગાવો. સ્વૈચ્છિક છોડ દૂર કરો.',
        },
        severity: 'medium',
        affectedCrops: ['wheat', 'barley', 'oats'],
      ),
      'anthracnose': LocalizedDisease(
        id: 5,
        diseaseKey: 'anthracnose',
        names: {
          'en': 'Anthracnose',
          'hi': 'श्यामवर्ण (एन्थ्रेक्नोज)',
          'mr': 'करपा',
          'ta': 'ஆந்திரக்னோஸ்',
          'kn': 'ಆಂಥ್ರಾಕ್ನೋಸ್',
          'te': 'ఆంత్రాక్నోస్',
          'gu': 'એન્થ્રેકનોઝ',
        },
        descriptions: {
          'en': 'Anthracnose is a fungal disease causing dark, sunken lesions on leaves, stems, flowers, and fruits.',
          'hi': 'एन्थ्रेक्नोज एक फफूंद रोग है जो पत्तियों, तनों, फूलों और फलों पर गहरे, धंसे हुए घाव पैदा करता है।',
          'mr': 'करपा हा बुरशीजन्य रोग आहे ज्यामुळे पाने, देठ, फुले आणि फळांवर गडद, बुडालेले जखम होतात.',
          'ta': 'ஆந்திரக்னோஸ் இலைகள், தண்டுகள், மலர்கள் மற்றும் பழங்களில் இருண்ட, குழிவான புண்களை ஏற்படுத்தும் பூஞ்சை நோய்.',
          'kn': 'ಆಂಥ್ರಾಕ್ನೋಸ್ ಎಲೆಗಳು, ಕಾಂಡಗಳು, ಹೂವುಗಳು ಮತ್ತು ಹಣ್ಣುಗಳ ಮೇಲೆ ಗಾಢ, ಕುಸಿದ ಗಾಯಗಳನ್ನು ಉಂಟುಮಾಡುವ ಶಿಲೀಂಧ್ರ ರೋಗ.',
          'te': 'ఆంత్రాక్నోస్ ఆకులు, కాండాలు, పువ్వులు మరియు పండ్లపై చీకటి, కుంగిన గాయాలను కలిగించే శిలీంధ్ర వ్యాధి.',
          'gu': 'એન્થ્રેકનોઝ એ ફૂગનો રોગ છે જે પાંદડા, દાંડી, ફૂલો અને ફળો પર ઘેરા, ડૂબેલા ઘા પેદા કરે છે.',
        },
        symptoms: {
          'en': 'Dark, sunken spots with concentric rings. Spots may have pinkish spore masses. Leaf wilting and fruit rot.',
          'hi': 'गाढ़े वृत्ताकार छल्लों वाले गहरे, धंसे हुए धब्बे। धब्बों पर गुलाबी बीजाणु समूह हो सकते हैं। पत्ती मुरझाना और फल सड़ना।',
          'mr': 'केंद्रित वलयांसह गडद, बुडालेले डाग. डागांवर गुलाबी बीजाणू समूह असू शकतात.',
          'ta': 'செறிவு வளையங்களுடன் இருண்ட, குழிவான புள்ளிகள். புள்ளிகளில் இளஞ்சிவப்பு விதை திரள்கள் இருக்கலாம்.',
          'kn': 'ಕೇಂದ್ರೀಕೃತ ಉಂಗುರಗಳೊಂದಿಗೆ ಗಾಢ, ಕುಸಿದ ಚುಕ್ಕೆಗಳು. ಚುಕ್ಕೆಗಳು ಗುಲಾಬಿ ಬೀಜಕಣ ಸಮೂಹಗಳನ್ನು ಹೊಂದಿರಬಹುದು.',
          'te': 'కేంద్రీకృత వలయాలతో చీకటి, కుంగిన మచ్చలు. మచ్చలలో పింక్ బీజకణ గుచ్ఛాలు ఉండవచ్చు.',
          'gu': 'કેન્દ્રિત વલયો સાથે ઘેરા, ડૂબેલા ડાઘ. ડાઘ પર ગુલાબી બીજાણુ સમૂહ હોઈ શકે છે.',
        },
        prevention: {
          'en': 'Use disease-free seeds. Avoid overhead irrigation. Apply copper-based fungicides. Remove infected plant debris.',
          'hi': 'रोग-मुक्त बीज का उपयोग करें। ऊपर से सिंचाई से बचें। तांबा आधारित फफूंदनाशक लगाएं। संक्रमित पौधों के मलबे को हटाएं।',
          'mr': 'रोगमुक्त बियाणे वापरा. वरून सिंचन टाळा. तांबे आधारित बुरशीनाशक फवारा.',
          'ta': 'நோயற்ற விதைகளைப் பயன்படுத்தவும். மேலே இருந்து நீர்ப்பாசனம் தவிர்க்கவும். தாமிர அடிப்படையிலான பூஞ்சைக்கொல்லிகளைப் பயன்படுத்தவும்.',
          'kn': 'ರೋಗ-ಮುಕ್ತ ಬೀಜಗಳನ್ನು ಬಳಸಿ. ಮೇಲಿನಿಂದ ನೀರಾವರಿ ತಪ್ಪಿಸಿ. ತಾಮ್ರ-ಆಧಾರಿತ ಶಿಲೀಂಧ್ರನಾಶಕಗಳನ್ನು ಅನ್ವಯಿಸಿ.',
          'te': 'వ్యాధి-రహిత విత్తనాలను ఉపయోగించండి. పైనుండి నీటిపారుదలను నివారించండి. రాగి-ఆధారిత శిలీంధ్రనాశకాలను వర్తింపజేయండి.',
          'gu': 'રોગ-મુક્ત બીજનો ઉપયોગ કરો. ઉપરથી સિંચાઈ ટાળો. તાંબા આધારિત ફૂગનાશકો લગાવો.',
        },
        severity: 'medium',
        affectedCrops: ['chili', 'mango', 'banana', 'papaya', 'beans'],
      ),
    };
  }

  /// Default treatment translations (bundled)
  Map<String, LocalizedTreatment> _getDefaultTreatments() {
    return {
      'neem_oil_spray': LocalizedTreatment(
        id: 1,
        treatmentKey: 'neem_oil_spray',
        treatmentType: 'organic',
        names: {
          'en': 'Neem Oil Spray',
          'hi': 'नीम तेल स्प्रे',
          'mr': 'कडूनिंब तेल फवारणी',
          'ta': 'வேப்ப எண்ணெய் தெளிப்பு',
          'kn': 'ಬೇವಿನ ಎಣ್ಣೆ ಸಿಂಪಡಣೆ',
          'te': 'వేప నూనె స్ప్రే',
          'gu': 'લીમડા તેલ સ્પ્રે',
        },
        descriptions: {
          'en': 'Natural pesticide and fungicide derived from neem tree. Effective against many pests and diseases.',
          'hi': 'नीम के पेड़ से प्राप्त प्राकृतिक कीटनाशक और फफूंदनाशक। कई कीटों और रोगों के खिलाफ प्रभावी।',
          'mr': 'कडूनिंबाच्या झाडापासून मिळवलेले नैसर्गिक कीटकनाशक आणि बुरशीनाशक. अनेक कीटक आणि रोगांविरुद्ध प्रभावी.',
          'ta': 'வேப்ப மரத்திலிருந்து பெறப்பட்ட இயற்கை பூச்சிக்கொல்லி மற்றும் பூஞ்சைக்கொல்லி.',
          'kn': 'ಬೇವಿನ ಮರದಿಂದ ಪಡೆದ ನೈಸರ್ಗಿಕ ಕೀಟನಾಶಕ ಮತ್ತು ಶಿಲೀಂಧ್ರನಾಶಕ.',
          'te': 'వేప చెట్టు నుండి పొందిన సహజ పురుగుమందు మరియు శిలీంధ్రనాశకం.',
          'gu': 'લીમડાના ઝાડમાંથી મેળવેલ કુદરતી જંતુનાશક અને ફૂગનાશક.',
        },
        applicationMethods: {
          'en': 'Mix 5ml neem oil with 1 liter of water and a few drops of liquid soap. Spray on affected plants.',
          'hi': '5ml नीम तेल को 1 लीटर पानी और कुछ बूंद तरल साबुन के साथ मिलाएं। प्रभावित पौधों पर स्प्रे करें।',
          'mr': '5ml कडूनिंब तेल 1 लिटर पाणी आणि काही थेंब द्रव साबणाबरोबर मिसळा. बाधित झाडांवर फवारणी करा.',
          'ta': '5ml வேப்ப எண்ணெயை 1 லிட்டர் தண்ணீர் மற்றும் சில சொட்டு திரவ சோப்புடன் கலக்கவும்.',
          'kn': '5ml ಬೇವಿನ ಎಣ್ಣೆಯನ್ನು 1 ಲೀಟರ್ ನೀರು ಮತ್ತು ಕೆಲವು ಹನಿ ದ್ರವ ಸೋಪ್ನೊಂದಿಗೆ ಮಿಶ್ರಣ ಮಾಡಿ.',
          'te': '5ml వేప నూనెను 1 లీటర్ నీరు మరియు కొన్ని చుక్కల ద్రవ సబ్బుతో కలపండి.',
          'gu': '5ml લીમડા તેલને 1 લીટર પાણી અને થોડા ટીપાં પ્રવાહી સાબુ સાથે ભેળવો.',
        },
        dosages: {
          'en': '5ml per liter of water',
          'hi': '5ml प्रति लीटर पानी',
          'mr': '5ml प्रति लिटर पाणी',
          'ta': '1 லிட்டர் தண்ணீருக்கு 5ml',
          'kn': 'ಪ್ರತಿ ಲೀಟರ್ ನೀರಿಗೆ 5ml',
          'te': 'లీటర్ నీటికి 5ml',
          'gu': 'પ્રતિ લીટર પાણીમાં 5ml',
        },
        timings: {
          'en': 'Early morning or late evening',
          'hi': 'सुबह जल्दी या शाम को देर से',
          'mr': 'सकाळी लवकर किंवा संध्याकाळी उशिरा',
          'ta': 'அதிகாலை அல்லது மாலை தாமதமாக',
          'kn': 'ಮುಂಜಾನೆ ಅಥವಾ ತಡ ಸಂಜೆ',
          'te': 'తెల్లవారుజామున లేదా సాయంత్రం ఆలస్యంగా',
          'gu': 'વહેલી સવારે અથવા મોડી સાંજે',
        },
        frequencies: {
          'en': 'Every 7-10 days until symptoms subside',
          'hi': 'लक्षण कम होने तक हर 7-10 दिन',
          'mr': 'लक्षणे कमी होईपर्यंत दर 7-10 दिवसांनी',
          'ta': 'அறிகுறிகள் குறையும் வரை ஒவ்வொரு 7-10 நாட்களும்',
          'kn': 'ರೋಗಲಕ್ಷಣಗಳು ಕಡಿಮೆಯಾಗುವವರೆಗೆ ಪ್ರತಿ 7-10 ದಿನಗಳು',
          'te': 'లక్షణాలు తగ్గే వరకు ప్రతి 7-10 రోజులు',
          'gu': 'લક્ષણો ઓછા થાય ત્યાં સુધી દર 7-10 દિવસે',
        },
        precautions: {
          'en': 'Avoid spraying in direct sunlight. Do not use on plants in bloom as it may affect pollinators.',
          'hi': 'सीधी धूप में छिड़काव से बचें। फूल वाले पौधों पर उपयोग न करें क्योंकि यह परागणकों को प्रभावित कर सकता है।',
          'mr': 'थेट सूर्यप्रकाशात फवारणी टाळा. फुलांवर वापरू नका कारण त्याचा परागणकांवर परिणाम होऊ शकतो.',
          'ta': 'நேரடி சூரிய ஒளியில் தெளிப்பதைத் தவிர்க்கவும். பூக்கும் தாவரங்களில் பயன்படுத்த வேண்டாம்.',
          'kn': 'ನೇರ ಸೂರ್ಯನ ಬೆಳಕಿನಲ್ಲಿ ಸಿಂಪಡಿಸುವುದನ್ನು ತಪ್ಪಿಸಿ. ಹೂಬಿಡುವ ಸಸ್ಯಗಳ ಮೇಲೆ ಬಳಸಬೇಡಿ.',
          'te': 'ప్రత్యక్ష సూర్యకాంతిలో స్ప్రే చేయడం మానండి. పుష్పించే మొక్కలపై ఉపయోగించవద్దు.',
          'gu': 'સીધા સૂર્યપ્રકાશમાં છંટકાવ ટાળો. ફૂલ પર ઉપયોગ કરશો નહીં.',
        },
        activeIngredient: 'Azadirachtin',
        costEstimate: '₹150-250 per liter',
        availability: 'easily_available',
        effectivenessRating: 4,
        relatedDiseases: ['powdery_mildew', 'anthracnose', 'rust'],
      ),
      'copper_fungicide': LocalizedTreatment(
        id: 2,
        treatmentKey: 'copper_fungicide',
        treatmentType: 'chemical',
        names: {
          'en': 'Copper Fungicide',
          'hi': 'तांबा फफूंदनाशक',
          'mr': 'तांबे बुरशीनाशक',
          'ta': 'செம்பு பூஞ்சைக்கொல்லி',
          'kn': 'ತಾಮ್ರ ಶಿಲೀಂಧ್ರನಾಶಕ',
          'te': 'రాగి శిలీంధ్రనాశకం',
          'gu': 'તાંબુ ફૂગનાશક',
        },
        descriptions: {
          'en': 'Broad-spectrum fungicide effective against many fungal and bacterial diseases.',
          'hi': 'कई फफूंद और जीवाणु रोगों के खिलाफ प्रभावी व्यापक-स्पेक्ट्रम फफूंदनाशक।',
          'mr': 'अनेक बुरशी आणि जिवाणू रोगांविरुद्ध प्रभावी व्यापक-स्पेक्ट्रम बुरशीनाशक.',
          'ta': 'பல பூஞ்சை மற்றும் பாக்டீரியா நோய்களுக்கு எதிராக பயனுள்ள பரந்த-நிறமாலை பூஞ்சைக்கொல்லி.',
          'kn': 'ಅನೇಕ ಶಿಲೀಂಧ್ರ ಮತ್ತು ಬ್ಯಾಕ್ಟೀರಿಯಾ ರೋಗಗಳ ವಿರುದ್ಧ ಪರಿಣಾಮಕಾರಿ ವಿಶಾಲ-ರೋಹಿತ ಶಿಲೀಂಧ್ರನಾಶಕ.',
          'te': 'అనేక శిలీంధ్ర మరియు బ్యాక్టీరియా వ్యాధులకు వ్యతిరేకంగా ప్రభావవంతమైన విస్తృత-స్పెక్ట్రమ్ శిలీంధ్రనాశకం.',
          'gu': 'ઘણા ફૂગ અને બેક્ટેરિયલ રોગો સામે અસરકારક વ્યાપક-સ્પેક્ટ્રમ ફૂગનાશક.',
        },
        applicationMethods: {
          'en': 'Mix according to package instructions. Spray thoroughly on all plant surfaces.',
          'hi': 'पैकेज निर्देशों के अनुसार मिलाएं। सभी पौधों की सतहों पर अच्छी तरह से स्प्रे करें।',
          'mr': 'पॅकेज सूचनांनुसार मिसळा. सर्व वनस्पती पृष्ठभागांवर पूर्णपणे फवारणी करा.',
          'ta': 'பேக்கேஜ் வழிமுறைகளின்படி கலக்கவும். அனைத்து தாவர மேற்பரப்புகளிலும் முழுமையாக தெளிக்கவும்.',
          'kn': 'ಪ್ಯಾಕೇಜ್ ಸೂಚನೆಗಳ ಪ್ರಕಾರ ಮಿಶ್ರಣ ಮಾಡಿ. ಎಲ್ಲಾ ಸಸ್ಯ ಮೇಲ್ಮೈಗಳ ಮೇಲೆ ಸಂಪೂರ್ಣವಾಗಿ ಸಿಂಪಡಿಸಿ.',
          'te': 'ప్యాకేజీ సూచనల ప్రకారం కలపండి. అన్ని మొక్కల ఉపరితలాలపై పూర్తిగా స్ప్రే చేయండి.',
          'gu': 'પેકેજ સૂચનો અનુસાર ભેળવો. બધી છોડની સપાટી પર સંપૂર્ણ રીતે સ્પ્રે કરો.',
        },
        dosages: {
          'en': '2-3g per liter of water',
          'hi': '2-3 ग्राम प्रति लीटर पानी',
          'mr': '2-3 ग्रॅम प्रति लिटर पाणी',
          'ta': '1 லிட்டர் தண்ணீருக்கு 2-3 கிராம்',
          'kn': 'ಪ್ರತಿ ಲೀಟರ್ ನೀರಿಗೆ 2-3 ಗ್ರಾಂ',
          'te': 'లీటర్ నీటికి 2-3 గ్రాములు',
          'gu': 'પ્રતિ લીટર પાણીમાં 2-3 ગ્રામ',
        },
        timings: {
          'en': 'Apply before disease onset or at first sign of symptoms',
          'hi': 'रोग शुरू होने से पहले या लक्षणों के पहले संकेत पर लगाएं',
          'mr': 'रोग सुरू होण्यापूर्वी किंवा लक्षणांच्या पहिल्या चिन्हावर लागू करा',
          'ta': 'நோய் தொடங்குவதற்கு முன் அல்லது அறிகுறிகளின் முதல் அறிகுறியில் பயன்படுத்தவும்',
          'kn': 'ರೋಗ ಪ್ರಾರಂಭವಾಗುವ ಮೊದಲು ಅಥವಾ ರೋಗಲಕ್ಷಣಗಳ ಮೊದಲ ಚಿಹ್ನೆಯಲ್ಲಿ ಅನ್ವಯಿಸಿ',
          'te': 'వ్యాధి ప్రారంభానికి ముందు లేదా లక్షణాల మొదటి సంకేతంలో వర్తింపజేయండి',
          'gu': 'રોગ શરૂ થાય તે પહેલાં અથવા લક્ષણોના પ્રથમ સંકેત પર લગાવો',
        },
        frequencies: {
          'en': 'Every 7-14 days during wet weather',
          'hi': 'गीले मौसम में हर 7-14 दिन',
          'mr': 'ओल्या हवामानात दर 7-14 दिवसांनी',
          'ta': 'ஈரமான வானிலையில் ஒவ்வொரு 7-14 நாட்களும்',
          'kn': 'ಒದ್ದೆ ಹವಾಮಾನದಲ್ಲಿ ಪ್ರತಿ 7-14 ದಿನಗಳು',
          'te': 'తడి వాతావరణంలో ప్రతి 7-14 రోజులు',
          'gu': 'ભીના હવામાનમાં દર 7-14 દિવસે',
        },
        precautions: {
          'en': 'Wear protective equipment. Do not apply to crops close to harvest. Keep away from water sources.',
          'hi': 'सुरक्षात्मक उपकरण पहनें। कटाई के करीब फसलों पर न लगाएं। जल स्रोतों से दूर रखें।',
          'mr': 'संरक्षक उपकरणे घाला. कापणीच्या जवळ पिकांवर लागू करू नका. पाण्याच्या स्त्रोतांपासून दूर ठेवा.',
          'ta': 'பாதுகாப்பு உபகரணங்களை அணியுங்கள். அறுவடைக்கு அருகில் உள்ள பயிர்களுக்கு பயன்படுத்த வேண்டாம்.',
          'kn': 'ರಕ್ಷಣಾ ಸಾಧನಗಳನ್ನು ಧರಿಸಿ. ಕೊಯ್ಲಿನ ಹತ್ತಿರ ಬೆಳೆಗಳಿಗೆ ಅನ್ವಯಿಸಬೇಡಿ.',
          'te': 'రక్షణ పరికరాలు ధరించండి. కోత సమీపంలో పంటలకు వర్తింపజేయకూడదు.',
          'gu': 'રક્ષણાત્મક સાધનો પહેરો. લણણી નજીક પાક પર લગાવશો નહીં.',
        },
        activeIngredient: 'Copper Hydroxide / Copper Oxychloride',
        costEstimate: '₹200-400 per kg',
        availability: 'easily_available',
        effectivenessRating: 4,
        relatedDiseases: ['late_blight', 'bacterial_leaf_blight', 'anthracnose'],
      ),
      'trichoderma': LocalizedTreatment(
        id: 3,
        treatmentKey: 'trichoderma',
        treatmentType: 'biological',
        names: {
          'en': 'Trichoderma (Bio-fungicide)',
          'hi': 'ट्राइकोडर्मा (जैव फफूंदनाशक)',
          'mr': 'ट्रायकोडर्मा (जैव बुरशीनाशक)',
          'ta': 'ட்ரைகோடெர்மா (உயிரி பூஞ்சைக்கொல்லி)',
          'kn': 'ಟ್ರೈಕೋಡರ್ಮಾ (ಜೈವಿಕ ಶಿಲೀಂಧ್ರನಾಶಕ)',
          'te': 'ట్రైకోడెర్మా (జీవ శిలీంధ్రనాశకం)',
          'gu': 'ટ્રાઇકોડર્મા (જૈવ ફૂગનાશક)',
        },
        descriptions: {
          'en': 'Beneficial fungus that protects plants from soil-borne diseases and promotes root growth.',
          'hi': 'लाभकारी फफूंद जो पौधों को मिट्टी जनित रोगों से बचाती है और जड़ वृद्धि को बढ़ावा देती है।',
          'mr': 'फायदेशीर बुरशी जी झाडांना मातीतून होणाऱ्या रोगांपासून वाचवते आणि मुळांची वाढ वाढवते.',
          'ta': 'மண்ணில் பரவும் நோய்களிலிருந்து தாவரங்களைப் பாதுகாக்கும் மற்றும் வேர் வளர்ச்சியை ஊக்குவிக்கும் நன்மை பயக்கும் பூஞ்சை.',
          'kn': 'ಮಣ್ಣಿನಿಂದ ಹರಡುವ ರೋಗಗಳಿಂದ ಸಸ್ಯಗಳನ್ನು ರಕ್ಷಿಸುವ ಮತ್ತು ಬೇರಿನ ಬೆಳವಣಿಗೆಯನ್ನು ಉತ್ತೇಜಿಸುವ ಪ್ರಯೋಜನಕಾರಿ ಶಿಲೀಂಧ್ರ.',
          'te': 'నేల ద్వారా వ్యాపించే వ్యాధుల నుండి మొక్కలను రక్షించే మరియు వేరు పెరుగుదలను ప్రోత్సహించే ప్రయోజనకరమైన శిలీంధ్రం.',
          'gu': 'ફાયદાકારક ફૂગ જે છોડને જમીનથી ફેલાતા રોગોથી બચાવે છે અને મૂળ વૃદ્ધિને પ્રોત્સાહન આપે છે.',
        },
        applicationMethods: {
          'en': 'Mix with compost and apply to soil around roots. Can also be used as seed treatment.',
          'hi': 'खाद के साथ मिलाकर जड़ों के चारों ओर मिट्टी में डालें। बीज उपचार के रूप में भी इस्तेमाल किया जा सकता है।',
          'mr': 'कंपोस्टबरोबर मिसळा आणि मुळांभोवती मातीमध्ये लावा. बियाणे उपचार म्हणून देखील वापरता येते.',
          'ta': 'உரத்துடன் கலந்து வேர்களைச் சுற்றி மண்ணில் பயன்படுத்தவும். விதை சிகிச்சையாகவும் பயன்படுத்தலாம்.',
          'kn': 'ಕಾಂಪೋಸ್ಟ್‌ನೊಂದಿಗೆ ಮಿಶ್ರಣ ಮಾಡಿ ಮತ್ತು ಬೇರುಗಳ ಸುತ್ತ ಮಣ್ಣಿಗೆ ಅನ್ವಯಿಸಿ.',
          'te': 'కంపోస్ట్‌తో కలిపి వేర్ల చుట్టూ నేలకు వర్తింపజేయండి. విత్తన చికిత్సగా కూడా ఉపయోగించవచ్చు.',
          'gu': 'કમ્પોસ્ટ સાથે ભેળવો અને મૂળની આસપાસ જમીનમાં લગાવો.',
        },
        dosages: {
          'en': '4-5kg per acre mixed with organic matter',
          'hi': '4-5 किलो प्रति एकड़ जैविक पदार्थ के साथ मिलाकर',
          'mr': '4-5 किलो प्रति एकर सेंद्रिय पदार्थांमध्ये मिसळून',
          'ta': 'ஏக்கருக்கு 4-5 கிலோ கரிம பொருளுடன் கலந்து',
          'kn': 'ಎಕರೆಗೆ 4-5 ಕೆಜಿ ಸಾವಯವ ವಸ್ತುವಿನೊಂದಿಗೆ ಮಿಶ್ರಿತ',
          'te': 'ఎకరానికి 4-5 కిలోలు సేంద్రియ పదార్థంతో కలిపి',
          'gu': 'એકર દીઠ 4-5 કિલો કાર્બનિક પદાર્થ સાથે મિશ્રિત',
        },
        timings: {
          'en': 'Before sowing or at transplanting',
          'hi': 'बुवाई से पहले या रोपाई के समय',
          'mr': 'पेरणीपूर्वी किंवा लावणीच्या वेळी',
          'ta': 'விதைப்பதற்கு முன் அல்லது நடவு செய்யும் போது',
          'kn': 'ಬಿತ್ತನೆ ಮೊದಲು ಅಥವಾ ನಾಟಿ ಸಮಯದಲ್ಲಿ',
          'te': 'విత్తడానికి ముందు లేదా మార్పిడి సమయంలో',
          'gu': 'વાવણી પહેલાં અથવા રોપણી સમયે',
        },
        frequencies: {
          'en': 'Once at planting, repeat every 45-60 days if needed',
          'hi': 'एक बार रोपाई के समय, जरूरत पड़ने पर हर 45-60 दिन दोहराएं',
          'mr': 'लागवडीच्या वेळी एकदा, आवश्यक असल्यास दर 45-60 दिवसांनी पुन्हा करा',
          'ta': 'நடவு செய்யும் போது ஒரு முறை, தேவைப்பட்டால் ஒவ்வொரு 45-60 நாட்களும் மீண்டும் செய்யவும்',
          'kn': 'ನಾಟಿ ಸಮಯದಲ್ಲಿ ಒಮ್ಮೆ, ಅಗತ್ಯವಿದ್ದರೆ ಪ್ರತಿ 45-60 ದಿನಗಳಿಗೊಮ್ಮೆ ಪುನರಾವರ್ತಿಸಿ',
          'te': 'నాటే సమయంలో ఒకసారి, అవసరమైతే ప్రతి 45-60 రోజులు పునరావృతం చేయండి',
          'gu': 'રોપણી સમયે એકવાર, જરૂર પડે તો દર 45-60 દિવસે પુનરાવર્તન કરો',
        },
        precautions: {
          'en': 'Store in cool, dry place. Do not mix with chemical fungicides. Best results with organic farming.',
          'hi': 'ठंडी, सूखी जगह में रखें। रासायनिक फफूंदनाशकों के साथ न मिलाएं। जैविक खेती के साथ सर्वोत्तम परिणाम।',
          'mr': 'थंड, कोरड्या जागी ठेवा. रासायनिक बुरशीनाशकांमध्ये मिसळू नका.',
          'ta': 'குளிர்ந்த, உலர்ந்த இடத்தில் சேமிக்கவும். இரசாயன பூஞ்சைக்கொல்லிகளுடன் கலக்க வேண்டாம்.',
          'kn': 'ತಂಪಾದ, ಒಣ ಸ್ಥಳದಲ್ಲಿ ಸಂಗ್ರಹಿಸಿ. ರಾಸಾಯನಿಕ ಶಿಲೀಂಧ್ರನಾಶಕಗಳೊಂದಿಗೆ ಮಿಶ್ರಣ ಮಾಡಬೇಡಿ.',
          'te': 'చల్లని, పొడి ప్రదేశంలో నిల్వ చేయండి. రసాయన శిలీంధ్రనాశకాలతో కలపవద్దు.',
          'gu': 'ઠંડી, સૂકી જગ્યાએ સંગ્રહ કરો. રાસાયણિક ફૂગનાશકો સાથે ભેળવશો નહીં.',
        },
        activeIngredient: 'Trichoderma viride / Trichoderma harzianum',
        costEstimate: '₹100-200 per kg',
        availability: 'locally_available',
        effectivenessRating: 4,
        relatedDiseases: ['late_blight', 'powdery_mildew', 'rust'],
      ),
      'crop_rotation': LocalizedTreatment(
        id: 4,
        treatmentKey: 'crop_rotation',
        treatmentType: 'cultural',
        names: {
          'en': 'Crop Rotation',
          'hi': 'फसल चक्र',
          'mr': 'पीक फेरपालट',
          'ta': 'பயிர் சுழற்சி',
          'kn': 'ಬೆಳೆ ಪರಿವರ್ತನೆ',
          'te': 'పంట మార్పిడి',
          'gu': 'પાક પરિભ્રમણ',
        },
        descriptions: {
          'en': 'Practice of growing different crops in succession on the same land to break disease cycles.',
          'hi': 'रोग चक्र को तोड़ने के लिए एक ही भूमि पर क्रमिक रूप से अलग-अलग फसलें उगाने की प्रथा।',
          'mr': 'रोग चक्र खंडित करण्यासाठी एकाच जमिनीवर वेगवेगळ्या पिके क्रमाने लागवड करण्याची पद्धत.',
          'ta': 'நோய் சுழற்சிகளை உடைக்க ஒரே நிலத்தில் வெவ்வேறு பயிர்களை தொடர்ச்சியாக வளர்க்கும் நடைமுறை.',
          'kn': 'ರೋಗ ಚಕ್ರಗಳನ್ನು ಮುರಿಯಲು ಒಂದೇ ಭೂಮಿಯಲ್ಲಿ ವಿವಿಧ ಬೆಳೆಗಳನ್ನು ಅನುಕ್ರಮವಾಗಿ ಬೆಳೆಯುವ ಅಭ್ಯಾಸ.',
          'te': 'వ్యాధి చక్రాలను విచ్ఛిన్నం చేయడానికి ఒకే భూమిలో వివిధ పంటలను వరుసగా పండించే పద్ధతి.',
          'gu': 'રોગ ચક્રને તોડવા માટે એક જ જમીન પર ક્રમશઃ વિવિધ પાક ઉગાડવાની પ્રથા.',
        },
        applicationMethods: {
          'en': 'Avoid planting the same crop family in the same field for 2-3 years. Alternate with non-host crops.',
          'hi': '2-3 साल तक एक ही खेत में एक ही फसल परिवार को न लगाएं। गैर-मेजबान फसलों के साथ बदलें।',
          'mr': '2-3 वर्षे एकाच शेतात एकाच पीक कुटुंबातील पीक लावू नका. गैर-यजमान पिकांसह बदला.',
          'ta': '2-3 ஆண்டுகள் ஒரே வயலில் ஒரே பயிர் குடும்பத்தை நடவு செய்வதைத் தவிர்க்கவும்.',
          'kn': '2-3 ವರ್ಷಗಳ ಕಾಲ ಒಂದೇ ಹೊಲದಲ್ಲಿ ಒಂದೇ ಬೆಳೆ ಕುಟುಂಬವನ್ನು ನೆಡುವುದನ್ನು ತಪ್ಪಿಸಿ.',
          'te': '2-3 సంవత్సరాలు ఒకే పొలంలో ఒకే పంట కుటుంబాన్ని నాటడం మానుకోండి.',
          'gu': '2-3 વર્ષ સુધી એક જ ખેતરમાં એક જ પાક પરિવાર ન વાવો.',
        },
        dosages: {
          'en': 'N/A - Management practice',
          'hi': 'लागू नहीं - प्रबंधन प्रथा',
          'mr': 'लागू नाही - व्यवस्थापन पद्धत',
          'ta': 'பொருந்தாது - மேலாண்மை நடைமுறை',
          'kn': 'ಅನ್ವಯಿಸುವುದಿಲ್ಲ - ನಿರ್ವಹಣೆ ಅಭ್ಯಾಸ',
          'te': 'వర్తించదు - నిర్వహణ పద్ధతి',
          'gu': 'લાગુ નથી - વ્યવસ્થાપન પ્રથા',
        },
        timings: {
          'en': 'Plan before each growing season',
          'hi': 'प्रत्येक उगाने के मौसम से पहले योजना बनाएं',
          'mr': 'प्रत्येक वाढत्या हंगामापूर्वी नियोजन करा',
          'ta': 'ஒவ்வொரு வளரும் பருவத்திற்கு முன் திட்டமிடுங்கள்',
          'kn': 'ಪ್ರತಿ ಬೆಳೆಯುವ ಋತುವಿನ ಮೊದಲು ಯೋಜಿಸಿ',
          'te': 'ప్రతి పండించే సీజన్‌కు ముందు ప్లాన్ చేయండి',
          'gu': 'દરેક ઉગાડવાની મોસમ પહેલાં આયોજન કરો',
        },
        frequencies: {
          'en': 'Rotate crops every season or year',
          'hi': 'हर मौसम या साल फसल बदलें',
          'mr': 'दर हंगामात किंवा वर्षी पीक फिरवा',
          'ta': 'ஒவ்வொரு பருவத்திலும் அல்லது ஆண்டிலும் பயிர்களை மாற்றவும்',
          'kn': 'ಪ್ರತಿ ಋತುವಿನಲ್ಲಿ ಅಥವಾ ವರ್ಷದಲ್ಲಿ ಬೆಳೆಗಳನ್ನು ತಿರುಗಿಸಿ',
          'te': 'ప్రతి సీజన్ లేదా సంవత్సరం పంటలను మార్చండి',
          'gu': 'દરેક મોસમ અથવા વર્ષે પાક બદલો',
        },
        precautions: {
          'en': 'Consider soil nutrient needs of different crops. Keep records of crop history per field.',
          'hi': 'विभिन्न फसलों की मिट्टी पोषक तत्वों की जरूरतों पर विचार करें। प्रति खेत फसल इतिहास का रिकॉर्ड रखें।',
          'mr': 'विविध पिकांच्या माती पोषक गरजा विचारात घ्या. प्रत्येक शेताचा पीक इतिहास नोंदवा.',
          'ta': 'வெவ்வேறு பயிர்களின் மண் ஊட்டச்சத்து தேவைகளை கருத்தில் கொள்ளுங்கள்.',
          'kn': 'ವಿವಿಧ ಬೆಳೆಗಳ ಮಣ್ಣಿನ ಪೋಷಕಾಂಶ ಅಗತ್ಯಗಳನ್ನು ಪರಿಗಣಿಸಿ.',
          'te': 'వివిధ పంటల నేల పోషక అవసరాలను పరిగణించండి.',
          'gu': 'વિવિધ પાકની જમીન પોષક જરૂરિયાતો ધ્યાનમાં લો.',
        },
        costEstimate: '₹0 - Management practice',
        availability: 'easily_available',
        effectivenessRating: 5,
        relatedDiseases: ['late_blight', 'bacterial_leaf_blight', 'rust', 'anthracnose', 'powdery_mildew'],
      ),
    };
  }
}
