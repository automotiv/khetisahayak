import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/activity_service.dart';
import '../../services/location_service.dart';
import '../../widgets/activity_type_dropdown.dart';
import '../../widgets/task/task_image_selector.dart';
import '../../models/task/task_image.dart';

class ActivityFormScreen extends StatefulWidget {
  final int? fieldId;
  
  const ActivityFormScreen({Key? key, this.fieldId}) : super(key: key);

  @override
  State<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends State<ActivityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();
  final ActivityService _activityService = ActivityService();
  final LocationService _locationService = LocationService.instance;
  
  String _selectedActivityType = 'Planting';
  final List<TaskImage> _photos = [];
  Position? _currentPosition;
  bool _isCapturingLocation = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _captureLocation() async {
    setState(() => _isCapturingLocation = true);

    try {
      final position = await _locationService.getLocationWithTimeout(
        timeout: const Duration(seconds: 10),
      );

      if (position != null) {
        setState(() {
          _currentPosition = position;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Location captured: ${_locationService.formatCoordinates(position.latitude, position.longitude)}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to get location. Please check permissions and GPS.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isCapturingLocation = false);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Extract photo paths
      final photoPaths = _photos.map((photo) => photo.localPath).toList();

      // Create activity record
      final id = await _activityService.createActivityRecord(
        activityType: _selectedActivityType,
        fieldId: widget.fieldId,
        cost: double.tryParse(_costController.text) ?? 0.0,
        metadata: {
          'notes': _notesController.text,
          'photo_count': photoPaths.length,
          'has_location': _currentPosition != null,
        },
        photoPaths: photoPaths,
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
        locationAccuracy: _currentPosition?.accuracy,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Activity record created successfully! (ID: $id)'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating activity: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Activity Record'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Activity Type Dropdown
              ActivityTypeDropdown(
                value: _selectedActivityType,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedActivityType = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Cost Input
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(
                  labelText: 'Cost (₹)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Photo Selector
              TaskImageSelector(
                initialImages: _photos,
                maxImages: 5,
                onImagesChanged: (images) {
                  setState(() {
                    _photos.clear();
                    _photos.addAll(images);
                  });
                },
                title: 'Activity Photos',
                description: 'Add up to 5 photos of this activity',
              ),
              const SizedBox(height: 24),

              // GPS Location Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            'Location',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      if (_currentPosition == null)
                        ElevatedButton.icon(
                          onPressed: _isCapturingLocation ? null : _captureLocation,
                          icon: _isCapturingLocation
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.my_location),
                          label: Text(_isCapturingLocation ? 'Capturing...' : 'Capture GPS Location'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLocationInfo(
                              'Coordinates',
                              _locationService.formatCoordinates(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              ),
                              Icons.place,
                            ),
                            const SizedBox(height: 8),
                            _buildLocationInfo(
                              'Accuracy',
                              _locationService.getAccuracyDescription(_currentPosition!.accuracy),
                              Icons.gps_fixed,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _isCapturingLocation ? null : _captureLocation,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Recapture Location'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 40),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Notes Input
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  hintText: 'Add any additional details about this activity...',
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Save Activity Record',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationInfo(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
