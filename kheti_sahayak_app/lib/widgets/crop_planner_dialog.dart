import 'package:flutter/material.dart';
import '../services/crop_planning_service.dart';

class CropPlannerDialog extends StatefulWidget {
  final String? previousCrop;
  final Function(String selectedCrop) onSelected;

  const CropPlannerDialog({
    super.key,
    this.previousCrop,
    required this.onSelected,
  });

  @override
  State<CropPlannerDialog> createState() => _CropPlannerDialogState();
}

class _CropPlannerDialogState extends State<CropPlannerDialog> {
  final CropPlanningService _planningService = CropPlanningService();
  List<String> _suggestions = [];
  bool _showSuggestions = true;

  @override
  void initState() {
    super.initState();
    if (widget.previousCrop != null) {
      _suggestions = _planningService.getRecommendations(widget.previousCrop!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Plan Next Crop'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.previousCrop != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Previous Crop: ${widget.previousCrop}',
                  style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                ),
              ),
            
            if (_showSuggestions && _suggestions.isNotEmpty) ...[
              const Text(
                'Recommended Rotations',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _suggestions.map((crop) {
                  return ActionChip(
                    label: Text(crop),
                    backgroundColor: Colors.green[50],
                    labelStyle: TextStyle(color: Colors.green[800]),
                    onPressed: () {
                      widget.onSelected(crop);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
              const Divider(height: 24),
            ],

            const Text('Or select custom:'),
            // In a real app, this would be a full autocomplete list
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Enter Manually'),
              onTap: () {
                // Return simple dialog to enter text, or callback with empty to trigger manual flow
                 Navigator.pop(context); // Close this, parent handles manual
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
