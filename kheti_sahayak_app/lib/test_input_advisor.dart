import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/screens/info/input_advisor_screen.dart';
import 'package:kheti_sahayak_app/services/app_config_service.dart';

void main() {
  runApp(const TestInputAdvisorApp());
}

class TestInputAdvisorApp extends StatelessWidget {
  const TestInputAdvisorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Input Advisor Test',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const InputAdvisorScreen(),
    );
  }
}
