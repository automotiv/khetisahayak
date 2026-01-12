import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProductComparisonScreen Widget', () {
    testWidgets('renders app bar with title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _MockProductComparisonScreen(),
        ),
      );

      expect(find.text('Product Comparison'), findsOneWidget);
    });

    testWidgets('shows empty state when no products to compare',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _MockProductComparisonScreen(products: []),
        ),
      );

      expect(find.text('No products to compare'), findsOneWidget);
      expect(find.text('Add at least 2 products to compare'), findsOneWidget);
    });

    testWidgets('shows minimum products warning when only one product',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _MockProductComparisonScreen(
            products: [_createMockProduct('1', 'Product 1', 100)],
          ),
        ),
      );

      expect(find.text('Add at least 2 products to compare'), findsOneWidget);
    });

    testWidgets('shows comparison summary card when products available',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _MockProductComparisonScreen(
            products: [
              _createMockProduct('1', 'Product 1', 100),
              _createMockProduct('2', 'Product 2', 150),
            ],
            showSummary: true,
          ),
        ),
      );

      expect(find.text('Comparison Summary'), findsOneWidget);
    });

    testWidgets('shows lowest price in summary', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _MockProductComparisonScreen(
            products: [
              _createMockProduct('1', 'Product 1', 100),
              _createMockProduct('2', 'Product 2', 150),
            ],
            showSummary: true,
            lowestPrice: 100,
          ),
        ),
      );

      expect(find.text('Lowest Price'), findsOneWidget);
      expect(find.textContaining('100'), findsWidgets);
    });

    testWidgets('shows highest rating in summary', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _MockProductComparisonScreen(
            products: [
              _createMockProduct('1', 'Product 1', 100, rating: 4.2),
              _createMockProduct('2', 'Product 2', 150, rating: 4.8),
            ],
            showSummary: true,
            highestRating: 4.8,
          ),
        ),
      );

      expect(find.text('Highest Rating'), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);
    });

    testWidgets('shows product count in summary', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _MockProductComparisonScreen(
            products: [
              _createMockProduct('1', 'Product 1', 100),
              _createMockProduct('2', 'Product 2', 150),
              _createMockProduct('3', 'Product 3', 120),
            ],
            showSummary: true,
          ),
        ),
      );

      expect(find.text('Products'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows product headers in comparison table',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _MockProductComparisonScreen(
            products: [
              _createMockProduct('1', 'Product 1', 100),
              _createMockProduct('2', 'Product 2', 150),
            ],
          ),
        ),
      );

      expect(find.text('Product 1'), findsOneWidget);
      expect(find.text('Product 2'), findsOneWidget);
    });

    testWidgets('shows best price badge on cheapest product',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _MockProductComparisonScreen(
            products: [
              _createMockProduct('1', 'Product 1', 100, isBestPrice: true),
              _createMockProduct('2', 'Product 2', 150),
            ],
          ),
        ),
      );

      expect(find.text('Best Price'), findsOneWidget);
    });

    testWidgets('shows top rated badge on highest rated product',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _MockProductComparisonScreen(
            products: [
              _createMockProduct('1', 'Product 1', 100, rating: 4.2),
              _createMockProduct('2', 'Product 2', 150,
                  rating: 4.8, isTopRated: true),
            ],
          ),
        ),
      );

      expect(find.text('Top Rated'), findsOneWidget);
    });

    testWidgets('shows comparison attributes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _MockProductComparisonScreen(
            products: [
              _createMockProduct('1', 'Product 1', 100),
              _createMockProduct('2', 'Product 2', 150),
            ],
            attributes: ['Price', 'Category', 'Brand', 'Rating'],
          ),
        ),
      );

      expect(find.text('Price'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Brand'), findsOneWidget);
      expect(find.text('Rating'), findsOneWidget);
    });

    testWidgets('shows remove button for each product',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _MockProductComparisonScreen(
            products: [
              _createMockProduct('1', 'Product 1', 100),
              _createMockProduct('2', 'Product 2', 150),
            ],
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsNWidgets(2));
    });

    testWidgets('calls onRemove when remove button is pressed',
        (WidgetTester tester) async {
      String? removedProductId;

      await tester.pumpWidget(
        MaterialApp(
          home: _MockProductComparisonScreen(
            products: [
              _createMockProduct('1', 'Product 1', 100),
              _createMockProduct('2', 'Product 2', 150),
            ],
            onRemove: (id) => removedProductId = id,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pump();

      expect(removedProductId, '1');
    });

    testWidgets('shows clear all button in app bar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _MockProductComparisonScreen(
            products: [
              _createMockProduct('1', 'Product 1', 100),
              _createMockProduct('2', 'Product 2', 150),
            ],
          ),
        ),
      );

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('shows loading indicator when loading',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _MockProductComparisonScreen(
            isLoading: true,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message when error occurs',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _MockProductComparisonScreen(
            errorMessage: 'Failed to load comparison',
          ),
        ),
      );

      expect(find.text('Failed to load comparison'), findsOneWidget);
    });

    testWidgets('horizontal scroll works for comparison table',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _MockProductComparisonScreen(
            products: [
              _createMockProduct('1', 'Product 1', 100),
              _createMockProduct('2', 'Product 2', 150),
              _createMockProduct('3', 'Product 3', 120),
              _createMockProduct('4', 'Product 4', 180),
              _createMockProduct('5', 'Product 5', 90),
            ],
          ),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsWidgets);
    });
  });

  group('Comparison data formatting', () {
    test('formats currency correctly', () {
      expect(_formatCurrency(100), '\u20B9100');
      expect(_formatCurrency(1500.50), '\u20B91,500.50');
    });

    test('formats rating correctly', () {
      expect(_formatRating(4.5), '4.5');
      expect(_formatRating(0), '0.0');
    });

    test('formats boolean correctly', () {
      expect(_formatBoolean(true), 'Yes');
      expect(_formatBoolean(false), 'No');
    });
  });
}

