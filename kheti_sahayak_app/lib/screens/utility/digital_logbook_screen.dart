import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/logbook_entry.dart';
import 'package:kheti_sahayak_app/services/logbook_service.dart';
import 'package:intl/intl.dart';

class DigitalLogbookScreen extends StatefulWidget {
  const DigitalLogbookScreen({Key? key}) : super(key: key);

  @override
  _DigitalLogbookScreenState createState() => _DigitalLogbookScreenState();
}

class _DigitalLogbookScreenState extends State<DigitalLogbookScreen> {
  List<LogbookEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    final entries = await LogbookService.getEntries();
    if (mounted) {
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    }
  }

  Future<void> _addEntry() async {
    // Show dialog to add entry
    final result = await showDialog<LogbookEntry>(
      context: context,
      builder: (context) => const AddLogbookEntryDialog(),
    );

    if (result != null) {
      final success = await LogbookService.createEntry(result);
      if (success) {
        _loadEntries();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry added successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add entry')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Logbook'),
        backgroundColor: Colors.green[700],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? const Center(child: Text('No entries found. Add one!'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _entries.length,
                  itemBuilder: (context, index) {
                    final entry = _entries[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green[100],
                          child: Icon(
                            _getActivityIcon(entry.activityType),
                            color: Colors.green[700],
                          ),
                        ),
                        title: Text(entry.activityType),
                        subtitle: Text(DateFormat('MMM d, yyyy').format(DateTime.parse(entry.date))),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (entry.income > 0)
                              Text(
                                '+₹${entry.income}',
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                            if (entry.cost > 0)
                              Text(
                                '-₹${entry.cost}',
                                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEntry,
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'sowing': return Icons.grass;
      case 'harvesting': return Icons.agriculture;
      case 'fertilizer': return Icons.science;
      case 'irrigation': return Icons.water_drop;
      default: return Icons.edit_note;
    }
  }
}

class AddLogbookEntryDialog extends StatefulWidget {
  const AddLogbookEntryDialog({Key? key}) : super(key: key);

  @override
  _AddLogbookEntryDialogState createState() => _AddLogbookEntryDialogState();
}

class _AddLogbookEntryDialogState extends State<AddLogbookEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  String _activityType = 'Sowing';
  DateTime _selectedDate = DateTime.now();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  final _incomeController = TextEditingController();

  final List<String> _activityTypes = ['Sowing', 'Harvesting', 'Fertilizer', 'Irrigation', 'Other'];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Entry'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _activityType,
                items: _activityTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) => setState(() => _activityType = value!),
                decoration: const InputDecoration(labelText: 'Activity Type'),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text('Date: ${DateFormat('MMM d, yyyy').format(_selectedDate)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(labelText: 'Cost (₹)'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _incomeController,
                decoration: const InputDecoration(labelText: 'Income (₹)'),
                keyboardType: TextInputType.number,
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
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final entry = LogbookEntry(
                id: 0, // ID will be assigned by backend
                activityType: _activityType,
                date: _selectedDate.toIso8601String(),
                description: _descriptionController.text,
                cost: double.tryParse(_costController.text) ?? 0.0,
                income: double.tryParse(_incomeController.text) ?? 0.0,
              );
              Navigator.pop(context, entry);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
