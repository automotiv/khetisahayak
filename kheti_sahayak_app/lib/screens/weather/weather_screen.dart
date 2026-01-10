import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kheti_sahayak_app/services/weather_service.dart';
import 'package:kheti_sahayak_app/models/weather_model.dart';
import 'package:kheti_sahayak_app/models/weather_alert.dart';
import 'package:kheti_sahayak_app/services/weather_alert_service.dart';
import 'package:kheti_sahayak_app/services/language_service.dart';
import 'package:kheti_sahayak_app/screens/weather/weather_alerts_screen.dart';
import 'package:kheti_sahayak_app/widgets/weather/alert_card.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late Future<Map<String, dynamic>> _weatherData;
  final WeatherService _weatherService = WeatherService();
  
  // Weather alerts state
  List<WeatherAlert> _activeAlerts = [];
  bool _loadingAlerts = true;
  int _alertCount = 0;

  @override
  void initState() {
    super.initState();
    _weatherData = _weatherService.getWeatherData();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    try {
      final location = await WeatherAlertService.getSubscriptionLocation();
      if (location != null) {
        final alerts = await WeatherAlertService.getActiveAlerts(
          location['latitude']!,
          location['longitude']!,
        );
        if (mounted) {
          setState(() {
            _activeAlerts = alerts;
            _alertCount = alerts.length;
            _loadingAlerts = false;
          });
        }
      } else {
        // Try to get alerts based on current weather location
        // For now, just check for alert count
        final count = await WeatherAlertService.getActiveAlertCount();
        if (mounted) {
          setState(() {
            _alertCount = count;
            _loadingAlerts = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingAlerts = false);
      }
    }
  }

  void _navigateToAlerts() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WeatherAlertsScreen()),
    ).then((_) => _loadAlerts()); // Refresh on return
  }

  Future<void> _showHistoricalWeather() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 1)),
      firstDate: DateTime.now().subtract(const Duration(days: 5)),
      lastDate: DateTime.now().subtract(const Duration(days: 1)),
    );

    if (picked != null && mounted) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        final historicalWeather = await _weatherService.getHistoricalWeather(picked);
        
        if (mounted) {
          Navigator.pop(context);
          _showHistoricalDialog(historicalWeather, picked);
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  void _showHistoricalDialog(UnifiedWeather weather, DateTime date) {
    final localizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Weather on ${DateFormat.yMMMd(localizations.locale.toString()).format(date)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network('http://openweathermap.org/img/wn/${weather.icon}@2x.png'),
            Text(
              '${weather.temp.round()}°C',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            Text(weather.condition, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Icon(Icons.water_drop, color: Colors.blue),
                    Text('${weather.humidity}%'),
                  ],
                ),
                Column(
                  children: [
                    const Icon(Icons.air, color: Colors.grey),
                    Text('${weather.windSpeed} m/s'),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.weatherForecast),
        actions: [
          // Weather Alerts Button with Badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_active),
                tooltip: 'Weather Alerts',
                onPressed: _navigateToAlerts,
              ),
              if (_alertCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: AlertCountBadge(count: _alertCount),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historical Weather',
            onPressed: _showHistoricalWeather,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _weatherData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '${localizations.error}: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          } else if (snapshot.hasData) {
            final weather = snapshot.data!['forecast'] as UnifiedWeather;
            final locationName = snapshot.data!['locationName'] as String;

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _weatherData = _weatherService.getWeatherData();
                });
                await _loadAlerts();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Active Alerts Banner
                    if (!_loadingAlerts && _activeAlerts.isNotEmpty)
                      AlertBanner(
                        alertCount: _activeAlerts.length,
                        topAlertTitle: _activeAlerts.first.title,
                        severity: _activeAlerts.first.severity,
                        onTap: _navigateToAlerts,
                      ),
                    
                    // Main Weather Content
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCurrentWeather(context, weather, locationName),
                          const SizedBox(height: 24),
                          
                          // Quick Alerts Preview (if any)
                          if (!_loadingAlerts && _activeAlerts.isNotEmpty) ...[
                            _buildAlertsPreview(),
                            const SizedBox(height: 24),
                          ],
                          
                          if (weather.dailyForecasts.isNotEmpty) ...[
                            Text(
                              '5-Day ${localizations.forecast}',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildDailyForecast(context, weather.dailyForecasts, localizations),
                          ] else
                            const Text('No forecast available'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return Center(child: Text(localizations.noData));
          }
        },
      ),
    );
  }

  Widget _buildAlertsPreview() {
    // Show only severe/high alerts in preview
    final severeAlerts = _activeAlerts
        .where((a) => a.severityLevel >= 3)
        .take(2)
        .toList();

    if (severeAlerts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber, color: Color(0xFFF97316), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Active Alerts',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: _navigateToAlerts,
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...severeAlerts.map((alert) => _buildMiniAlertCard(alert)),
      ],
    );
  }

  Widget _buildMiniAlertCard(WeatherAlert alert) {
    final severityColor = _getSeverityColor(alert.severity);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: severityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: severityColor.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: _navigateToAlerts,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: severityColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getAlertIcon(alert.type),
                color: severityColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    alert.remainingTimeFormatted,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: severityColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                AlertSeverity.getDisplayName(alert.severity),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'severe':
        return const Color(0xFFDC2626);
      case 'high':
        return const Color(0xFFF97316);
      case 'moderate':
        return const Color(0xFFEAB308);
      case 'low':
        return const Color(0xFF3B82F6);
      default:
        return Colors.grey;
    }
  }

  IconData _getAlertIcon(String type) {
    switch (type) {
      case 'heat_wave':
        return Icons.wb_sunny;
      case 'heavy_rain':
        return Icons.water_drop;
      case 'frost':
        return Icons.ac_unit;
      case 'storm':
        return Icons.thunderstorm;
      case 'drought':
        return Icons.wb_twilight;
      case 'flood':
        return Icons.waves;
      case 'hailstorm':
        return Icons.grain;
      case 'strong_wind':
        return Icons.air;
      default:
        return Icons.warning_amber;
    }
  }

  Widget _buildCurrentWeather(BuildContext context, UnifiedWeather weather, String locationName) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: <Widget>[
            Text(locationName, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    Image.network('http://openweathermap.org/img/wn/${weather.icon}@2x.png'),
                    Text('${weather.temp.round()}°C', style: theme.textTheme.displayLarge?.copyWith(fontSize: 60, fontWeight: FontWeight.bold)),
                ],
            ),
            Text(weather.condition, style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetailItem(Icons.water_drop, '${weather.humidity}%', 'Humidity'),
                _buildDetailItem(Icons.air, '${weather.windSpeed} m/s', 'Wind'),
                if (weather.rainChance != null)
                  _buildDetailItem(Icons.umbrella, '${(weather.rainChance! * 100).round()}%', 'Rain'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildDailyForecast(BuildContext context, List<DailyForecast> dailyForecast, AppLocalizations localizations) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: dailyForecast.length > 5 ? 5 : dailyForecast.length,
      itemBuilder: (context, index) {
        final item = dailyForecast[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          child: ListTile(
            leading: Image.network('http://openweathermap.org/img/wn/${item.icon}.png'),
            title: Text(DateFormat.EEEE(localizations.locale.toString()).format(item.date), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            trailing: Text('${item.tempMax.round()}°C / ${item.tempMin.round()}°C', style: Theme.of(context).textTheme.titleMedium),
            subtitle: item.rainChance != null ? Text('Rain: ${(item.rainChance! * 100).round()}%') : null,
          ),
        );
      },
    );
  }
}
