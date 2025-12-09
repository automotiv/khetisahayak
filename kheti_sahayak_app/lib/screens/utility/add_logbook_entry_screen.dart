import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:kheti_sahayak_app/models/field.dart';
import 'package:kheti_sahayak_app/models/logbook_entry.dart';
import 'package:kheti_sahayak_app/services/field_service.dart';
import 'package:kheti_sahayak_app/services/language_service.dart';
import 'package:kheti_sahayak_app/widgets/activity_type_dropdown.dart';

class AddLogbookEntryScreen extends StatefulWidget {
  final LogbookEntry? entry;

  const AddLogbookEntryScreen({Key? key, this.entry}) : super(key: key);

  @override
  _AddLogbookEntryScreenState createState() => _AddLogbookEntryScreenState();
}

class _AddLogbookEntryScreenState extends State<AddLogbookEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  String _activityType = 'Planting';
  DateTime _selectedDate = DateTime.now();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  
  List<Field> _fields = [];
  int? _selectedFieldId;
  List<String> _imagePaths = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadFields();
    if (widget.entry != null) {
      _activityType = widget.entry!.activityType;
      _selectedDate = DateTime.parse(widget.entry!.date);
      _descriptionController.text = widget.entry!.description ?? '';
      _costController.text = widget.entry!.cost.toString();
      _selectedFieldId = widget.entry!.fieldId;
      _imagePaths = widget.entry!.images ?? [];
    }
  }

  Future<void> _loadFields() async {
    final fields = await FieldService().getFields();
    setState(() {
      _fields = fields;
      if (_selectedFieldId == null && fields.isNotEmpty) {
        _selectedFieldId = fields.first.id;
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _imagePaths.add(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? localizations.add : 'Edit Activity'), // Add to translations
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Activity Details'),
              const SizedBox(height: 16),
              ActivityTypeDropdown(
                value: _activityType,
                onChanged: (value) => setState(() => _activityType = value!),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Date: ${DateFormat.yMMMd(localizations.locale.toString()).format(_selectedDate)}',
                  style: const TextStyle(fontSize: 16),
                ),
                trailing: const Icon(Icons.calendar_today, color: Colors.green),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    locale: localizations.locale,
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
              ),
              const SizedBox(height: 16),
              if (_fields.isNotEmpty)
                DropdownButtonFormField<int>(
                  value: _selectedFieldId,
                  decoration: const InputDecoration(
                    labelText: 'Field',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.landscape),
                  ),
                  items: _fields.map((field) {
                    return DropdownMenuItem<int>(
                      value: field.id,
                      child: Text(field.name),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedFieldId = val),
                  validator: (val) => val == null ? 'Please select a field' : null,
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: localizations.description,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _costController,
                decoration: InputDecoration(
                  labelText: '${localizations.expenses} (₹)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.currency_rupee),
                ),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val != null && val.isNotEmpty && double.tryParse(val) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Photos'),
              const SizedBox(height: 8),
              _buildPhotoGrid(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _saveEntry,
                  child: Text(
                    widget.entry == null ? localizations.add : 'Update',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.green[800],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _imagePaths.length + 1,
      itemBuilder: (context, index) {
        if (index == _imagePaths.length) {
          return InkWell(
            onTap: () => _showImagePickerOptions(),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[400]!),
              ),
              child: const Icon(Icons.add_a_photo, size: 32, color: Colors.grey),
            ),
          );
        }
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(_imagePaths[index]),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: InkWell(
                onTap: () => setState(() => _imagePaths.removeAt(index)),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.red),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _saveEntry() {
    if (_formKey.currentState!.validate()) {
      final entry = LogbookEntry(
        id: widget.entry?.id, // Keep existing ID if editing
        backendId: widget.entry?.backendId,
        activityType: _activityType,
        date: _selectedDate.toIso8601String(),
        description: _descriptionController.text,
        cost: double.tryParse(_costController.text) ?? 0.0,
        fieldId: _selectedFieldId,
        images: _imagePaths,
        // TODO: Add GPS and weather
      );
      Navigator.pop(context, entry);
    }
  }
}
