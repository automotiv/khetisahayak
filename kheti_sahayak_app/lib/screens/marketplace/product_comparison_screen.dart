import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/services/product_comparison_service.dart';
import 'package:kheti_sahayak_app/services/cart_service.dart';
import 'package:kheti_sahayak_app/routes/routes.dart';

class ProductComparisonScreen extends StatefulWidget {
  final List<String>? productIds;

  const ProductComparisonScreen({Key? key, this.productIds}) : super(key: key);

  @override
  State<ProductComparisonScreen> createState() =>
      _ProductComparisonScreenState();
}

class _ProductComparisonScreenState extends State<ProductComparisonScreen> {
  ComparisonResult? _result;
  bool _isLoading = true;
  String? _error;
  List<String> _productIds = [];

  @override
  void initState() {
    super.initState();
    _loadComparison();
  }

  Future<void> _loadComparison() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _productIds =
          widget.productIds ?? await ProductComparisonService.getComparisonList();

      if (_productIds.length < 2) {
        setState(() {
          _isLoading = false;
          _error = 'Add at least 2 products to compare';
        });
        return;
      }

      final result =
          await ProductComparisonService.compareProducts(_productIds);

      if (mounted) {
        setState(() {
          _result = result;
          _isLoading = false;
          if (result == null) {
            _error = 'Failed to load comparison data';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _removeProduct(String productId) async {
    await ProductComparisonService.removeFromComparison(productId);
    _loadComparison();
  }

  Future<void> _addToCart(Map<String, dynamic> product) async {
    try {
      await CartService.addToCart(
        productId: product['id'],
        quantity: 1,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product['name']} added to cart'),
            action: SnackBarAction(
              label: 'View Cart',
              onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add to cart: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Products'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          if (_productIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () async {
                await ProductComparisonService.clearComparison();
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              tooltip: 'Clear comparison',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.compare_arrows, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.marketplace),
                icon: const Icon(Icons.shopping_bag),
                label: const Text('Browse Products'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_result == null) {
      return const Center(child: Text('No data available'));
    }

    return Column(
      children: [
        _buildSummaryCard(),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: _buildComparisonTable(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final summary = _result!.summary;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            icon: Icons.attach_money,
            label: 'Lowest Price',
            value: '₹${summary.lowestPrice.toStringAsFixed(0)}',
            color: Colors.green[700]!,
          ),
          _buildSummaryItem(
            icon: Icons.star,
            label: 'Highest Rating',
            value: summary.highestRating.toStringAsFixed(1),
            color: Colors.amber[700]!,
          ),
          _buildSummaryItem(
            icon: Icons.compare_arrows,
            label: 'Products',
            value: '${summary.productCount}',
            color: Colors.blue[700]!,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildComparisonTable() {
    final products = _result!.products;
    final attributes = _result!.attributes;
    
    final columnWidth = 160.0;
    final labelWidth = 120.0;

    return DataTable(
      columnSpacing: 8,
      headingRowHeight: 180,
      dataRowMinHeight: 48,
      dataRowMaxHeight: 80,
      columns: [
        DataColumn(
          label: SizedBox(
            width: labelWidth,
            child: const Text(
              'Feature',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        ...products.map((product) => DataColumn(
              label: SizedBox(
                width: columnWidth,
                child: _buildProductHeader(product),
              ),
            )),
      ],
      rows: attributes.map((attr) => _buildAttributeRow(attr, products, labelWidth, columnWidth)).toList(),
    );
  }

  Widget _buildProductHeader(Map<String, dynamic> product) {
    final images = product['image_urls'] as List?;
    final imageUrl = images?.isNotEmpty == true ? images!.first : null;
    final isLowestPrice = product['price'] == _result!.summary.lowestPrice;
    final isHighestRated =
        (product['avg_rating'] ?? 0) == _result!.summary.highestRating &&
            _result!.summary.highestRating > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.eco, size: 40, color: Colors.green),
                      ),
                    )
                  : const Icon(Icons.eco, size: 40, color: Colors.green),
            ),
            if (isLowestPrice)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Best Price',
                    style: TextStyle(color: Colors.white, fontSize: 8),
                  ),
                ),
              ),
            if (isHighestRated && !isLowestPrice)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Top Rated',
                    style: TextStyle(color: Colors.black, fontSize: 8),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          product['name'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 24,
              child: IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: () => _removeProduct(product['id']),
                padding: EdgeInsets.zero,
                tooltip: 'Remove',
              ),
            ),
            SizedBox(
              height: 24,
              child: IconButton(
                icon: const Icon(Icons.add_shopping_cart, size: 16),
                onPressed: () => _addToCart(product),
                padding: EdgeInsets.zero,
                color: Colors.green[700],
                tooltip: 'Add to cart',
              ),
            ),
          ],
        ),
      ],
    );
  }

  DataRow _buildAttributeRow(
    ComparisonAttribute attr,
    List<Map<String, dynamic>> products,
    double labelWidth,
    double columnWidth,
  ) {
    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: labelWidth,
            child: Text(
              attr.label,
              style: TextStyle(
                fontWeight: attr.isSpec ? FontWeight.normal : FontWeight.w500,
                color: attr.isSpec ? Colors.grey[700] : Colors.black,
              ),
            ),
          ),
        ),
        ...products.map((product) {
          final value = product[attr.key];
          return DataCell(
            SizedBox(
              width: columnWidth,
              child: _buildAttributeValue(attr, value, products),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAttributeValue(
    ComparisonAttribute attr,
    dynamic value,
    List<Map<String, dynamic>> products,
  ) {
    if (value == null) {
      return Text('-', style: TextStyle(color: Colors.grey[400]));
    }

    switch (attr.type) {
      case 'currency':
        final price = (value as num).toDouble();
        final isLowest = price == _result!.summary.lowestPrice;
        return Text(
          '₹${price.toStringAsFixed(0)}',
          style: TextStyle(
            fontWeight: isLowest ? FontWeight.bold : FontWeight.normal,
            color: isLowest ? Colors.green[700] : Colors.black,
          ),
        );

      case 'rating':
        final rating = (value as num).toDouble();
        final isHighest = rating == _result!.summary.highestRating && rating > 0;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star,
              size: 16,
              color: isHighest ? Colors.amber : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              rating.toStringAsFixed(1),
              style: TextStyle(
                fontWeight: isHighest ? FontWeight.bold : FontWeight.normal,
                color: isHighest ? Colors.amber[800] : Colors.black,
              ),
            ),
          ],
        );

      case 'boolean':
        final boolVal = value == true;
        return Icon(
          boolVal ? Icons.check_circle : Icons.cancel,
          color: boolVal ? Colors.green : Colors.red[300],
          size: 20,
        );

      case 'number':
        return Text(value.toString());

      default:
        return Text(
          value.toString(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
    }
  }
}
