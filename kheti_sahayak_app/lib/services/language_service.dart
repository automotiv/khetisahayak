import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported languages in the app
enum AppLanguage {
  english('en', 'English', 'English'),
  hindi('hi', 'हिन्दी', 'Hindi'),
  marathi('mr', 'मराठी', 'Marathi'),
  tamil('ta', 'தமிழ்', 'Tamil'),
  kannada('kn', 'ಕನ್ನಡ', 'Kannada'),
  telugu('te', 'తెలుగు', 'Telugu'),
  gujarati('gu', 'ગુજરાતી', 'Gujarati'),
  bengali('bn', 'বাংলা', 'Bengali'),
  punjabi('pa', 'ਪੰਜਾਬੀ', 'Punjabi'),
  odia('or', 'ଓଡ଼ିଆ', 'Odia'),
  malayalam('ml', 'മലയാളം', 'Malayalam'),
  urdu('ur', 'اردو', 'Urdu');

  final String code;
  final String nativeName;
  final String englishName;

  const AppLanguage(this.code, this.nativeName, this.englishName);

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => AppLanguage.english,
    );
  }
}

/// Language Service for managing app localization
///
/// Supports Language Selection & Switching (Story #376)
class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';

  static LanguageService? _instance;
  static LanguageService get instance {
    _instance ??= LanguageService._();
    return _instance!;
  }

  LanguageService._();

  AppLanguage _currentLanguage = AppLanguage.english;
  bool _isInitialized = false;

  /// Current language
  AppLanguage get currentLanguage => _currentLanguage;

  /// Current locale
  Locale get locale => Locale(_currentLanguage.code);

  /// Check if initialized
  bool get isInitialized => _isInitialized;

  /// Initialize service and load saved language preference
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_languageKey);

      if (savedCode != null) {
        _currentLanguage = AppLanguage.fromCode(savedCode);
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error initializing LanguageService: $e');
      _isInitialized = true;
    }
  }

  /// Change the current language
  Future<void> setLanguage(AppLanguage language) async {
    if (_currentLanguage == language) return;

    _currentLanguage = language;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, language.code);
    } catch (e) {
      print('Error saving language preference: $e');
    }
  }

  /// Get all supported languages
  List<AppLanguage> get supportedLanguages => AppLanguage.values.toList();
}

/// App Localizations - Contains all translated strings
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': _englishStrings,
    'hi': _hindiStrings,
    'mr': _marathiStrings,
    'ta': _tamilStrings,
    'kn': _kannadaStrings,
    'te': _teluguStrings,
    'gu': _gujaratiStrings,
    'bn': _englishStrings,
    'pa': _englishStrings,
    'or': _englishStrings,
    'ml': _englishStrings,
    'ur': _englishStrings,
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  // Common getters for frequently used strings
  String get appName => translate('app_name');
  String get home => translate('home');
  String get dashboard => translate('dashboard');
  String get marketplace => translate('marketplace');
  String get diagnostics => translate('diagnostics');
  String get education => translate('education');
  String get profile => translate('profile');
  String get settings => translate('settings');
  String get language => translate('language');
  String get logout => translate('logout');
  String get login => translate('login');
  String get register => translate('register');
  String get email => translate('email');
  String get password => translate('password');
  String get forgotPassword => translate('forgot_password');
  String get cart => translate('cart');
  String get orders => translate('orders');
  String get weather => translate('weather');
  String get notifications => translate('notifications');
  String get search => translate('search');
  String get loading => translate('loading');
  String get error => translate('error');
  String get retry => translate('retry');
  String get cancel => translate('cancel');
  String get save => translate('save');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get add => translate('add');
  String get done => translate('done');
  String get yes => translate('yes');
  String get no => translate('no');
  String get ok => translate('ok');
  String get close => translate('close');
  String get next => translate('next');
  String get back => translate('back');
  String get submit => translate('submit');
  String get confirm => translate('confirm');
  String get success => translate('success');
  String get failed => translate('failed');
  String get noData => translate('no_data');
  String get selectLanguage => translate('select_language');
  String get changeLanguage => translate('change_language');

  // Cart strings
  String get addToCart => translate('add_to_cart');
  String get removeFromCart => translate('remove_from_cart');
  String get cartEmpty => translate('cart_empty');
  String get checkout => translate('checkout');
  String get total => translate('total');
  String get quantity => translate('quantity');

  // Product strings
  String get products => translate('products');
  String get categories => translate('categories');
  String get price => translate('price');
  String get outOfStock => translate('out_of_stock');
  String get inStock => translate('in_stock');
  String get addReview => translate('add_review');
  String get reviews => translate('reviews');

  // Diagnostics strings
  String get scanCrop => translate('scan_crop');
  String get takePhoto => translate('take_photo');
  String get chooseFromGallery => translate('choose_from_gallery');
  String get analyzing => translate('analyzing');
  String get diagnosis => translate('diagnosis');
  String get treatment => translate('treatment');
  String get healthy => translate('healthy');
  String get diseaseDetected => translate('disease_detected');

  // Weather strings
  String get currentWeather => translate('current_weather');
  String get forecast => translate('forecast');
  String get temperature => translate('temperature');
  String get humidity => translate('humidity');
  String get windSpeed => translate('wind_speed');
  String get rainfall => translate('rainfall');

  // Farm strings
  String get myFarm => translate('my_farm');
  String get crops => translate('crops');
  String get activities => translate('activities');
  String get expenses => translate('expenses');
  String get income => translate('income');

  // Schemes strings
  String get governmentSchemes => translate('government_schemes');
  String get allSchemes => translate('all_schemes');
  String get recentlyViewed => translate('recently_viewed');
  String get searchSchemes => translate('search_schemes');
  String get noSchemesFound => translate('no_schemes_found');
  String get description => translate('description');
  String get benefits => translate('benefits');
  String get eligibility => translate('eligibility');
  String get visitWebsite => translate('visit_website');
  
  // Dashboard strings
  String get yieldTrends => translate('yield_trends');
  String get viewAnalytics => translate('view_analytics');
  String get weatherForecast => translate('weather_forecast');
  String get cropAdvisory => translate('crop_advisory');
  String get marketPrices => translate('market_prices');
  String get pestDiseaseInfo => translate('pest_disease_info');
  String get quickAccess => translate('quick_access');
  
  // Scheme comparison strings
  String get compare => translate('compare');
  String get clear => translate('clear');
  String get apply => translate('apply');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'hi', 'mr', 'ta', 'kn', 'te', 'gu', 'bn', 'pa', 'or', 'ml', 'ur'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// English strings
