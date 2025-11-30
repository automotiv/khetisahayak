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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Fetch crop recommendations (using default parameters for now)
      final cropRes = await http.get(Uri.parse('${Constants.baseUrl}/api/diagnostics/recommendations?season=Kharif'));
      
      // Fetch weather recommendations (using hardcoded location for demo)
      final weatherRes = await http.get(Uri.parse('${Constants.baseUrl}/api/weather/recommendations?lat=28.61&lon=77.20'));

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
                _buildCropRecommendationsList(),
                _buildWeatherRecommendationsList(),
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
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            title: Text(item['crop_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Season: ${item['season']}'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Show details dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(item['crop_name']),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Soil: ${item['soil_type']}'),
                        const SizedBox(height: 8),
                        Text('Water: ${item['water_requirement']}'),
                        const SizedBox(height: 8),
                        Text('Description: ${item['description'] ?? "N/A"}'),
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
