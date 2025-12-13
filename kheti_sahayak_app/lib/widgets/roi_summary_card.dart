import 'package:flutter/material.dart';

class ROISummaryCard extends StatelessWidget {
  final Map<String, double> roiData; // Expected keys: 'gross_revenue', 'net_profit', 'roi_percentage'
  final VoidCallback? onTap;

  const ROISummaryCard({
    super.key,
    required this.roiData,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final netProfit = roiData['net_profit'] ?? 0.0;
    final roiPercent = roiData['roi_percentage'] ?? 0.0;
    final isProfitable = netProfit >= 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ROI Analysis',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isProfitable ? Colors.green[100] : Colors.red[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${roiPercent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: isProfitable ? Colors.green[800] : Colors.red[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetric('Revenue', roiData['gross_revenue'] ?? 0.0, Colors.black),
                  _buildMetric('Net Profit', netProfit, isProfitable ? Colors.green : Colors.red),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          '₹${value.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
