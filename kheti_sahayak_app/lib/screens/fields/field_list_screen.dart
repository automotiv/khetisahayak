import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/field.dart';
import 'package:kheti_sahayak_app/services/field_service.dart';
import 'package:kheti_sahayak_app/screens/fields/add_field_screen.dart';
import 'package:kheti_sahayak_app/screens/fields/field_details_screen.dart';
import 'package:kheti_sahayak_app/screens/fields/bulk_field_update_screen.dart';

class FieldListScreen extends StatefulWidget {
  const FieldListScreen({super.key});

  @override
  State<FieldListScreen> createState() => _FieldListScreenState();
}

class _FieldListScreenState extends State<FieldListScreen> {
  final FieldService _fieldService = FieldService();
  List<Field> _fields = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  Future<void> _loadFields() async {
    setState(() => _isLoading = true);
    try {
      final fields = await _fieldService.getFields();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const BulkFieldUpdateScreen()),
                            );
                            if (result == true) {
                              _loadFields();
                            }
                          },
                          icon: const Icon(Icons.edit_note),
                          label: const Text('Bulk Update Fields'),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _fields.length,
                        itemBuilder: (context, index) {
                    final field = _fields[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green[100],
                          child: Icon(Icons.landscape, color: Colors.green[800]),
                        ),
                        title: Text(field.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${field.area} acres • ${field.cropType}'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _navigateToDetails(field),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddField,
        child: const Icon(Icons.add),
        tooltip: 'Add Field',
      ),
    );
  }
}
