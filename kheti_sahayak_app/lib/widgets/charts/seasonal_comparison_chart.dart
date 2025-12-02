import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SeasonalComparisonChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String cropName;

  const SeasonalComparisonChart({
    super.key,
    required this.data,
    required this.cropName,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No seasonal data available.'));
    }

    double maxY = 0;
    for (var d in data) {
      if (d['yield_per_acre'] > maxY) maxY = d['yield_per_acre'];
    }
    maxY = maxY * 1.2; // Buffer

    return Column(
      children: [
        Text(
          '$cropName Yield per Acre (Comparison)',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        AspectRatio(
          aspectRatio: 1.5,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final item = data[group.x.toInt()];
                    return BarTooltipItem(
                      '${item['season_year']}\n',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: '${rod.toY.toStringAsFixed(1)} / acre',
                          style: const TextStyle(
                            color: Colors.yellow,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < data.length) {
                        // Show only Year or short season code to save space
                        // e.g., "Rabi 2023" -> "R'23"
                        final label = data[index]['season_year'] as String;
                        final parts = label.split(' ');
                        final season = parts[0][0]; // First letter
                        final year = parts.last.substring(2); // Last 2 digits
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '$season\'$year',
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false), // Hide Y axis labels for cleaner look
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: data.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final value = (item['yield_per_acre'] as num).toDouble();
                
                // Color coding: Kharif (Green), Rabi (Orange), Zaid (Blue)
                Color color = Colors.grey;
                if (item['season_year'].toString().contains('Kharif')) color = Colors.green;
                else if (item['season_year'].toString().contains('Rabi')) color = Colors.orange;
                else if (item['season_year'].toString().contains('Zaid')) color = Colors.blue;

                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: value,
                      color: color,
                      width: 16,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Legend
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendItem(color: Colors.green, label: 'Kharif'),
            SizedBox(width: 16),
            _LegendItem(color: Colors.orange, label: 'Rabi'),
            SizedBox(width: 16),
            _LegendItem(color: Colors.blue, label: 'Zaid'),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
