import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kheti_sahayak_app/widgets/activity_type_dropdown.dart';

void main() {
  testWidgets('ActivityTypeDropdown shows selected value', (WidgetTester tester) async {
    String? selectedValue = 'Sowing';

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

    expect(find.text('Sowing'), findsOneWidget);
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
}
