import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kheti_sahayak_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End App Test', () {
    testWidgets('App starts and shows initial screen without crashing',
        (WidgetTester tester) async {
      // Start the app
      app.main();
      // Wait for all animations and frames to settle.
      await tester.pumpAndSettle();

      // Verify that the app has started.
      // A good basic check is to find a common widget like a Scaffold.
      // For a real test, you would look for specific text or widgets on your home screen.
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}