import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/weather_model.dart';
import 'package:kheti_sahayak_app/services/weather_service.dart';
import 'package:intl/intl.dart';
import 'package:kheti_sahayak_app/services/language_service.dart';
import 'package:kheti_sahayak_app/services/weather_marketplace_service.dart';
import 'package:kheti_sahayak_app/models/product.dart';
import 'package:kheti_sahayak_app/screens/marketplace/product_detail_screen.dart';

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  final WeatherService _weatherService = WeatherService();
  bool _isLoading = true;
  String? _error;
  UnifiedWeather? _weather;
  String _locationName = 'Loading...';
  List<Product> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    try {
      final data = await _weatherService.getWeatherData();
      final weather = data['forecast'] as UnifiedWeather;
      final recommendations = await WeatherMarketplaceService.getRecommendedProducts(weather);
      
      if (mounted) {
        setState(() {
          _weather = weather;
          _locationName = data['locationName'] as String;
          _recommendations = recommendations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load weather';
          _locationName = 'Unknown Location';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade400, Colors.blue.shade700],
          ),
        ),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final localizations = AppLocalizations.of(context);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_error != null) {
      return Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 32),
          const SizedBox(height: 8),
          Text(
            _error!, // Error messages from service might be in English, consider localizing service errors too
            style: const TextStyle(color: Colors.white),
          ),
          TextButton(
            onPressed: () {
              setState(() => _isLoading = true);
              _loadWeather();
            },
            child: Text(localizations.retry, style: const TextStyle(color: Colors.white)),
          )
        ],
      );
    }

    if (_weather == null) {
      return Text(localizations.noData, style: const TextStyle(color: Colors.white));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _locationName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_weather!.isPrecision)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'PRECISION', // Keep as technical term or add to translations
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                Text(
                  DateFormat.yMMMd(localizations.locale.toString()).format(DateTime.now()),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            // Weather Icon
            const Icon(Icons.wb_sunny, color: Colors.yellow, size: 40),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${_weather!.temp.round()}°',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                _weather!.condition,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildWeatherDetail(Icons.water_drop, '${_weather!.humidity}%'),
            _buildWeatherDetail(Icons.air, '${_weather!.windSpeed} m/s'),
            _buildWeatherDetail(Icons.thermostat, '${_weather!.tempMax.round()}°/${_weather!.tempMin.round()}°'),
          ],
        ),
        if (_weather!.uvi != null || _weather!.rainChance != null) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              if (_weather!.uvi != null)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: _buildWeatherDetail(Icons.wb_sunny_outlined, 'UV: ${_weather!.uvi}'),
                ),
              if (_weather!.rainChance != null)
                _buildWeatherDetail(Icons.umbrella, '${localizations.rainfall}: ${(_weather!.rainChance! * 100).round()}%'),
            ],
          ),
        ],
        if (_recommendations.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Divider(color: Colors.white30),
          const SizedBox(height: 8),
          Text(
            'Recommended for you:', // Add to translations
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _recommendations.length,
              itemBuilder: (context, index) {
                final product = _recommendations[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(product: product),
                      ),
                    );
                  },
                  child: Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            image: product.images.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(product.images.first),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: product.images.isEmpty
                              ? const Icon(Icons.image, size: 20, color: Colors.grey)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '₹${product.price}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWeatherDetail(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }
}
