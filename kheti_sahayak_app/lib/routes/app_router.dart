
import 'package:flutter/material.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home_page.dart';
import '../screens/main_sections/dashboard_screen.dart';
import '../screens/main_sections/marketplace_screen.dart';
import '../screens/main_sections/diagnostics_screen.dart';
import '../screens/main_sections/educational_content_screen.dart';
import '../screens/main_sections/profile_screen.dart';
import '../screens/marketplace/product_detail_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/checkout/checkout_screen.dart';
import '../screens/checkout/order_confirmation_screen.dart';
import 'routes.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.splash:
        return MaterialPageRoute(builder: (_) => SplashScreen());
      case Routes.login:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case Routes.register:
        return MaterialPageRoute(builder: (_) => RegisterScreen());
      case Routes.home:
        return MaterialPageRoute(builder: (_) => HomePage());
      case Routes.dashboard:
        return MaterialPageRoute(builder: (_) => DashboardScreen());
      case Routes.marketplace:
        return MaterialPageRoute(builder: (_) => MarketplaceScreen());
      case Routes.diagnostics:
        return MaterialPageRoute(builder: (_) => DiagnosticsScreen());
      case Routes.education:
        return MaterialPageRoute(builder: (_) => EducationalContentScreen());
      case Routes.profile:
        return MaterialPageRoute(builder: (_) => ProfileScreen());
      case Routes.productDetail:
        final productId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ProductDetailScreen(productId: productId),
        );
      case Routes.cart:
        return MaterialPageRoute(builder: (_) => CartScreen());
      case Routes.checkout:
        return MaterialPageRoute(builder: (_) => CheckoutScreen());
      case Routes.orderConfirmation:
        final orderId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => OrderConfirmationScreen(orderId: orderId),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
