import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/field.dart';
import 'package:kheti_sahayak_app/models/crop_rotation.dart';
import 'package:kheti_sahayak_app/models/yield_record.dart';
import 'package:kheti_sahayak_app/services/farm_management_service.dart';
import 'package:kheti_sahayak_app/models/activity_record.dart';
import 'package:kheti_sahayak_app/services/analytics_service.dart';
import 'package:kheti_sahayak_app/services/activity_service.dart';
import 'package:kheti_sahayak_app/widgets/charts/yield_trend_chart.dart';
import 'package:kheti_sahayak_app/widgets/activity_type_dropdown.dart';
import 'package:kheti_sahayak_app/widgets/roi_summary_card.dart';
import 'package:kheti_sahayak_app/widgets/crop_planner_dialog.dart';

class FieldDetailsScreen extends StatefulWidget {
  final Field field;

  const FieldDetailsScreen({super.key, required this.field});

  @override
  State<FieldDetailsScreen> createState() => _FieldDetailsScreenState();
}

class _FieldDetailsScreenState extends State<FieldDetailsScreen> {
  final FarmManagementService _farmService = FarmManagementService();
  final AnalyticsService _analyticsService = AnalyticsService();
  
  List<CropRotation> _rotations = [];
  Map<int, double> _yieldTrends = {};
  bool _isLoading = true;
  Map<String, double>? _currentROI;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.field.id == null) return;
    setState(() => _isLoading = true);
    try {
      // In a real app we would fetch rotations from FarmService. 
      // For now mocking empty as FarmService doesn't have getRotations yet, 
      // assuming we'd add it or use a separate RotationService.
      // Keeping original list logic for UI demo.
      final rotations = <CropRotation>[]; 
      
      // Calculate Trends
      final trends = _analyticsService.getYieldTrends(rotations);
      
      // Calculate ROI for latest cycle (mock logic for demo)
      final roi = _analyticsService.calculateROI(
        yieldAmount: 50, 
        pricePerUnit: 2000, 
        totalCost: 45000
      );

      setState(() {
        _rotations = rotations;
        _yieldTrends = trends;
        _currentROI = roi;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddRotationDialog() {
    String? lastCrop = _rotations.isNotEmpty ? _rotations.first.cropName : widget.field.cropType;
    
    showDialog(
      context: context,
      builder: (context) => CropPlannerDialog(
        previousCrop: lastCrop,
        onSelected: (selectedCrop) {
           // Proceed to add detailed plan with this crop
           _showAddDetailedPlanDialog(selectedCrop);
        },
      ),
    );
  }

  void _showAddDetailedPlanDialog(String cropName) {
     showDialog(
      context: context,
      builder: (context) => _AddRotationDialog(
        fieldId: widget.field.id!,
        initialCrop: cropName,
        onSaved: _loadData,
      ),
    );
  }

  void _showAddActivityDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddActivityDialog(
        fieldId: widget.field.id!,
        onSaved: _loadData,
      ),
    );
  }

  void _showAddYieldDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddYieldDialog(
        fieldId: widget.field.id!,
        onSaved: _loadData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.field.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Field Info Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.aspect_ratio, 'Area', '${widget.field.area} Acres'),
                    const Divider(),
                    _buildInfoRow(Icons.grass, 'Current Crop', widget.field.cropType),
                    const Divider(),
                    _buildInfoRow(Icons.location_on, 'Location', widget.field.location),
                    const Divider(),
                    // New Attributes
                    _buildInfoRow(Icons.terrain, 'Soil Type', widget.field.soilType),
                    const Divider(),
                    _buildInfoRow(Icons.water_drop, 'Irrigation', widget.field.irrigationSource),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (_currentROI != null) ...[
              ROISummaryCard(roiData: _currentROI!), // New Widget
              const SizedBox(height: 24),
            ],

            // Yield Trends Section (Adapted for Map input if graph widget supports it, 
            // else converting to List<Map> for compatibility with existing chart widget)
            if (!_isLoading && _yieldTrends.isNotEmpty) ...[
              const Text(
                'Yield History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: YieldTrendChart(
                    yieldData: _yieldTrends.entries.map((e) => {'year': e.key, 'yield': e.value}).toList()
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showAddActivityDialog,
                    icon: const Icon(Icons.work),
                    label: const Text('Add Activity'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showAddYieldDialog,
                    icon: const Icon(Icons.agriculture),
                    label: const Text('Add Yield'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Crop Rotation Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Crop Rotation History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _showAddRotationDialog, // Opens Planner
                  icon: const Icon(Icons.add),
                  label: const Text('Add Plan'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _rotations.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No crop rotation history available.'),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _rotations.length,
                        itemBuilder: (context, index) {
                          final rotation = _rotations[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(rotation.status).withOpacity(0.2),
                                child: Icon(Icons.history, color: _getStatusColor(rotation.status)),
                              ),
                              title: Text('${rotation.cropName} (${rotation.season} ${rotation.year})'),
                              subtitle: Text(rotation.status),
                              trailing: rotation.notes != null
                                  ? IconButton(
                                      icon: const Icon(Icons.note),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Notes'),
                                            content: Text(rotation.notes!),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Close'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Colors.green;
      case 'active': return Colors.blue;
      case 'planned': return Colors.orange;
      default: return Colors.grey;
    }
  }
}

class _AddRotationDialog extends StatefulWidget {
  final int fieldId;
  final String? initialCrop;
  final VoidCallback onSaved;

  const _AddRotationDialog({required this.fieldId, this.initialCrop, required this.onSaved});

  @override
  State<_AddRotationDialog> createState() => _AddRotationDialogState();
}

class _AddRotationDialogState extends State<_AddRotationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cropController = TextEditingController();
  final _yearController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedSeason = 'Kharif';
  String _selectedStatus = 'Planned';
  // ignore: unused_field
  final FarmManagementService _farmService = FarmManagementService();

  @override
  void initState() {
    super.initState();
    _yearController.text = DateTime.now().year.toString();
    if (widget.initialCrop != null) {
      _cropController.text = widget.initialCrop!;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final rotation = CropRotation(
        fieldId: widget.fieldId,
        cropName: _cropController.text,
        season: _selectedSeason,
        year: int.parse(_yearController.text),
        status: _selectedStatus,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      // await _farmService.addRotation(rotation); // method to be implemented in service
      print('Mock: Rotation Added $rotation');
      
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Crop Plan'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _cropController,
                decoration: const InputDecoration(labelText: 'Crop Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              DropdownButtonFormField<String>(
                value: _selectedSeason,
                items: ['Kharif', 'Rabi', 'Zaid']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedSeason = v!),
                decoration: const InputDecoration(labelText: 'Season'),
              ),
              TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(labelText: 'Year'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                items: ['Planned', 'Active', 'Completed']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedStatus = v!),
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes (Optional)'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _AddActivityDialog extends StatefulWidget {
  final int fieldId;
  final VoidCallback onSaved;

  const _AddActivityDialog({required this.fieldId, required this.onSaved});

  @override
  State<_AddActivityDialog> createState() => _AddActivityDialogState();
}

class _AddActivityDialogState extends State<_AddActivityDialog> {
  final _formKey = GlobalKey<FormState>();
  String _selectedActivityType = 'Planting';
  final _costController = TextEditingController();
  final ActivityService _activityService = ActivityService();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await _activityService.createActivityRecord(
        fieldId: widget.fieldId,
        activityType: _selectedActivityType,
        cost: double.tryParse(_costController.text) ?? 0.0,
      );

      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Activity'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ActivityTypeDropdown(
              value: _selectedActivityType,
              onChanged: (value) => setState(() => _selectedActivityType = value!),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _costController,
              decoration: const InputDecoration(labelText: 'Cost (₹)'),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _AddYieldDialog extends StatefulWidget {
  final int fieldId;
  final VoidCallback onSaved;

  const _AddYieldDialog({required this.fieldId, required this.onSaved});

  @override
  State<_AddYieldDialog> createState() => _AddYieldDialogState();
}

class _AddYieldDialogState extends State<_AddYieldDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cropController = TextEditingController();
  final _amountController = TextEditingController();
  final _unitController = TextEditingController(text: 'Quintal');
  final _priceController = TextEditingController();
  // ignore: unused_field
  final FarmManagementService _farmService = FarmManagementService();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final record = YieldRecord(
        fieldId: widget.fieldId,
        cropName: _cropController.text,
        harvestDate: DateTime.now(),
        yieldAmount: double.tryParse(_amountController.text) ?? 0.0,
        unit: _unitController.text,
        marketPrice: double.tryParse(_priceController.text) ?? 0.0,
      );

      // await _farmService.addYieldRecord(record);
      print('Mock: Yield Added $record');
      
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Yield'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _cropController,
                decoration: const InputDecoration(labelText: 'Crop Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Yield Amount'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(labelText: 'Unit'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Market Price (per unit)'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
