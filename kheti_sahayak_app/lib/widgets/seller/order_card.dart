import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kheti_sahayak_app/models/seller_dashboard.dart';

/// Seller Order Card - Beautiful order card with status actions
/// 
/// Displays order information with action buttons based on current status
class SellerOrderCard extends StatelessWidget {
  final SellerOrder order;
  final VoidCallback? onTap;
  final VoidCallback? onConfirm;
  final VoidCallback? onShip;
  final VoidCallback? onDeliver;
  final VoidCallback? onCancel;
  final bool isLoading;

  const SellerOrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.onConfirm,
    this.onShip,
    this.onDeliver,
    this.onCancel,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: _getStatusColor(order.status).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Order ID & Status
                _buildHeader(),
                const SizedBox(height: 16),
                
                // Order Items
                if (order.items.isNotEmpty) ...[
                  _buildOrderItems(),
                  const SizedBox(height: 14),
                ],
                
                // Divider with gradient
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        const Color(0xFFE5E7EB).withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                
                // Buyer Info & Total
                _buildBuyerInfo(),
                
                // Action Buttons
                if (_shouldShowActions()) ...[
                  const SizedBox(height: 16),
                  _buildActionButtons(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    size: 18,
                    color: const Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '#${order.orderNumber}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(order.createdAt),
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
        _buildStatusBadge(order.status),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    final bgColor = color.withOpacity(0.1);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            order.statusText.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems() {
    // Show first 2 items, then "and X more"
    final displayItems = order.items.take(2).toList();
    final remainingCount = order.items.length - displayItems.length;

    return Column(
      children: [
        ...displayItems.map((item) => _buildOrderItemRow(item)),
        if (remainingCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '+ $remainingCount more item${remainingCount > 1 ? 's' : ''}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF6B7280),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOrderItemRow(SellerOrderItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFF9FAFB),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: item.productImage != null
                  ? Image.network(
                      item.productImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                    )
                  : _buildPlaceholderImage(),
            ),
          ),
          const SizedBox(width: 12),
          
          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  'Qty: ${item.quantity} x ${_formatCurrency(item.unitPrice)}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          
          // Item Total
          Text(
            _formatCurrency(item.totalPrice),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: const Color(0xFFF3F4F6),
      child: const Center(
        child: Icon(
          Icons.shopping_bag_outlined,
          color: Color(0xFFD1D5DB),
          size: 24,
        ),
      ),
    );
  }

  Widget _buildBuyerInfo() {
    return Row(
      children: [
        // Buyer Details
        Expanded(
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF6366F1).withOpacity(0.2),
                      const Color(0xFF8B5CF6).withOpacity(0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: Color(0xFF6366F1),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.buyerName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (order.buyerPhone != null)
                      Text(
                        order.buyerPhone!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Total Amount
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Total',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatCurrency(order.totalAmount),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // Cancel Button (if applicable)
        if (order.canCancel && onCancel != null)
          Expanded(
            child: _ActionButton(
              label: 'Cancel',
              icon: Icons.close_rounded,
              color: const Color(0xFFEF4444),
              isOutlined: true,
              onPressed: isLoading ? null : onCancel,
            ),
          ),
        
        if (order.canCancel && onCancel != null && _getPrimaryAction() != null)
          const SizedBox(width: 10),
        
        // Primary Action Button
        if (_getPrimaryAction() != null)
          Expanded(
            flex: order.canCancel ? 2 : 1,
            child: _ActionButton(
              label: _getPrimaryActionLabel()!,
              icon: _getPrimaryActionIcon()!,
              color: _getPrimaryActionColor()!,
              isOutlined: false,
              isLoading: isLoading,
              onPressed: isLoading ? null : _getPrimaryAction(),
            ),
          ),
      ],
    );
  }

  bool _shouldShowActions() {
    return order.canConfirm || order.canShip || order.canDeliver;
  }

  VoidCallback? _getPrimaryAction() {
    if (order.canConfirm) return onConfirm;
    if (order.canShip) return onShip;
    if (order.canDeliver) return onDeliver;
    return null;
  }

  String? _getPrimaryActionLabel() {
    if (order.canConfirm) return 'Confirm Order';
    if (order.canShip) return 'Mark Shipped';
    if (order.canDeliver) return 'Mark Delivered';
    return null;
  }

  IconData? _getPrimaryActionIcon() {
    if (order.canConfirm) return Icons.check_circle_outline_rounded;
    if (order.canShip) return Icons.local_shipping_outlined;
    if (order.canDeliver) return Icons.inventory_2_outlined;
    return null;
  }

  Color? _getPrimaryActionColor() {
    if (order.canConfirm) return const Color(0xFF3B82F6);
    if (order.canShip) return const Color(0xFF8B5CF6);
    if (order.canDeliver) return const Color(0xFF10B981);
    return null;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'confirmed':
        return const Color(0xFF3B82F6);
      case 'shipped':
        return const Color(0xFF8B5CF6);
      case 'delivered':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatCurrency(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '${amount.toStringAsFixed(0)}';
  }
}

/// Action Button for Order Card
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isOutlined;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isOutlined,
    this.isLoading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isOutlined ? Colors.transparent : color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isOutlined
                ? Border.all(color: color.withOpacity(0.4), width: 1.5)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      isOutlined ? color : Colors.white,
                    ),
                  ),
                )
              else
                Icon(
                  icon,
                  size: 18,
                  color: isOutlined ? color : Colors.white,
                ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isOutlined ? color : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
