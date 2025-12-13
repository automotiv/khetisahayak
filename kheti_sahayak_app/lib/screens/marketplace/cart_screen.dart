import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/cart.dart';
import 'package:kheti_sahayak_app/models/order.dart';
import 'package:kheti_sahayak_app/services/marketplace_service.dart';
import 'package:uuid/uuid.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartItem> _cartItems = [];
  bool _isLoading = true;
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() => _isLoading = true);
    final items = await MarketplaceService.getCart();
    if (mounted) {
      setState(() {
        _cartItems = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateQuantity(CartItem item, int newQuantity) async {
    await MarketplaceService.updateCartQuantity(item.id, newQuantity, item.unitPrice);
    _loadCart();
  }

  Future<void> _placeOrder() async {
    if (_cartItems.isEmpty) return;

    setState(() => _isPlacingOrder = true);

    final totalAmount = _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    final order = Order(
      id: const Uuid().v4(),
      items: _cartItems,
      totalAmount: totalAmount,
      status: 'pending',
      paymentMethod: 'COD', // Default for now
      shippingAddress: 'Default Address', // Should come from user profile
      createdAt: DateTime.now(),
    );

    final success = await MarketplaceService.placeOrder(order);

    if (mounted) {
      setState(() => _isPlacingOrder = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to place order')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        backgroundColor: Colors.green[700],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
              ? const Center(child: Text('Your cart is empty.'))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _cartItems.length,
                        itemBuilder: (context, index) {
                          final item = _cartItems[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[200],
                                    child: item.productImages != null && item.productImages!.isNotEmpty
                                        ? Image.network(item.productImages!.first, fit: BoxFit.cover)
                                        : const Icon(Icons.image, color: Colors.grey),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.productName,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text('₹${item.unitPrice}'),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline),
                                        onPressed: () => _updateQuantity(item, item.quantity - 1),
                                      ),
                                      Text('${item.quantity}'),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline),
                                        onPressed: () => _updateQuantity(item, item.quantity + 1),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total:',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '₹$totalAmount',
                                style: TextStyle(fontSize: 20, color: Colors.green[700], fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isPlacingOrder ? null : _placeOrder,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: _isPlacingOrder
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text('Place Order'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
