import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kheti_sahayak_app/widgets/activity_type_dropdown.dart';

void main() {
  testWidgets('ActivityTypeDropdown shows selected value', (WidgetTester tester) async {
    String? selectedValue = 'Planting';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActivityTypeDropdown(
            value: selectedValue,
            onChanged: (value) {
              selectedValue = value;
            },
          ),
        ),
      ),
    );

    expect(find.text('Planting'), findsOneWidget);
    expect(find.byIcon(Icons.grass), findsOneWidget);
  });

  testWidgets('ActivityTypeDropdown opens and selects item', (WidgetTester tester) async {
    String? selectedValue;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActivityTypeDropdown(
            value: selectedValue,
            onChanged: (value) {
              selectedValue = value;
            },
          ),
        ),
      ),
    );

    // Tap the dropdown to open it
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();

    // Verify items are shown
    expect(find.text('Irrigation').last, findsOneWidget);
    expect(find.text('Harvesting').last, findsOneWidget);

    // Select an item
    await tester.tap(find.text('Irrigation').last);
    await tester.pumpAndSettle();

    expect(selectedValue, 'Irrigation');
  });

  testWidgets('ActivityTypeDropdown displays all 10 activity types', (WidgetTester tester) async {
    String? selectedValue;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActivityTypeDropdown(
            value: selectedValue,
            onChanged: (value) {
              selectedValue = value;
            },
          ),
        ),
      ),
    );

    // Open the dropdown
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();

    // Verify all activity types are present
    expect(find.text('Planting').last, findsOneWidget);
    expect(find.text('Irrigation').last, findsOneWidget);
    expect(find.text('Spraying').last, findsOneWidget);
    expect(find.text('Fertilizing').last, findsOneWidget);
    expect(find.text('Harvesting').last, findsOneWidget);
    expect(find.text('Tillage').last, findsOneWidget);
    expect(find.text('Weeding').last, findsOneWidget);
    expect(find.text('Pruning').last, findsOneWidget);
    expect(find.text('Mulching').last, findsOneWidget);
    expect(find.text('Other').last, findsOneWidget);
  });

  testWidgets('ActivityTypeDropdown displays icons for new activity types', (WidgetTester tester) async {
    String? selectedValue;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActivityTypeDropdown(
            value: selectedValue,
            onChanged: (value) {
              selectedValue = value;
            },
          ),
        ),
      ),
    );

    // Open the dropdown
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();

    // Verify icons are displayed for new activity types
    expect(find.byIcon(Icons.construction), findsOneWidget); // Tillage
    expect(find.byIcon(Icons.yard), findsOneWidget); // Weeding
    expect(find.byIcon(Icons.content_cut), findsOneWidget); // Pruning
    expect(find.byIcon(Icons.layers), findsOneWidget); // Mulching
  });

  testWidgets('ActivityTypeDropdown can select new activity types', (WidgetTester tester) async {
    String? selectedValue;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActivityTypeDropdown(
            value: selectedValue,
            onChanged: (value) {
              selectedValue = value;
            },
          ),
        ),
      ),
    );

    // Test selecting Tillage
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tillage').last);
    await tester.pumpAndSettle();
    expect(selectedValue, 'Tillage');

    // Test selecting Weeding
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weeding').last);
    await tester.pumpAndSettle();
    expect(selectedValue, 'Weeding');

    // Test selecting Pruning
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pruning').last);
    await tester.pumpAndSettle();
    expect(selectedValue, 'Pruning');
  });
}

