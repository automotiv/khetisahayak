import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart'; // For PlatformException
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kheti_sahayak_app/widgets/primary_button.dart';
import 'package:kheti_sahayak_app/widgets/error_dialog.dart';
import 'package:kheti_sahayak_app/widgets/success_dialog.dart';
import 'package:kheti_sahayak_app/services/diagnostic_service.dart';
import 'package:kheti_sahayak_app/models/diagnostic.dart';
import 'package:kheti_sahayak_app/models/crop_recommendation.dart';
import 'package:kheti_sahayak_app/screens/diagnostics/treatment_details_screen.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();
  File? _selectedImage;
  bool _isAnalyzing = false;
  bool _showResult = false;
  bool _isLoadingHistory = false;

  // Form controllers
  final TextEditingController _cropTypeController = TextEditingController();
  final TextEditingController _issueDescriptionController =
      TextEditingController();

  // Data
  Diagnostic? _currentDiagnostic;
  List<Diagnostic> _diagnosticHistory = [];
  List<CropRecommendation> _cropRecommendations = [];
  Map<String, dynamic>? _aiAnalysis;

  // Filter options
  String? _selectedStatus;
  String? _selectedCropType;
  final List<String> _statusOptions = [
    'All',
    'pending',
    'analyzed',
    'resolved'
  ];
  // Crop type options are now dynamically loaded from the API

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
    _scrollController.dispose();
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
        ErrorDialog.show(
          context,
          title: 'Error',
          content: 'Failed to load diagnostic history: ${e.toString().replaceAll('Exception: ', '')}',
          onRetry: _loadDiagnosticHistory,
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
      if (mounted && _cropRecommendations.isEmpty) {
        // Only show error if we don't have any recommendations yet
        ErrorDialog.show(
          context,
          title: 'Warning',
          content: 'Could not load crop recommendations. Some features may be limited.',
          onRetry: _loadCropRecommendations,
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85, // Reduce quality to reduce file size
        maxWidth: 2048, // Limit image dimensions
        maxHeight: 2048,
      );
      
      if (image == null) return; // User cancelled the picker

      final file = File(image.path);
      
      // Check file size (10MB = 10 * 1024 * 1024 bytes)
      final fileSize = await file.length();
      const maxSize = 10 * 1024 * 1024; // 10MB in bytes
      
      if (fileSize > maxSize) {
        ErrorDialog.show(
          context,
          title: 'Image Too Large',
          content: 'The selected image is ${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB. Please select an image smaller than 10MB.',
        );
        return;
      }

      // Check file type
      final fileExtension = image.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'heic'].contains(fileExtension)) {
        ErrorDialog.show(
          context,
          title: 'Unsupported Format',
          content: 'Please select an image in JPG, PNG, or HEIC format.',
        );
        return;
      }

      // Check image dimensions
      try {
        final decodedImage = await decodeImageFromList(await file.readAsBytes());
        if (decodedImage.width < 800 || decodedImage.height < 600) {
          ErrorDialog.show(
            context,
            title: 'Image Too Small',
            content: 'Selected image is ${decodedImage.width}x${decodedImage.height}px. Please select an image with minimum dimensions of 800x600 pixels for better analysis.',
          );
          return;
        }
        
        setState(() {
          _selectedImage = file;
          _showResult = false;
          _currentDiagnostic = null;
          _aiAnalysis = null;
        });
      } catch (e) {
        ErrorDialog.show(
          context,
          title: 'Invalid Image',
          content: 'Could not process the selected image. It may be corrupted or in an unsupported format.',
        );
      }
    } on PlatformException catch (e) {
      if (e.code == 'camera_permission' || e.code == 'photo_access_denied') {
        ErrorDialog.show(
          context,
          title: 'Permission Required',
          content: 'Please grant camera and photo library access to upload images for diagnosis.',
        );
      } else {
        ErrorDialog.show(
          context,
          title: 'Error',
          content: 'Failed to access image: ${e.message ?? 'Unknown error'}.',
        );
      }
    } catch (e) {
// Only show error dialog if the widget is still in the tree
      if (mounted) {
        ErrorDialog.show(
          context,
          title: 'Error',
          content: 'Failed to process image: ${e.toString().replaceAll('Exception: ', '')}',
        );
      }
    }
  }

  Future<void> _analyzeImage({bool isRetry = false}) async {
    if (_selectedImage == null) {
      if (!isRetry) {
        ErrorDialog.show(
          context,
          title: 'No Image Selected',
          content: 'Please select an image to analyze.',
        );
      }
      return;
    }

    if (_cropTypeController.text.isEmpty || _issueDescriptionController.text.isEmpty) {
      if (!isRetry) {
        ErrorDialog.show(
          context,
          title: 'Missing Information',
          content: 'Please provide both crop type and issue description.',
        );
      }
      return;
    }

    // Check file size and type
    try {
      final fileSize = await _selectedImage!.length();
      const maxSize = 10 * 1024 * 1024; // 10MB
      
      if (fileSize > maxSize) {
        throw 'Image size exceeds 10MB limit. Please choose a smaller image.';
      }

      final fileExtension = _selectedImage!.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'heic'].contains(fileExtension)) {
        throw 'Unsupported file format. Please use JPG, PNG, or HEIC.';
      }
    } catch (e) {
      if (mounted) {
        ErrorDialog.show(
          context,
          title: 'Invalid Image',
          content: e.toString(),
        );
      }
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
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw 'Request timed out. Please check your internet connection and try again.';
        },
      );
      
      setState(() {
        _currentDiagnostic = result['diagnostic'];
        _aiAnalysis = result['aiAnalysis'];
        _isAnalyzing = false;
        _showResult = true;
      });
      
      // Reload history to include new diagnostic
      _loadDiagnosticHistory();
    } on SocketException {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ErrorDialog.show(
          context,
          title: 'Network Error',
          content: 'Unable to connect to the server. Please check your internet connection.',
          onRetry: () => _analyzeImage(isRetry: true),
        );
      }
    } on FormatException {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ErrorDialog.show(
          context,
          title: 'Invalid Response',
          content: 'Received invalid data from the server. Please try again.',
          onRetry: () => _analyzeImage(isRetry: true),
        );
      }
    } on TimeoutException {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ErrorDialog.show(
          context,
          title: 'Request Timeout',
          content: 'The request took too long to complete. Please try again.',
          onRetry: () => _analyzeImage(isRetry: true),
        );
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ErrorDialog.show(
          context,
          title: 'Analysis Failed',
          content: 'Failed to analyze image: ${e.toString().replaceAll('Exception: ', '')}',
          onRetry: () => _analyzeImage(isRetry: true),
        );
      }
    }
  }

  Future<void> _requestExpertReview() async {
    if (_currentDiagnostic == null) return;

    try {
      final result =
          await DiagnosticService.requestExpertReview(_currentDiagnostic!.id);

      setState(() {
        _currentDiagnostic = result['diagnostic'];
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => SuccessDialog(
            title: 'Expert Review Requested',
            content:
                'Your diagnostic has been assigned to an expert for review.',
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

  // Load recent analyses from the diagnostic history
  List<Diagnostic> get _recentAnalyses {
    // Get the 3 most recent analyses, excluding the current one if it exists
    final currentId = _currentDiagnostic?.id;
    final recent = _diagnosticHistory
        .where((d) => currentId == null || d.id != currentId)
        .take(3)
        .toList();
    return recent;
  }

  // Navigate to a specific diagnostic result
  void _viewDiagnosticResult(Diagnostic diagnostic) {
    setState(() {
      _currentDiagnostic = diagnostic;
      _selectedImage = null;
      _cropTypeController.text = diagnostic.cropType;
      _issueDescriptionController.text = diagnostic.issueDescription;
      // Create a map with the analysis results from the diagnostic
      _aiAnalysis = {
        'disease': diagnostic.diagnosisResult ?? 'Unknown',
        'confidence': diagnostic.confidenceScore ?? 0.0,
        'treatment':
            diagnostic.recommendations ?? 'No specific treatment available.',
        'prevention':
            'Follow recommended agricultural practices and monitor plant health regularly.',
      };
    });
    // Scroll to the top of the results
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Recent Analyses Section
            if (_recentAnalyses.isNotEmpty) ...[
              _buildRecentAnalysesSection(theme, colorScheme),
              const SizedBox(height: 24),
            ],
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.health_and_safety_outlined,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plant Health Check',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Get instant diagnosis for plant diseases',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Step-by-step guide
            Text(
              'How to take a good photo:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 8),
            _buildStepItem(
              icon: Icons.photo_camera,
              text: 'Take a clear, well-lit photo of the affected plant part',
              theme: theme,
              colorScheme: colorScheme,
            ),
            _buildStepItem(
              icon: Icons.zoom_in,
              text: 'Get close to show details but keep the plant in focus',
              theme: theme,
              colorScheme: colorScheme,
            ),
            _buildStepItem(
              icon: Icons.light_mode,
              text: 'Use natural light for best results',
              theme: theme,
              colorScheme: colorScheme,
            ),

            const SizedBox(height: 20),

            // Image preview with improved styling
            Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                color:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
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
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.primary.withValues(alpha: 0.1),
                          ),
                          child: Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 36,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No image selected',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.hintColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            'Upload a clear photo of the affected plant part for analysis',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),

            // Form fields with improved styling
            if (_selectedImage != null) ...[
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _cropTypeController,
                  style: theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Crop Type',
                    labelStyle: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.7)),
                    hintText: 'e.g., Tomato, Potato, Corn',
                    hintStyle: TextStyle(color: theme.hintColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    prefixIcon: Icon(
                      Icons.eco_outlined,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _issueDescriptionController,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Issue Description',
                    labelStyle: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.7)),
                    hintText: 'Describe the symptoms you observe...',
                    hintStyle: TextStyle(color: theme.hintColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(bottom: 32.0),
                      child: Icon(
                        Icons.description_outlined,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Action buttons with improved styling
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined, size: 20),
                    label: const Text('Take Photo'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      backgroundColor: colorScheme.primaryContainer,
                      foregroundColor: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined, size: 20),
                    label: const Text('Choose from Gallery'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.3),
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

  // Build a step item for the how-to guide
  Widget _buildStepItem({
    required IconData icon,
    required String text,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAnalysisResults(ThemeData theme, ColorScheme colorScheme) {
    final diagnostic = _currentDiagnostic!;
    final aiAnalysis = _aiAnalysis;
    final confidence = aiAnalysis != null && aiAnalysis['confidence'] != null
        ? (aiAnalysis['confidence'] * 100).toStringAsFixed(1)
        : null;

    return [
      // Analysis results card
      Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getStatusColor(diagnostic.status)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getStatusIcon(diagnostic.status),
                      color: _getStatusColor(diagnostic.status),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Analysis Complete',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Status: ${diagnostic.status[0].toUpperCase()}${diagnostic.status.substring(1)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (confidence != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_outlined,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$confidence% Confidence',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // Disease details if available
              if (aiAnalysis != null && aiAnalysis['disease'] != null)
                _buildDiseaseDetails(aiAnalysis, theme, colorScheme),

              // View Treatments Button
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TreatmentDetailsScreen(
                          diagnosticId: diagnostic.id.toString(),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.medical_services),
                  label: const Text('View Treatment Recommendations'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              // Treatment recommendations
              if (aiAnalysis != null && aiAnalysis['treatment'] != null) ...[
                _buildInfoCard(
                  theme,
                  colorScheme,
                  title: 'Recommended Treatment',
                  icon: Icons.medical_services_outlined,
                  items: aiAnalysis['treatment'] is String
                      ? [aiAnalysis['treatment']]
                      : List<String>.from(aiAnalysis['treatment']),
                ),
                const SizedBox(height: 16),
              ],

              if (diagnostic.diagnosisResult != null) ...[
                Text(
                  diagnostic.diagnosisResult!,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
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
          items: diagnostic.recommendations!
              .split('\n')
              .where((line) => line.trim().isNotEmpty)
              .toList(),
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

  Widget _buildExpertReviewSection(
      ThemeData theme, ColorScheme colorScheme, Diagnostic diagnostic) {
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

  // Build disease details card
  Widget _buildDiseaseDetails(Map<String, dynamic> aiAnalysis, ThemeData theme,
      ColorScheme colorScheme) {
    final disease = aiAnalysis['disease'];
    if (disease == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Disease Identified',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                disease is String
                    ? disease
                    : disease['name'] ?? 'Unknown Disease',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (disease is Map && disease['scientific_name'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  disease['scientific_name'],
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
              if (disease is Map && disease['description'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  disease['description'],
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // Build a styled info card for displaying related information
  Widget _buildInfoCard(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String title,
    required IconData icon,
    required List<String> items,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
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
                  color: colorScheme.onSurface,
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
                    const Text('• '),
                    Expanded(
                      child: Text(
                        item,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildRecentAnalysesSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Recent Analyses',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _recentAnalyses.length,
            itemBuilder: (context, index) {
              final diagnostic = _recentAnalyses[index];
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
                          diagnostic.cropType,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Status: ${diagnostic.status}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Date: ${diagnostic.createdAt.toString().substring(0, 10)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => _viewDiagnosticResult(diagnostic),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.secondary,
                            foregroundColor: colorScheme.onSecondary,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('View Result'),
                        ),
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

  Widget _buildCropRecommendationsSection(
      ThemeData theme, ColorScheme colorScheme) {
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
