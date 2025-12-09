import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/field.dart';
import 'package:kheti_sahayak_app/services/field_service.dart';
import 'package:kheti_sahayak_app/services/language_service.dart';

class BulkFieldUpdateScreen extends StatefulWidget {
  const BulkFieldUpdateScreen({Key? key}) : super(key: key);

  @override
  _BulkFieldUpdateScreenState createState() => _BulkFieldUpdateScreenState();
}

class _BulkFieldUpdateScreenState extends State<BulkFieldUpdateScreen> {
  final FieldService _fieldService = FieldService();
  List<Field> _fields = [];
  final Set<int> _selectedFieldIds = {};
  bool _isLoading = true;
  String? _selectedCropType;

  final List<String> _cropTypes = [
    'Wheat',
    'Rice',
    'Corn',
    'Soybean',
    'Cotton',
    'Sugarcane',
    'Potato',
    'Tomato',
    'Onion',
    'Fallow', // Important for fallow period tracking
  ];

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  Future<void> _loadFields() async {
    try {
      final fields = await _fieldService.getFields();
      setState(() {
        _fields = fields;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading fields: $e')),
      );
    }
  }

  Future<void> _performBulkUpdate() async {
    if (_selectedFieldIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one field')),
      );
      return;
    }

    if (_selectedCropType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a crop type to update')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _fieldService.updateFieldsBulk(
        fieldIds: _selectedFieldIds.toList(),
        cropType: _selectedCropType,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fields updated successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating fields: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Field Update'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _performBulkUpdate,
            tooltip: 'Apply Update',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Select New Crop Type',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedCropType,
                    items: _cropTypes.map((crop) {
                      return DropdownMenuItem(
                        value: crop,
                        child: Text(crop),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCropType = value;
                      });
                    },
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Fields (${_selectedFieldIds.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            if (_selectedFieldIds.length == _fields.length) {
                              _selectedFieldIds.clear();
                            } else {
                              _selectedFieldIds.addAll(_fields.map((f) => f.id!).toList());
                            }
                          });
                        },
                        child: Text(_selectedFieldIds.length == _fields.length ? 'Deselect All' : 'Select All'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _fields.length,
                    itemBuilder: (context, index) {
                      final field = _fields[index];
                      final isSelected = _selectedFieldIds.contains(field.id);
                      return CheckboxListTile(
                        title: Text(field.name),
                        subtitle: Text('${field.area} acres - Current: ${field.cropType}'),
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedFieldIds.add(field.id!);
                            } else {
                              _selectedFieldIds.remove(field.id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
