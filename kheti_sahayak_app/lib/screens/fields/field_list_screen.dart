import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/field.dart';
import 'package:kheti_sahayak_app/services/farm_management_service.dart';
import 'package:kheti_sahayak_app/screens/fields/add_field_screen.dart';
import 'package:kheti_sahayak_app/screens/fields/field_details_screen.dart';
import 'package:kheti_sahayak_app/services/offline_service.dart';

class FieldListScreen extends StatefulWidget {
  const FieldListScreen({super.key});

  @override
  State<FieldListScreen> createState() => _FieldListScreenState();
}

class _FieldListScreenState extends State<FieldListScreen> {
  final FarmManagementService _farmService = FarmManagementService();
  // ignore: unused_field
  final OfflineService _offlineService = OfflineService(); // Ensure instantiated
  
  List<Field> _fields = [];
  bool _isLoading = true;
  bool _isSelectionMode = false;
  final Set<int> _selectedFieldIds = {};

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  Future<void> _loadFields() async {
    setState(() => _isLoading = true);
    try {
      final fields = await _farmService.getAllFields();
      setState(() {
        _fields = fields;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error
    }
  }

  void _navigateToAddField() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddFieldScreen()),
    );
    if (result == true) {
      _loadFields();
    }
  }

  void _navigateToDetails(Field field) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FieldDetailsScreen(field: field)),
    );
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedFieldIds.contains(id)) {
        _selectedFieldIds.remove(id);
        if (_selectedFieldIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedFieldIds.add(id);
      }
    });
  }

  Future<void> _performBulkAction() async {
    if (_selectedFieldIds.isEmpty) return;

    // Placeholder for bulk action dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bulk action for ${_selectedFieldIds.length} fields coming soon!')),
    );
    
    // Reset selection
    setState(() {
      _isSelectionMode = false;
      _selectedFieldIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode ? '${_selectedFieldIds.length} Selected' : 'Fields'),
        actions: [
          StreamBuilder<bool>(
            stream: _offlineService.onConnectionChanged,
            initialData: _offlineService.isOnline,
            builder: (context, snapshot) {
              final isOnline = snapshot.data ?? false;
              return Icon(
                isOnline ? Icons.cloud_done : Icons.cloud_off,
                color: isOnline ? Colors.green : Colors.grey,
              );
            },
          ),
          const SizedBox(width: 12),
          if (_isSelectionMode)
             IconButton(
              icon: const Icon(Icons.playlist_add_check),
              onPressed: _performBulkAction,
              tooltip: 'Bulk Action',
            ),
          if (!_isSelectionMode && _fields.isNotEmpty)
             IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: () => setState(() => _isSelectionMode = true),
              tooltip: 'Select Multiple',
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _fields.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.landscape, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No fields added yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _navigateToAddField,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Your First Field'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _fields.length,
                  itemBuilder: (context, index) {
                    final field = _fields[index];
                    final isSelected = _selectedFieldIds.contains(field.id);

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      color: isSelected ? Colors.green[50] : null,
                      child: ListTile(
                        leading: _isSelectionMode
                            ? Checkbox(
                                value: isSelected,
                                onChanged: (_) => _toggleSelection(field.id!),
                              )
                            : CircleAvatar(
                                backgroundColor: Colors.green[100],
                                child: Icon(Icons.landscape, color: Colors.green[800]),
                              ),
                        title: Text(field.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${field.area} acres • ${field.cropType}'),
                        trailing: _isSelectionMode ? null : const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          if (_isSelectionMode) {
                            _toggleSelection(field.id!);
                          } else {
                            _navigateToDetails(field);
                          }
                        },
                        onLongPress: () {
                           if (!_isSelectionMode) {
                             setState(() {
                               _isSelectionMode = true;
                               _selectedFieldIds.add(field.id!);
                             });
                           }
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: !_isSelectionMode
          ? FloatingActionButton(
              onPressed: _navigateToAddField,
              child: const Icon(Icons.add),
              tooltip: 'Add Field',
            )
          : null,
    );
  }
}
