import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/services/field_service.dart';
import 'package:kheti_sahayak_app/widgets/charts/yield_trend_chart.dart';

class YieldTrendsWidget extends StatefulWidget {
  const YieldTrendsWidget({super.key});

  @override
  State<YieldTrendsWidget> createState() => _YieldTrendsWidgetState();
}

class _YieldTrendsWidgetState extends State<YieldTrendsWidget> {
  final FieldService _fieldService = FieldService();
  List<Map<String, dynamic>> _yieldTrends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Fetch trends for all fields (fieldId: null)
      final trends = await _fieldService.getYieldTrends(years: 5);
      if (mounted) {
        setState(() {
          _yieldTrends = trends;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_yieldTrends.isEmpty) {
      return const SizedBox.shrink(); // Hide if no data
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Yield Trends (Last 5 Years)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, 'analytics');
                  },
                  child: const Text('View Full Analytics'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            YieldTrendChart(yieldData: _yieldTrends),
          ],
        ),
      ),
    );
  }
}
