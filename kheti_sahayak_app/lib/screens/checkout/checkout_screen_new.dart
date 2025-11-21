import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/cart.dart';
import 'package:kheti_sahayak_app/services/cart_service.dart';
import 'package:kheti_sahayak_app/services/order_service.dart';
import 'package:kheti_sahayak_app/widgets/primary_button.dart';
import 'package:kheti_sahayak_app/widgets/loading_indicator.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pincodeController = TextEditingController();

  bool _isLoading = true;
  bool _isPlacingOrder = false;
  Cart? _cart;
  String? _error;

  String _selectedPaymentMethod = 'Cash on Delivery';
  final List<String> _paymentMethods = [
    'Cash on Delivery',
    'UPI',
    'Credit/Debit Card',
    'Net Banking',
  ];

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _loadCart() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final cart = await CartService.getCart();
      if (cart.isEmpty) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Your cart is empty')),
          );
        }
        return;
      }

      setState(() {
        _cart = cart;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final shippingAddress = '''
${_addressController.text.trim()}
Phone: ${_phoneController.text.trim()}
Pincode: ${_pincodeController.text.trim()}
''';

      final order = await OrderService.createOrderFromCart(
        shippingAddress: shippingAddress,
        paymentMethod: _selectedPaymentMethod,
      );

      if (mounted) {
        // Navigate to order confirmation screen
        Navigator.pushReplacementNamed(
          context,
          '/order-confirmation',
          arguments: order.id,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order placed successfully! Order ID: ${order.id.substring(0, 8)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _error != null
              ? _buildError()
              : _buildCheckoutForm(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load cart',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Retry',
              onPressed: _loadCart,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutForm() {
    final deliveryCharge = _cart!.summary.subtotal > 500 ? 0.0 : 50.0;
    final total = _cart!.summary.subtotal + deliveryCharge;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Summary Card
                _buildOrderSummaryCard(),

                const SizedBox(height: 24),

                // Shipping Address Section
                Text(
                  'Shipping Address',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Full Address',
                    hintText: 'House No, Street, Area, City, State',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.home),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your address';
                    }
                    if (value.trim().length < 10) {
                      return 'Please enter a complete address';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '10-digit mobile number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (value.trim().length != 10) {
                      return 'Please enter a valid 10-digit phone number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _pincodeController,
                  decoration: const InputDecoration(
                    labelText: 'Pincode',
                    hintText: '6-digit pincode',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter pincode';
                    }
                    if (value.trim().length != 6) {
                      return 'Please enter a valid 6-digit pincode';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Payment Method Section
                Text(
                  'Payment Method',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                ..._paymentMethods.map((method) => RadioListTile<String>(
                      title: Text(method),
                      value: method,
                      groupValue: _selectedPaymentMethod,
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentMethod = value!;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    )),

                const SizedBox(height: 24),

                // Price Summary
                _buildPriceSummary(deliveryCharge, total),

                const SizedBox(height: 100), // Space for bottom button
              ],
            ),
          ),
        ),

        // Place Order Button
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: PrimaryButton(
                text: _isPlacingOrder
                    ? 'Placing Order...'
                    : 'Place Order - ₹${total.toStringAsFixed(2)}',
                onPressed: _isPlacingOrder ? null : _placeOrder,
                width: double.infinity,
              ),
            ),
          ),
        ),

        if (_isPlacingOrder)
          Container(
            color: Colors.black26,
            child: const Center(child: LoadingIndicator()),
          ),
      ],
    );
  }

  Widget _buildOrderSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${_cart!.items.length} items',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
            const Divider(height: 24),
            ..._cart!.items.take(3).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.productName,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'x${item.quantity}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₹${item.totalPrice.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                )),
            if (_cart!.items.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+ ${_cart!.items.length - 3} more items',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummary(double deliveryCharge, double total) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPriceRow('Subtotal', _cart!.summary.subtotal),
            const SizedBox(height: 8),
            _buildPriceRow(
              'Delivery Charge',
              deliveryCharge,
              isFree: deliveryCharge == 0,
            ),
            const Divider(height: 24),
            _buildPriceRow('Total', total, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    double amount, {
    bool isTotal = false,
    bool isFree = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
        ),
        if (isFree)
          Text(
            'FREE',
            style: TextStyle(
              color: Colors.green[700],
              fontWeight: FontWeight.bold,
            ),
          )
        else
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  color: isTotal ? Theme.of(context).primaryColor : null,
                ),
          ),
      ],
    );
  }
}
