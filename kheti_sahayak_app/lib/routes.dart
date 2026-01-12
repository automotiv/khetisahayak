import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/screens/home_page.dart';
import 'package:kheti_sahayak_app/screens/auth/login_screen.dart';
import 'package:kheti_sahayak_app/screens/auth/registration_screen.dart';
import 'package:kheti_sahayak_app/screens/community/community_home_screen.dart';
import 'package:kheti_sahayak_app/screens/community/ask_question_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String community = '/community';
  static const String askQuestion = '/community/ask';

  static Map<String, WidgetBuilder> routes = {
    home: (context) => const HomePage(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegistrationScreen(),
    community: (context) => const CommunityHomeScreen(),
    askQuestion: (context) => const AskQuestionScreen(),
  };
}