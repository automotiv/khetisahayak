
import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/screens/auth/new_login_screen.dart';
import 'package:kheti_sahayak_app/screens/auth/register_screen.dart';
import 'package:kheti_sahayak_app/screens/auth/forgot_password_screen.dart';
import 'package:kheti_sahayak_app/screens/auth/change_password_screen.dart';
import 'package:kheti_sahayak_app/screens/home_page.dart';
import 'package:kheti_sahayak_app/screens/main_sections/marketplace_screen.dart';
import 'package:kheti_sahayak_app/screens/marketplace/product_detail_screen.dart';
import 'package:kheti_sahayak_app/screens/cart/cart_screen.dart';
import 'package:kheti_sahayak_app/screens/checkout/checkout_screen_new.dart';
import 'package:kheti_sahayak_app/screens/checkout/order_confirmation_screen.dart';
import 'package:kheti_sahayak_app/screens/orders/order_detail_screen.dart';
import 'package:kheti_sahayak_app/screens/diagnostics/diagnostics_screen.dart';
import 'package:kheti_sahayak_app/screens/profile/profile_screen.dart';
import 'package:kheti_sahayak_app/screens/splash/splash_screen.dart';
import 'package:kheti_sahayak_app/screens/weather/weather_screen.dart';
import 'package:kheti_sahayak_app/screens/weather/weather_alerts_screen.dart';
import 'package:kheti_sahayak_app/screens/crop/crop_advisory_screen.dart';
import 'package:kheti_sahayak_app/screens/market/market_prices_screen.dart';
import 'package:kheti_sahayak_app/screens/crop/crop_detail_screen.dart';
import 'package:kheti_sahayak_app/screens/market/market_price_detail_screen.dart';
import 'package:kheti_sahayak_app/screens/tracking/application_tracking_screen.dart';
// Expert Consultation Screens
import 'package:kheti_sahayak_app/screens/expert/expert_list_screen.dart';
import 'package:kheti_sahayak_app/screens/expert/expert_profile_screen.dart';
import 'package:kheti_sahayak_app/screens/expert/book_consultation_screen.dart';
import 'package:kheti_sahayak_app/screens/expert/consultation_list_screen.dart';
import 'package:kheti_sahayak_app/screens/expert/consultation_detail_screen.dart';
import 'package:kheti_sahayak_app/screens/expert/video_call_screen.dart';
import 'package:kheti_sahayak_app/screens/expert/add_review_screen.dart';
import 'package:kheti_sahayak_app/models/consultation.dart';
import 'package:kheti_sahayak_app/models/expert.dart';

class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';
  static const String marketplace = '/marketplace';
  static const String productDetail = '/product-detail';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String orderConfirmation = '/order-confirmation';
  static const String orderDetails = '/order-details';
  static const String diagnostics = '/diagnostics';
  static const String education = '/education';
  static const String profile = '/profile';
  static const String changePassword = '/change-password';
  static const String weather = '/weather';
  static const String cropAdvisory = '/crop-advisory';
  static const String marketPrices = '/market-prices';
  static const String cropDetail = '/crop-detail'; 
  static const String marketPriceDetail = '/market-price-detail';
  static const String editProfile = '/edit-profile';
  static const String applicationTracking = '/application-tracking';
  static const String weatherAlerts = '/weather-alerts';
  
  // Expert Consultation Routes
  static const String expertList = '/experts';
  static const String expertProfile = '/expert-profile';
  static const String bookConsultation = '/book-consultation';
  static const String consultationHistory = '/consultation-history';
  static const String consultationDetail = '/consultation-detail';
  static const String videoCall = '/video-call';
  static const String addReview = '/add-review';

  // Routes map
  static final Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    login: (context) => const NewLoginScreen(),
    register: (context) => const RegisterScreen(),
    forgotPassword: (context) => const ForgotPasswordScreen(),
    dashboard: (context) => const HomePage(),
    marketplace: (context) => const MarketplaceScreen(),
    productDetail: (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      final product = args?['product'];
      return ProductDetailScreen(product: product);
    },
    cart: (context) => const CartScreen(),
    checkout: (context) => const CheckoutScreen(),
    orderConfirmation: (context) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
      return OrderConfirmationScreen(
        orderId: args?['orderId'] ?? '',
      );
    },
    orderDetails: (context) {
      final orderId = ModalRoute.of(context)!.settings.arguments as String?;
      return OrderDetailScreen(orderId: orderId ?? '');
    },
    diagnostics: (context) => const DiagnosticsScreen(),
    education: (context) => Scaffold(
      appBar: AppBar(title: const Text('Education')),
      body: const Center(child: Text('Education Content Coming Soon')),
    ),
    profile: (context) => const ProfileScreen(),
    changePassword: (context) => const ChangePasswordScreen(),
    weather: (context) => const WeatherScreen(),
    cropAdvisory: (context) => Scaffold(
      appBar: AppBar(title: const Text('Crop Advisory')),
      body: const Center(child: Text('Crop Advisory Coming Soon')),
    ),
    marketPrices: (context) => Scaffold(
      appBar: AppBar(title: const Text('Market Prices')),
      body: const Center(child: Text('Market Prices Coming Soon')),
    ),
    cropDetail: (context) { 
      final cropName = ModalRoute.of(context)!.settings.arguments as String;
      return CropDetailScreen(cropName: cropName);
    },
    marketPriceDetail: (context) {
      final commodity = ModalRoute.of(context)!.settings.arguments as Map<String, String>;
      return MarketPriceDetailScreen(commodity: commodity);
    },
    editProfile: (context) => Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: const Center(child: Text('Edit Profile Coming Soon')),
    ),
    applicationTracking: (context) => Scaffold(
      appBar: AppBar(title: const Text('Application Tracking')),
      body: const Center(child: Text('Application Tracking Coming Soon')),
    ),
    weatherAlerts: (context) => const WeatherAlertsScreen(),
    
    // Expert Consultation Routes
    expertList: (context) => const ExpertListScreen(),
    expertProfile: (context) {
      final expert = ModalRoute.of(context)!.settings.arguments as Expert;
      return ExpertProfileScreen(expert: expert);
    },
    bookConsultation: (context) {
      final expert = ModalRoute.of(context)!.settings.arguments as Expert;
      return BookConsultationScreen(expert: expert);
    },
    consultationHistory: (context) => const ConsultationListScreen(),
    consultationDetail: (context) {
      final consultation = ModalRoute.of(context)!.settings.arguments as Consultation;
      return ConsultationDetailScreen(consultation: consultation);
    },
    videoCall: (context) {
      final consultation = ModalRoute.of(context)!.settings.arguments as Consultation;
      return VideoCallScreen(consultation: consultation);
    },
    addReview: (context) {
      final consultation = ModalRoute.of(context)!.settings.arguments as Consultation;
      return AddReviewScreen(consultation: consultation);
    },
  };

  // Auth guard
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    return null;
  }

  // Helper methods for navigation
  static void goToLogin(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, login, (route) => false);
  }

  static void goToDashboard(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, dashboard, (route) => false);
  }

  static Future<T?> push<T>(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.of(context).pop(result);
  }

  static void popToRoot(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
