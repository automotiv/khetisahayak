
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kheti Sahayak'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: <Widget>[
            _buildDashboardCard('Weather Forecast', Icons.cloud),
            _buildDashboardCard('Crop Advisory', Icons.local_florist),
            _buildDashboardCard('Market Prices', Icons.bar_chart),
            _buildDashboardCard('Pest & Disease Info', Icons.bug_report),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(String title, IconData icon) {
    return Card(
      elevation: 2.0,
      child: InkWell(
        onTap: () {
          // TODO: Navigate to the respective screen
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 50.0, color: const Color(0xFF4CAF50)),
            const SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