const Map<String, String> _englishStrings = {
  'app_name': 'Kheti Sahayak',
  'home': 'Home',
  'dashboard': 'Dashboard',
  'marketplace': 'Marketplace',
  'diagnostics': 'Crop Doctor',
  'education': 'Learn',
  'profile': 'Profile',
  'settings': 'Settings',
  'language': 'Language',
  'logout': 'Logout',
  'login': 'Login',
  'register': 'Register',
  'email': 'Email',
  'password': 'Password',
  'forgot_password': 'Forgot Password?',
  'cart': 'Cart',
  'orders': 'Orders',
  'weather': 'Weather',
  'notifications': 'Notifications',
  'search': 'Search',
  'loading': 'Loading...',
  'error': 'Error',
  'retry': 'Retry',
  'cancel': 'Cancel',
  'save': 'Save',
  'delete': 'Delete',
  'edit': 'Edit',
  'add': 'Add',
  'done': 'Done',
  'yes': 'Yes',
  'no': 'No',
  'ok': 'OK',
  'close': 'Close',
  'next': 'Next',
  'back': 'Back',
  'submit': 'Submit',
  'confirm': 'Confirm',
  'success': 'Success',
  'failed': 'Failed',
  'no_data': 'No data available',
  'select_language': 'Select Language',
  'change_language': 'Change Language',

  // Cart
  'add_to_cart': 'Add to Cart',
  'remove_from_cart': 'Remove from Cart',
  'cart_empty': 'Your cart is empty',
  'checkout': 'Checkout',
  'total': 'Total',
  'quantity': 'Quantity',

  // Products
  'products': 'Products',
  'categories': 'Categories',
  'price': 'Price',
  'out_of_stock': 'Out of Stock',
  'in_stock': 'In Stock',
  'add_review': 'Add Review',
  'reviews': 'Reviews',

  // Diagnostics
  'scan_crop': 'Scan Crop',
  'take_photo': 'Take Photo',
  'choose_from_gallery': 'Choose from Gallery',
  'analyzing': 'Analyzing...',
  'diagnosis': 'Diagnosis',
  'treatment': 'Treatment',
  'healthy': 'Healthy',
  'disease_detected': 'Disease Detected',

  // Weather
  'current_weather': 'Current Weather',
  'forecast': 'Forecast',
  'temperature': 'Temperature',
  'humidity': 'Humidity',
  'wind_speed': 'Wind Speed',
  'rainfall': 'Rainfall',

  // Farm
  'my_farm': 'My Farm',
  'crops': 'Crops',
  'activities': 'Activities',
  'expenses': 'Expenses',
  'income': 'Income',

  // Schemes
  'government_schemes': 'Government Schemes',
  'all_schemes': 'All Schemes',
  'recently_viewed': 'Recently Viewed',
  'search_schemes': 'Search schemes...',
  'no_schemes_found': 'No schemes found.',
  'description': 'Description',
  'benefits': 'Benefits',
  'eligibility': 'Eligibility',
  'visit_website': 'Visit Website',

  // Dashboard
  'yield_trends': 'Yield Trends',
  'view_analytics': 'View Analytics',
  'weather_forecast': 'Weather Forecast',
  'crop_advisory': 'Crop Advisory',
  'market_prices': 'Market Prices',
  'pest_disease_info': 'Pest & Disease Info',
  'quick_access': 'Quick Access',
  
  // Scheme comparison
  'compare': 'Compare',
  'clear': 'Clear',
  'apply': 'Apply',
};

