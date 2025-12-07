import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/menu_item.dart';
import 'package:kheti_sahayak_app/services/app_config_service.dart';
import 'package:kheti_sahayak_app/screens/common/coming_soon_screen.dart';
import 'package:kheti_sahayak_app/screens/weather/weather_screen.dart';
import 'package:kheti_sahayak_app/screens/main_sections/dashboard_screen.dart';
import 'package:kheti_sahayak_app/screens/marketplace/marketplace_screen_new.dart';
import 'package:kheti_sahayak_app/screens/main_sections/diagnostics_screen.dart';
import 'package:kheti_sahayak_app/screens/main_sections/educational_content_screen.dart';
import 'package:kheti_sahayak_app/screens/main_sections/profile_screen.dart';
import 'package:kheti_sahayak_app/screens/social/expert_connect_screen.dart';
import 'package:kheti_sahayak_app/screens/social/community_screen.dart';
import 'package:kheti_sahayak_app/screens/info/government_schemes_screen.dart';
import 'package:kheti_sahayak_app/screens/info/recommendations_screen.dart';
import 'package:kheti_sahayak_app/screens/utility/digital_logbook_screen.dart';
import 'package:kheti_sahayak_app/screens/utility/equipment_screen.dart';
import 'package:kheti_sahayak_app/screens/system/notifications_screen.dart';
import 'package:kheti_sahayak_app/screens/cart/cart_screen.dart';
import 'package:kheti_sahayak_app/services/cart_service.dart';
import 'package:kheti_sahayak_app/models/cart.dart';
import 'package:kheti_sahayak_app/screens/fields/field_list_screen.dart';
import 'package:kheti_sahayak_app/screens/analytics/analytics_screen.dart';
import 'package:kheti_sahayak_app/screens/analytics/analytics_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedRouteId = 'dashboard';
  CartSummary _cartSummary = CartSummary(subtotal: 0, totalItems: 0, itemCount: 0);
  List<MenuItem> _menuItems = [];
  bool _isLoadingMenu = true;

  @override
  void initState() {
    super.initState();
    _loadCartSummary();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    final items = await AppConfigService.getMenuItems();
    if (mounted) {
      setState(() {
        // Add "My Fields" if not present (temporary until backend update)
        if (!items.any((i) => i.routeId == 'fields')) {
          items.insert(1, MenuItem(
            id: 999,
            label: 'My Fields',
            iconName: 'landscape',
            routeId: 'fields',
            displayOrder: 2,
          ));
        }
        
        // Add "Analytics" if not present
        if (!items.any((i) => i.routeId == 'analytics')) {
          items.insert(2, MenuItem(
            id: 998,
            label: 'Analytics',
            iconName: 'analytics',
            routeId: 'analytics',
            displayOrder: 3,
          ));
        }
        
        // Add "Analytics" if not present
        if (!items.any((i) => i.routeId == 'analytics')) {
          items.insert(2, MenuItem(
            id: 998,
            label: 'Analytics',
            iconName: 'analytics',
            routeId: 'analytics',
            displayOrder: 3,
          ));
        }

        _menuItems = items;
        _isLoadingMenu = false;
        // Ensure selected route exists in menu, else default to first or dashboard
        if (items.isNotEmpty && !items.any((i) => i.routeId == _selectedRouteId)) {
          _selectedRouteId = items.first.routeId;
        }
      });
    }
  }

  Future<void> _loadCartSummary() async {
    try {
      final summary = await CartService.getCartSummary();
      if (mounted) {
        setState(() {
          _cartSummary = summary;
        });
      }
    } catch (e) {
      // Silently fail
    }
  }

  void _onItemTapped(String routeId) {
    setState(() {
      _selectedRouteId = routeId;
    });
    Navigator.pop(context); // Close drawer
  }

  void _navigateToCart() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CartScreen()),
    );
    _loadCartSummary();
  }

  Widget _getWidgetForRoute(String routeId) {
    switch (routeId) {
      case 'dashboard':
        return const DashboardScreen();
      case 'weather':
        return const WeatherScreen();
      case 'diagnostics':
        return const DiagnosticsScreen();
      case 'fields':
        return const FieldListScreen();
      case 'marketplace':
        return const MarketplaceScreenNew();
      case 'education':
        return const EducationalContentScreen();
      case 'expert_connect':
        return const ExpertConnectScreen();
      case 'community':
        return const CommunityScreen();
      case 'schemes':
        return const GovernmentSchemesScreen();
      case 'recommendations':
        return const RecommendationsScreen();
      case 'logbook':
        return const DigitalLogbookScreen();
      case 'equipment':
        return const EquipmentScreen();
      case 'notifications':
        return const NotificationsScreen();
      case 'profile':
        return const ProfileScreen();
      default:
        // Find label for title
        final item = _menuItems.firstWhere(
          (i) => i.routeId == routeId,
          orElse: () => MenuItem(id: 0, label: 'Feature', iconName: '', routeId: '', displayOrder: 0),
        );
        return ComingSoonScreen(title: item.label);
    }
  }

  Widget _getIconWidget(String iconName, bool isSelected) {
    // Check for existing assets first
    String? assetName;
    switch (iconName) {
      case 'dashboard': assetName = 'dashboard.png'; break;
      case 'wb_sunny': assetName = 'wb_sunny.png'; break;
      case 'medical_services': assetName = 'medical_services.png'; break;
      case 'store': assetName = 'store.png'; break;
      case 'school': assetName = 'school.png'; break;
      case 'people': assetName = 'people.png'; break;
      case 'forum': assetName = 'forum.png'; break;
      case 'book': assetName = 'book.png'; break;
      case 'account_balance': assetName = 'account_balance.png'; break;
      case 'lightbulb': assetName = 'lightbulb.png'; break;
      case 'handyman': assetName = 'handyman.png'; break;
      case 'notifications': assetName = 'notifications.png'; break;
      case 'person': assetName = 'person.png'; break;
    }

    if (assetName != null) {
      return Image.asset(
        'assets/icons/$assetName',
        width: 24,
        height: 24,
        // No tint to show original colors
      );
    }

    // Fallback to Material Icons
    IconData iconData;
    switch (iconName) {
      case 'dashboard': iconData = Icons.dashboard; break;
      case 'wb_sunny': iconData = Icons.wb_sunny; break;
      case 'medical_services': iconData = Icons.medical_services; break;
      case 'store': iconData = Icons.store; break;
      case 'school': iconData = Icons.school; break;
      case 'people': iconData = Icons.people; break;
      case 'forum': iconData = Icons.forum; break;
      case 'landscape': iconData = Icons.landscape; break;
      case 'book': iconData = Icons.book; break;
      case 'account_balance': iconData = Icons.account_balance; break;
      case 'lightbulb': iconData = Icons.lightbulb; break;
      case 'handyman': iconData = Icons.handyman; break;
      case 'notifications': iconData = Icons.notifications; break;
      case 'analytics': iconData = Icons.analytics; break;
      case 'person': iconData = Icons.person; break;
      case 'person': iconData = Icons.person; break;
      default: iconData = Icons.circle; break;
    }
    return Icon(iconData, color: isSelected ? Colors.green[800] : Colors.grey[700]);
  }

  @override
  Widget build(BuildContext context) {
    // Find current title
    String currentTitle = 'Kheti Sahayak';
    if (_menuItems.isNotEmpty) {
      try {
        currentTitle = _menuItems.firstWhere((i) => i.routeId == _selectedRouteId).label;
      } catch (e) {}
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(currentTitle),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: _navigateToCart,
                tooltip: 'Shopping Cart',
              ),
              if (_cartSummary.itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '${_cartSummary.itemCount > 99 ? '99+' : _cartSummary.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        child: _isLoadingMenu
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: Colors.green[700],
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Kheti Sahayak',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Empowering Farmers',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ..._menuItems.map((item) {
                    return ListTile(
                      leading: _getIconWidget(item.iconName, _selectedRouteId == item.routeId),
                      title: Text(
                        item.label,
                        style: TextStyle(
                          color: _selectedRouteId == item.routeId ? Colors.green[800] : Colors.black87,
                          fontWeight: _selectedRouteId == item.routeId ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: _selectedRouteId == item.routeId,
                      selectedTileColor: Colors.green[50],
                      onTap: () => _onItemTapped(item.routeId),
                    );
                  }).toList(),
                ],
              ),
      ),
      body: _isLoadingMenu
          ? const Center(child: CircularProgressIndicator())
          : _getWidgetForRoute(_selectedRouteId),
    );
  }
}