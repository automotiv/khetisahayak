import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported languages in the app
enum AppLanguage {
  english('en', 'English', 'English'),
  hindi('hi', 'हिन्दी', 'Hindi'),
  marathi('mr', 'मराठी', 'Marathi');

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
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'hi', 'mr'].contains(locale.languageCode);
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
};
