
import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/widgets/optimized_network_image.dart';

class MarketPriceDetailScreen extends StatelessWidget {
  final Map<String, String> commodity;

  const MarketPriceDetailScreen({Key? key, required this.commodity}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(commodity['name']!),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildPriceCard(context, 'Current Price', commodity['price']!),
            const SizedBox(height: 24),
            _buildDetailSection(context, 'Price Trend', 'Prices have been stable for the past week, with a slight increase due to seasonal demand.'),
            _buildDetailSection(context, 'Market Information', 'Trading is active in the morning sessions. The market is closed on Sundays.'),
             // Placeholder for a chart
            const SizedBox(height: 24),
            Text('Price History (Last 7 Days)', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: OptimizedNetworkImage(
                  imageUrl: 'https://img.icons8.com/plasticine/100/banana.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCard(BuildContext context, String title, String price) {
    return Center(
      child: Card(
        elevation: 4.0,
        color: const Color(0xFF4CAF50),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 32.0),
          child: Column(
            children: [
              Text(title, style: const TextStyle(fontSize: 18, color: Colors.white)),
              const SizedBox(height: 8),
              Text(price, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

   Widget _buildDetailSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
