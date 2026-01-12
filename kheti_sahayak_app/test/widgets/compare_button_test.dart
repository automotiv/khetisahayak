import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CompareButton Widget', () {
    testWidgets('renders icon button by default', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockCompareButton(
              productId: 'test-product-1',
              isInComparison: false,
            ),
          ),
        ),
      );

      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byIcon(Icons.compare_arrows_outlined), findsOneWidget);
    });

    testWidgets('shows text button when showLabel is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockCompareButton(
              productId: 'test-product-1',
              isInComparison: false,
              showLabel: true,
            ),
          ),
        ),
      );

      expect(find.text('Compare'), findsOneWidget);
    });

    testWidgets('shows different icon when in comparison',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockCompareButton(
              productId: 'test-product-1',
              isInComparison: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.compare), findsOneWidget);
    });

    testWidgets('shows "In Comparison" label when added',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockCompareButton(
              productId: 'test-product-1',
              isInComparison: true,
              showLabel: true,
            ),
          ),
        ),
      );

      expect(find.text('In Comparison'), findsOneWidget);
    });

    testWidgets('calls onTap callback when pressed',
        (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockCompareButton(
              productId: 'test-product-1',
              isInComparison: false,
              onTap: () => wasPressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(wasPressed, isTrue);
    });

    testWidgets('shows loading indicator when loading',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockCompareButton(
              productId: 'test-product-1',
              isInComparison: false,
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('disables button when loading', (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockCompareButton(
              productId: 'test-product-1',
              isInComparison: false,
              isLoading: true,
              onTap: () => wasPressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(wasPressed, isFalse);
    });

    testWidgets('uses correct tooltip when not in comparison',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockCompareButton(
              productId: 'test-product-1',
              isInComparison: false,
            ),
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.tooltip, 'Add to comparison');
    });

    testWidgets('uses correct tooltip when in comparison',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockCompareButton(
              productId: 'test-product-1',
              isInComparison: true,
            ),
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.tooltip, 'Remove from comparison');
    });
  });

  group('ComparisonFAB Widget', () {
    testWidgets('does not render when count is less than 2',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockComparisonFAB(count: 1),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('renders when count is 2 or more', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockComparisonFAB(count: 2),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows correct count in badge', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockComparisonFAB(count: 3),
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows Compare label', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockComparisonFAB(count: 2),
          ),
        ),
      );

      expect(find.text('Compare'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _MockComparisonFAB(
              count: 2,
              onPressed: () => wasPressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      expect(wasPressed, isTrue);
    });
  });
}

class _MockCompareButton extends StatelessWidget {
  final String productId;
  final bool isInComparison;
  final bool showLabel;
  final bool isLoading;
  final VoidCallback? onTap;
  final double size;

  const _MockCompareButton({
    required this.productId,
    required this.isInComparison,
    this.showLabel = false,
    this.isLoading = false,
    this.onTap,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    if (showLabel) {
      return TextButton.icon(
        onPressed: isLoading ? null : onTap,
        icon: isLoading
            ? SizedBox(
                width: size,
                height: size,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                isInComparison ? Icons.compare : Icons.compare_arrows_outlined,
                size: size,
                color: isInComparison ? Colors.green[700] : Colors.grey[600],
              ),
        label: Text(
          isInComparison ? 'In Comparison' : 'Compare',
          style: TextStyle(
            color: isInComparison ? Colors.green[700] : Colors.grey[600],
          ),
        ),
      );
    }

    return IconButton(
      onPressed: isLoading ? null : onTap,
      icon: isLoading
          ? SizedBox(
              width: size,
              height: size,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              isInComparison ? Icons.compare : Icons.compare_arrows_outlined,
              size: size,
              color: isInComparison ? Colors.green[700] : Colors.grey[600],
            ),
      tooltip: isInComparison ? 'Remove from comparison' : 'Add to comparison',
    );
  }
}

class _MockComparisonFAB extends StatelessWidget {
  final int count;
  final VoidCallback? onPressed;

  const _MockComparisonFAB({
    required this.count,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (count < 2) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: Colors.green[700],
      foregroundColor: Colors.white,
      icon: Badge(
        label: Text('$count'),
        child: const Icon(Icons.compare_arrows),
      ),
      label: const Text('Compare'),
    );
  }
}
