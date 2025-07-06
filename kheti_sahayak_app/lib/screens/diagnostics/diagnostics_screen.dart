import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kheti_sahayak_app/theme/app_theme.dart';
import 'package:kheti_sahayak_app/widgets/primary_button.dart';
import 'package:kheti_sahayak_app/widgets/loading_indicator.dart';
import 'package:kheti_sahayak_app/widgets/error_dialog.dart';
import 'package:kheti_sahayak_app/widgets/success_dialog.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({Key? key}) : super(key: key);

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isAnalyzing = false;
  bool _showResult = false;
  
  // Mock data for demonstration
  final Map<String, dynamic> _mockDiagnosis = {
    'diseaseName': 'Tomato Early Blight',
    'scientificName': 'Alternaria solani',
    'confidence': 87,
    'description': 'Early blight is a common tomato disease caused by the fungus Alternaria solani. It affects leaves, stems, and fruit and can reduce yield.',
    'symptoms': [
      'Small, dark spots on lower leaves',
      'Concentric rings in spots (target pattern)',
      'Yellowing leaves',
      'Defoliation (leaf drop) from the bottom up',
    ],
    'treatment': [
      'Remove and destroy infected plant parts',
      'Apply copper-based fungicides',
      'Improve air circulation',
      'Water at the base of plants',
      'Use disease-resistant varieties',
    ],
    'prevention': [
      'Rotate crops (3-year rotation)',
      'Space plants properly',
      'Use mulch to prevent soil splash',
      'Avoid overhead watering',
      'Remove plant debris at season end',
    ],
  };

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _showResult = false;
        });
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => ErrorDialog(
            title: 'Error',
            content: 'Failed to pick image: $e',
          ),
        );
      }
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
      _showResult = false;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isAnalyzing = false;
      _showResult = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Diagnostics'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image preview and capture section
            _buildImageCaptureSection(theme, colorScheme),
            
            const SizedBox(height: 24),
            
            // Analysis button
            if (_selectedImage != null && !_showResult)
              PrimaryButton(
                onPressed: _isAnalyzing ? null : _analyzeImage,
                text: _isAnalyzing ? 'Analyzing...' : 'Analyze Plant',
                icon: _isAnalyzing ? null : Icons.search,
                isLoading: _isAnalyzing,
              ),
            
            // Analysis results
            if (_showResult && _selectedImage != null) ..._buildAnalysisResults(theme, colorScheme),
            
            // Recent scans section
            _buildRecentScansSection(theme),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCaptureSection(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Title and instructions
            Text(
              'Plant Disease Detection',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Take a clear photo of the affected plant part (leaf, stem, fruit) for analysis',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Image preview
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.dividerColor,
                  width: 1,
                ),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_camera_outlined,
                          size: 48,
                          color: theme.hintColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No image selected',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAnalysisResults(ThemeData theme, ColorScheme colorScheme) {
    return [
      // Disease name and confidence
      Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.health_and_safety_outlined,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _mockDiagnosis['diseaseName'],
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _mockDiagnosis['scientificName'],
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_mockDiagnosis['confidence']}% Confidence',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _mockDiagnosis['description'],
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
      
      const SizedBox(height: 16),
      
      // Symptoms
      _buildInfoCard(
        theme,
        colorScheme,
        title: 'Symptoms',
        icon: Icons.warning_amber_rounded,
        items: List<String>.from(_mockDiagnosis['symptoms']),
      ),
      
      const SizedBox(height: 16),
      
      // Treatment
      _buildInfoCard(
        theme,
        colorScheme,
        title: 'Treatment',
        icon: Icons.medical_services_outlined,
        items: List<String>.from(_mockDiagnosis['treatment']),
      ),
      
      const SizedBox(height: 16),
      
      // Prevention
      _buildInfoCard(
        theme,
        colorScheme,
        title: 'Prevention',
        icon: Icons.shield_outlined,
        items: List<String>.from(_mockDiagnosis['prevention']),
      ),
      
      const SizedBox(height: 24),
      
      // Action buttons
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // Save diagnosis
                showDialog(
                  context: context,
                  builder: (ctx) => SuccessDialog(
                    title: 'Diagnosis Saved',
                    content: 'The diagnosis has been saved to your history.',
                    buttonText: 'OK',
                  ),
                );
              },
              icon: const Icon(Icons.bookmark_border),
              label: const Text('Save'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                // Share diagnosis
              },
              icon: const Icon(Icons.share_outlined),
              label: const Text('Share'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildInfoCard(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String title,
    required IconData icon,
    required List<String> items,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.circle,
                    size: 6,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentScansSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Recent Scans',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        // Placeholder for recent scans list
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.dividerColor.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Icon(
                  Icons.history_outlined,
                  size: 48,
                  color: theme.hintColor.withOpacity(0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'No recent scans',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your recent plant disease scans will appear here',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
