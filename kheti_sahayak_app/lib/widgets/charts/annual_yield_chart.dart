import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AnnualYieldChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String cropName;

  const AnnualYieldChart({
    super.key,
    required this.data,
    required this.cropName,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No annual data available.'));
    }

    // Prepare data points
    // data is sorted by year DESC, so we reverse it for the chart (ASC)
    final sortedData = List<Map<String, dynamic>>.from(data.reversed);
    
    double maxY = 0;
    final spots = <FlSpot>[];
    
    for (int i = 0; i < sortedData.length; i++) {
      final item = sortedData[i];
      final yieldAmount = (item['total_yield'] as num).toDouble();
      if (yieldAmount > maxY) maxY = yieldAmount;
      spots.add(FlSpot(i.toDouble(), yieldAmount));
    }
    
    maxY = maxY * 1.2; // Buffer

    return Column(
      children: [
        Text(
          '$cropName Annual Yield Trend',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        AspectRatio(
          aspectRatio: 1.5,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < sortedData.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            sortedData[index]['year'].toString(),
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }
                      return const Text('');
                    },
                    interval: 1,
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.withOpacity(0.3))),
              minX: 0,
              maxX: (sortedData.length - 1).toDouble(),
              minY: 0,
              maxY: maxY,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.green.withOpacity(0.2),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final index = spot.x.toInt();
                      final item = sortedData[index];
                      return LineTooltipItem(
                        '${item['year']}\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(
                            text: '${spot.y.toStringAsFixed(1)} ${item['unit']}',
                            style: const TextStyle(
                              color: Colors.yellow,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
