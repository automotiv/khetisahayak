import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kheti_sahayak_app/widgets/error_dialog.dart';

void main() {
  testWidgets('ErrorDialog shows title and content', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                ErrorDialog.show(
                  context,
                  title: 'Test Error',
                  content: 'This is a test error message.',
                );
              },
              child: const Text('Show Error'),
            ),
          ),
        ),
      ),
    );

    // Tap the button to show the dialog
    await tester.tap(find.text('Show Error'));
    await tester.pump();

    // Verify the dialog is shown with correct content
    expect(find.text('Test Error'), findsOneWidget);
    expect(find.text('This is a test error message.'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
  });

  testWidgets('ErrorDialog shows custom button text', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                ErrorDialog.show(
                  context,
                  title: 'Custom Button',
                  content: 'With custom button text',
                  buttonText: 'Close',
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Dialog'));
    await tester.pump();

    expect(find.text('Custom Button'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
  });

  testWidgets('ErrorDialog shows retry button when onRetry is provided', (WidgetTester tester) async {
    bool retryPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                ErrorDialog.show(
                  context,
                  title: 'Test Error',
                  content: 'Please try again.',
                  onRetry: () {
                    retryPressed = true;
                  },
                );
              },
              child: const Text('Show Error'),
            ),
          ),
        ),
      ),
    );

    // Tap the button to show the dialog
    await tester.tap(find.text('Show Error'));
    await tester.pump();

    // Verify the retry button is shown
    expect(find.text('Retry'), findsOneWidget);
    
    // Tap the retry button
    await tester.tap(find.text('Retry'));
    await tester.pump();

    // Verify the retry callback was called
    expect(retryPressed, isTrue);
  });

  testWidgets('ErrorDialog shows custom retry button text', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                ErrorDialog.show(
                  context,
                  title: 'Custom Retry',
                  content: 'Try with custom text',
                  onRetry: () {},
                  retryButtonText: 'Try Again',
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Dialog'));
    await tester.pump();

    expect(find.text('Try Again'), findsOneWidget);
  });

  testWidgets('ErrorDialog can be dismissed by tapping OK', (WidgetTester tester) async {
    bool dialogDismissed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                TextButton(
                  onPressed: () {
                    ErrorDialog.show(
                      context,
                      title: 'Dismiss Test',
                      content: 'This dialog can be dismissed',
                      onPressed: () {
                        dialogDismissed = true;
                        Navigator.of(context).pop();
                      },
                    );
                  },
                  child: const Text('Show Dialog'),
                ),
                Text(dialogDismissed ? 'Dialog Dismissed' : 'Dialog Not Dismissed'),
              ],
            ),
          ),
        ),
      ),
    );

    // Initial state
    expect(find.text('Dialog Not Dismissed'), findsOneWidget);

    // Show dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pump();

    // Dismiss dialog by tapping OK
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Verify dialog was dismissed
    expect(find.text('Dialog Dismissed'), findsOneWidget);
  });
}