// Hindi strings
const Map<String, String> _hindiStrings = {
  'app_name': 'खेती सहायक',
  'home': 'होम',
  'dashboard': 'डैशबोर्ड',
  'marketplace': 'बाज़ार',
  'diagnostics': 'फसल डॉक्टर',
  'education': 'सीखें',
  'profile': 'प्रोफ़ाइल',
  'settings': 'सेटिंग्स',
  'language': 'भाषा',
  'logout': 'लॉगआउट',
  'login': 'लॉगिन',
  'register': 'रजिस्टर',
  'email': 'ईमेल',
  'password': 'पासवर्ड',
  'forgot_password': 'पासवर्ड भूल गए?',
  'cart': 'कार्ट',
  'orders': 'ऑर्डर',
  'weather': 'मौसम',
  'notifications': 'सूचनाएं',
  'search': 'खोजें',
  'loading': 'लोड हो रहा है...',
  'error': 'त्रुटि',
  'retry': 'पुनः प्रयास करें',
  'cancel': 'रद्द करें',
  'save': 'सेव करें',
  'delete': 'हटाएं',
  'edit': 'संपादित करें',
  'add': 'जोड़ें',
  'done': 'हो गया',
  'yes': 'हां',
  'no': 'नहीं',
  'ok': 'ठीक है',
  'close': 'बंद करें',
  'next': 'अगला',
  'back': 'पीछे',
  'submit': 'जमा करें',
  'confirm': 'पुष्टि करें',
  'success': 'सफल',
  'failed': 'विफल',
  'no_data': 'कोई डेटा उपलब्ध नहीं',
  'select_language': 'भाषा चुनें',
  'change_language': 'भाषा बदलें',

  // Cart
  'add_to_cart': 'कार्ट में जोड़ें',
  'remove_from_cart': 'कार्ट से हटाएं',
  'cart_empty': 'आपका कार्ट खाली है',
  'checkout': 'चेकआउट',
  'total': 'कुल',
  'quantity': 'मात्रा',

  // Products
  'products': 'उत्पाद',
  'categories': 'श्रेणियाँ',
  'price': 'कीमत',
  'out_of_stock': 'स्टॉक में नहीं',
  'in_stock': 'स्टॉक में',
  'add_review': 'समीक्षा जोड़ें',
  'reviews': 'समीक्षाएं',

  // Diagnostics
  'scan_crop': 'फसल स्कैन करें',
  'take_photo': 'फोटो लें',
  'choose_from_gallery': 'गैलरी से चुनें',
  'analyzing': 'विश्लेषण हो रहा है...',
  'diagnosis': 'निदान',
  'treatment': 'उपचार',
  'healthy': 'स्वस्थ',
  'disease_detected': 'रोग का पता चला',

  // Weather
  'current_weather': 'वर्तमान मौसम',
  'forecast': 'पूर्वानुमान',
  'temperature': 'तापमान',
  'humidity': 'आर्द्रता',
  'wind_speed': 'हवा की गति',
  'rainfall': 'वर्षा',

  // Farm
  'my_farm': 'मेरा खेत',
  'crops': 'फसलें',
  'activities': 'गतिविधियाँ',
  'expenses': 'खर्चे',
  'income': 'आय',

  // Schemes
  'government_schemes': 'सरकारी योजनाएं',
  'all_schemes': 'सभी योजनाएं',
  'recently_viewed': 'हाल ही में देखा गया',
  'search_schemes': 'योजनाएं खोजें...',
  'no_schemes_found': 'कोई योजना नहीं मिली।',
  'description': 'विवरण',
  'benefits': 'लाभ',
  'eligibility': 'पात्रता',
  'visit_website': 'वेबसाइट पर जाएं',

  // Dashboard
  'yield_trends': 'उपज के रुझान',
  'view_analytics': 'एनालिटिक्स देखें',
  'weather_forecast': 'मौसम पूर्वानुमान',
  'crop_advisory': 'फसल सलाह',
  'market_prices': 'बाजार भाव',
  'pest_disease_info': 'कीट और रोग जानकारी',
  'quick_access': 'त्वरित पहुंच',
  
  // Scheme comparison
  'compare': 'तुलना करें',
  'clear': 'साफ़ करें',
  'apply': 'लागू करें',
};

