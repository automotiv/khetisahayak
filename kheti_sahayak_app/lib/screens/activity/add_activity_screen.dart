import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kheti_sahayak_app/models/field.dart';
import 'package:kheti_sahayak_app/services/activity_service.dart';
import 'package:kheti_sahayak_app/services/field_service.dart';
import 'package:kheti_sahayak_app/services/weather_service.dart';
import 'package:kheti_sahayak_app/widgets/activity_type_dropdown.dart';
import 'package:intl/intl.dart';

class AddActivityScreen extends StatefulWidget {
  final int? preselectedFieldId;

  const AddActivityScreen({Key? key, this.preselectedFieldId}) : super(key: key);

  @override
  _AddActivityScreenState createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final ActivityService _activityService = ActivityService();
  final FieldService _fieldService = FieldService();
  final WeatherService _weatherService = WeatherService();

  // Form Fields
  String? _activityType;
  int? _selectedFieldId;
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  
  // Data
  List<Field> _fields = [];
  List<String> _photoPaths = [];
  bool _isLoading = false;
  
  // Location & Weather
  Position? _currentPosition;
  Map<String, dynamic>? _weatherSnapshot;
  bool _isFetchingLocation = false;

  @override
  void initState() {
    super.initState();
    _selectedFieldId = widget.preselectedFieldId;
    _loadFields();
    _fetchLocationAndWeather();
  }

  Future<void> _loadFields() async {
    final fields = await _fieldService.getFields();
    if (mounted) {
      setState(() {
        _fields = fields;
        // If no field preselected and fields exist, select first
        if (_selectedFieldId == null && fields.isNotEmpty) {
          _selectedFieldId = fields.first.id;
        }
      });
    }
  }

  Future<void> _fetchLocationAndWeather() async {
    setState(() => _isFetchingLocation = true);
    try {
      // 1. Get Location
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition();
        if (mounted) {
          setState(() => _currentPosition = position);
          
          // 2. Get Weather for this location
          try {
            final weather = await _weatherService.getWeather(
              position.latitude,
              position.longitude,
            );
            if (mounted) {
              setState(() => _weatherSnapshot = weather);
            }
          } catch (e) {
            print('Error fetching weather: $e');
          }
        }
      }
    } catch (e) {
      print('Error getting location: $e');
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source, imageQuality: 80);
    
    if (image != null) {
      setState(() {
        _photoPaths.add(image.path);
      });
    }
  }

  Future<void> _saveActivity() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFieldId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a field')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _activityService.createActivityRecord(
        activityType: _activityType!,
        fieldId: _selectedFieldId,
        customTimestamp: _selectedDate,
        metadata: {'notes': _notesController.text},
        cost: double.tryParse(_costController.text) ?? 0.0,
        photoPaths: _photoPaths,
        weatherSnapshot: _weatherSnapshot,
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
        locationAccuracy: _currentPosition?.accuracy,
      );

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving activity: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Activity'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _saveActivity,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Field Selection
                  DropdownButtonFormField<int>(
                    value: _selectedFieldId,
                    decoration: const InputDecoration(
                      labelText: 'Field',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.landscape),
                    ),
                    items: _fields.map((field) {
                      return DropdownMenuItem(
                        value: field.id,
                        child: Text(field.name),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedFieldId = val),
                    validator: (val) => val == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Activity Type
                  ActivityTypeDropdown(
                    value: _activityType,
                    onChanged: (val) => setState(() => _activityType = val),
                    validator: (val) => val == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Date Picker
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _selectedDate = date);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Cost
                  TextFormField(
                    controller: _costController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cost (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes / Description',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Location & Weather Info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 20, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _currentPosition != null
                                      ? 'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, Lng: ${_currentPosition!.longitude.toStringAsFixed(4)}'
                                      : _isFetchingLocation ? 'Fetching location...' : 'Location not available',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              if (!_isFetchingLocation)
                                IconButton(
                                  icon: const Icon(Icons.refresh, size: 20),
                                  onPressed: _fetchLocationAndWeather,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                            ],
                          ),
                          if (_weatherSnapshot != null) ...[
                            const Divider(),
                            Row(
                              children: [
                                const Icon(Icons.cloud, size: 20, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text(
                                  '${_weatherSnapshot!['current']['temp_c']}°C, ${_weatherSnapshot!['current']['condition']['text']}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Photos
                  const Text('Photos', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // Add Photo Button
                        InkWell(
                          onTap: () => _showImageSourceDialog(),
                          child: Container(
                            width: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[400]!),
                            ),
                            child: const Icon(Icons.add_a_photo, size: 32, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Photo List
                        ..._photoPaths.map((path) => Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(path),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: InkWell(
                                  onTap: () => setState(() => _photoPaths.remove(path)),
                                  child: Container(
                                    color: Colors.black54,
                                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
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
}