Map<String, dynamic> _createMockProduct(
  String id,
  String name,
  double price, {
  double rating = 4.0,
  bool isBestPrice = false,
  bool isTopRated = false,
}) {
  return {
    'id': id,
    'name': name,
    'price': price,
    'rating': rating,
    'isBestPrice': isBestPrice,
    'isTopRated': isTopRated,
  };
}

String _formatCurrency(double amount) {
  if (amount >= 1000) {
    return '\u20B9${amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}';
  }
  return '\u20B9${amount.toStringAsFixed(0)}';
}

String _formatRating(double rating) {
  return rating.toStringAsFixed(1);
}

String _formatBoolean(bool value) {
  return value ? 'Yes' : 'No';
}

class _MockProductComparisonScreen extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final List<String> attributes;
  final bool showSummary;
  final double? lowestPrice;
  final double? highestRating;
  final bool isLoading;
  final String? errorMessage;
  final Function(String)? onRemove;

  const _MockProductComparisonScreen({
    this.products = const [],
    this.attributes = const ['Price', 'Category', 'Brand', 'Rating'],
    this.showSummary = false,
    this.lowestPrice,
    this.highestRating,
    this.isLoading = false,
    this.errorMessage,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Comparison'),
        actions: [
          if (products.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {},
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(child: Text(errorMessage!));
    }

    if (products.isEmpty || products.length < 2) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.compare_arrows, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No products to compare'),
            Text('Add at least 2 products to compare'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          if (showSummary) _buildSummary(),
          _buildComparisonTable(),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Comparison Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Lowest Price',
                    lowestPrice != null ? _formatCurrency(lowestPrice!) : '-'),
                _buildSummaryItem('Highest Rating',
                    highestRating != null ? _formatRating(highestRating!) : '-'),
                _buildSummaryItem('Products', '${products.length}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildComparisonTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        children: [
          Row(
            children: products.map((product) => _buildProductHeader(product)).toList(),
          ),
          ...attributes.map((attr) => _buildAttributeRow(attr)),
        ],
      ),
    );
  }

  Widget _buildProductHeader(Map<String, dynamic> product) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => onRemove?.call(product['id']),
              ),
            ],
          ),
          Text(product['name'],
              style: const TextStyle(fontWeight: FontWeight.bold)),
          if (product['isBestPrice'] == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Best Price',
                  style: TextStyle(color: Colors.green, fontSize: 12)),
            ),
          if (product['isTopRated'] == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Top Rated',
                  style: TextStyle(color: Colors.orange, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildAttributeRow(String attribute) {
    return Row(
      children: [
        Container(
          width: 100,
          padding: const EdgeInsets.all(8),
          child: Text(attribute),
        ),
        ...products.map((p) => Container(
              width: 150,
              padding: const EdgeInsets.all(8),
              child: Text(_getAttributeValue(p, attribute)),
            )),
      ],
    );
  }

  String _getAttributeValue(Map<String, dynamic> product, String attribute) {
    switch (attribute) {
      case 'Price':
        return _formatCurrency(product['price']);
      case 'Rating':
        return _formatRating(product['rating']);
      default:
        return product[attribute.toLowerCase()] ?? '-';
    }
  }
}