// Marathi strings
const Map<String, String> _marathiStrings = {
  'app_name': 'शेती सहाय्यक',
  'home': 'होम',
  'dashboard': 'डॅशबोर्ड',
  'marketplace': 'बाजार',
  'diagnostics': 'पीक डॉक्टर',
  'education': 'शिका',
  'profile': 'प्रोफाइल',
  'settings': 'सेटिंग्ज',
  'language': 'भाषा',
  'logout': 'लॉगआउट',
  'login': 'लॉगिन',
  'register': 'नोंदणी',
  'email': 'ईमेल',
  'password': 'पासवर्ड',
  'forgot_password': 'पासवर्ड विसरलात?',
  'cart': 'कार्ट',
  'orders': 'ऑर्डर',
  'weather': 'हवामान',
  'notifications': 'सूचना',
  'search': 'शोधा',
  'loading': 'लोड होत आहे...',
  'error': 'त्रुटी',
  'retry': 'पुन्हा प्रयत्न करा',
  'cancel': 'रद्द करा',
  'save': 'सेव्ह करा',
  'delete': 'हटवा',
  'edit': 'संपादित करा',
  'add': 'जोडा',
  'done': 'झाले',
  'yes': 'हो',
  'no': 'नाही',
  'ok': 'ठीक आहे',
  'close': 'बंद करा',
  'next': 'पुढे',
  'back': 'मागे',
  'submit': 'सबमिट करा',
  'confirm': 'पुष्टी करा',
  'success': 'यशस्वी',
  'failed': 'अयशस्वी',
  'no_data': 'कोणताही डेटा उपलब्ध नाही',
  'select_language': 'भाषा निवडा',
  'change_language': 'भाषा बदला',

  // Cart
  'add_to_cart': 'कार्टमध्ये जोडा',
  'remove_from_cart': 'कार्टमधून काढा',
  'cart_empty': 'तुमची कार्ट रिकामी आहे',
  'checkout': 'चेकआउट',
  'total': 'एकूण',
  'quantity': 'प्रमाण',

  // Products
  'products': 'उत्पादने',
  'categories': 'वर्ग',
  'price': 'किंमत',
  'out_of_stock': 'स्टॉक नाही',
  'in_stock': 'स्टॉकमध्ये',
  'add_review': 'पुनरावलोकन जोडा',
  'reviews': 'पुनरावलोकने',

  // Diagnostics
  'scan_crop': 'पीक स्कॅन करा',
  'take_photo': 'फोटो घ्या',
  'choose_from_gallery': 'गॅलरीमधून निवडा',
  'analyzing': 'विश्लेषण होत आहे...',
  'diagnosis': 'निदान',
  'treatment': 'उपचार',
  'healthy': 'निरोगी',
  'disease_detected': 'रोग आढळला',

  // Weather
  'current_weather': 'सध्याचे हवामान',
  'forecast': 'अंदाज',
  'temperature': 'तापमान',
  'humidity': 'आर्द्रता',
  'wind_speed': 'वाऱ्याचा वेग',
  'rainfall': 'पाऊस',

  // Farm
  'my_farm': 'माझे शेत',
  'crops': 'पिके',
  'activities': 'क्रियाकलाप',
  'expenses': 'खर्च',
  'income': 'उत्पन्न',

  // Schemes
  'government_schemes': 'सरकारी योजना',
  'all_schemes': 'सर्व योजना',
  'recently_viewed': 'अलीकडे पाहिलेले',
  'search_schemes': 'योजना शोधा...',
  'no_schemes_found': 'कोणत्याही योजना आढळल्या नाहीत.',
  'description': 'वर्णन',
  'benefits': 'फायदे',
  'eligibility': 'पात्रता',
  'visit_website': 'वेबसाइटला भेट द्या',

  // Dashboard
  'yield_trends': 'उत्पादन कल',
  'view_analytics': 'विश्लेषण पहा',
  'weather_forecast': 'हवामान अंदाज',
  'crop_advisory': 'पीक सल्ला',
  'market_prices': 'बाजार भाव',
  'pest_disease_info': 'कीड आणि रोग माहिती',
  'quick_access': 'जलद प्रवेश',
  
  // Scheme comparison
  'compare': 'तुलना करा',
  'clear': 'साफ करा',
  'apply': 'लागू करा',
};

