import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/diagnostic.dart';
import 'package:kheti_sahayak_app/services/diagnostic_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  final TextEditingController _cropTypeController = TextEditingController();
  final TextEditingController _issueDescriptionController = TextEditingController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  Future<List<Diagnostic>>? _diagnosticsFuture;

  @override
  void initState() {
    super.initState();
    _loadDiagnostics();
  }

  void _loadDiagnostics() {
    _diagnosticsFuture = _fetchDiagnostics();
  }

  Future<List<Diagnostic>> _fetchDiagnostics() async {
    final result = await DiagnosticService.getUserDiagnostics();
    return result['diagnostics'] ?? [];
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _submitDiagnostic() async {
    if (_cropTypeController.text.isEmpty || _issueDescriptionController.text.isEmpty || _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and take a photo.')),
      );
      return;
    }

    try {
      await DiagnosticService.uploadForDiagnosis(
        imageFile: _selectedImage!,
        cropType: _cropTypeController.text,
        issueDescription: _issueDescriptionController.text,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diagnostic request submitted!')),
      );
      
      _cropTypeController.clear();
      _issueDescriptionController.clear();
      setState(() {
        _selectedImage = null;
        _loadDiagnostics(); // Refresh list
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit diagnostic: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Submit New Diagnostic Request',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
          ),
          const SizedBox(height: 16.0),
          TextField(
            controller: _cropTypeController,
            decoration: InputDecoration(
              labelText: 'Crop Type',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              prefixIcon: const Icon(Icons.grass),
            ),
          ),
          const SizedBox(height: 16.0),
          TextField(
            controller: _issueDescriptionController,
            decoration: InputDecoration(
              labelText: 'Issue Description',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              prefixIcon: const Icon(Icons.description),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16.0),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: Colors.grey),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 50, color: Colors.grey[600]),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to take photo',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24.0),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitDiagnostic,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.send),
              label: const Text(
                'Submit Diagnostic',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(height: 40.0),
          Text(
            'Your Past Diagnostics',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
          ),
          const SizedBox(height: 16.0),
          FutureBuilder<List<Diagnostic>>(
            future: _diagnosticsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No past diagnostics found.'));
              } else {
                final diagnostics = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: diagnostics.length,
                  itemBuilder: (context, index) {
                    final diagnostic = diagnostics[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Crop: ${diagnostic.cropType}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[800],
                                  ),
                            ),
                            const SizedBox(height: 4.0),
                            Text('Issue: ${diagnostic.issueDescription}'),
                            const SizedBox(height: 4.0),
                            Text(
                              'Result: ${diagnostic.diagnosisResult ?? 'Pending'}',
                              style: TextStyle(
                                color: diagnostic.diagnosisResult != null
                                    ? Colors.blue
                                    : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              'Date: ${diagnostic.createdAt.toLocal().toString().split(' ')[0]}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
            },
          ),
        ],
      ),
    );
  }
}