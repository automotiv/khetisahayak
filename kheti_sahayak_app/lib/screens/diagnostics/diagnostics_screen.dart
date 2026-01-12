
import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kheti_sahayak_app/widgets/primary_button.dart';
import 'package:kheti_sahayak_app/widgets/error_dialog.dart';
import 'package:kheti_sahayak_app/widgets/success_dialog.dart';
import 'package:kheti_sahayak_app/services/diagnostic_service.dart';
import 'package:kheti_sahayak_app/models/diagnostic.dart';
import 'package:kheti_sahayak_app/models/crop_recommendation.dart';
import 'package:kheti_sahayak_app/screens/diagnostics/localized_treatment_details_screen.dart';
import 'package:kheti_sahayak_app/widgets/localized_diagnostic_result_card.dart';

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

  final TextEditingController _cropTypeController = TextEditingController();
  final TextEditingController _issueDescriptionController = TextEditingController();

  Diagnostic? _currentDiagnostic;
  List<Diagnostic> _diagnosticHistory = [];
  List<CropRecommendation> _cropRecommendations = [];
  Map<String, dynamic>? _aiAnalysis;

  String? _selectedStatus;
  String? _selectedCropType;
  final List<String> _statusOptions = ['All', 'pending', 'analyzed', 'resolved'];

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
    setState(() => _isLoadingHistory = true);
    try {
      final result = await DiagnosticService.getUserDiagnostics(
        status: _selectedStatus == 'All' ? null : _selectedStatus,
        cropType: _selectedCropType == 'All' ? null : _selectedCropType,
      );
      if (mounted) setState(() => _diagnosticHistory = result['diagnostics']);
    } catch (e) {
      if (mounted) ErrorDialog.show(context, title: 'Error', content: 'Failed to load diagnostic history: ${e.toString().replaceAll('Exception: ', '')}', onRetry: _loadDiagnosticHistory);
    } finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _loadCropRecommendations() async {
    try {
      final recommendations = await DiagnosticService.getCropRecommendations();
      if (mounted) setState(() => _cropRecommendations = recommendations);
    } catch (e) {
      if (mounted && _cropRecommendations.isEmpty) {
        ErrorDialog.show(context, title: 'Warning', content: 'Could not load crop recommendations.', onRetry: _loadCropRecommendations);
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, imageQuality: 85, maxWidth: 2048, maxHeight: 2048);
      if (image == null) return;
      final file = File(image.path);
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) { // 10MB
        ErrorDialog.show(context, title: 'Image Too Large', content: 'Please select an image smaller than 10MB.');
        return;
      }
      setState(() {
        _selectedImage = file;
        _showResult = false;
        _currentDiagnostic = null;
        _aiAnalysis = null;
      });
    } catch (e) {
      if (mounted) ErrorDialog.show(context, title: 'Error', content: 'Failed to process image: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  Future<void> _analyzeImage({bool isRetry = false}) async {
    if (_selectedImage == null) {
      if (!isRetry) ErrorDialog.show(context, title: 'No Image Selected', content: 'Please select an image to analyze.');
      return;
    }
    if (_cropTypeController.text.isEmpty || _issueDescriptionController.text.isEmpty) {
      if (!isRetry) ErrorDialog.show(context, title: 'Missing Information', content: 'Please provide both crop type and issue description.');
      return;
    }
    setState(() => _isAnalyzing = true);
    try {
      final result = await DiagnosticService.uploadForDiagnosis(
        imageFile: _selectedImage!,
        cropType: _cropTypeController.text,
        issueDescription: _issueDescriptionController.text,
      ).timeout(const Duration(seconds: 30));
      setState(() {
        _currentDiagnostic = result['diagnostic'];
        _aiAnalysis = result['aiAnalysis'];
        _showResult = true;
      });
      _loadDiagnosticHistory();
    } catch (e) {
      if (mounted) ErrorDialog.show(context, title: 'Analysis Failed', content: 'Failed to analyze image: ${e.toString().replaceAll('Exception: ', '')}', onRetry: () => _analyzeImage(isRetry: true));
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _viewDiagnosticResult(Diagnostic diagnostic) {
    setState(() {
      _currentDiagnostic = diagnostic;
      _selectedImage = null;
      _cropTypeController.text = diagnostic.cropType;
      _issueDescriptionController.text = diagnostic.issueDescription;
      _aiAnalysis = {
        'disease': diagnostic.diagnosisResult ?? 'Unknown',
        'confidence': diagnostic.confidenceScore ?? 0.0,
        'treatment': diagnostic.recommendations ?? 'No specific treatment available.',
      };
      _showResult = true;
    });
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pest & Disease Info'),
        backgroundColor: const Color(0xFF4CAF50),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showDiagnosticHistory,
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImageCaptureSection(),
            const SizedBox(height: 20),
            if (_selectedImage != null && !_showResult)
              PrimaryButton(
                onPressed: _isAnalyzing ? null : _analyzeImage,
                text: _isAnalyzing ? 'Analyzing...' : 'Analyze Plant',
                isLoading: _isAnalyzing,
              ),
            if (_showResult && _currentDiagnostic != null)
              LocalizedDiagnosticResultCard(
                diagnostic: _currentDiagnostic!,
                aiAnalysis: _aiAnalysis,
                onViewTreatment: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LocalizedTreatmentDetailsScreen(
                        diagnosticId: _currentDiagnostic!.id.toString(),
                      ),
                    ),
                  );
                },
              ),

            if (_recentAnalyses.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildRecentAnalysesSection(context, _recentAnalyses),
            ],

            if (_cropRecommendations.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildCropRecommendationsSection(context, _cropRecommendations),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageCaptureSection() {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _selectedImage != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(8.0), child: Image.file(_selectedImage!, fit: BoxFit.cover))
                  : const Center(child: Text('No image selected.')),
            ),
            const SizedBox(height: 16),
            if (_selectedImage != null) ...[
              TextField(
                controller: _cropTypeController,
                decoration: const InputDecoration(labelText: 'Crop Type', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _issueDescriptionController,
                decoration: const InputDecoration(labelText: 'Issue Description', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.camera_alt, color: Color(0xFF4CAF50)),
                  label: const Text('Take Photo', style: TextStyle(color: Color(0xFF4CAF50))),
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.photo_library, color: Color(0xFF4CAF50)),
                  label: const Text('From Gallery', style: TextStyle(color: Color(0xFF4CAF50))),
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // NOTE: _buildAnalysisResults removed - now using LocalizedDiagnosticResultCard widget

  Widget _buildRecentAnalysesSection(BuildContext context, List<Diagnostic> recentAnalyses) {
     return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Analyses', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recentAnalyses.length,
            itemBuilder: (context, index) {
              final diagnostic = recentAnalyses[index];
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 12),
                child: LocalizedDiagnosticListItem(
                  diagnostic: diagnostic,
                  onTap: () => _viewDiagnosticResult(diagnostic),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

   Widget _buildCropRecommendationsSection(BuildContext context, List<CropRecommendation> recommendations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Crop Recommendations', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recommendations.length,
            itemBuilder: (context, index) {
              final recommendation = recommendations[index];
              return Container(
                width: 180,
                margin: const EdgeInsets.only(right: 12.0),
                child: Card(
                  elevation: 2.0,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(recommendation.cropName, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(recommendation.seasonDisplay, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF4CAF50))),
                        const SizedBox(height: 8),
                        Expanded(child: Text(recommendation.description ?? '', style: Theme.of(context).textTheme.bodySmall, maxLines: 3, overflow: TextOverflow.ellipsis)),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7, minChildSize: 0.5, maxChildSize: 0.9, expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Text('Diagnostic History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              Expanded(
                child: _isLoadingHistory
                    ? const Center(child: CircularProgressIndicator())
                    : _diagnosticHistory.isEmpty
                        ? const Center(child: Text('No diagnostic history found'))
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            itemCount: _diagnosticHistory.length,
                            itemBuilder: (context, index) {
                              final diagnostic = _diagnosticHistory[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                                child: ListTile(
                                  leading: Icon(_getStatusIcon(diagnostic.status), color: _getStatusColor(diagnostic.status)),
                                  title: Text(diagnostic.cropType),
                                  subtitle: Text('Status: ${diagnostic.status} • ${diagnostic.createdAt.toString().substring(0, 10)}'),
                                  trailing: const Icon(Icons.arrow_forward_ios),
                                  onTap: () {
                                      Navigator.pop(context); // Close the sheet
                                      _viewDiagnosticResult(diagnostic);
                                  },
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'analyzed': return Colors.blue;
      case 'resolved': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Icons.schedule;
      case 'analyzed': return Icons.psychology;
      case 'resolved': return Icons.check_circle;
      default: return Icons.help;
    }
  }

  List<Diagnostic> get _recentAnalyses {
    final currentId = _currentDiagnostic?.id;
    return _diagnosticHistory.where((d) => currentId == null || d.id != currentId).take(5).toList();
  }
}