// Tamil strings
const Map<String, String> _tamilStrings = {
  'app_name': 'விவசாய உதவியாளர்',
  'home': 'முகப்பு',
  'dashboard': 'டாஷ்போர்டு',
  'marketplace': 'சந்தை',
  'diagnostics': 'பயிர் மருத்துவர்',
  'education': 'கற்க',
  'profile': 'சுயவிவரம்',
  'settings': 'அமைப்புகள்',
  'language': 'மொழி',
  'logout': 'வெளியேறு',
  'login': 'உள்நுழைய',
  'register': 'பதிவு',
  'email': 'மின்னஞ்சல்',
  'password': 'கடவுச்சொல்',
  'forgot_password': 'கடவுச்சொல்லை மறந்தீர்களா?',
  'cart': 'வண்டி',
  'orders': 'ஆர்டர்கள்',
  'weather': 'வானிலை',
  'notifications': 'அறிவிப்புகள்',
  'search': 'தேடு',
  'loading': 'ஏற்றுகிறது...',
  'error': 'பிழை',
  'retry': 'மீண்டும் முயற்சி',
  'cancel': 'ரத்து',
  'save': 'சேமி',
  'delete': 'அழி',
  'edit': 'திருத்து',
  'add': 'சேர்',
  'done': 'முடிந்தது',
  'yes': 'ஆம்',
  'no': 'இல்லை',
  'ok': 'சரி',
  'close': 'மூடு',
  'next': 'அடுத்து',
  'back': 'பின்',
  'submit': 'சமர்ப்பி',
  'confirm': 'உறுதிப்படுத்து',
  'success': 'வெற்றி',
  'failed': 'தோல்வி',
  'no_data': 'தரவு இல்லை',
  'select_language': 'மொழியைத் தேர்ந்தெடு',
  'change_language': 'மொழியை மாற்று',

  // Cart
  'add_to_cart': 'வண்டியில் சேர்',
  'remove_from_cart': 'வண்டியிலிருந்து நீக்கு',
  'cart_empty': 'உங்கள் வண்டி காலியாக உள்ளது',
  'checkout': 'செக்அவுட்',
  'total': 'மொத்தம்',
  'quantity': 'அளவு',

  // Products
  'products': 'தயாரிப்புகள்',
  'categories': 'வகைகள்',
  'price': 'விலை',
  'out_of_stock': 'இருப்பு இல்லை',
  'in_stock': 'இருப்பில் உள்ளது',
  'add_review': 'மதிப்பாய்வு சேர்',
  'reviews': 'மதிப்பாய்வுகள்',

  // Diagnostics
  'scan_crop': 'பயிரை ஸ்கேன் செய்',
  'take_photo': 'புகைப்படம் எடு',
  'choose_from_gallery': 'கேலரியில் இருந்து தேர்வு செய்',
  'analyzing': 'பகுப்பாய்வு செய்கிறது...',
  'diagnosis': 'கண்டறிதல்',
  'treatment': 'சிகிச்சை',
  'healthy': 'ஆரோக்கியமான',
  'disease_detected': 'நோய் கண்டறியப்பட்டது',

  // Weather
  'current_weather': 'தற்போதைய வானிலை',
  'forecast': 'முன்னறிவிப்பு',
  'temperature': 'வெப்பநிலை',
  'humidity': 'ஈரப்பதம்',
  'wind_speed': 'காற்றின் வேகம்',
  'rainfall': 'மழைப்பொழிவு',

  // Farm
  'my_farm': 'என் பண்ணை',
  'crops': 'பயிர்கள்',
  'activities': 'செயல்பாடுகள்',
  'expenses': 'செலவுகள்',
  'income': 'வருமானம்',

  // Schemes
  'government_schemes': 'அரசு திட்டங்கள்',
  'all_schemes': 'அனைத்து திட்டங்கள்',
  'recently_viewed': 'சமீபத்தில் பார்த்தவை',
  'search_schemes': 'திட்டங்களைத் தேடு...',
  'no_schemes_found': 'திட்டங்கள் எதுவும் இல்லை.',
  'description': 'விளக்கம்',
  'benefits': 'நன்மைகள்',
  'eligibility': 'தகுதி',
  'visit_website': 'இணையதளத்தைப் பார்வையிடு',

  // Dashboard
  'yield_trends': 'மகசூல் போக்குகள்',
  'view_analytics': 'பகுப்பாய்வைப் பார்',
  'weather_forecast': 'வானிலை முன்னறிவிப்பு',
  'crop_advisory': 'பயிர் ஆலோசனை',
  'market_prices': 'சந்தை விலைகள்',
  'pest_disease_info': 'பூச்சி & நோய் தகவல்',
  'quick_access': 'விரைவு அணுகல்',
  
  // Scheme comparison
  'compare': 'ஒப்பிடு',
  'clear': 'அழி',
  'apply': 'பயன்படுத்து',
};

