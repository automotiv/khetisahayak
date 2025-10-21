import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/treatment.dart';
import 'package:kheti_sahayak_app/services/diagnostic_service.dart';
import 'package:kheti_sahayak_app/widgets/loading_indicator.dart';
import 'package:kheti_sahayak_app/widgets/error_view.dart';

class TreatmentDetailsScreen extends StatefulWidget {
  final String diagnosticId;

  const TreatmentDetailsScreen({
    Key? key,
    required this.diagnosticId,
  }) : super(key: key);

  @override
  State<TreatmentDetailsScreen> createState() => _TreatmentDetailsScreenState();
}

class _TreatmentDetailsScreenState extends State<TreatmentDetailsScreen> {
  TreatmentResponse? _treatmentResponse;
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'all'; // all, organic, chemical, cultural

  @override
  void initState() {
    super.initState();
    _loadTreatments();
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

      setState(() {
        _treatmentResponse = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  List<Treatment> get _filteredTreatments {
    if (_treatmentResponse == null) return [];

    switch (_selectedFilter) {
      case 'organic':
        return _treatmentResponse!.organicTreatments;
      case 'chemical':
        return _treatmentResponse!.chemicalTreatments;
      case 'cultural':
        return _treatmentResponse!.culturalTreatments;
      default:
        return _treatmentResponse!.treatments;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Treatment Recommendations'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _error != null
              ? ErrorView(
                  message: _error!,
                  onRetry: _loadTreatments,
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_treatmentResponse == null) {
      return const Center(child: Text('No treatments available'));
    }

    return Column(
      children: [
        // Disease Info Card
        if (_treatmentResponse!.disease != null) _buildDiseaseCard(),

        // Filter Chips
        _buildFilterChips(),

        // Treatments List
        Expanded(
          child: _filteredTreatments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.medical_services_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No ${_selectedFilter != 'all' ? _selectedFilter : ''} treatments available',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredTreatments.length,
                  itemBuilder: (context, index) {
                    return _buildTreatmentCard(_filteredTreatments[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDiseaseCard() {
    final disease = _treatmentResponse!.disease!;

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
          Row(
            children: [
              Icon(Icons.coronavirus, color: Colors.red[700], size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  disease.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[900],
                  ),
                ),
              ),
            ],
          ),
          if (disease.symptoms != null) ...[
            const SizedBox(height: 12),
            Text(
              'Symptoms:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              disease.symptoms!,
              style: TextStyle(color: Colors.red[900]),
            ),
          ],
          if (disease.prevention != null) ...[
            const SizedBox(height: 12),
            Text(
              'Prevention:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              disease.prevention!,
              style: TextStyle(color: Colors.green[900]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('All', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('Organic', 'organic'),
          const SizedBox(width: 8),
          _buildFilterChip('Chemical', 'chemical'),
          const SizedBox(width: 8),
          _buildFilterChip('Cultural', 'cultural'),
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

  Widget _buildTreatmentCard(Treatment treatment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: _getTreatmentIcon(treatment.treatmentType),
        title: Text(
          treatment.treatmentName,
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getTreatmentColor(treatment.treatmentType).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    treatment.treatmentTypeDisplay,
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
                    treatment.effectivenessStars,
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
                if (treatment.activeIngredient != null)
                  _buildDetailRow('Active Ingredient', treatment.activeIngredient!),
                if (treatment.dosage != null)
                  _buildDetailRow('Dosage', treatment.dosage!, icon: Icons.science),
                if (treatment.applicationMethod != null)
                  _buildDetailRow('Application', treatment.applicationMethod!),
                if (treatment.timing != null)
                  _buildDetailRow('Timing', treatment.timing!, icon: Icons.schedule),
                if (treatment.frequency != null)
                  _buildDetailRow('Frequency', treatment.frequency!),
                if (treatment.availability != null)
                  _buildDetailRow(
                    'Availability',
                    treatment.availabilityDisplay,
                    icon: Icons.store,
                  ),
                if (treatment.precautions != null) ...[
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
                              'Precautions',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[900],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              treatment.precautions!,
                              style: TextStyle(color: Colors.orange[800]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                if (treatment.notes != null) ...[
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
                            const Text(
                              'Notes',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(treatment.notes!),
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
              label + ':',
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
