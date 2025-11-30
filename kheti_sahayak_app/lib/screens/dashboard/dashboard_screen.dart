
import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/screens/main_sections/marketplace_screen.dart';
import 'package:kheti_sahayak_app/screens/diagnostics/diagnostics_screen.dart';
import 'package:kheti_sahayak_app/screens/main_sections/educational_content_screen.dart';
import 'package:kheti_sahayak_app/screens/profile/profile_screen.dart';
import 'package:kheti_sahayak_app/routes/routes.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  // The main screens for the bottom navigation
  static final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),
    const MarketplaceScreen(),
    const DiagnosticsScreen(),
    const EducationalContentScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store_outlined),
            activeIcon: Icon(Icons.store),
            label: 'Market',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.health_and_safety_outlined),
            activeIcon: Icon(Icons.health_and_safety),
            label: 'Diagnose',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Learn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF4CAF50),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

// This is the Home screen content with the four-card grid
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kheti Sahayak'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: <Widget>[
            _buildDashboardCard(
              context,
              'Weather Forecast',
              '/weather',
              Icons.wb_sunny,
              Colors.orange,
            ),
            _buildDashboardCard(
              context,
              'Crop Advisory',
              AppRoutes.cropAdvisory,
              Icons.grass,
              Colors.green,
            ),
            _buildDashboardCard(
              context,
              'Market Prices',
              AppRoutes.marketPrices,
              Icons.trending_up,
              Colors.blue,
            ),
            _buildDashboardCard(
              context,
              'Pest & Disease Info',
              AppRoutes.diagnostics,
              Icons.bug_report,
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, String title, String route, IconData icon, Color color) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Check if route is for diagnostics tab or a separate page
          if (route == AppRoutes.diagnostics) {
            // Find the parent DashboardScreen and ask it to switch tabs
            final screenState = context.findAncestorStateOfType<_DashboardScreenState>();
            screenState?._onItemTapped(2); // 2 is the index for Diagnose
          } else {
            Navigator.pushNamed(context, route);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40.0, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
