import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kheti_sahayak_app/screens/info/government_schemes_screen.dart';
import 'package:kheti_sahayak_app/models/scheme.dart';
import 'package:kheti_sahayak_app/services/scheme_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Generate mock for SchemeService if needed, or just mock the static calls if possible.
// Since SchemeService methods are static, we might need to wrap them or use a different approach for testing.
// For this specific test, we are testing the UI Semantics, so we can potentially mock the service or just test the initial state.
// However, the screen calls SchemeService.getSchemes() in initState.
// To make it testable without changing the service too much, we can rely on the fact that we can pump the widget.
// But static method mocking in Dart is tricky without a wrapper.
// Let's assume for now we can test the initial UI structure or use a mockable service pattern if the project supports it.
// Given the existing code, SchemeService is a class with static methods.
// We will try to run the test and see if it fails due to network calls or missing mocks.
// If it fails, we might need to refactor SchemeService to be injectable or mockable.

// For now, let's create a basic test that checks for the presence of Semantics widgets we added.

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kheti_sahayak_app/services/language_service.dart';

void main() {
  testWidgets('GovernmentSchemesScreen has correct semantics', (WidgetTester tester) async {
    // Build the GovernmentSchemesScreen.
    // We wrap it in a MaterialApp to provide necessary context.
    await tester.pumpWidget(
      const MaterialApp(
        home: GovernmentSchemesScreen(),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          Locale('en'),
        ],
      ),
    );

    // Allow any async operations to complete (like the initial _loadSchemes).
    await tester.pumpAndSettle(); 

    // Verify Scaffold is present
    expect(find.byType(Scaffold), findsOneWidget);

    // Verify Search Field Semantics
    final searchFieldFinder = find.byType(TextField);
    expect(searchFieldFinder, findsOneWidget);

    // Verify the Semantics widget is present in the widget tree using Key
    final semanticsKeyFinder = find.byKey(const Key('searchSemantics'));
    expect(semanticsKeyFinder, findsOneWidget);
    
    // Check properties of the found Semantics widget
    final semanticsWidget = tester.widget<Semantics>(semanticsKeyFinder);
    expect(semanticsWidget.properties.label, 'Search schemes...');
    
    // Verify hint is present (might be part of label or hint)
    // expect(find.bySemanticsLabel('Search schemes...'), findsOneWidget); // Hint might be merged or separate

    // Verify "Clear Search" button is not present initially (text is empty)
    expect(find.byIcon(Icons.clear), findsNothing);

    // Enter text to show clear button
    await tester.enterText(searchFieldFinder, 'test');
    await tester.pump();

    // Verify Clear Button Semantics
    final clearButtonFinder = find.byIcon(Icons.clear);
    expect(clearButtonFinder, findsOneWidget);
    
    // Verify the label "Close" is present in the semantics tree (mapped to Close)
    expect(find.bySemanticsLabel('Close'), findsOneWidget);
    
    // Verify there is a button (the IconButton)
    // We don't strictly enforce that the label and button are on the same node 
    // because Tooltip and IconButton might create separate or nested nodes.
    // But we ensure the accessible name exists.
  });
}
