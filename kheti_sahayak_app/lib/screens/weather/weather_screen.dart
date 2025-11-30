
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kheti_sahayak_app/services/weather_service.dart';
import 'package:kheti_sahayak_app/models/weather_model.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({Key? key}) : super(key: key);

  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late Future<Map<String, dynamic>> _weatherData;

  @override
  void initState() {
    super.initState();
    _weatherData = WeatherService().getWeatherData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Forecast'),
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
                  'Error: ${snapshot.error}. Please ensure location services are enabled and permissions are granted.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          } else if (snapshot.hasData) {
            final forecast = snapshot.data!['forecast'] as WeatherForecast;
            final locationName = snapshot.data!['locationName'] as String;
            final currentWeather = forecast.list.first;
            final hourlyForecast = forecast.list.take(8).toList();
            final dailyForecast = _getDailyForecast(forecast.list);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildCurrentWeather(context, currentWeather, locationName),
                  const SizedBox(height: 24),
                   Text('Hourly Forecast', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildHourlyForecast(context, hourlyForecast),
                  const SizedBox(height: 24),
                  Text('5-Day Forecast', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildDailyForecast(context, dailyForecast),
                ],
              ),
            );
          } else {
            return const Center(child: Text('No weather data available.'));
          }
        },
      ),
    );
  }

  List<WeatherCondition> _getDailyForecast(List<WeatherCondition> list) {
    final Map<int, WeatherCondition> daily = {};
    for (var item in list) {
      final day = DateTime.parse(item.dtTxt).day;
      if (!daily.containsKey(day)) {
        daily[day] = item;
      }
    }
    return daily.values.toList();
  }

  Widget _buildCurrentWeather(BuildContext context, WeatherCondition currentWeather, String locationName) {
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
                    Image.network('http://openweathermap.org/img/wn/${currentWeather.weather.first.icon}@2x.png'),
                    Text('${currentWeather.main.temp.round()}°C', style: theme.textTheme.displayLarge?.copyWith(fontSize: 60, fontWeight: FontWeight.bold)),
                ],
            ),
            Text(currentWeather.weather.first.main, style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyForecast(BuildContext context, List<WeatherCondition> hourlyForecast) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: hourlyForecast.length,
        itemBuilder: (context, index) {
          final item = hourlyForecast[index];
          return Card(
            margin: const EdgeInsets.only(right: 12),
            child: Container(
              width: 90,
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Text(DateFormat.j().format(DateTime.parse(item.dtTxt)), style: theme.textTheme.bodyMedium),
                  Image.network('http://openweathermap.org/img/wn/${item.weather.first.icon}.png'),
                  Text('${item.main.temp.round()}°C', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDailyForecast(BuildContext context, List<WeatherCondition> dailyForecast) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: dailyForecast.length > 5 ? 5 : dailyForecast.length,
      itemBuilder: (context, index) {
        final item = dailyForecast[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          child: ListTile(
            leading: Image.network('http://openweathermap.org/img/wn/${item.weather.first.icon}.png'),
            title: Text(DateFormat.EEEE().format(DateTime.parse(item.dtTxt)), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            trailing: Text('${item.main.tempMax.round()}°C / ${item.main.tempMin.round()}°C', style: Theme.of(context).textTheme.titleMedium),
          ),
        );
      },
    );
  }
}
