import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kheti_sahayak_app/providers/cart_provider.dart';
import 'package:kheti_sahayak_app/providers/order_provider.dart';
import 'package:kheti_sahayak_app/theme/app_theme.dart';
import 'package:kheti_sahayak_app/widgets/primary_button.dart';
import 'package:kheti_sahayak_app/widgets/loading_indicator.dart';
import 'package:kheti_sahayak_app/widgets/error_dialog.dart';
import 'package:kheti_sahayak_app/screens/checkout/order_confirmation_screen.dart';
import 'package:kheti_sahayak_app/services/payment_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _addressController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  
  bool _isLoading = false;
  bool _isPlacingOrder = false;
  int _selectedAddressIndex = 0;
  int _selectedPaymentMethod = 0; // 0: UPI, 1: Card, 2: Net Banking, 3: COD
  
  // Payment service instance
  final PaymentService _paymentService = PaymentService.instance;
  String? _currentOrderId; // Track current order for payment
  
  // Saved addresses
  final List<Map<String, dynamic>> _savedAddresses = [
    {
      'id': 'addr_1',
      'name': 'Rahul Sharma',
      'phone': '9876543210',
      'address': '123, Green Valley Farms',
      'landmark': 'Near Bus Stand',
      'city': 'Nashik',
      'state': 'Maharashtra',
      'pincode': '422001',
      'type': 'Home',
      'isDefault': true,
    },
    {
      'id': 'addr_2',
      'name': 'Rahul Sharma',
      'phone': '9876543210',
      'address': '456, Sunshine Apartments, Sector 12',
      'landmark': 'Opposite City Mall',
      'city': 'Pune',
      'state': 'Maharashtra',
      'pincode': '411001',
      'type': 'Work',
      'isDefault': false,
    },
  ];
  
  @override
  void initState() {
    super.initState();
    // Load cart data
    _loadCartData();
    // Initialize payment service
    _initPaymentService();
  }
  
  /// Initialize payment service with callbacks
  Future<void> _initPaymentService() async {
    await _paymentService.init(
      onSuccess: _handlePaymentSuccess,
      onError: _handlePaymentError,
      onWalletSelected: _handleWalletSelected,
    );
  }
  
  /// Handle successful payment from Razorpay
  void _handlePaymentSuccess(Map<String, dynamic> response) async {
    debugPrint('Payment Success: $response');
    
    // Verify payment on backend
    final verifyResult = await _paymentService.verifyPayment(
      razorpayOrderId: response['razorpay_order_id'] ?? '',
      razorpayPaymentId: response['razorpay_payment_id'] ?? '',
      razorpaySignature: response['razorpay_signature'] ?? '',
    );
    
    if (verifyResult.success && mounted) {
      // Clear cart after successful payment
      final cartProvider = context.read<CartProvider>();
      cartProvider.clearAfterOrder();
      
      // Navigate to order confirmation
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderConfirmationScreen(
            orderId: _currentOrderId ?? verifyResult.orderId ?? '',
          ),
        ),
      );
    } else if (mounted) {
      // Show verification error
      showDialog(
        context: context,
        builder: (ctx) => ErrorDialog(
          title: 'Payment Verification Failed',
          content: verifyResult.error ?? 'Could not verify payment. Please contact support.',
        ),
      );
    }
    
    setState(() => _isPlacingOrder = false);
  }
  
  /// Handle payment error from Razorpay
  void _handlePaymentError(Map<String, dynamic> response) {
    debugPrint('Payment Error: $response');
    
    if (mounted) {
      setState(() => _isPlacingOrder = false);
      
      showDialog(
        context: context,
        builder: (ctx) => ErrorDialog(
          title: 'Payment Failed',
          content: response['message'] ?? 'Payment could not be completed. Please try again.',
        ),
      );
    }
  }
  
  /// Handle external wallet selection
  void _handleWalletSelected() {
    debugPrint('External wallet selected');
    // External wallet flow is handled by Razorpay SDK
  }
  
  @override
  void dispose() {
    _paymentService.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _pincodeController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }
  
  Future<void> _loadCartData() async {
    final cartProvider = context.read<CartProvider>();
    
    // If cart is empty, show empty state
    if (cartProvider.isEmpty) {
      if (mounted) {
        Navigator.pop(context); // Go back to cart screen
      }
      return;
    }
    
    // Pre-fill first address if available
    if (_savedAddresses.isNotEmpty) {
      _fillAddress(_savedAddresses[_selectedAddressIndex]);
    }
  }
  
  void _fillAddress(Map<String, dynamic> address) {
    _nameController.text = address['name'];
    _phoneController.text = address['phone'];
    _addressController.text = address['address'];
    _landmarkController.text = address['landmark'];
    _cityController.text = address['city'];
    _stateController.text = address['state'];
    _pincodeController.text = address['pincode'];
  }
  
  void _selectAddress(int index) {
    setState(() {
      _selectedAddressIndex = index;
      _fillAddress(_savedAddresses[index]);
    });
  }
  
  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() => _isPlacingOrder = true);
    
    try {
      final cartProvider = context.read<CartProvider>();
      final orderProvider = context.read<OrderProvider>();
      
      // Prepare shipping address
      final shippingAddress = '''
${_nameController.text}
${_addressController.text}
${_landmarkController.text.isNotEmpty ? '${_landmarkController.text}, ' : ''}
${_cityController.text}, ${_stateController.text}
${_pincodeController.text}
Phone: ${_phoneController.text}
      '''.trim();
      
      // Get payment method
      final paymentMethods = ['UPI', 'Credit/Debit Card', 'Net Banking', 'Cash on Delivery'];
      final paymentMethod = paymentMethods[_selectedPaymentMethod];
      final isCOD = _selectedPaymentMethod == 3; // Cash on Delivery
      
      // Place order first (with pending payment status for online payments)
      final order = await orderProvider.placeOrder(
        items: cartProvider.items,
        shippingAddress: shippingAddress,
        paymentMethod: paymentMethod,
        paymentStatus: isCOD ? 'COD' : 'Pending',
        discount: cartProvider.couponDiscount,
      );
      
      if (order != null) {
        _currentOrderId = order.id;
        
        if (isCOD) {
          // For COD, directly go to confirmation
          cartProvider.clearAfterOrder();
          
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => OrderConfirmationScreen(orderId: order.id),
              ),
            );
          }
        } else {
          // For online payments, initiate Razorpay payment
          await _initiateRazorpayPayment(order.id, cartProvider.total);
        }
      } else {
        // Show error if order placement failed
        if (mounted) {
          setState(() => _isPlacingOrder = false);
          showDialog(
            context: context,
            builder: (ctx) => ErrorDialog(
              title: 'Order Failed',
              content: orderProvider.error ?? 'Failed to place order. Please try again.',
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error placing order: $e');
      if (mounted) {
        setState(() => _isPlacingOrder = false);
        showDialog(
          context: context,
          builder: (ctx) => const ErrorDialog(
            title: 'Error',
            content: 'An error occurred while placing your order. Please try again.',
          ),
        );
      }
    }
  }
  
  /// Initiate Razorpay payment for the order
  Future<void> _initiateRazorpayPayment(String orderId, double amount) async {
    try {
      // Initialize payment on backend to get Razorpay order ID
      final initResult = await _paymentService.initiatePayment(orderId);
      
      if (initResult.success) {
        // Open Razorpay checkout
        await _paymentService.openCheckout(
          razorpayOrderId: initResult.razorpayOrderId!,
          amount: initResult.amount!, // Amount in paise from backend
          key: initResult.key!,
          name: 'Kheti Sahayak',
          description: 'Order #${orderId.substring(0, 8)}',
          email: _getEmail(),
          contact: _phoneController.text,
          currency: initResult.currency ?? 'INR',
          notes: {
            'order_id': orderId,
            'customer_name': _nameController.text,
          },
        );
      } else {
        // Payment initiation failed
        if (mounted) {
          setState(() => _isPlacingOrder = false);
          showDialog(
            context: context,
            builder: (ctx) => ErrorDialog(
              title: 'Payment Initiation Failed',
              content: initResult.error ?? 'Could not initiate payment. Please try again.',
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error initiating Razorpay payment: $e');
      if (mounted) {
        setState(() => _isPlacingOrder = false);
        showDialog(
          context: context,
          builder: (ctx) => const ErrorDialog(
            title: 'Payment Error',
            content: 'Could not start payment process. Please try again.',
          ),
        );
      }
    }
  }
  
  /// Get user email (placeholder - should come from user profile)
  String _getEmail() {
    // TODO: Get from user profile/auth service
    return '';
  }
  
  void _addNewAddress() {
    // Show add new address dialog
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildAddAddressSheet(),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        if (cartProvider.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Checkout'),
              centerTitle: true,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text('Add some items to your cart first'),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    onPressed: () => Navigator.pop(context),
                    text: 'Back to Cart',
                  ),
                ],
              ),
            ),
          );
        }
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Checkout'),
            centerTitle: true,
          ),
          body: _isLoading
              ? const Center(child: LoadingIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Delivery Address Section
                      _buildAddressSection(),
                      
                      // Delivery Method Section
                      _buildDeliveryMethodSection(),
                      
                      // Order Summary Section
                      _buildOrderSummary(),
                      
                      // Payment Method Section
                      _buildPaymentMethodSection(),
                      
                      // Terms and Conditions
                      _buildTermsAndConditions(context),
                      
                      // Place Order Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: PrimaryButton(
                          onPressed: _isPlacingOrder ? null : _placeOrder,
                          text: _isPlacingOrder 
                              ? 'Placing Order...' 
                              : 'Place Order (${_formatCurrency(cartProvider.total)})',
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
  
  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    String? actionText,
    VoidCallback? onAction,
  }) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (actionText != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 24),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildAddressCard(
    BuildContext context, {
    required Map<String, dynamic> address,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : theme.dividerColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    address['type'],
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (address['isDefault'] == true) ...[
                  const SizedBox(width: 8),
                  Text(
                    'DEFAULT',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.hintColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              address['name'],
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${address['address']}, ${address['landmark']}',
              style: theme.textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${address['city']}, ${address['state']} - ${address['pincode']}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Phone: ${address['phone']}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAddAddressCard(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: _addNewAddress,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.dividerColor,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              color: theme.hintColor,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Add New',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAddressForm(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your name';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            prefixIcon: Icon(Icons.phone_outlined),
            prefixText: '+91 ',
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your phone number';
            }
            if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
              return 'Please enter a valid 10-digit phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _pincodeController,
          decoration: const InputDecoration(
            labelText: 'Pincode',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter pincode';
            }
            if (!RegExp(r'^[0-9]{6}$').hasMatch(value)) {
              return 'Please enter a valid 6-digit pincode';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Address (House No, Building, Street)',
            prefixIcon: Icon(Icons.home_outlined),
          ),
          maxLines: 2,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your address';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _landmarkController,
          decoration: const InputDecoration(
            labelText: 'Landmark (Optional)',
            prefixIcon: Icon(Icons.place_outlined),
            hintText: 'E.g. Near bus stand, behind hospital',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter city';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _stateController,
                decoration: const InputDecoration(
                  labelText: 'State',
                  prefixIcon: Icon(Icons.map_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter state';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Checkbox(
              value: true,
              onChanged: (value) {},
              activeColor: theme.colorScheme.primary,
            ),
            const Text('Make this my default address'),
          ],
        ),
        const SizedBox(height: 8),
        PrimaryButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // Save address
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Address saved successfully')),
              );
            }
          },
          text: 'Save Address',
        ),
      ],
    );
  }
  
  Widget _buildDeliveryMethodCard(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.delivery_dining_outlined, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Standard Delivery',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '₹0',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Free delivery on orders above ₹500',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Estimated delivery: ${_getDeliveryDate()}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOrderSummary() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, _) {
        final subtotal = cartProvider.subtotal;
        final deliveryCharge = cartProvider.deliveryCharge;
        final total = cartProvider.total;
        final theme = Theme.of(context);
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPriceRow('Subtotal', subtotal.toStringAsFixed(2), theme),
                _buildPriceRow('Delivery', deliveryCharge == 0 ? 'FREE' : deliveryCharge.toStringAsFixed(2), theme),
                const Divider(),
                _buildPriceRow('Total', total.toStringAsFixed(2), theme, isBold: true),
                if (subtotal < 500)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Add items worth ₹${(500 - subtotal).toStringAsFixed(0)} more for FREE delivery',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildPaymentMethods(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final List<Map<String, dynamic>> paymentMethods = [
      {
        'title': 'UPI',
        'description': 'Pay via any UPI app',
        'icon': Icons.phone_android_outlined,
        'types': [
          'assets/images/upi.png',
          'assets/images/gpay.png',
          'assets/images/phonepe.png',
          'assets/images/paytm.png',
        ],
      },
      {
        'title': 'Credit/Debit Card',
        'description': 'Pay using credit or debit card',
        'icon': Icons.credit_card_outlined,
        'types': [
          'assets/images/visa.png',
          'assets/images/mastercard.png',
          'assets/images/rupay.png',
        ],
      },
      {
        'title': 'Net Banking',
        'description': 'Pay using net banking',
        'icon': Icons.account_balance_outlined,
        'types': [
          'assets/images/bank.png',
        ],
      },
      {
        'title': 'Cash on Delivery',
        'description': 'Pay when you receive your order',
        'icon': Icons.money_outlined,
        'types': [
          'assets/images/cod.png',
        ],
      },
    ];
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Column(
        children: List.generate(
          paymentMethods.length,
          (index) => Column(
            children: [
              RadioListTile<int>(
                value: index,
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
                activeColor: colorScheme.primary,
                title: Text(
                  paymentMethods[index]['title'],
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  paymentMethods[index]['description'],
                  style: theme.textTheme.bodySmall,
                ),
                secondary: Icon(
                  paymentMethods[index]['icon'],
                  color: _selectedPaymentMethod == index
                      ? colorScheme.primary
                      : theme.iconTheme.color,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              if (_selectedPaymentMethod == index) ...[
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
                  child: Row(
                    children: [
                      ...paymentMethods[index]['types'].map<Widget>((type) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Image.asset(
                            type,
                            width: 40,
                            height: 24,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const SizedBox(
                              width: 40,
                              height: 24,
                              child: Icon(Icons.credit_card, size: 20),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                if (index == 0) // UPI specific fields
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Enter UPI ID',
                        hintText: 'example@upi',
                        prefixIcon: const Icon(Icons.payment_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter UPI ID';
                        }
                        if (!RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9]+$').hasMatch(value)) {
                          return 'Please enter a valid UPI ID';
                        }
                        return null;
                      },
                    ),
                  ),
              ],
              if (index < paymentMethods.length - 1)
                const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTermsAndConditions(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.bodySmall,
          children: [
            const TextSpan(text: 'By placing this order, you agree to our '),
            TextSpan(
              text: 'Terms of Service',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
            const TextSpan(text: ' and '),
            TextSpan(
              text: 'Privacy Policy',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
            const TextSpan(text: '. We may send you order updates via SMS or WhatsApp.'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPriceRow(
    String label,
    String value,
    ThemeData theme, {
    bool isBold = false,
    Color? textColor,
    double? fontSize,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: theme.hintColor,
              fontSize: fontSize,
            ),
          ),
          Text(
            value.startsWith('₹') ? value : '₹$value',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: textColor ?? theme.textTheme.bodyMedium?.color,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{2})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }
  
  String _getDeliveryDate() {
    final now = DateTime.now();
    final deliveryDate = now.add(const Duration(days: 3));
    return '${_getWeekday(deliveryDate.weekday)}, ${deliveryDate.day} ${_getMonth(deliveryDate.month)}';
  }
  
  String _getWeekday(int weekday) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[weekday % 7];
  }
  
  String _getMonth(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
  
  Widget _buildAddAddressSheet() {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add New Address',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: _buildAddressForm(context),
            ),
          ),
        ],
      ),
    );
  }

  // Add missing helper widget for address section
  Widget _buildAddressSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, title: 'Delivery Address', actionText: 'Add New', onAction: _addNewAddress),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _savedAddresses.length + 1,
              itemBuilder: (context, index) {
                if (index < _savedAddresses.length) {
                  return _buildAddressCard(
                    context,
                    address: _savedAddresses[index],
                    isSelected: _selectedAddressIndex == index,
                    onTap: () => _selectAddress(index),
                  );
                } else {
                  return _buildAddAddressCard(context);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Add missing helper widget for delivery method section
  Widget _buildDeliveryMethodSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, title: 'Delivery Method'),
          _buildDeliveryMethodCard(context),
        ],
      ),
    );
  }

  // Add missing helper widget for payment method section
  Widget _buildPaymentMethodSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, title: 'Payment Method'),
          _buildPaymentMethods(context),
        ],
      ),
    );
  }
}
