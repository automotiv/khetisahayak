import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/field.dart';
import 'package:kheti_sahayak_app/services/field_service.dart';
import 'package:kheti_sahayak_app/widgets/dashboard/yield_trend_chart.dart';

class LogbookAnalyticsTab extends StatefulWidget {
  const LogbookAnalyticsTab({Key? key}) : super(key: key);

  @override
  _LogbookAnalyticsTabState createState() => _LogbookAnalyticsTabState();
}

class _LogbookAnalyticsTabState extends State<LogbookAnalyticsTab> {
  List<Field> _fields = [];
  int? _selectedFieldId;
  Map<String, double>? _roiData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final fields = await FieldService().getFields();
      if (fields.isNotEmpty) {
        _fields = fields;
        _selectedFieldId = fields.first.id;
        await _loadROI();
      }
    } catch (e) {
      print('Error loading analytics data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadROI() async {
    if (_selectedFieldId == null) return;
    try {
      final data = await FieldService().getROIData(_selectedFieldId!);
      if (mounted) setState(() => _roiData = data);
    } catch (e) {
      print('Error loading ROI data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_fields.isEmpty) {
      return const Center(child: Text('No fields found. Add fields to see analytics.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldSelector(),
          const SizedBox(height: 24),
          const Text(
            'Yield Trends',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const SizedBox(
            height: 300,
            child: YieldTrendChart(), // Uses internal logic to fetch data, might need update to accept fieldId
          ),
          const SizedBox(height: 24),
          const Text(
            'ROI Analysis',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildROICard(),
        ],
      ),
    );
  }

  Widget _buildFieldSelector() {
    return DropdownButtonFormField<int>(
      value: _selectedFieldId,
      decoration: const InputDecoration(
        labelText: 'Select Field',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.landscape),
      ),
      items: _fields.map((field) {
        return DropdownMenuItem<int>(
          value: field.id,
          child: Text(field.name),
        );
      }).toList(),
      onChanged: (val) {
        setState(() => _selectedFieldId = val);
        _loadROI();
      },
    );
  }

  Widget _buildROICard() {
    if (_roiData == null) {
      return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No data available')));
    }

    final investment = _roiData!['total_investment'] ?? 0.0;
    final returns = _roiData!['total_return'] ?? 0.0;
    final profit = _roiData!['net_profit'] ?? 0.0;
    final roi = _roiData!['roi_percentage'] ?? 0.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildROIRow('Total Investment', '₹${investment.toStringAsFixed(2)}', Colors.red),
            const Divider(),
            _buildROIRow('Total Returns', '₹${returns.toStringAsFixed(2)}', Colors.green),
            const Divider(),
            _buildROIRow('Net Profit', '₹${profit.toStringAsFixed(2)}', profit >= 0 ? Colors.green : Colors.red),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: roi >= 0 ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: roi >= 0 ? Colors.green : Colors.red),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ROI: ${roi.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: roi >= 0 ? Colors.green[800] : Colors.red[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildROIRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