// Kannada strings
const Map<String, String> _kannadaStrings = {
  'app_name': 'ಕೃಷಿ ಸಹಾಯಕ',
  'home': 'ಮುಖಪುಟ',
  'dashboard': 'ಡ್ಯಾಶ್‌ಬೋರ್ಡ್',
  'marketplace': 'ಮಾರುಕಟ್ಟೆ',
  'diagnostics': 'ಬೆಳೆ ವೈದ್ಯ',
  'education': 'ಕಲಿ',
  'profile': 'ಪ್ರೊಫೈಲ್',
  'settings': 'ಸೆಟ್ಟಿಂಗ್‌ಗಳು',
  'language': 'ಭಾಷೆ',
  'logout': 'ಲಾಗ್ ಔಟ್',
  'login': 'ಲಾಗಿನ್',
  'register': 'ನೋಂದಣಿ',
  'email': 'ಇಮೇಲ್',
  'password': 'ಪಾಸ್‌ವರ್ಡ್',
  'forgot_password': 'ಪಾಸ್‌ವರ್ಡ್ ಮರೆತಿರಾ?',
  'cart': 'ಕಾರ್ಟ್',
  'orders': 'ಆರ್ಡರ್‌ಗಳು',
  'weather': 'ಹವಾಮಾನ',
  'notifications': 'ಸೂಚನೆಗಳು',
  'search': 'ಹುಡುಕಿ',
  'loading': 'ಲೋಡ್ ಆಗುತ್ತಿದೆ...',
  'error': 'ದೋಷ',
  'retry': 'ಮರುಪ್ರಯತ್ನಿಸಿ',
  'cancel': 'ರದ್ದು',
  'save': 'ಉಳಿಸಿ',
  'delete': 'ಅಳಿಸಿ',
  'edit': 'ತಿದ್ದು',
  'add': 'ಸೇರಿಸಿ',
  'done': 'ಮುಗಿದಿದೆ',
  'yes': 'ಹೌದು',
  'no': 'ಇಲ್ಲ',
  'ok': 'ಸರಿ',
  'close': 'ಮುಚ್ಚಿ',
  'next': 'ಮುಂದೆ',
  'back': 'ಹಿಂದೆ',
  'submit': 'ಸಲ್ಲಿಸಿ',
  'confirm': 'ಖಚಿತಪಡಿಸಿ',
  'success': 'ಯಶಸ್ವಿ',
  'failed': 'ವಿಫಲ',
  'no_data': 'ಯಾವುದೇ ಡೇಟಾ ಲಭ್ಯವಿಲ್ಲ',
  'select_language': 'ಭಾಷೆಯನ್ನು ಆಯ್ಕೆಮಾಡಿ',
  'change_language': 'ಭಾಷೆಯನ್ನು ಬದಲಾಯಿಸಿ',

  // Cart
  'add_to_cart': 'ಕಾರ್ಟ್‌ಗೆ ಸೇರಿಸಿ',
  'remove_from_cart': 'ಕಾರ್ಟ್‌ನಿಂದ ತೆಗೆದುಹಾಕಿ',
  'cart_empty': 'ನಿಮ್ಮ ಕಾರ್ಟ್ ಖಾಲಿಯಾಗಿದೆ',
  'checkout': 'ಚೆಕ್‌ಔಟ್',
  'total': 'ಒಟ್ಟು',
  'quantity': 'ಪ್ರಮಾಣ',

  // Products
  'products': 'ಉತ್ಪನ್ನಗಳು',
  'categories': 'ವರ್ಗಗಳು',
  'price': 'ಬೆಲೆ',
  'out_of_stock': 'ಸ್ಟಾಕ್ ಇಲ್ಲ',
  'in_stock': 'ಸ್ಟಾಕ್ ಇದೆ',
  'add_review': 'ವಿಮರ್ಶೆಯನ್ನು ಸೇರಿಸಿ',
  'reviews': 'ವಿಮರ್ಶೆಗಳು',

  // Diagnostics
  'scan_crop': 'ಬೆಳೆ ಸ್ಕ್ಯಾನ್ ಮಾಡಿ',
  'take_photo': 'ಫೋಟೋ ತೆಗೆಯಿರಿ',
  'choose_from_gallery': 'ಗ್ಯಾಲರಿಯಿಂದ ಆರಿಸಿ',
  'analyzing': 'ವಿಶ್ಲೇಷಿಸಲಾಗುತ್ತಿದೆ...',
  'diagnosis': 'ರೋಗನಿರ್ಣಯ',
  'treatment': 'ಚಿಕಿತ್ಸೆ',
  'healthy': 'ಆರೋಗ್ಯಕರ',
  'disease_detected': 'ರೋಗ ಪತ್ತೆಯಾಗಿದೆ',

  // Weather
  'current_weather': 'ಪ್ರಸ್ತುತ ಹವಾಮಾನ',
  'forecast': 'ಮುನ್ಸೂಚನೆ',
  'temperature': 'ತಾಪಮಾನ',
  'humidity': 'ತೇವಾಂಶ',
  'wind_speed': 'ಗಾಳಿಯ ವೇಗ',
  'rainfall': 'ಮಳೆ',

  // Farm
  'my_farm': 'ನನ್ನ ತೋಟ',
  'crops': 'ಬೆಳೆಗಳು',
  'activities': 'ಚಟುವಟಿಕೆಗಳು',
  'expenses': 'ಖರ್ಚುಗಳು',
  'income': 'ಆದಾಯ',

  // Schemes
  'government_schemes': 'ಸರ್ಕಾರಿ ಯೋಜನೆಗಳು',
  'all_schemes': 'ಎಲ್ಲಾ ಯೋಜನೆಗಳು',
  'recently_viewed': 'ಇತ್ತೀಚೆಗೆ ವೀಕ್ಷಿಸಿದ',
  'search_schemes': 'ಯೋಜನೆಗಳನ್ನು ಹುಡುಕಿ...',
  'no_schemes_found': 'ಯಾವುದೇ ಯೋಜನೆಗಳು ಕಂಡುಬಂದಿಲ್ಲ.',
  'description': 'ವಿವರಣೆ',
  'benefits': 'ಪ್ರಯೋಜನಗಳು',
  'eligibility': 'ಅರ್ಹತೆ',
  'visit_website': 'ವೆಬ್‌ಸೈಟ್‌ಗೆ ಭೇಟಿ ನೀಡಿ',

  // Dashboard
  'yield_trends': 'ಇಳುವರಿ ಪ್ರವೃತ್ತಿಗಳು',
  'view_analytics': 'ವಿಶ್ಲೇಷಣೆ ವೀಕ್ಷಿಸಿ',
  'weather_forecast': 'ಹವಾಮಾನ ಮುನ್ಸೂಚನೆ',
  'crop_advisory': 'ಬೆಳೆ ಸಲಹೆ',
  'market_prices': 'ಮಾರುಕಟ್ಟೆ ಬೆಲೆಗಳು',
  'pest_disease_info': 'ಕೀಟ ಮತ್ತು ರೋಗ ಮಾಹಿತಿ',
  'quick_access': 'ತ್ವರಿತ ಪ್ರವೇಶ',
  
  // Scheme comparison
  'compare': 'ಹೋಲಿಸಿ',
  'clear': 'ತೆರವು',
  'apply': 'ಅನ್ವಯಿಸು',
};

