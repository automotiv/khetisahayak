import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kheti_sahayak_app/theme/app_theme.dart';
import 'package:kheti_sahayak_app/widgets/primary_button.dart';
import 'package:kheti_sahayak_app/widgets/loading_indicator.dart';
import 'package:kheti_sahayak_app/widgets/error_dialog.dart';
import 'package:kheti_sahayak_app/widgets/success_dialog.dart';
import 'package:kheti_sahayak_app/services/diagnostic_service.dart';
import 'package:kheti_sahayak_app/models/diagnostic.dart';
import 'package:kheti_sahayak_app/models/crop_recommendation.dart';

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
  bool _isLoadingHistory = false;
  
  // Form controllers
  final TextEditingController _cropTypeController = TextEditingController();
  final TextEditingController _issueDescriptionController = TextEditingController();
  
  // Data
  Diagnostic? _currentDiagnostic;
  List<Diagnostic> _diagnosticHistory = [];
  List<CropRecommendation> _cropRecommendations = [];
  Map<String, dynamic>? _aiAnalysis;
  
  // Filter options
  String? _selectedStatus;
  String? _selectedCropType;
  final List<String> _statusOptions = ['All', 'pending', 'analyzed', 'resolved'];
  final List<String> _cropTypeOptions = [
    'All', 'Tomato', 'Potato', 'Corn', 'Wheat', 'Rice', 'Cotton', 'Sugarcane'
  ];

  @override
  void initState() {
    super.initState();
    _loadDiagnosticHistory();
    _loadCropRecommendations();
  }

  @override
  void dispose() {
    _cropTypeController.dispose();
    _issueDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadDiagnosticHistory() async {
    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final result = await DiagnosticService.getUserDiagnostics(
        status: _selectedStatus == 'All' ? null : _selectedStatus,
        cropType: _selectedCropType == 'All' ? null : _selectedCropType,
      );
      
      setState(() {
        _diagnosticHistory = result['diagnostics'];
        _isLoadingHistory = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingHistory = false;
      });
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => ErrorDialog(
            title: 'Error',
            content: 'Failed to load diagnostic history: $e',
          ),
        );
      }
    }
  }

  Future<void> _loadCropRecommendations() async {
    try {
      final recommendations = await DiagnosticService.getCropRecommendations();
      setState(() {
        _cropRecommendations = recommendations;
      });
    } catch (e) {
      // Silently handle error for recommendations
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _showResult = false;
          _currentDiagnostic = null;
          _aiAnalysis = null;
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
    if (_selectedImage == null || 
        _cropTypeController.text.isEmpty || 
        _issueDescriptionController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => ErrorDialog(
          title: 'Missing Information',
          content: 'Please provide crop type and issue description.',
        ),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _showResult = false;
    });

    try {
      final result = await DiagnosticService.uploadForDiagnosis(
        imageFile: _selectedImage!,
        cropType: _cropTypeController.text,
        issueDescription: _issueDescriptionController.text,
      );
      
      setState(() {
        _currentDiagnostic = result['diagnostic'];
        _aiAnalysis = result['aiAnalysis'];
        _isAnalyzing = false;
        _showResult = true;
      });
      
      // Reload history to include new diagnostic
      _loadDiagnosticHistory();
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => ErrorDialog(
            title: 'Analysis Failed',
            content: 'Failed to analyze image: $e',
          ),
        );
      }
    }
  }

  Future<void> _requestExpertReview() async {
    if (_currentDiagnostic == null) return;

    try {
      final result = await DiagnosticService.requestExpertReview(_currentDiagnostic!.id);
      
      setState(() {
        _currentDiagnostic = result['diagnostic'];
      });
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => SuccessDialog(
            title: 'Expert Review Requested',
            content: 'Your diagnostic has been assigned to an expert for review.',
            buttonText: 'OK',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => ErrorDialog(
            title: 'Request Failed',
            content: 'Failed to request expert review: $e',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Diagnostics'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // Show diagnostic history in a bottom sheet
              _showDiagnosticHistory();
            },
          ),
        ],
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
                isLoading: _isAnalyzing,
              ),
            
            // Analysis results
            if (_showResult && _currentDiagnostic != null) 
              ..._buildAnalysisResults(theme, colorScheme),
            
            // Crop recommendations section
            if (_cropRecommendations.isNotEmpty)
              _buildCropRecommendationsSection(theme, colorScheme),
            
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
            
            // Form fields
            if (_selectedImage != null) ...[
              TextField(
                controller: _cropTypeController,
                decoration: InputDecoration(
                  labelText: 'Crop Type',
                  hintText: 'e.g., Tomato, Potato, Corn',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _issueDescriptionController,
                decoration: InputDecoration(
                  labelText: 'Issue Description',
                  hintText: 'Describe the symptoms you observe',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
            ],
            
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
    final diagnostic = _currentDiagnostic!;
    final aiAnalysis = _aiAnalysis;
    
    return [
      // Status and confidence
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
                      color: _getStatusColor(diagnostic.status).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getStatusIcon(diagnostic.status),
                      color: _getStatusColor(diagnostic.status),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status: ${diagnostic.status.toUpperCase()}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (diagnostic.confidenceScore != null)
                          Text(
                            'Confidence: ${(diagnostic.confidenceScore! * 100).toStringAsFixed(1)}%',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (diagnostic.diagnosisResult != null) ...[
                Text(
                  'AI Diagnosis:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  diagnostic.diagnosisResult!,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ),
      
      const SizedBox(height: 16),
      
      // AI Analysis details
      if (aiAnalysis != null) ...[
        _buildInfoCard(
          theme,
          colorScheme,
          title: 'AI Analysis',
          icon: Icons.psychology_outlined,
          items: [
            'Disease: ${aiAnalysis['disease_name'] ?? 'Unknown'}',
            'Confidence: ${(aiAnalysis['confidence'] ?? 0) * 100}%',
            'Severity: ${aiAnalysis['severity'] ?? 'Unknown'}',
          ],
        ),
        const SizedBox(height: 16),
      ],
      
      // Recommendations
      if (diagnostic.recommendations != null) ...[
        _buildInfoCard(
          theme,
          colorScheme,
          title: 'Recommendations',
          icon: Icons.medical_services_outlined,
          items: diagnostic.recommendations!.split('\n').where((line) => line.trim().isNotEmpty).toList(),
        ),
        const SizedBox(height: 16),
      ],
      
      // Expert review section
      if (diagnostic.hasExpertReview) ...[
        _buildExpertReviewSection(theme, colorScheme, diagnostic),
        const SizedBox(height: 16),
      ],
      
      // Action buttons
      Row(
        children: [
          if (!diagnostic.hasExpertReview && diagnostic.status == 'analyzed')
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _requestExpertReview,
                icon: const Icon(Icons.person_search),
                label: const Text('Request Expert Review'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.secondary,
                  foregroundColor: colorScheme.onSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          if (diagnostic.hasExpertReview)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // Contact expert
                },
                icon: const Icon(Icons.phone),
                label: const Text('Contact Expert'),
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
    ];
  }

  Widget _buildExpertReviewSection(ThemeData theme, ColorScheme colorScheme, Diagnostic diagnostic) {
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
                  Icons.person_outline,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Expert Review',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Expert: ${diagnostic.expertFullName}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            if (diagnostic.expertPhone != null) ...[
              const SizedBox(height: 4),
              Text(
                'Phone: ${diagnostic.expertPhone}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCropRecommendationsSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Crop Recommendations',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _cropRecommendations.length,
            itemBuilder: (context, index) {
              final recommendation = _cropRecommendations[index];
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 12),
                child: Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recommendation.cropName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (recommendation.season != null) ...[
                          Text(
                            recommendation.seasonDisplay,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (recommendation.waterRequirement != null) ...[
                          Text(
                            recommendation.waterRequirementDisplay,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (recommendation.description != null) ...[
                          Text(
                            recommendation.description!,
                            style: theme.textTheme.bodySmall,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showDiagnosticHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Text(
                    'Diagnostic History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoadingHistory
                  ? const Center(child: CircularProgressIndicator())
                  : _diagnosticHistory.isEmpty
                      ? const Center(
                          child: Text('No diagnostic history found'),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _diagnosticHistory.length,
                          itemBuilder: (context, index) {
                            final diagnostic = _diagnosticHistory[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Icon(
                                  _getStatusIcon(diagnostic.status),
                                  color: _getStatusColor(diagnostic.status),
                                ),
                                title: Text(diagnostic.cropType),
                                subtitle: Text(
                                  'Status: ${diagnostic.status} • ${diagnostic.createdAt.toString().substring(0, 10)}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.arrow_forward_ios),
                                  onPressed: () {
                                    // Navigate to diagnostic detail
                                  },
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'analyzed':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'analyzed':
        return Icons.psychology;
      case 'resolved':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }
}
