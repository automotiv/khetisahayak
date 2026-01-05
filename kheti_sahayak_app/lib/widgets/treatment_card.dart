import 'package:flutter/material.dart';
import '../models/treatment_model.dart';

/// Treatment Card Widget
///
/// Displays a single treatment recommendation with all details
class TreatmentCard extends StatelessWidget {
  final TreatmentModel treatment;
  final bool isRecommended;

  const TreatmentCard({
    Key? key,
    required this.treatment,
    this.isRecommended = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isRecommended ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isRecommended
            ? BorderSide(color: Colors.green[700]!, width: 2)
            : BorderSide.none,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with recommendation badge
          if (isRecommended) _buildRecommendedBadge(),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Treatment Name and Type
                _buildHeader(),
                const SizedBox(height: 12),

                // Effectiveness Rating
                if (treatment.effectivenessRating != null) ...[
                  _buildEffectivenessRating(),
                  const SizedBox(height: 12),
                ],

                // Active Ingredient
                if (treatment.activeIngredient != null) ...[
                  _buildDetailRow(
                    Icons.science,
                    'सक्रिय घटक',
                    treatment.activeIngredient!,
                  ),
                  const SizedBox(height: 8),
                ],

                // Dosage
                if (treatment.dosage != null) ...[
                  _buildDetailRow(
                    Icons.colorize,
                    'खुराक',
                    treatment.dosage!,
                  ),
                  const SizedBox(height: 8),
                ],

                // Application Method
                if (treatment.applicationMethod != null) ...[
                  _buildDetailRow(
                    Icons.agriculture,
                    'उपयोग विधि',
                    treatment.applicationMethod!,
                  ),
                  const SizedBox(height: 8),
                ],

                // Timing
                if (treatment.timing != null) ...[
                  _buildDetailRow(
                    Icons.schedule,
                    'समय',
                    treatment.timing!,
                  ),
                  const SizedBox(height: 8),
                ],

                // Frequency
                if (treatment.frequency != null) ...[
                  _buildDetailRow(
                    Icons.repeat,
                    'आवृत्ति',
                    treatment.frequency!,
                  ),
                  const SizedBox(height: 8),
                ],

                // Cost Estimate and Availability
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Cost
                    if (treatment.costEstimate != null)
                      Expanded(
                        child: _buildCostChip(),
                      ),
                    const SizedBox(width: 8),

                    // Availability
                    if (treatment.availability != null)
                      Expanded(
                        child: _buildAvailabilityChip(),
                      ),
                  ],
                ),

                // Precautions
                if (treatment.precautions != null) ...[
                  const SizedBox(height: 16),
                  _buildPrecautionsSection(),
                ],

                // Notes
                if (treatment.notes != null) ...[
                  const SizedBox(height: 12),
                  _buildNotesSection(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedBadge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green[700],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text(
            'सर्वाधिक प्रभावी उपचार',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Type Icon
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getTypeColor().withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            treatment.typeIcon,
            style: const TextStyle(fontSize: 24),
          ),
        ),
        const SizedBox(width: 12),

        // Treatment Name and Type
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                treatment.treatmentName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTypeColor(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getTreatmentTypeLabel(treatment.treatmentType),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEffectivenessRating() {
    final rating = treatment.effectivenessRating!;
    return Row(
      children: [
        const Text(
          'प्रभावशीलता: ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        ...List.generate(
          5,
          (index) => Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 20,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$rating/5',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCostChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.currency_rupee, size: 16, color: Colors.blue[700]),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              treatment.costEstimate!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityChip() {
    final color = _getAvailabilityColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.store, size: 16, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              treatment.availabilityText,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrecautionsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.red[700], size: 18),
              const SizedBox(width: 8),
              Text(
                'सावधानियाँ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            treatment.precautions!,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.grey[700], size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              treatment.notes!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor() {
    switch (treatment.treatmentType.toLowerCase()) {
      case 'organic':
        return Colors.green;
      case 'chemical':
        return Colors.deepOrange;
      case 'cultural':
        return Colors.brown;
      case 'biological':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getAvailabilityColor() {
    switch (treatment.availability?.toLowerCase()) {
      case 'easily_available':
        return Colors.green;
      case 'locally_available':
        return Colors.orange;
      case 'requires_order':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getTreatmentTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'organic':
        return 'जैविक';
      case 'chemical':
        return 'रासायनिक';
      case 'cultural':
        return 'सांस्कृतिक';
      case 'biological':
        return 'जैविक नियंत्रण';
      default:
        return type;
    }
  }
}
