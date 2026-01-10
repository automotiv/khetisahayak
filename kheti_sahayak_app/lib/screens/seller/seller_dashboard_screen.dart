import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kheti_sahayak_app/models/seller_dashboard.dart';
import 'package:kheti_sahayak_app/services/seller_service.dart';
import 'package:kheti_sahayak_app/widgets/seller/stat_card.dart';
import 'package:kheti_sahayak_app/widgets/seller/order_card.dart';
import 'package:kheti_sahayak_app/widgets/seller/revenue_chart.dart';
import 'package:kheti_sahayak_app/screens/seller/seller_orders_screen.dart';
import 'package:kheti_sahayak_app/screens/seller/seller_analytics_screen.dart';
import 'package:kheti_sahayak_app/screens/seller/seller_inventory_screen.dart';

/// Seller Dashboard Screen
/// 
/// A beautiful, animated dashboard for sellers with:
/// - Welcome header with seller name
/// - 3 stat cards: Orders, Revenue, Products
/// - Revenue chart (last 7 days)
/// - Recent orders list
/// - Quick action buttons
class SellerDashboardScreen extends StatefulWidget {
  final String? sellerName;
  
  const SellerDashboardScreen({
    super.key,
    this.sellerName,
  });

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;

  SellerDashboardStats? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadDashboardData();
  }

  void _setupAnimations() {
    _headerAnimController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerAnimController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _headerAnimController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _headerAnimController.forward();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stats = await SellerService.getDashboardStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: const Color(0xFF2E7D32),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Custom App Bar with gradient
            _buildSliverAppBar(),
            
            // Content
            SliverToBoxAdapter(
              child: _isLoading
                  ? _buildShimmerLoading()
                  : _error != null
                      ? _buildErrorState()
                      : _buildDashboardContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final sellerName = widget.sellerName ?? 'Seller';
    final firstName = sellerName.split(' ').first;
    
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF2E7D32),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient background with pattern
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1B5E20),
                    Color(0xFF2E7D32),
                    Color(0xFF388E3C),
                  ],
                ),
              ),
            ),
            // Decorative circles
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            // Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: FadeTransition(
                  opacity: _headerFadeAnimation,
                  child: SlideTransition(
                    position: _headerSlideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.store_rounded,
                                    color: Colors.white.withOpacity(0.9),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Seller Dashboard',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _getGreeting(),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          firstName,
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  Widget _buildDashboardContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Cards Row
          _buildStatsSection(),
          const SizedBox(height: 28),
          
          // Revenue Chart
          _buildRevenueSection(),
          const SizedBox(height: 28),
          
          // Quick Actions
          _buildQuickActions(),
          const SizedBox(height: 28),
          
          // Recent Orders
          _buildRecentOrdersSection(),
          const SizedBox(height: 100), // Bottom padding for FAB
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final stats = _stats ?? SellerDashboardStats.empty();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth > 600;
            
            if (isTablet) {
              return Row(
                children: [
                  Expanded(
                    child: SellerStatCard(
                      title: 'Total Orders',
                      value: stats.totalOrders.toString(),
                      icon: Icons.shopping_bag_outlined,
                      primaryColor: const Color(0xFF3B82F6),
                      badgeCount: stats.pendingOrders,
                      badgeLabel: '${stats.pendingOrders} pending',
                      badgeColor: const Color(0xFFF59E0B),
                      animationDelay: 0,
                      onTap: () => _navigateToOrders(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SellerStatCard(
                      title: 'Revenue',
                      value: _formatCurrency(stats.revenueThisMonth),
                      subtitle: 'This month',
                      icon: Icons.account_balance_wallet_outlined,
                      primaryColor: const Color(0xFF2E7D32),
                      trend: stats.revenueTrend,
                      animationDelay: 100,
                      onTap: () => _navigateToAnalytics(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SellerStatCard(
                      title: 'Products',
                      value: stats.totalProducts.toString(),
                      icon: Icons.inventory_2_outlined,
                      primaryColor: const Color(0xFF8B5CF6),
                      badgeCount: stats.lowStockProducts,
                      badgeLabel: '${stats.lowStockProducts} low stock',
                      badgeColor: const Color(0xFFEF4444),
                      animationDelay: 200,
                      onTap: () => _navigateToInventory(),
                    ),
                  ),
                ],
              );
            }
            
            return Column(
              children: [
                SellerStatCard(
                  title: 'Total Orders',
                  value: stats.totalOrders.toString(),
                  icon: Icons.shopping_bag_outlined,
                  primaryColor: const Color(0xFF3B82F6),
                  badgeCount: stats.pendingOrders,
                  badgeLabel: '${stats.pendingOrders} pending',
                  badgeColor: const Color(0xFFF59E0B),
                  animationDelay: 0,
                  onTap: () => _navigateToOrders(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SellerStatCard(
                        title: 'Revenue',
                        value: _formatCurrency(stats.revenueThisMonth),
                        subtitle: 'This month',
                        icon: Icons.account_balance_wallet_outlined,
                        primaryColor: const Color(0xFF2E7D32),
                        trend: stats.revenueTrend,
                        animationDelay: 100,
                        onTap: () => _navigateToAnalytics(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SellerStatCard(
                        title: 'Products',
                        value: stats.totalProducts.toString(),
                        icon: Icons.inventory_2_outlined,
                        primaryColor: const Color(0xFF8B5CF6),
                        badgeCount: stats.lowStockProducts,
                        badgeLabel: '${stats.lowStockProducts} low',
                        badgeColor: const Color(0xFFEF4444),
                        animationDelay: 200,
                        onTap: () => _navigateToInventory(),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildRevenueSection() {
    final stats = _stats ?? SellerDashboardStats.empty();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: RevenueLineChart(
        data: stats.revenueChart,
        title: 'Revenue (Last 7 Days)',
        height: 200,
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.receipt_long_rounded,
                label: 'View All Orders',
                color: const Color(0xFF3B82F6),
                onTap: () => _navigateToOrders(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.add_box_rounded,
                label: 'Add Product',
                color: const Color(0xFF2E7D32),
                onTap: () => _navigateToAddProduct(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.analytics_outlined,
                label: 'Analytics',
                color: const Color(0xFF8B5CF6),
                onTap: () => _navigateToAnalytics(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.inventory_outlined,
                label: 'Inventory',
                color: const Color(0xFFF59E0B),
                onTap: () => _navigateToInventory(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentOrdersSection() {
    final stats = _stats ?? SellerDashboardStats.empty();
    final recentOrders = stats.recentOrders.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Orders',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
            TextButton(
              onPressed: () => _navigateToOrders(),
              child: Text(
                'View All',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2E7D32),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (recentOrders.isEmpty)
          _buildEmptyOrdersState()
        else
          ...recentOrders.map((order) => SellerOrderCard(
                order: order,
                onTap: () => _navigateToOrderDetail(order.id),
                onConfirm: order.canConfirm ? () => _confirmOrder(order.id) : null,
                onShip: order.canShip ? () => _shipOrder(order.id) : null,
                onDeliver: order.canDeliver ? () => _deliverOrder(order.id) : null,
              )),
      ],
    );
  }

  Widget _buildEmptyOrdersState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No orders yet',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your recent orders will appear here',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF9CA3AF),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats shimmer
          _buildShimmerBox(height: 24, width: 100),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildShimmerCard()),
              const SizedBox(width: 12),
              Expanded(child: _buildShimmerCard()),
            ],
          ),
          const SizedBox(height: 28),
          // Chart shimmer
          _buildShimmerBox(height: 260, width: double.infinity, radius: 20),
          const SizedBox(height: 28),
          // Quick actions shimmer
          _buildShimmerBox(height: 24, width: 120),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildShimmerBox(height: 80, radius: 16)),
              const SizedBox(width: 12),
              Expanded(child: _buildShimmerBox(height: 80, radius: 16)),
            ],
          ),
          const SizedBox(height: 28),
          // Recent orders shimmer
          _buildShimmerBox(height: 24, width: 150),
          const SizedBox(height: 16),
          _buildShimmerBox(height: 140, radius: 20),
          const SizedBox(height: 16),
          _buildShimmerBox(height: 140, radius: 20),
        ],
      ),
    );
  }

  Widget _buildShimmerBox({
    double? height,
    double? width,
    double radius = 8,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 0.7),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                const Color(0xFFE5E7EB),
                Color.lerp(
                  const Color(0xFFE5E7EB),
                  const Color(0xFFF3F4F6),
                  value,
                )!,
                const Color(0xFFE5E7EB),
              ],
              stops: [0.0, value, 1.0],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShimmerBox(height: 44, width: 44, radius: 14),
            const SizedBox(height: 16),
            _buildShimmerBox(height: 20, width: 80),
            const SizedBox(height: 8),
            _buildShimmerBox(height: 14, width: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Color(0xFFEF4444),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Failed to load dashboard',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'An unexpected error occurred',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadDashboardData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '${amount.toStringAsFixed(0)}';
  }

  // Navigation methods
  void _navigateToOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SellerOrdersScreen()),
    );
  }

  void _navigateToAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SellerAnalyticsScreen()),
    );
  }

  void _navigateToInventory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SellerInventoryScreen()),
    );
  }

  void _navigateToAddProduct() {
    // TODO: Navigate to add product screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add Product coming soon!')),
    );
  }

  void _navigateToOrderDetail(String orderId) {
    // TODO: Navigate to order detail screen
  }

  Future<void> _confirmOrder(String orderId) async {
    try {
      await SellerService.confirmOrder(orderId);
      _loadDashboardData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order confirmed successfully'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to confirm order: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _shipOrder(String orderId) async {
    try {
      await SellerService.shipOrder(orderId);
      _loadDashboardData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order marked as shipped'),
            backgroundColor: Color(0xFF8B5CF6),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ship order: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _deliverOrder(String orderId) async {
    try {
      await SellerService.deliverOrder(orderId);
      _loadDashboardData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order marked as delivered'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to deliver order: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }
}

/// Quick Action Button Widget
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151),
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