// Telugu strings
const Map<String, String> _teluguStrings = {
  'app_name': 'వ్యవసాయ సహాయక్',
  'home': 'హోమ్',
  'dashboard': 'డాష్‌బోర్డ్',
  'marketplace': 'మార్కెట్',
  'diagnostics': 'పంట డాక్టర్',
  'education': 'నేర్చుకోండి',
  'profile': 'ప్రొఫైల్',
  'settings': 'సెట్టింగ్‌లు',
  'language': 'భాష',
  'logout': 'లాగౌట్',
  'login': 'లాగిన్',
  'register': 'రిజిస్టర్',
  'email': 'ఈమెయిల్',
  'password': 'పాస్‌వర్డ్',
  'forgot_password': 'పాస్‌వర్డ్ మర్చిపోయారా?',
  'cart': 'కార్ట్',
  'orders': 'ఆర్డర్లు',
  'weather': 'వాతావరణం',
  'notifications': 'నోటిఫికేషన్లు',
  'search': 'వెతకండి',
  'loading': 'లోడ్ అవుతోంది...',
  'error': 'లోపం',
  'retry': 'మళ్ళీ ప్రయత్నించండి',
  'cancel': 'రద్దు',
  'save': 'సేవ్',
  'delete': 'తొలగించు',
  'edit': 'సవరించు',
  'add': 'జోడించు',
  'done': 'పూర్తయింది',
  'yes': 'అవును',
  'no': 'కాదు',
  'ok': 'సరే',
  'close': 'మూసివేయి',
  'next': 'తరువాత',
  'back': 'వెనుకకు',
  'submit': 'సమర్పించు',
  'confirm': 'నిర్ధారించు',
  'success': 'విజయం',
  'failed': 'విఫలం',
  'no_data': 'డేటా అందుబాటులో లేదు',
  'select_language': 'భాషను ఎంచుకోండి',
  'change_language': 'భాషను మార్చండి',

  // Cart
  'add_to_cart': 'కార్ట్‌కు జోడించు',
  'remove_from_cart': 'కార్ట్ నుండి తొలగించు',
  'cart_empty': 'మీ కార్ట్ ఖాళీగా ఉంది',
  'checkout': 'చెక్‌అవుట్',
  'total': 'మొత్తం',
  'quantity': 'పరిమాణం',

  // Products
  'products': 'ఉత్పత్తులు',
  'categories': 'వర్గాలు',
  'price': 'ధర',
  'out_of_stock': 'స్టాక్ లేదు',
  'in_stock': 'స్టాక్ ఉంది',
  'add_review': 'సమీక్షను జోడించు',
  'reviews': 'సమీక్షలు',

  // Diagnostics
  'scan_crop': 'పంటను స్కాన్ చేయండి',
  'take_photo': 'ఫోటో తీయండి',
  'choose_from_gallery': 'గ్యాలరీ నుండి ఎంచుకోండి',
  'analyzing': 'విశ్లేషిస్తోంది...',
  'diagnosis': 'నిర్ధారణ',
  'treatment': 'చికిత్స',
  'healthy': 'ఆరోగ్యకరమైన',
  'disease_detected': 'వ్యాధి గుర్తించబడింది',

  // Weather
  'current_weather': 'ప్రస్తుత వాతావరణం',
  'forecast': 'సూచన',
  'temperature': 'ఉష్ణోగ్రత',
  'humidity': 'తేమ',
  'wind_speed': 'గాలి వేగం',
  'rainfall': 'వర్షపాతం',

  // Farm
  'my_farm': 'నా పొలం',
  'crops': 'పంటలు',
  'activities': 'కార్యకలాపాలు',
  'expenses': 'ఖర్చులు',
  'income': 'ఆదాయం',

  // Schemes
  'government_schemes': 'ప్రభుత్వ పథకాలు',
  'all_schemes': 'అన్ని పథకాలు',
  'recently_viewed': 'ఇటీవల చూసినవి',
  'search_schemes': 'పథకాలను వెతకండి...',
  'no_schemes_found': 'ఎటువంటి పథకాలు కనుగొనబడలేదు.',
  'description': 'వి వివరణ',
  'benefits': 'ప్రయోజనాలు',
  'eligibility': 'అర్హత',
  'visit_website': 'వెబ్‌సైట్‌ను సందర్శించండి',

  // Dashboard
  'yield_trends': 'దిగుబడి పోకడలు',
  'view_analytics': 'విశ్లేషణలను చూడండి',
  'weather_forecast': 'వాతావరణ సూచన',
  'crop_advisory': 'పంట సలహా',
  'market_prices': 'మార్కెట్ ధరలు',
  'pest_disease_info': 'తెగులు & వ్యాధి సమాచారం',
  'quick_access': 'త్వరిత ప్రాప్యత',
  
  // Scheme comparison
  'compare': 'పోల్చండి',
  'clear': 'క్లియర్',
  'apply': 'వర్తించు',
};

