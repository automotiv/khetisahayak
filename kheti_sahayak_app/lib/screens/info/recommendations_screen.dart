import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:kheti_sahayak_app/utils/constants.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({Key? key}) : super(key: key);

  @override
  _RecommendationsScreenState createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _cropRecommendations = [];
  Map<String, dynamic>? _weatherRecommendations;

  String _selectedSeason = 'Kharif';
  String _selectedSoil = 'Loam';
  String _selectedWater = 'Medium';

  final List<String> _seasons = ['Kharif', 'Rabi', 'Zaid'];
  final List<String> _soilTypes = ['Loam', 'Clay', 'Sandy', 'Black', 'Red'];
  final List<String> _waterLevels = ['Low', 'Medium', 'High'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Fetch crop recommendations with filters
      final queryParams = {
        'season': _selectedSeason,
        'soil_type': _selectedSoil,
        'water_availability': _selectedWater.toLowerCase(),
      };
      final uri = Uri.parse('${AppConstants.baseUrl}/diagnostics/recommendations')
          .replace(queryParameters: queryParams);

      final cropRes = await http.get(uri);

      // Fetch weather recommendations (using hardcoded location for demo)
      final weatherRes = await http.get(Uri.parse('${AppConstants.baseUrl}/weather/recommendations?lat=28.61&lon=77.20'));

      if (mounted) {
        setState(() {
          if (cropRes.statusCode == 200) {
            final data = json.decode(cropRes.body);
            if (data['success'] == true) {
              _cropRecommendations = data['recommendations'];
            }
          }

          if (weatherRes.statusCode == 200) {
            final data = json.decode(weatherRes.body);
            if (data['success'] == true) {
              _weatherRecommendations = data['data'];
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading recommendations: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommendations'),
        backgroundColor: Colors.green[700],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Crops'),
            Tab(text: 'Weather Tips'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCropRecommendationsTab(),
                _buildWeatherRecommendationsList(),
              ],
            ),
    );
  }

  Widget _buildCropRecommendationsTab() {
    return Column(
      children: [
        _buildFilters(),
        Expanded(child: _buildCropRecommendationsList()),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.green[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Customize Recommendations', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSeason,
                  decoration: const InputDecoration(labelText: 'Season', contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), border: OutlineInputBorder()),
                  items: _seasons.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedSeason = val);
                      _loadData();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSoil,
                  decoration: const InputDecoration(labelText: 'Soil', contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), border: OutlineInputBorder()),
                  items: _soilTypes.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedSoil = val);
                      _loadData();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
           DropdownButtonFormField<String>(
              value: _selectedWater,
              decoration: const InputDecoration(labelText: 'Water Availability', contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), border: OutlineInputBorder()),
              items: _waterLevels.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedWater = val);
                  _loadData();
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCropRecommendationsList() {
    if (_cropRecommendations.isEmpty) {
      return const Center(child: Text('No crop recommendations available.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cropRecommendations.length,
      itemBuilder: (context, index) {
        final item = _cropRecommendations[index];
        // Handle both ML response (crop, confidence) and DB response (crop_name, etc.)
        final name = item['crop'] ?? item['crop_name'];
        final confidence = item['confidence'];
        final reason = item['reason'];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green[100],
              child: Text(name[0], style: TextStyle(color: Colors.green[800])),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (confidence != null)
                  Text('Match Score: ${(confidence * 100).toInt()}%', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold)),
                if (reason != null)
                  Text(reason, style: const TextStyle(fontSize: 12)),
                if (item['season'] != null)
                  Text('Season: ${item['season']}'),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Show details dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(name),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (confidence != null)
                           Container(
                             padding: const EdgeInsets.all(8),
                             decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
                             child: Row(children: [const Icon(Icons.verified, color: Colors.green), const SizedBox(width: 8), Text('AI Confidence: ${(confidence * 100).toInt()}%')])
                           ),
                        const SizedBox(height: 16),
                        Text('Soil: ${item['soil_type'] ?? _selectedSoil}'),
                        const SizedBox(height: 8),
                        Text('Water: ${item['water_requirement'] ?? _selectedWater}'),
                        const SizedBox(height: 8),
                        Text('Description: ${item['description'] ?? reason ?? "Recommended based on your farm profile."}'),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildWeatherRecommendationsList() {
    if (_weatherRecommendations == null) {
      return const Center(child: Text('No weather recommendations available.'));
    }

    final activities = _weatherRecommendations!['activity_recommendations'] as List<dynamic>? ?? [];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        Color color = Colors.grey;
        if (activity['severity'] == 'ideal') color = Colors.green;
        if (activity['severity'] == 'caution') color = Colors.orange;
        if (activity['severity'] == 'avoid') color = Colors.red;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: color),
                    const SizedBox(width: 8),
                    Text(
                      activity['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(activity['message']),
              ],
            ),
          ),
        );
      },
    );
  }
}
