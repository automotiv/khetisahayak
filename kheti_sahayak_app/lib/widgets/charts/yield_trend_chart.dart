import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class YieldTrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> yieldData;

  const YieldTrendChart({super.key, required this.yieldData});

  @override
  Widget build(BuildContext context) {
    if (yieldData.isEmpty) {
      return const Center(
        child: Text('No yield data available for the last 5 years.'),
      );
    }

    // Group data by crop
    final Map<String, List<Map<String, dynamic>>> dataByCrop = {};
    final Set<String> years = {};
    double maxYield = 0;

    for (var record in yieldData) {
      final crop = record['crop_name'] as String;
      final year = record['year'] as String;
      final yieldAmount = (record['total_yield'] as num).toDouble();

      if (!dataByCrop.containsKey(crop)) {
        dataByCrop[crop] = [];
      }
      dataByCrop[crop]!.add(record);
      years.add(year);
      if (yieldAmount > maxYield) maxYield = yieldAmount;
    }

    final sortedYears = years.toList()..sort();
    final yearMap = {for (var i = 0; i < sortedYears.length; i++) sortedYears[i]: i.toDouble()};

    // Define colors for different crops
    final List<Color> colors = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.red,
      Colors.purple,
    ];

    int colorIndex = 0;
    final List<LineChartBarData> lineBarsData = [];

    dataByCrop.forEach((crop, records) {
      // Sort records by year
      records.sort((a, b) => (a['year'] as String).compareTo(b['year'] as String));

      final List<FlSpot> spots = records.map((r) {
        final year = r['year'] as String;
        final yieldAmount = (r['total_yield'] as num).toDouble();
        return FlSpot(yearMap[year]!, yieldAmount);
      }).toList();

      lineBarsData.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: colors[colorIndex % colors.length],
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(show: false),
        ),
      );
      colorIndex++;
    });

    return Column(
      children: [
        const Text(
          'Yield Trends (Last 5 Years)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        AspectRatio(
          aspectRatio: 1.70,
          child: Padding(
            padding: const EdgeInsets.only(
              right: 18,
              left: 12,
              top: 24,
              bottom: 12,
            ),
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 1,
                  verticalInterval: 1,
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < sortedYears.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              sortedYears[index],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: maxYield > 0 ? maxYield / 5 : 1,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.left,
                        );
                      },
                      reservedSize: 42,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: const Color(0xff37434d)),
                ),
                minX: 0,
                maxX: (sortedYears.length - 1).toDouble(),
                minY: 0,
                maxY: maxYield * 1.2, // Add some buffer
                lineBarsData: lineBarsData,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        final flSpot = barSpot;
                        final yearIndex = flSpot.x.toInt();
                        final year = sortedYears[yearIndex];
                        
                        // Find crop name for this bar
                        // This is a bit tricky since we don't have direct access to the crop name from the spot
                        // But we know the order of lineBarsData matches our iteration
                        
                        // A better way is to put the crop name in the tooltip
                        // For now, let's just show the value
                        
                        return LineTooltipItem(
                          '$year: ${flSpot.y.toStringAsFixed(1)}',
                          const TextStyle(color: Colors.white),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Legend
        Wrap(
          spacing: 16,
          children: dataByCrop.keys.toList().asMap().entries.map((entry) {
            final index = entry.key;
            final crop = entry.value;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  color: colors[index % colors.length],
                ),
                const SizedBox(width: 4),
                Text(crop),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
