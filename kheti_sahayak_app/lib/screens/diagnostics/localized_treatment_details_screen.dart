import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kheti_sahayak_app/models/localized_diagnostic.dart';
import 'package:kheti_sahayak_app/models/treatment.dart';
import 'package:kheti_sahayak_app/services/diagnostic_service.dart';
import 'package:kheti_sahayak_app/services/diagnostic_translation_service.dart';
import 'package:kheti_sahayak_app/services/language_service.dart';
import 'package:kheti_sahayak_app/widgets/loading_indicator.dart';
import 'package:kheti_sahayak_app/widgets/error_view.dart';

/// Treatment details screen with multilingual support
/// Displays localized disease information and treatment recommendations
class LocalizedTreatmentDetailsScreen extends StatefulWidget {
  final String diagnosticId;

  const LocalizedTreatmentDetailsScreen({
    Key? key,
    required this.diagnosticId,
  }) : super(key: key);

  @override
  State<LocalizedTreatmentDetailsScreen> createState() =>
      _LocalizedTreatmentDetailsScreenState();
}

class _LocalizedTreatmentDetailsScreenState
    extends State<LocalizedTreatmentDetailsScreen> {
  TreatmentResponse? _treatmentResponse;
  LocalizedDiagnosticResult? _localizedResult;
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'all';

  final DiagnosticTranslationService _translationService =
      DiagnosticTranslationService.instance;

  @override
  void initState() {
    super.initState();
    _initializeAndLoad();
  }

  Future<void> _initializeAndLoad() async {
    await _translationService.initialize();
    await _loadTreatments();
  }

  Future<void> _loadTreatments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await DiagnosticService.getTreatmentRecommendations(
        widget.diagnosticId,
      );

      // Get localized version
      final diagnostic = await DiagnosticService.getDiagnosticById(
        widget.diagnosticId,
      );

      final languageCode =
          Provider.of<LanguageService>(context, listen: false)
              .currentLanguage
              .code;

      final localizedResult = _translationService.localizeResult(
        diagnostic,
        response,
        languageCode,
      );

      setState(() {
        _treatmentResponse = response;
        _localizedResult = localizedResult;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  List<LocalizedTreatment> get _filteredTreatments {
    if (_localizedResult == null) return [];

    switch (_selectedFilter) {
      case 'organic':
        return _localizedResult!.organicTreatments;
      case 'chemical':
        return _localizedResult!.chemicalTreatments;
      case 'cultural':
        return _localizedResult!.culturalTreatments;
      case 'biological':
        return _localizedResult!.biologicalTreatments;
      default:
        return _localizedResult!.treatments;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        final langCode = languageService.currentLanguage.code;

        return Scaffold(
          appBar: AppBar(
            title: Text(_translationService.getString(
                'treatment_recommendations', langCode)),
            elevation: 0,
          ),
          body: _isLoading
              ? const Center(child: LoadingIndicator())
              : _error != null
                  ? ErrorView(
                      error: _error!,
                      onRetry: _loadTreatments,
                    )
                  : _buildContent(langCode),
        );
      },
    );
  }

  Widget _buildContent(String langCode) {
    if (_localizedResult == null) {
      return Center(
        child: Text(_translationService.getString(
            'no_treatments_available', langCode)),
      );
    }

    return Column(
      children: [
        // Disease Info Card
        if (_localizedResult!.disease != null)
          _buildDiseaseCard(langCode),

        // Filter Chips
        _buildFilterChips(langCode),

        // Treatments List
        Expanded(
          child: _filteredTreatments.isEmpty
              ? _buildEmptyState(langCode)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredTreatments.length,
                  itemBuilder: (context, index) {
                    return _buildTreatmentCard(
                        _filteredTreatments[index], langCode);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String langCode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medical_services_outlined,
              size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _translationService.getString('no_treatments_available', langCode),
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseCard(String langCode) {
    final disease = _localizedResult!.disease!;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Disease Name
          Row(
            children: [
              Icon(Icons.coronavirus, color: Colors.red[700], size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  disease.getName(langCode),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[900],
                  ),
                ),
              ),
            ],
          ),

          // Confidence Score
          if (_localizedResult!.confidenceScore != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${_translationService.getString('confidence', langCode)}: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[800],
                  ),
                ),
                Text(
                  '${(_localizedResult!.confidenceScore! * 100).toStringAsFixed(1)}%',
                  style: TextStyle(color: Colors.red[900]),
                ),
              ],
            ),
          ],

          // Severity
          if (disease.severity.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${_translationService.getString('severity', langCode)}: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[800],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(disease.severity),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _translationService.getString(disease.severity, langCode),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Description
          if (disease.getDescription(langCode).isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              disease.getDescription(langCode),
              style: TextStyle(color: Colors.red[900]),
            ),
          ],

          // Symptoms
          if (disease.getSymptoms(langCode).isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '${_translationService.getString('symptoms', langCode)}:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              disease.getSymptoms(langCode),
              style: TextStyle(color: Colors.red[900]),
            ),
          ],

          // Causes
          if (disease.getCauses(langCode).isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '${_translationService.getString('causes', langCode)}:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              disease.getCauses(langCode),
              style: TextStyle(color: Colors.orange[900]),
            ),
          ],

          // Prevention
          if (disease.getPrevention(langCode).isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '${_translationService.getString('prevention', langCode)}:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              disease.getPrevention(langCode),
              style: TextStyle(color: Colors.green[900]),
            ),
          ],
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red[700]!;
      case 'medium':
        return Colors.orange[700]!;
      case 'low':
        return Colors.green[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  Widget _buildFilterChips(String langCode) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip(
              _translationService.getString('all', langCode), 'all'),
          const SizedBox(width: 8),
          _buildFilterChip(
              LocalizedTreatment(
                id: 0,
                treatmentKey: '',
                treatmentType: 'organic',
                names: {},
              ).getTreatmentTypeDisplay(langCode),
              'organic'),
          const SizedBox(width: 8),
          _buildFilterChip(
              LocalizedTreatment(
                id: 0,
                treatmentKey: '',
                treatmentType: 'chemical',
                names: {},
              ).getTreatmentTypeDisplay(langCode),
              'chemical'),
          const SizedBox(width: 8),
          _buildFilterChip(
              LocalizedTreatment(
                id: 0,
                treatmentKey: '',
                treatmentType: 'cultural',
                names: {},
              ).getTreatmentTypeDisplay(langCode),
              'cultural'),
          const SizedBox(width: 8),
          _buildFilterChip(
              LocalizedTreatment(
                id: 0,
                treatmentKey: '',
                treatmentType: 'biological',
                names: {},
              ).getTreatmentTypeDisplay(langCode),
              'biological'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.green[100],
      checkmarkColor: Colors.green[700],
      labelStyle: TextStyle(
        color: isSelected ? Colors.green[900] : Colors.grey[800],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildTreatmentCard(LocalizedTreatment treatment, String langCode) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: _getTreatmentIcon(treatment.treatmentType),
        title: Text(
          treatment.getName(langCode),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getTreatmentColor(treatment.treatmentType)
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    treatment.getTreatmentTypeDisplay(langCode),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getTreatmentColor(treatment.treatmentType),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (treatment.effectivenessRating != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '⭐' * treatment.effectivenessRating!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ],
            ),
            if (treatment.costEstimate != null) ...[
              const SizedBox(height: 4),
              Text(
                treatment.costEstimate!,
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                if (treatment.getDescription(langCode).isNotEmpty)
                  _buildDescriptionRow(treatment.getDescription(langCode)),

                // Active Ingredient
                if (treatment.activeIngredient != null)
                  _buildDetailRow(
                      _translationService.getString(
                          'active_ingredient', langCode),
                      treatment.activeIngredient!),

                // Dosage
                if (treatment.getDosage(langCode).isNotEmpty)
                  _buildDetailRow(
                    _translationService.getString('dosage', langCode),
                    treatment.getDosage(langCode),
                    icon: Icons.science,
                  ),

                // Application Method
                if (treatment.getApplicationMethod(langCode).isNotEmpty)
                  _buildDetailRow(
                    _translationService.getString(
                        'application_method', langCode),
                    treatment.getApplicationMethod(langCode),
                  ),

                // Timing
                if (treatment.getTiming(langCode).isNotEmpty)
                  _buildDetailRow(
                    _translationService.getString('timing', langCode),
                    treatment.getTiming(langCode),
                    icon: Icons.schedule,
                  ),

                // Frequency
                if (treatment.getFrequency(langCode).isNotEmpty)
                  _buildDetailRow(
                    _translationService.getString('frequency', langCode),
                    treatment.getFrequency(langCode),
                  ),

                // Availability
                if (treatment.availability != null)
                  _buildDetailRow(
                    _translationService.getString('availability', langCode),
                    treatment.getAvailabilityDisplay(langCode),
                    icon: Icons.store,
                  ),

                // Precautions
                if (treatment.getPrecautions(langCode).isNotEmpty) ...[
                  const Divider(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _translationService.getString(
                                  'precautions', langCode),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[900],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              treatment.getPrecautions(langCode),
                              style: TextStyle(color: Colors.orange[800]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],

                // Notes
                if (treatment.getNotes(langCode).isNotEmpty) ...[
                  const Divider(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _translationService.getString('notes', langCode),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(treatment.getNotes(langCode)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionRow(String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        description,
        style: const TextStyle(
          color: Colors.black87,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Icon _getTreatmentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'organic':
        return Icon(Icons.eco, color: Colors.green[700]);
      case 'chemical':
        return Icon(Icons.science, color: Colors.blue[700]);
      case 'cultural':
        return Icon(Icons.agriculture, color: Colors.brown[700]);
      case 'biological':
        return Icon(Icons.bug_report, color: Colors.purple[700]);
      default:
        return Icon(Icons.medical_services, color: Colors.grey[700]);
    }
  }

  Color _getTreatmentColor(String type) {
    switch (type.toLowerCase()) {
      case 'organic':
        return Colors.green[700]!;
      case 'chemical':
        return Colors.blue[700]!;
      case 'cultural':
        return Colors.brown[700]!;
      case 'biological':
        return Colors.purple[700]!;
      default:
        return Colors.grey[700]!;
    }
  }
}
