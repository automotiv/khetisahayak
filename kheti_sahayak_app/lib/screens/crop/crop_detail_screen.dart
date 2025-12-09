
import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/widgets/optimized_network_image.dart';

class CropDetailScreen extends StatelessWidget {
  final String cropName;

  const CropDetailScreen({Key? key, required this.cropName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(cropName),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Placeholder for a crop image
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
            const SizedBox(height: 24),
            _buildDetailSection(context, 'Sowing Information', 'Ideal sowing time is from May to June. Use a seed rate of 15 kg/hectare.'),
            _buildDetailSection(context, 'Watering Schedule', 'Requires irrigation every 10-15 days during the growing season. Ensure good drainage to prevent waterlogging.'),
            _buildDetailSection(context, 'Fertilizer Requirements', 'Apply a basal dose of NPK at 40:60:40 kg/ha. Top dress with Nitrogen after 30 and 60 days.'),
            _buildDetailSection(context, 'Common Pests & Diseases', 'Watch out for aphids and stem borer. Powdery mildew can be an issue in humid conditions.'),
          ],
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
