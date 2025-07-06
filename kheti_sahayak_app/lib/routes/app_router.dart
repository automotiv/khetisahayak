import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/screens/profile/profile_screen.dart';
import 'package:kheti_sahayak_app/screens/auth/change_password_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/profile':
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case '/change-password':
        return MaterialPageRoute(builder: (_) => const ChangePasswordScreen());
      // Add other routes here
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
