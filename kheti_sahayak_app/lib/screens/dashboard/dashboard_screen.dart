
import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/screens/main_sections/marketplace_screen.dart';
import 'package:kheti_sahayak_app/screens/diagnostics/diagnostics_screen.dart';
import 'package:kheti_sahayak_app/screens/main_sections/educational_content_screen.dart';
import 'package:kheti_sahayak_app/screens/profile/profile_screen.dart';
import 'package:kheti_sahayak_app/routes/routes.dart';
import 'package:kheti_sahayak_app/widgets/dashboard/weather_widget.dart';
import 'package:kheti_sahayak_app/widgets/dashboard/task_summary_widget.dart';
import 'package:kheti_sahayak_app/widgets/dashboard/alerts_widget.dart';
import 'package:kheti_sahayak_app/widgets/dashboard/yield_trends_widget.dart';
import 'package:kheti_sahayak_app/widgets/dashboard/yield_trends_widget.dart';
import 'package:kheti_sahayak_app/services/language_service.dart';
import 'package:kheti_sahayak_app/screens/recommendations/recommendations_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

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
            label: AppLocalizations.of(context).home,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store_outlined),
            activeIcon: Icon(Icons.store),
            label: AppLocalizations.of(context).marketplace,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.health_and_safety_outlined),
            activeIcon: Icon(Icons.health_and_safety),
            label: AppLocalizations.of(context).diagnosis,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: AppLocalizations.of(context).education,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: AppLocalizations.of(context).profile,
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
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).appName),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Weather Widget
              const WeatherWidget(),
              const SizedBox(height: 16),

              // Task Summary Widget
              const TaskSummaryWidget(),
              const SizedBox(height: 16),

              // Alerts Widget
              const AlertsWidget(),
              const SizedBox(height: 16),

              // Yield Trends Widget
              const YieldTrendsWidget(),
              const SizedBox(height: 24),

              // Quick Access Grid Header
              Text(
                AppLocalizations.of(context).quickAccess,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Existing Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: <Widget>[
                  _buildDashboardCard(
                    context,
                    AppLocalizations.of(context).weatherForecast,
                    '/weather',
                    Icons.wb_sunny,
                    Colors.orange,
                  ),
                  _buildDashboardCard(
                    context,
                    'Smart Recommendations',
                    '/recommendations',
                    Icons.lightbulb,
                    Colors.purple,
                  ),
                  _buildDashboardCard(
                    context,
                    AppLocalizations.of(context).cropAdvisory,
                    AppRoutes.cropAdvisory,
                    Icons.grass,
                    Colors.green,
                  ),
                  _buildDashboardCard(
                    context,
                    AppLocalizations.of(context).marketPrices,
                    AppRoutes.marketPrices,
                    Icons.trending_up,
                    Colors.blue,
                  ),
                  _buildDashboardCard(
                    context,
                    AppLocalizations.of(context).pestDiseaseInfo,
                    AppRoutes.diagnostics,
                    Icons.bug_report,
                    Colors.red,
                  ),
                ],
              ),
            ],
          ),
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
            final screenState = context.findAncestorStateOfType<_DashboardScreenState>();
            screenState?._onItemTapped(2); // 2 is the index for Diagnose
          } else if (route == '/recommendations') {
             Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RecommendationsScreen()),
            );
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
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
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
