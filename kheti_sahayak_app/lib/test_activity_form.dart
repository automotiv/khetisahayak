import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/screens/activity/activity_form_screen.dart';

void main() {
  runApp(const ActivityFormTestApp());
}

class ActivityFormTestApp extends StatelessWidget {
  const ActivityFormTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Activity Form Test',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const ActivityFormScreen(),
    );
  }
}
