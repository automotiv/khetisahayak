import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kheti_sahayak_app/services/weather_service.dart';
import 'package:kheti_sahayak_app/models/weather_model.dart';
import 'package:kheti_sahayak_app/services/language_service.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({Key? key}) : super(key: key);

  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late Future<Map<String, dynamic>> _weatherData;
  final WeatherService _weatherService = WeatherService();

  @override
  void initState() {
    super.initState();
    _weatherData = _weatherService.getWeatherData();
  }

  Future<void> _showHistoricalWeather() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 1)),
      firstDate: DateTime.now().subtract(const Duration(days: 5)), // One Call 2.5 usually allows 5 days back for free/standard
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
          Navigator.pop(context); // Dismiss loading
          _showHistoricalDialog(historicalWeather, picked);
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Dismiss loading
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
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historical Weather', // Add to translations
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

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildCurrentWeather(context, weather, locationName),
                  const SizedBox(height: 24),
                  if (weather.dailyForecasts.isNotEmpty) ...[
                    Text('5-Day ${localizations.forecast}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildDailyForecast(context, weather.dailyForecasts, localizations),
                  ] else
                    const Text('No forecast available'),
                ],
              ),
            );
          } else {
            return Center(child: Text(localizations.noData));
          }
        },
      ),
    );
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
