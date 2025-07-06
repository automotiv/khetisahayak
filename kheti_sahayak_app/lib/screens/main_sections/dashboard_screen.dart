import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';  // Temporarily disabled
import 'package:kheti_sahayak_app/services/weather_service.dart';
import 'package:kheti_sahayak_app/services/diagnostic_service.dart';
import 'package:kheti_sahayak_app/models/diagnostic.dart';
import 'package:kheti_sahayak_app/services/educational_content_service.dart';
import 'package:kheti_sahayak_app/models/educational_content.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _weatherData;
  String _weatherError = '';
  List<Diagnostic> _recentDiagnostics = [];
  String _diagnosticsError = '';
  List<EducationalContent> _featuredContent = [];
  String _contentError = '';

  // TODO: Replace with actual user ID from authentication
  final String _currentUserId = 'some_user_id';

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
    _fetchRecentDiagnostics();
    _fetchFeaturedContent();
  }

  Future<void> _fetchWeatherData() async {
    // Temporarily disabled geolocation functionality
    setState(() {
      _weatherError = 'Weather service is currently unavailable.';
    });
    
    // Example weather data - remove this in production
    setState(() {
      _weatherData = {
        'temperature': 25.0,
        'condition': 'Sunny',
        'humidity': 65,
        'wind_speed': 5.0,
        'location': 'Demo Location'
      };
      _weatherError = '';
    });
  }

  Future<void> _fetchRecentDiagnostics() async {
    try {
      final diagnostics = await DiagnosticService.getUserDiagnostics(_currentUserId);
      setState(() {
        _recentDiagnostics = diagnostics.take(3).toList(); // Show up to 3 recent diagnostics
        _diagnosticsError = '';
      });
    } catch (e) {
      setState(() {
        _diagnosticsError = 'Failed to load recent diagnostics: $e';
      });
    }
  }

  Future<void> _fetchFeaturedContent() async {
    try {
      final content = await EducationalContentService.getEducationalContent();
      setState(() {
        _featuredContent = content.take(3).toList(); // Show up to 3 featured content
        _contentError = '';
      });
    } catch (e) {
      setState(() {
        _contentError = 'Failed to load featured content: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Welcome Section
          Text(
            'Welcome, User!', // Replace with actual user name
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
          ),
          const SizedBox(height: 20),

          // Weather Information Section
          _buildSectionCard(
            context,
            title: 'Current Weather',
            child: _weatherError.isNotEmpty
                ? Text(_weatherError, style: const TextStyle(color: Colors.red))
                : _weatherData == null
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWeatherDetail(
                              'Temperature', '${_weatherData!['temperature']}°C',
                              Icons.thermostat),
                          _buildWeatherDetail(
                              'Condition', '${_weatherData!['condition']}',
                              Icons.cloud),
                          _buildWeatherDetail(
                              'Humidity', '${_weatherData!['humidity']}%',
                              Icons.water_drop),
                          _buildWeatherDetail(
                              'Wind Speed', '${_weatherData!['wind_speed']} m/s',
                              Icons.wind_power),
                        ],
                      ),
          ),
          const SizedBox(height: 20),

          // Recent Diagnostics Section
          _buildSectionCard(
            context,
            title: 'Recent Diagnostics',
            child: _diagnosticsError.isNotEmpty
                ? Text(_diagnosticsError, style: const TextStyle(color: Colors.red))
                : _recentDiagnostics.isEmpty
                    ? const Text('No recent diagnostics found.')
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _recentDiagnostics.length,
                        itemBuilder: (context, index) {
                          final diagnostic = _recentDiagnostics[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                const Icon(Icons.bug_report, size: 18, color: Colors.orange),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${diagnostic.cropType}: ${diagnostic.issueDescription.substring(0, diagnostic.issueDescription.length > 50 ? 50 : diagnostic.issueDescription.length)}...',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          const SizedBox(height: 20),

          // Featured Educational Content Section
          _buildSectionCard(
            context,
            title: 'Featured Educational Content',
            child: _contentError.isNotEmpty
                ? Text(_contentError, style: const TextStyle(color: Colors.red))
                : _featuredContent.isEmpty
                    ? const Text('No featured content available.')
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _featuredContent.length,
                        itemBuilder: (context, index) {
                          final content = _featuredContent[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                const Icon(Icons.book, size: 18, color: Colors.blue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${content.title}: ${content.content.substring(0, content.content.length > 50 ? 50 : content.content.length)}...',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, {required String title, required Widget child}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 10),
          Text('$label: ', style: Theme.of(context).textTheme.bodyLarge),
          Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}