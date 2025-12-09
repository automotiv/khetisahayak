import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/field.dart';
import 'package:kheti_sahayak_app/models/recommendation.dart';
import 'package:kheti_sahayak_app/services/field_service.dart';
import 'package:kheti_sahayak_app/services/recommendation_service.dart';
import 'package:intl/intl.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({Key? key}) : super(key: key);

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final FieldService _fieldService = FieldService();
  final RecommendationService _recommendationService = RecommendationService();
  
  List<Field> _fields = [];
  Field? _selectedField;
  List<Recommendation> _recommendations = [];
  bool _isLoading = false;
  String _filterType = 'All'; // All, Crop, Input

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  Future<void> _loadFields() async {
    final fields = await _fieldService.getFields();
    if (mounted) {
      setState(() {
        _fields = fields;
        if (fields.isNotEmpty) {
          _selectedField = fields.first;
          _loadRecommendations();
        }
      });
    }
  }

  Future<void> _loadRecommendations() async {
    if (_selectedField == null) return;

    setState(() => _isLoading = true);
    try {
      final recs = await _recommendationService.getRecommendations(_selectedField!.id!);
      if (mounted) {
        setState(() {
          _recommendations = recs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Recommendation> get _filteredRecommendations {
    if (_filterType == 'All') return _recommendations;
    return _recommendations.where((r) => r.type == _filterType).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Recommendations'),
      ),
      body: Column(
        children: [
          // Field Selector
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<int>(
              value: _selectedField?.id,
              decoration: const InputDecoration(
                labelText: 'Select Field',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.landscape),
              ),
              items: _fields.map((field) {
                return DropdownMenuItem(
                  value: field.id,
                  child: Text(field.name),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedField = _fields.firstWhere((f) => f.id == val);
                });
                _loadRecommendations();
              },
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['All', 'Crop', 'Input'].map((type) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(type),
                    selected: _filterType == type,
                    onSelected: (selected) {
                      if (selected) setState(() => _filterType = type);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Recommendations List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRecommendations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _fields.isEmpty 
                                  ? 'Add a field to get started' 
                                  : 'No recommendations available yet.\nAdd soil data for better insights.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredRecommendations.length,
                        itemBuilder: (context, index) {
                          final rec = _filteredRecommendations[index];
                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                          color: _getTypeColor(rec.type).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(_getTypeIcon(rec.type), color: _getTypeColor(rec.type)),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              rec.type.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: _getTypeColor(rec.type),
                                              ),
                                            ),
                                            Text(
                                              rec.title,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green[50],
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.green[200]!),
                                        ),
                                        child: Text(
                                          '${(rec.confidence * 100).toInt()}% Match',
                                          style: TextStyle(fontSize: 12, color: Colors.green[800]),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    rec.description,
                                    style: TextStyle(color: Colors.grey[800], height: 1.4),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat('MMM dd, yyyy').format(rec.timestamp),
                                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          // TODO: Implement Apply/Action
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Feature coming soon!')),
                                          );
                                        },
                                        child: const Text('View Details'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Crop': return Colors.green;
      case 'Input': return Colors.orange;
      case 'Market': return Colors.blue;
      default: return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Crop': return Icons.grass;
      case 'Input': return Icons.science;
      case 'Market': return Icons.trending_up;
      default: return Icons.info;
    }
  }
}
