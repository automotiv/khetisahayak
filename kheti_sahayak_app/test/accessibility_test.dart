import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kheti_sahayak_app/widgets/primary_button.dart';
import 'package:kheti_sahayak_app/widgets/custom_text_field.dart';

void main() {
  testWidgets('PrimaryButton has semantic label', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryButton(
            onPressed: () {},
            text: 'Click Me',
            semanticLabel: 'Submit Button',
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Submit Button'), findsOneWidget);
  });

  testWidgets('CustomTextField has semantic label', (WidgetTester tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomTextField(
            controller: controller,
            label: 'Email',
            semanticLabel: 'Enter your email address',
            icon: Icons.email,
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Enter your email address'), findsOneWidget);
  });
}
