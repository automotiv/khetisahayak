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

  static const Map<String, IconData> activityTypes = {
    'Sowing': Icons.grass,
    'Irrigation': Icons.water_drop,
    'Fertilizing': Icons.eco,
    'Harvesting': Icons.agriculture,
    'Spraying': Icons.pest_control,
    'Other': Icons.category,
  };

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
      ),
      items: activityTypes.entries.map((entry) {
        return DropdownMenuItem<String>(
          value: entry.key,
          child: Row(
            children: [
              Icon(entry.value, size: 20, color: Theme.of(context).primaryColor),
              SizedBox(width: 12),
              Text(entry.key),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}