// Gujarati strings
const Map<String, String> _gujaratiStrings = {
  'app_name': 'ખેતી સહાયક',
  'home': 'હોમ',
  'dashboard': 'ડેશબોર્ડ',
  'marketplace': 'બજાર',
  'diagnostics': 'પાક ડોક્ટર',
  'education': 'શીખો',
  'profile': 'પ્રોફાઇલ',
  'settings': 'સેટિંગ્સ',
  'language': 'ભાષા',
  'logout': 'લોગઆઉટ',
  'login': 'લોગિન',
  'register': 'રજીસ્ટર',
  'email': 'ઇમેઇલ',
  'password': 'પાસવર્ડ',
  'forgot_password': 'પાસવર્ડ ભૂલી ગયા?',
  'cart': 'કાર્ટ',
  'orders': 'ઓર્ડર',
  'weather': 'હવામાન',
  'notifications': 'સૂચનાઓ',
  'search': 'શોધો',
  'loading': 'લોડ થઈ રહ્યું છે...',
  'error': 'ભૂલ',
  'retry': 'ફરી પ્રયાસ કરો',
  'cancel': 'રદ કરો',
  'save': 'સાચવો',
  'delete': 'કાઢી નાખો',
  'edit': 'ફેરફાર કરો',
  'add': 'ઉમેરો',
  'done': 'થઈ ગયું',
  'yes': 'હા',
  'no': 'ના',
  'ok': 'બરાબર',
  'close': 'બંધ કરો',
  'next': 'આગળ',
  'back': 'પાછળ',
  'submit': 'સબમિટ કરો',
  'confirm': 'પુષ્ટિ કરો',
  'success': 'સફળ',
  'failed': 'નિષ્ફળ',
  'no_data': 'કોઈ ડેટા ઉપલબ્ધ નથી',
  'select_language': 'ભાષા પસંદ કરો',
  'change_language': 'ભાષા બદલો',

  // Cart
  'add_to_cart': 'કાર્ટમાં ઉમેરો',
  'remove_from_cart': 'કાર્ટમાંથી દૂર કરો',
  'cart_empty': 'તમારું કાર્ટ ખાલી છે',
  'checkout': 'ચેકઆઉટ',
  'total': 'કુલ',
  'quantity': 'જથ્થો',

  // Products
  'products': 'ઉત્પાદનો',
  'categories': 'શ્રેણીઓ',
  'price': 'કિંમત',
  'out_of_stock': 'સ્ટોકમાં નથી',
  'in_stock': 'સ્ટોકમાં છે',
  'add_review': 'સમીક્ષા ઉમેરો',
  'reviews': 'સમીક્ષાઓ',

  // Diagnostics
  'scan_crop': 'પાક સ્કેન કરો',
  'take_photo': 'ફોટો લો',
  'choose_from_gallery': 'ગેલેરીમાંથી પસંદ કરો',
  'analyzing': 'વિશ્લેષણ થઈ રહ્યું છે...',
  'diagnosis': 'નિદાન',
  'treatment': 'સારવાર',
  'healthy': 'તંદુરસ્ત',
  'disease_detected': 'રોગ મળી આવ્યો',

  // Weather
  'current_weather': 'વર્તમાન હવામાન',
  'forecast': 'આગાહી',
  'temperature': 'તાપમાન',
  'humidity': 'ભેજ',
  'wind_speed': 'પવનની ગતિ',
  'rainfall': 'વરસાદ',

  // Farm
  'my_farm': 'મારું ખેતર',
  'crops': 'પાક',
  'activities': 'પ્રવૃત્તિઓ',
  'expenses': 'ખર્ચ',
  'income': 'આવક',

  // Schemes
  'government_schemes': 'સરકારી યોજનાઓ',
  'all_schemes': 'બધી યોજનાઓ',
  'recently_viewed': 'તાજેતરમાં જોયેલ',
  'search_schemes': 'યોજનાઓ શોધો...',
  'no_schemes_found': 'કોઈ યોજનાઓ મળી નથી.',
  'description': 'વર્ણન',
  'benefits': 'લાભો',
  'eligibility': 'પાત્રતા',
  'visit_website': 'વેબસાઇટની મુલાકાત લો',

  // Dashboard
  'yield_trends': 'ઉપજ વલણો',
  'view_analytics': 'એનાલિટિક્સ જુઓ',
  'weather_forecast': 'હવામાન આગાહી',
  'crop_advisory': 'પાક સલાહ',
  'market_prices': 'બજાર ભાવ',
  'pest_disease_info': 'જીવાત અને રોગ માહિતી',
  'quick_access': 'ઝડપી accessક્સેસ',
  
  // Scheme comparison
  'compare': 'સરખામણી',
  'clear': 'સાફ કરો',
  'apply': 'લાગુ કરો',
};
