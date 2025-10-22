import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/screens/main_sections/dashboard_screen.dart';
import 'package:kheti_sahayak_app/screens/marketplace/marketplace_screen_new.dart';
import 'package:kheti_sahayak_app/screens/main_sections/diagnostics_screen.dart';
import 'package:kheti_sahayak_app/screens/main_sections/educational_content_screen.dart';
import 'package:kheti_sahayak_app/screens/main_sections/profile_screen.dart';
import 'package:kheti_sahayak_app/screens/cart/cart_screen.dart';
import 'package:kheti_sahayak_app/services/cart_service.dart';
import 'package:kheti_sahayak_app/models/cart.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  CartSummary _cartSummary = CartSummary(subtotal: 0, totalItems: 0, itemCount: 0);

  @override
  void initState() {
    super.initState();
    _loadCartSummary();
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
      // Silently fail - cart badge will show 0
    }
  }

  static const List<Widget> _widgetOptions = <Widget>[
    DashboardScreen(),
    MarketplaceScreenNew(),
    DiagnosticsScreen(),
    EducationalContentScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToCart() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CartScreen()),
    );
    // Reload cart summary when returning from cart screen
    _loadCartSummary();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kheti Sahayak'),
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
                    decoration: BoxDecoration(
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
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Marketplace',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: 'Diagnostics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Education',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green[800],
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Ensures all labels are visible
      ),
    );
  }
}