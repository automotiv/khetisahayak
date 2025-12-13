import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/logbook_entry.dart';
import 'package:kheti_sahayak_app/services/logbook_service.dart';
import 'package:kheti_sahayak_app/widgets/activity_type_dropdown.dart';
import 'package:intl/intl.dart';
import 'package:kheti_sahayak_app/services/language_service.dart';
import 'package:kheti_sahayak_app/screens/utility/add_logbook_entry_screen.dart';
import 'package:kheti_sahayak_app/screens/utility/logbook_analytics_tab.dart';
import 'package:kheti_sahayak_app/models/field.dart';
import 'package:kheti_sahayak_app/services/field_service.dart';

class DigitalLogbookScreen extends StatefulWidget {
  const DigitalLogbookScreen({Key? key}) : super(key: key);

  @override
  _DigitalLogbookScreenState createState() => _DigitalLogbookScreenState();
}

class _DigitalLogbookScreenState extends State<DigitalLogbookScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<LogbookEntry> _entries = [];
  List<Field> _fields = [];
  int? _filterFieldId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final fields = await FieldService().getFields();
      final entries = await LogbookService.getEntries(fieldId: _filterFieldId);
      
      if (mounted) {
        setState(() {
          _fields = fields;
          _entries = entries;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading logbook data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addEntry() async {
    final result = await Navigator.push<LogbookEntry>(
      context,
      MaterialPageRoute(builder: (context) => const AddLogbookEntryScreen()),
    );

    if (result != null) {
      final success = await LogbookService.createEntry(result);
      if (mounted) {
        if (success) {
          _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).success)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).failed)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Logbook'),
        backgroundColor: Colors.green[700],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Activities'),
            Tab(text: 'Analytics'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              await LogbookService.syncEntries();
              _loadData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sync triggered')),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActivitiesTab(localizations),
          const LogbookAnalyticsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEntry,
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildActivitiesTab(AppLocalizations localizations) {
    return Column(
      children: [
        if (_fields.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<int>(
              value: _filterFieldId,
              decoration: const InputDecoration(
                labelText: 'Filter by Field',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.filter_list),
              ),
              items: [
                const DropdownMenuItem<int>(value: null, child: Text('All Fields')),
                ..._fields.map((field) {
                  return DropdownMenuItem<int>(
                    value: field.id,
                    child: Text(field.name),
                  );
                }),
              ],
              onChanged: (val) {
                setState(() => _filterFieldId = val);
                _loadData();
              },
            ),
          ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _entries.isEmpty
                  ? Center(child: Text(localizations.noData))
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
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(DateFormat.yMMMd(localizations.locale.toString()).format(DateTime.parse(entry.date))),
                                if (entry.fieldId != null)
                                  Text(
                                    'Field: ${_getFieldName(entry.fieldId!)}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                              ],
                            ),
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
                                if (!entry.synced)
                                  const Icon(Icons.cloud_off, size: 12, color: Colors.grey),
                              ],
                            ),
                            onTap: () {
                              // TODO: Show details or edit
                            },
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  String _getFieldName(int id) {
    try {
      return _fields.firstWhere((f) => f.id == id).name;
    } catch (e) {
      return 'Unknown Field';
    }
  }

  IconData _getActivityIcon(String type) {
    final iconMap = ActivityTypeDropdown.activityTypes;
    return iconMap[type] ?? Icons.edit_note;
  }
}
