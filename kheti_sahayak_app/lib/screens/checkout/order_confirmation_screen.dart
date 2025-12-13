import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kheti_sahayak_app/providers/order_provider.dart';
import 'package:kheti_sahayak_app/theme/app_theme.dart';
import 'package:kheti_sahayak_app/widgets/primary_button.dart';
import 'package:kheti_sahayak_app/widgets/loading_indicator.dart';
import 'package:kheti_sahayak_app/widgets/error_dialog.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final String orderId;

  const OrderConfirmationScreen({
    Key? key,
    required this.orderId,
  }) : super(key: key);

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  bool _isLoading = true;
  String? _error;
  OrderItem? _order;
  
  TextTheme get textTheme => Theme.of(context).textTheme;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    final orderProvider = context.read<OrderProvider>();
    
    try {
      // Try to find the order in the local list first
      _order = orderProvider.getOrderById(widget.orderId);
      
      // If not found, try to fetch it from the server
      if (_order == null) {
        _order = await orderProvider.trackOrder(widget.orderId);
      }
      
      if (_order == null) {
        setState(() {
          _error = 'Order not found';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load order details';
        _isLoading = false;
      });
      debugPrint('Error loading order: $e');
    }
  }
  
  // Format date to a readable string
  String _formatDate(DateTime date) {
    return '${_getDayName(date.weekday)}, ${date.day} ${_getMonthName(date.month)} ${date.year}';
  }
  
  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
  
  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    
    // Show loading indicator while loading
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: LoadingIndicator()),
      );
    }
    
    // Show error if order not found
    if (_error != null || _order == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Order Details'),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Order not found',
                  style: textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  text: 'Back to Home',
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    final order = _order!;
    final orderDate = order.orderDate;
    
    // Show order saved message if offline
    final isOffline = order.status == 'pending_sync' || order.status == 'Pending (Offline)';
    
    return WillPopScope(
      onWillPop: () async {
        // Prevent going back to checkout screen
        Navigator.popUntil(context, (route) => route.isFirst);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Order Confirmation'),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Success message
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (isOffline ? Colors.orange : colorScheme.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      isOffline ? Icons.save_outlined : Icons.check_circle_outline,
                      size: 64,
                      color: isOffline ? Colors.orange : colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isOffline ? 'Order Saved Offline' : 'Order Placed Successfully!',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isOffline ? Colors.orange : colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isOffline 
                          ? 'Your order has been saved and will be uploaded automatically when you reconnect to the internet.'
                          : 'Your order ${order.orderNumber} has been placed and is being processed. You will receive an order confirmation email shortly.',
                      style: textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isOffline ? Colors.orange : colorScheme.primary),
                      ),
                      child: Text(
                        'Order #${order.orderNumber}',
                        style: textTheme.bodyLarge?.copyWith(
                          color: isOffline ? Colors.orange : colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Order details card
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order ID
                      _buildDetailRow(
                        context,
                        icon: Icons.receipt_long_outlined,
                        label: 'Order ID',
                        value: order.orderNumber,
                        isBold: true,
                      ),
                      const SizedBox(height: 12),
                      
                      // Order date
                      _buildDetailRow(
                        context,
                        icon: Icons.calendar_today_outlined,
                        label: 'Order Date',
                        value: _formatDate(orderDate),
                      ),
                      const SizedBox(height: 12),
                      
                      // Expected delivery (3-7 business days)
                      _buildDetailRow(
                        context,
                        icon: Icons.local_shipping_outlined,
                        label: 'Expected Delivery',
                        value: isOffline ? 'Pending Upload' : _formatDate(orderDate.add(const Duration(days: 5))),
                      ),
                      const SizedBox(height: 12),
                      
                      // Total amount
                      _buildDetailRow(
                        context,
                        icon: Icons.payment_outlined,
                        label: 'Total Amount',
                        value: '₹${order.total.toStringAsFixed(2)}',
                        isBold: true,
                      ),
                      const SizedBox(height: 8),
                      
                      // Track order button
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            // Navigate to order tracking
                            // Navigator.pushNamed(context, '/track-order', arguments: order.id);
                          },
                          icon: const Icon(Icons.arrow_forward_ios, size: 14),
                          label: const Text('Track Order'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Order summary
              _buildSectionHeader(context, title: 'Order Summary'),
              const SizedBox(height: 12),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  children: [
                    // Order items
                    ...order.items.map((item) => _buildOrderItem(context, item)).toList(),
                    
                    // Divider
                    const Divider(height: 1, thickness: 1),
                    
                    // Price summary
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Subtotal
                          _buildPriceRow(
                            'Subtotal',
                            '₹${order.subtotal.toStringAsFixed(2)}',
                            theme,
                          ),
                          const SizedBox(height: 8),
                          
                          // Delivery charge
                          _buildPriceRow(
                            'Delivery Charge',
                            order.deliveryCharge == 0 ? 'FREE' : '₹${order.deliveryCharge.toStringAsFixed(2)}',
                            theme,
                            valueColor: order.deliveryCharge == 0 ? colorScheme.primary : null,
                          ),
                          
                          // Coupon discount if applied
                          if (order.discount > 0) ...[
                            const SizedBox(height: 8),
                            _buildPriceRow(
                              'Coupon Discount',
                              '-₹${order.discount.toStringAsFixed(2)}',
                              theme,
                              valueColor: colorScheme.primary,
                            ),
                          ],
                          
                          const SizedBox(height: 16),
                          
                          // Total
                          _buildPriceRow(
                            'Total Amount',
                            '₹${order.total.toStringAsFixed(2)}',
                            theme,
                            isBold: true,
                            valueColor: colorScheme.primary,
                            fontSize: 16,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Delivery address
              _buildSectionHeader(context, title: 'Delivery Address'),
              const SizedBox(height: 12),
              _buildAddressCard(context),
              
              const SizedBox(height: 24),
              
              // Payment details
              _buildSectionHeader(context, title: 'Payment Details'),
              const SizedBox(height: 12),
              _buildPaymentDetails(context),
              
              const SizedBox(height: 24),
              
              // Order status timeline
              _buildSectionHeader(context, title: 'Order Status'),
              const SizedBox(height: 12),
              _buildOrderTimeline(context),
              
              const SizedBox(height: 24),
              
              // Help & support
              _buildHelpSection(context),
              
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Navigate to home
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: colorScheme.primary),
                      ),
                      child: Text(
                        'Continue Shopping',
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: PrimaryButton(
                      onPressed: () {
                        // Navigate to order details or track order
                        Navigator.pushNamed(context, '/order-details', arguments: widget.orderId);
                      },
                      text: 'Track Order',
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Update _buildOrderTimeline to handle offline status
  Widget _buildOrderTimeline(BuildContext context) {
    // ... existing initialization ...
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final allStatuses = [
      'placed',
      'confirmed',
      'processing',
      'shipped',
      'out_for_delivery',
      'delivered'
    ];

    var currentStatus = _order!.status.toString().toLowerCase();
    
    // Map offline status to 'placed' for timeline visualization
    if (currentStatus == 'pending_sync' || currentStatus == 'pending (offline)') {
        currentStatus = 'placed';
    }

    final currentStatusIndex = allStatuses.indexOf(currentStatus);
    
    // ... rest of the timeline logic ...
    // Note: Since I can't easily replicate just the map part, I'm returning the original function body with the status mapping logic added at the start.
    // For brevity in ReplacementContent, I will just provide the full method rewrite if needed, or careful splicing.
    
    // Actually, I'm replacing lines 137 to 620. This includes build method and creates duplicates if I'm not careful.
    // I should provide the full build method and new _buildOrderTimeline or just be careful.
    // The ReplacementContent above is targeting lines 137-620 which is the Scaffold part.
    // I'll assume _buildOrderTimeline is outside this range?
    // Wait, _buildOrderTimeline is at 607.
    
    // Let's refine the replacement to cover build method AND handle the `isOffline` logic properly.
    // And I'll need to update `_buildOrderTimeline` separately or include it.
    
    // The previous `replace_file_content` I proposed covered `build` method.
    // But `_buildOrderTimeline` (line 607) needs update too.
    
    // I will simplify: I'll update `build` first to handle the messages.
    // Then I'll update `_buildOrderTimeline` in a separate call or chunk.
    
    // The provided replacement covers the whole `build` method.
    // I'll proceed with that.

  }
  
  Widget _buildSectionHeader(BuildContext context, {required String title}) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
  
  Widget _buildOrderSummary(BuildContext context) {
    final order = _order!;
    final orderDate = order.orderDate;
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
            _buildInfoRow('Order ID', order.orderNumber, context),
            const SizedBox(height: 8),
            _buildInfoRow('Order Date', _formatDate(orderDate), context),
            const SizedBox(height: 8),
            _buildInfoRow('Items', '${order.items.length} items', context),
            const SizedBox(height: 8),
            _buildInfoRow('Delivery', 'Standard Delivery', context),
            const SizedBox(height: 8),
            _buildInfoRow('Expected Delivery', _getExpectedDeliveryDate(), context),
            const Divider(height: 24),
            _buildPriceRow('Subtotal', _calculateSubtotal().toStringAsFixed(2), theme),
            _buildPriceRow('Delivery', 'FREE', theme),
            const Divider(height: 24),
            _buildPriceRow('Total Amount', '₹${order.total.toStringAsFixed(2)}', theme),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAddressCard(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final order = _order!;
    final addressLines = _order!.shippingAddress.split('\n');
    final name = addressLines.isNotEmpty ? addressLines[0] : '';
    final address = addressLines.length > 1 ? addressLines[1] : '';
    final landmark = addressLines.length > 2 ? addressLines[2].replaceAll('Landmark: ', '') : '';
    final cityStatePincode = addressLines.length > 3 ? addressLines[3] : '';
    final phone = addressLines.length > 4 ? addressLines[4].replaceAll('Phone: ', '') : '';
    
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
                const Icon(Icons.location_on_outlined, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Delivery Address',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (address.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(address, style: textTheme.bodyMedium),
            ],
            if (cityStatePincode.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(cityStatePincode, style: textTheme.bodyMedium),
            ],
            if (phone.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Phone: $phone', style: textTheme.bodyMedium),
            ],
            if (landmark.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Landmark: $landmark', style: textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildPaymentDetails(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    
    // Get payment status color
    Color getStatusColor(String status) {
      switch (status.toLowerCase()) {
        case 'paid':
          return Colors.green;
        case 'pending':
          return Colors.orange;
        case 'failed':
          return Colors.red;
        case 'refunded':
          return Colors.blue;
        default:
          return theme.colorScheme.primary;
      }
    }
    
    final statusColor = getStatusColor(_order!.paymentStatus);
    
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
                const Icon(Icons.payment_outlined, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Payment Details',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _order!.paymentStatus.toUpperCase(),
                    style: textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Payment Method', _order!.paymentMethod, context),
            const SizedBox(height: 8),
            _buildInfoRow('Transaction ID', _order!.id, context,
                valueStyle: textTheme.bodySmall),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Amount Paid', 
              '₹${_order!.total.toStringAsFixed(2)}', 
              context,
              valueStyle: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOrderTimeline(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Define all possible order statuses in sequence
    final allStatuses = [
      'placed',
      'confirmed',
      'processing',
      'shipped',
      'out_for_delivery',
      'delivered'
    ];
    
    // Get the current status index
    var currentStatus = _order!.status.toString().toLowerCase();
    
    // Map offline status to 'placed' for timeline visualization
    if (currentStatus == 'pending_sync' || currentStatus == 'pending (offline)') {
        currentStatus = 'placed';
    }

    final currentStatusIndex = allStatuses.indexOf(currentStatus);
    
    // Define status details
    final statusDetails = {
      'placed': {
        'title': 'Order Placed',
        'subtitle': _formatDateTime(_order!.orderDate),
        'icon': Icons.shopping_bag_outlined,
      },
      'confirmed': {
        'title': 'Order Confirmed',
        'subtitle': _formatDateTime(_order!.orderDate.add(const Duration(minutes: 5))),
        'icon': Icons.verified_outlined,
      },
      'processing': {
        'title': 'Processing',
        'subtitle': 'Preparing your order',
        'icon': Icons.settings_outlined,
      },
      'shipped': {
        'title': 'Shipped',
        'subtitle': 'Estimated delivery: ${_formatDate(_order!.orderDate.add(const Duration(days: 3)))}',
        'icon': Icons.local_shipping_outlined,
      },
      'out_for_delivery': {
        'title': 'Out for Delivery',
        'subtitle': 'Your order is on the way',
        'icon': Icons.delivery_dining_outlined,
      },
      'delivered': {
        'title': 'Delivered',
        'subtitle': 'Your order has been delivered',
        'icon': Icons.check_circle_outline,
      },
    };
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: allStatuses.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final status = allStatuses[index];
            final isCompleted = index <= currentStatusIndex;
            final isCurrent = index == currentStatusIndex;
            final details = statusDetails[status]!;
            final isLast = index == allStatuses.length - 1;
            
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status icon with timeline
                Column(
                  children: [
                    // Status icon
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCurrent 
                            ? colorScheme.primary.withOpacity(0.1) 
                            : (isCompleted 
                                ? colorScheme.primary.withOpacity(0.05) 
                                : Colors.grey[100]),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCurrent 
                              ? colorScheme.primary 
                              : (isCompleted ? colorScheme.primary.withOpacity(0.5) : Colors.grey[300]!),
                          width: isCurrent ? 2 : 1,
                        ),
                      ),
                      child: isCompleted
                          ? Icon(
                              details['icon'] as IconData? ?? Icons.check_circle_outline,
                              size: 18,
                              color: isCurrent ? colorScheme.primary : colorScheme.primary.withOpacity(0.7),
                            )
                          : Icon(
                              details['icon'] as IconData? ?? Icons.radio_button_unchecked,
                              size: 18,
                              color: isCurrent ? colorScheme.primary : Colors.grey[400],
                            ),
                    ),
                    // Timeline line
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 40,
                        color: isCompleted 
                            ? colorScheme.primary.withOpacity(0.3) 
                            : Colors.grey[200],
                        margin: const EdgeInsets.only(top: 4, bottom: 4),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                // Status content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          details['title'] as String,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isCurrent 
                                ? colorScheme.onSurface 
                                : (isCompleted ? colorScheme.onSurface.withOpacity(0.8) : colorScheme.onSurface.withOpacity(0.5)),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          details['subtitle'] as String,
                          style: textTheme.bodySmall?.copyWith(
                            color: isCurrent 
                                ? colorScheme.primary 
                                : (isCompleted ? colorScheme.onSurface.withOpacity(0.6) : colorScheme.onSurface.withOpacity(0.4)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Status indicator for current status
                if (isCurrent)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Current',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildHelpSection(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    
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
            Text(
              'Need Help?',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              context,
              icon: Icons.help_outline,
              title: 'Help Center',
              subtitle: 'Find answers to common questions',
              onTap: () {
                // Navigate to help center
              },
            ),
            const Divider(height: 24),
            _buildHelpItem(
              context,
              icon: Icons.headset_mic_outlined,
              title: 'Contact Support',
              subtitle: 'Get help with your order',
              onTap: () => _showContactSupportDialog(context),
            ),
            const Divider(height: 24),
            _buildHelpItem(
              context,
              icon: Icons.receipt_long_outlined,
              title: 'View Order Details',
              subtitle: 'See all order information',
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/order-details',
                  arguments: _order!.id,
                );
              },
            ),
            const Divider(height: 24),
            _buildHelpItem(
              context,
              icon: Icons.local_shipping_outlined,
              title: 'Track Order',
              subtitle: 'Track your delivery status',
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/track-order',
                  arguments: _order!.id,
                );
              },
            ),
            if (_order!.status == OrderStatus.delivered) ...[
              const Divider(height: 24),
              _buildHelpItem(
                context,
                icon: Icons.rate_review_outlined,
                title: 'Rate & Review',
                subtitle: 'Share your experience',
                onTap: () {
                  // Navigate to review screen
                  Navigator.pushNamed(
                    context,
                    '/review-order',
                    arguments: _order!.id,
                  );
                },
              ),
            ],
            const Divider(height: 24),
            _buildHelpItem(
              context,
              icon: Icons.help_outline,
              title: 'FAQs',
              subtitle: 'Find answers to common questions',
              onTap: () {
                // Navigate to FAQs
                Navigator.pushNamed(context, '/faqs');
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHelpItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(
    String label,
    String value,
    BuildContext context, {
    TextStyle? valueStyle,
  }) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.hintColor,
          ),
        ),
        Text(
          value,
          style: valueStyle ?? theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
  
  Widget _buildPriceRow(
    String label,
    String value,
    ThemeData theme, {
    bool isBold = false,
    bool isFree = false,
    bool isPrimary = false,
    Color? valueColor,
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
              color: valueColor ?? theme.textTheme.bodyMedium?.color,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDateTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final amPm = date.hour < 12 ? 'AM' : 'PM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '${_getDayName(date.weekday)}, ${date.day} ${_getMonthName(date.month)} at $hour:$minute $amPm';
  }
  
  String _getExpectedDeliveryDate() {
    final deliveryDate = _order?.orderDate.add(const Duration(days: 3)) ?? DateTime.now().add(const Duration(days: 3));
    return '${_getDayName(deliveryDate.weekday)}, ${deliveryDate.day} ${_getMonthName(deliveryDate.month)}';
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
  
  double _calculateSubtotal() {
    return _order?.items.fold(0.0, (double? sum, item) {
      return sum! + (item.price * item.quantity);
    }) ?? 0.0;
  }
  
  void _showContactSupportDialog(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Contact Support',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'We\'re here to help with your order #${_order?.orderNumber}.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              
              // Call Support
              _buildContactOption(
                context,
                icon: Icons.phone_in_talk_outlined,
                title: 'Call Us',
                subtitle: 'Speak with our support team',
                actionText: 'Call Now',
                onTap: () {
                  // launch('tel:+18001234567');
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Opening phone app...'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              
              const Divider(height: 32),
              
              // Email Support
              _buildContactOption(
                context,
                icon: Icons.email_outlined,
                title: 'Email Us',
                subtitle: 'Get a response within 24 hours',
                actionText: 'Send Email',
                onTap: () {
                  final emailLaunchUri = Uri(
                    scheme: 'mailto',
                    path: 'support@khetisahayak.com',
                    query: 'subject=Support Request for Order #${_order?.orderNumber}',
                  );
                  // launch(emailLaunchUri.toString());
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Opening email client...'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              
              const Divider(height: 32),
              
              // Live Chat
              _buildContactOption(
                context,
                icon: Icons.chat_bubble_outline,
                title: 'Live Chat',
                subtitle: 'Chat with us in real-time',
                actionText: 'Start Chat',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to chat screen
                  Navigator.pushNamed(
                    context,
                    '/support-chat',
                    arguments: {
                      'orderId': _order?.id,
                      'orderNumber': _order?.orderNumber,
                    },
                  );
                },
              ),
              
              const SizedBox(height: 8),
              
              // FAQ Link
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/faqs');
                  },
                  child: const Text('View FAQs'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildContactOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: onTap,
                child: Text(actionText),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildContactInfoRow(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.hintColor),
        const SizedBox(width: 12),
        Text(
          text,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, {required IconData icon, required String label, required String value, bool isBold = false}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(label + ': ', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Expanded(child: Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: isBold ? FontWeight.bold : FontWeight.normal))),
      ],
    );
  }

  Widget _buildOrderItem(BuildContext context, dynamic item) {
    // Replace dynamic with your actual item type
    return ListTile(
      title: Text(item.name ?? ''),
      subtitle: Text('Qty: ${item.quantity}'),
      trailing: Text('₹${item.price}'),
    );
  }
}
