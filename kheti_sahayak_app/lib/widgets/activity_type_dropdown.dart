import 'package:flutter/material.dart';

class ActivityTypeDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  const ActivityTypeDropdown({
    Key? key,
    this.value,
    required this.onChanged,
    this.validator,
  }) : super(key: key);

  // Enhanced activity types with farming-specific icons
  // Aligned with backend activity definitions
  static const Map<String, IconData> activityTypes = {
    'Planting': Icons.grass,              // Sowing/Planting seeds
    'Irrigation': Icons.water_drop,        // Watering crops
    'Spraying': Icons.pest_control,        // Pesticide application
    'Fertilizing': Icons.eco,              // Fertilizer application
    'Harvesting': Icons.agriculture,       // Crop harvesting
    'Tillage': Icons.construction,         // Land preparation/plowing
    'Weeding': Icons.yard,                 // Weed removal
    'Pruning': Icons.content_cut,          // Trimming plants
    'Mulching': Icons.layers,              // Applying mulch
    'Other': Icons.category,               // Miscellaneous
  };

  // Color mapping for different activity categories
  static Color _getActivityColor(String activityType, BuildContext context) {
    switch (activityType) {
      case 'Planting':
        return Colors.green.shade700;
      case 'Irrigation':
        return Colors.blue.shade600;
      case 'Spraying':
      case 'Fertilizing':
        return Colors.orange.shade700;
      case 'Harvesting':
        return Colors.amber.shade800;
      case 'Tillage':
        return Colors.brown.shade600;
      case 'Weeding':
        return Colors.lightGreen.shade700;
      case 'Pruning':
        return Colors.teal.shade600;
      case 'Mulching':
        return Colors.blueGrey.shade600;
      default:
        return Theme.of(context).primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: 'Activity Type',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        prefixIcon: Icon(Icons.work_outline),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.light
            ? Colors.grey.shade50
            : null,
      ),
      items: activityTypes.entries.map((entry) {
        return DropdownMenuItem<String>(
          value: entry.key,
          child: Row(
            children: [
              Icon(
                entry.value,
                size: 24,
                color: _getActivityColor(entry.key, context),
              ),
              SizedBox(width: 12),
              Text(
                entry.key,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      isExpanded: true,
      icon: Icon(Icons.arrow_drop_down, size: 28),
      dropdownColor: Theme.of(context).brightness == Brightness.light
          ? Colors.white
          : null,
    );
  }
}
