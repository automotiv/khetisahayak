import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/screens/home_page.dart';
import 'package:kheti_sahayak_app/screens/auth/login_screen.dart';
import 'package:kheti_sahayak_app/screens/auth/registration_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';

  static Map<String, WidgetBuilder> routes = {
    home: (context) => const HomePage(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegistrationScreen(),
  };
}