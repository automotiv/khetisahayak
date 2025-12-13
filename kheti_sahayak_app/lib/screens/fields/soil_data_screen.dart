import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kheti_sahayak_app/models/soil_data.dart';
import 'package:kheti_sahayak_app/services/field_service.dart';
import 'package:kheti_sahayak_app/services/language_service.dart';

class SoilDataScreen extends StatefulWidget {
  final int fieldId;

  const SoilDataScreen({Key? key, required this.fieldId}) : super(key: key);

  @override
  _SoilDataScreenState createState() => _SoilDataScreenState();
}

class _SoilDataScreenState extends State<SoilDataScreen> {
  final FieldService _fieldService = FieldService();
  late Future<List<SoilData>> _soilDataFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _soilDataFuture = _fieldService.getSoilDataHistory(widget.fieldId);
    });
  }

  void _showAddDialog() {
    final _formKey = GlobalKey<FormState>();
    DateTime _selectedDate = DateTime.now();
    double? _ph;
    double? _organicCarbon;
    double? _nitrogen;
    double? _phosphorus;
    double? _potassium;
    String? _notes;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Soil Test Record'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text('Date: ${DateFormat.yMMMd().format(_selectedDate)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      // Update date in dialog state? 
                      // Dialogs are tricky with state, better to use a StatefulBuilder or just rebuild
                      // For simplicity, we'll just use the variable and hope the user remembers or re-opens
                      // Actually, let's use a StatefulBuilder inside the dialog if we want to update UI
                      _selectedDate = picked;
                    }
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'pH Level'),
                  keyboardType: TextInputType.number,
                  onSaved: (value) => _ph = double.tryParse(value ?? ''),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Organic Carbon (%)'),
                  keyboardType: TextInputType.number,
                  onSaved: (value) => _organicCarbon = double.tryParse(value ?? ''),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Nitrogen (kg/ha)'),
                  keyboardType: TextInputType.number,
                  onSaved: (value) => _nitrogen = double.tryParse(value ?? ''),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Phosphorus (kg/ha)'),
                  keyboardType: TextInputType.number,
                  onSaved: (value) => _phosphorus = double.tryParse(value ?? ''),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Potassium (kg/ha)'),
                  keyboardType: TextInputType.number,
                  onSaved: (value) => _potassium = double.tryParse(value ?? ''),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 2,
                  onSaved: (value) => _notes = value,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                final data = SoilData(
                  fieldId: widget.fieldId,
                  testDate: _selectedDate,
                  pH: _ph,
                  organicCarbon: _organicCarbon,
                  nitrogen: _nitrogen,
                  phosphorus: _phosphorus,
                  potassium: _potassium,
                  notes: _notes,
                );
                await _fieldService.addSoilData(data);
                if (mounted) {
                  Navigator.pop(context);
                  _refreshData();
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Soil Health Records'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<SoilData>>(
        future: _soilDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No soil records found.'));
          }

          final records = snapshot.data!;
          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ExpansionTile(
                  title: Text(DateFormat.yMMMd(localizations.locale.toString()).format(record.testDate)),
                  subtitle: Text('pH: ${record.pH ?? "N/A"} | OC: ${record.organicCarbon ?? "N/A"}%'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Nitrogen (N)', '${record.nitrogen ?? "-"} kg/ha'),
                          _buildDetailRow('Phosphorus (P)', '${record.phosphorus ?? "-"} kg/ha'),
                          _buildDetailRow('Potassium (K)', '${record.potassium ?? "-"} kg/ha'),
                          if (record.notes != null && record.notes!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text('Notes: ${record.notes}', style: const TextStyle(fontStyle: FontStyle.italic)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}
