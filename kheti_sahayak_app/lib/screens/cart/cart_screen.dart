import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kheti_sahayak_app/theme/app_theme.dart';
import 'package:kheti_sahayak_app/widgets/primary_button.dart';
import 'package:kheti_sahayak_app/widgets/loading_indicator.dart';
import 'package:kheti_sahayak_app/widgets/error_dialog.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = false;
  bool _isCheckingOut = false;
  
  // Mock cart data - replace with actual cart provider
  List<Map<String, dynamic>> _cartItems = [
    {
      'id': 'prod_123',
      'name': 'Organic Tomato Seeds',
      'seller': 'Green Valley Farms',
      'price': 120.0,
      'originalPrice': 150.0,
      'image': 'https://example.com/tomato_seeds.jpg',
      'quantity': 2,
      'inStock': true,
    },
    {
      'id': 'prod_456',
      'name': 'NPK Fertilizer 20-20-20',
      'seller': 'Agri Solutions',
      'price': 450.0,
      'originalPrice': 500.0,
      'image': 'https://example.com/fertilizer.jpg',
      'quantity': 1,
      'inStock': true,
    },
    {
      'id': 'prod_789',
      'name': 'Garden Trowel Set',
      'seller': 'Garden Tools Co.',
      'price': 350.0,
      'image': 'https://example.com/trowel_set.jpg',
      'quantity': 1,
      'inStock': false,
    },
  ];

  // Calculate subtotal
  double get _subtotal {
    return _cartItems.fold(0, (sum, item) {
      return sum + (item['price'] * item['quantity']);
    });
  }

  // Calculate total savings
  double get _totalSavings {
    return _cartItems.fold(0, (sum, item) {
      final originalPrice = item['originalPrice'] ?? item['price'];
      return sum + ((originalPrice - item['price']) * item['quantity']);
    });
  }

  // Calculate delivery charge
  double get _deliveryCharge {
    // Free delivery for orders above ₹500
    return _subtotal > 500 ? 0 : 50;
  }

  // Calculate total
  double get _total {
    return _subtotal + _deliveryCharge;
  }

  void _updateQuantity(int index, int newQuantity) {
    if (newQuantity > 0) {
      setState(() {
        _cartItems[index]['quantity'] = newQuantity;
      });
    }
  }

  void _removeItem(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Item'),
        content: const Text('Are you sure you want to remove this item from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _cartItems.removeAt(index);
              });
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Item removed from cart')),
              );
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _saveForLater(int index) {
    // TODO: Implement save for later functionality
    setState(() {
      final item = _cartItems.removeAt(index);
      // Add to saved items
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item saved for later')),
    );
  }

  void _proceedToCheckout() {
    setState(() => _isCheckingOut = true);
    // TODO: Implement checkout process
    Future.delayed(const Duration(seconds: 1), () {
      setState(() => _isCheckingOut = false);
      Navigator.pushNamed(context, '/checkout');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: LoadingIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _cartItems.isEmpty ? null : () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear Cart'),
                  content: const Text('Are you sure you want to remove all items from your cart?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _cartItems.clear());
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cart cleared')),
                        );
                      },
                      child: const Text('Clear', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _cartItems.isEmpty
          ? _buildEmptyCart(theme)
          : Column(
              children: [
                // Cart items list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) => _buildCartItem(
                      context,
                      _cartItems[index],
                      index,
                    ),
                  ),
                ),
                
                // Order summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                    border: Border(
                      top: BorderSide(
                        color: theme.dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Price details
                      _buildPriceRow(
                        'Subtotal',
                        _formatCurrency(_subtotal),
                      ),
                      if (_totalSavings > 0)
                        _buildPriceRow(
                          'Total Savings',
                          '-${_formatCurrency(_totalSavings)}',
                        ),
                      _buildPriceRow(
                        'Delivery Charge',
                        _deliveryCharge == 0
                            ? 'FREE'
                            : _formatCurrency(_deliveryCharge),
                      ),
                      const Divider(height: 24),
                      _buildPriceRow(
                        'Total Amount',
                        _formatCurrency(_total),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Checkout button
                      PrimaryButton(
                        onPressed: _isCheckingOut ? null : _proceedToCheckout,
                        text: _isCheckingOut
                            ? 'Processing...'
                            : 'Proceed to Checkout (${_formatCurrency(_total)})',
                        isLoading: _isCheckingOut,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Payment methods
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildPaymentIcon('assets/images/visa.png'),
                          const SizedBox(width: 8),
                          _buildPaymentIcon('assets/images/mastercard.png'),
                          const SizedBox(width: 8),
                          _buildPaymentIcon('assets/images/upi.png'),
                          const SizedBox(width: 8),
                          _buildPaymentIcon('assets/images/cod.png'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    Map<String, dynamic> item,
    int index,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: colorScheme.surfaceVariant,
                    image: DecorationImage(
                      image: NetworkImage(item['image']),
                      fit: BoxFit.cover,
                      onError: (_, __) => const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Product details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product name and price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item['name'],
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '₹${item['price']}'
                                .replaceAllMapped(
                                  RegExp(r'(\d)(?=(\d{2})+(?!\d))'),
                                  (match) => '${match[1]},',
                                ),
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      
                      // Seller
                      Text(
                        'Sold by: ${item['seller']}',
                        style: textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      
                      // Out of stock warning
                      if (item['inStock'] == false)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, size: 14, color: Colors.orange),
                              const SizedBox(width: 4),
                              Text(
                                'Out of stock',
                                style: textTheme.labelSmall?.copyWith(
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Quantity selector
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Quantity controls
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: theme.dividerColor),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 18),
                                  onPressed: item['quantity'] > 1
                                      ? () => _updateQuantity(
                                          index, item['quantity'] - 1)
                                      : null,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                SizedBox(
                                  width: 30,
                                  child: Text(
                                    '${item['quantity']}',
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodyMedium,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 18),
                                  onPressed: () => _updateQuantity(
                                      index, item['quantity'] + 1),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                          
                          const Spacer(),
                          
                          // Total price
                          Text(
                            '₹${(item['price'] * item['quantity']).toStringAsFixed(2)}'
                                .replaceAllMapped(
                                  RegExp(r'(\d)(?=(\d{2})+(?!\d))'),
                                  (match) => '${match[1]},',
                                ),
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Action buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () => _saveForLater(index),
                  icon: const Icon(Icons.bookmark_border, size: 18),
                  label: const Text('Save for later'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 36),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _removeItem(index),
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  label: const Text('Remove', style: TextStyle(color: Colors.red)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 36),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: theme.hintColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Your cart is empty',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Looks like you haven\'t added anything to your cart yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              onPressed: () {
                // Navigate to home or marketplace
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              text: 'Continue Shopping',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
          Text(
            value.startsWith('₹') ? value : '₹$value',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentIcon(String assetPath) {
    return Container(
      width: 40,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade200),
        image: DecorationImage(
          image: AssetImage(assetPath),
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{2})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }
}
