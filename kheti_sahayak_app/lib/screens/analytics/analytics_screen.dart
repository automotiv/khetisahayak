import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/field.dart';
import 'package:kheti_sahayak_app/services/field_service.dart';
import 'package:kheti_sahayak_app/widgets/charts/seasonal_comparison_chart.dart';
import 'package:kheti_sahayak_app/widgets/charts/annual_yield_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final FieldService _fieldService = FieldService();
  
  List<Field> _fields = [];
  Field? _selectedField;
  String? _selectedCrop;
  
  // Available crops (could be dynamic based on field history)
  final List<String> _cropOptions = ['Wheat', 'Rice', 'Corn', 'Sugarcane', 'Cotton'];
  
  List<Map<String, dynamic>> _comparisonData = [];
  List<Map<String, dynamic>> _annualData = [];
  Map<String, double> _roiData = {};
  bool _isLoading = false;
  
  // View Mode: 'seasonal' or 'annual'
  String _viewMode = 'seasonal';
  int _selectedYears = 5;

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  Future<void> _loadFields() async {
    final fields = await _fieldService.getFields();
    if (mounted) {
      setState(() {
        _fields = fields;
        if (fields.isNotEmpty) {
          _selectedField = fields.first;
          _selectedCrop = _cropOptions.first;
          _selectedField = fields.first;
          _selectedCrop = _cropOptions.first;
          _loadData();
        }
      });
    }
  }

  Future<void> _loadData() async {
    if (_selectedField == null) return;

    setState(() => _isLoading = true);
    try {
      // Load Seasonal Comparison (if crop selected)
      List<Map<String, dynamic>> comparisonData = [];
      List<Map<String, dynamic>> annualData = [];
      
      if (_selectedCrop != null) {
        comparisonData = await _fieldService.getSeasonalComparison(
          fieldId: _selectedField!.id!,
          cropName: _selectedCrop!,
        );
        
        annualData = await _fieldService.getYieldTrends(
          fieldId: _selectedField!.id!,
          cropName: _selectedCrop!,
          years: _selectedYears,
        );
      }

      // Load ROI Data
      final roiData = await _fieldService.getROIData(_selectedField!.id!);

      setState(() {
        _comparisonData = comparisonData;
        _annualData = annualData;
        _roiData = roiData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Analytics'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filters
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<Field>(
                      value: _selectedField,
                      decoration: const InputDecoration(labelText: 'Select Field'),
                      items: _fields.map((f) => DropdownMenuItem(value: f, child: Text(f.name))).toList(),
                      onChanged: (v) {
                        setState(() => _selectedField = v);
                        setState(() => _selectedField = v);
                        _loadData();
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCrop,
                      decoration: const InputDecoration(labelText: 'Select Crop'),
                      items: _cropOptions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) {
                        setState(() => _selectedCrop = v);
                        setState(() => _selectedCrop = v);
                        _loadData();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ROI Summary Card
            if (!_isLoading && _roiData.isNotEmpty) ...[
              const Text(
                'Financial Overview (All Time)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStat('Investment', _roiData['total_investment']!, Colors.red),
                          _buildStat('Returns', _roiData['total_return']!, Colors.green),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStat('Net Profit', _roiData['net_profit']!, 
                            _roiData['net_profit']! >= 0 ? Colors.green[800]! : Colors.red[800]!),
                          _buildStat('ROI', _roiData['roi_percentage']!, Colors.blue, isPercent: true),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Chart Section
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Yield Trends',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ToggleButtons(
                    isSelected: [_viewMode == 'seasonal', _viewMode == 'annual'],
                    onPressed: (index) {
                      setState(() {
                        _viewMode = index == 0 ? 'seasonal' : 'annual';
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    constraints: const BoxConstraints(minHeight: 36, minWidth: 80),
                    children: const [
                      Text('Seasonal'),
                      Text('Annual'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              if (_viewMode == 'seasonal') ...[
                if (_comparisonData.isEmpty)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No seasonal data available for selected crop.'),
                  ))
                else
                  SizedBox(
                    height: 300,
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SeasonalComparisonChart(
                          data: _comparisonData,
                          cropName: _selectedCrop!,
                        ),
                      ),
                    ),
                  ),
              ] else ...[
                // Annual View
                if (_annualData.isEmpty)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No annual data available for selected crop.'),
                  ))
                else ...[
                  // Year Filter for Annual View
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text('Show last: '),
                      DropdownButton<int>(
                        value: _selectedYears,
                        items: [5, 10, 15].map((y) => DropdownMenuItem(value: y, child: Text('$y Years'))).toList(),
                        onChanged: (v) {
                          setState(() => _selectedYears = v!);
                          _loadData();
                        },
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 300,
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: AnnualYieldChart(
                          data: _annualData,
                          cropName: _selectedCrop!,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 16),
              // Summary Table
              const Text(
                'Detailed Breakdown',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _comparisonData.length,
                  itemBuilder: (context, index) {
                    final item = _comparisonData[index];
                    return Card(
                      child: ListTile(
                        title: Text(item['season_year']),
                        subtitle: Text('Total Yield: ${item['total_yield']}'),
                        trailing: Text(
                          '${(item['yield_per_acre'] as double).toStringAsFixed(1)} / acre',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, double value, Color color, {bool isPercent = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          isPercent ? '${value.toStringAsFixed(1)}%' : '₹${value.toStringAsFixed(0)}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}
