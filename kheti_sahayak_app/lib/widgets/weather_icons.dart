import 'package:flutter/material.dart';

/// Weather Icons Widget
///
/// Provides weather condition icons based on OpenWeatherMap icon codes and conditions (#380)
class WeatherIcons {
  /// Get icon for weather condition
  /// Supports both OpenWeatherMap icon codes (e.g., '01d', '10n') and condition names
  static IconData getWeatherIcon(String? condition, {String? iconCode}) {
    // First try icon code (more precise)
    if (iconCode != null && iconCode.isNotEmpty) {
      return _getIconFromCode(iconCode);
    }

    // Fall back to condition name
    if (condition == null || condition.isEmpty) {
      return Icons.wb_sunny;
    }

    return _getIconFromCondition(condition.toLowerCase());
  }

  /// Get icon from OpenWeatherMap icon code
  static IconData _getIconFromCode(String code) {
    // Remove day/night suffix for mapping
    final baseCode = code.length >= 2 ? code.substring(0, 2) : code;

    switch (baseCode) {
      case '01': // Clear sky
        return code.endsWith('n') ? Icons.nights_stay : Icons.wb_sunny;
      case '02': // Few clouds
        return code.endsWith('n') ? Icons.nights_stay : Icons.wb_cloudy;
      case '03': // Scattered clouds
        return Icons.cloud;
      case '04': // Broken clouds
        return Icons.cloud_queue;
      case '09': // Shower rain
        return Icons.grain;
      case '10': // Rain
        return Icons.water_drop;
      case '11': // Thunderstorm
        return Icons.flash_on;
      case '13': // Snow
        return Icons.ac_unit;
      case '50': // Mist/fog
        return Icons.blur_on;
      default:
        return Icons.wb_sunny;
    }
  }

  /// Get icon from condition name
  static IconData _getIconFromCondition(String condition) {
    if (condition.contains('clear') || condition.contains('sunny')) {
      return Icons.wb_sunny;
    } else if (condition.contains('cloud') || condition.contains('overcast')) {
      return Icons.cloud;
    } else if (condition.contains('rain') || condition.contains('drizzle')) {
      return Icons.water_drop;
    } else if (condition.contains('thunder') || condition.contains('storm')) {
      return Icons.flash_on;
    } else if (condition.contains('snow') || condition.contains('sleet')) {
      return Icons.ac_unit;
    } else if (condition.contains('fog') || condition.contains('mist') || condition.contains('haze')) {
      return Icons.blur_on;
    } else if (condition.contains('wind')) {
      return Icons.air;
    } else if (condition.contains('partly')) {
      return Icons.wb_cloudy;
    } else if (condition.contains('hot') || condition.contains('heat')) {
      return Icons.whatshot;
    } else if (condition.contains('cold') || condition.contains('freeze')) {
      return Icons.severe_cold;
    } else {
      return Icons.wb_sunny;
    }
  }

  /// Get color for weather condition
  static Color getWeatherColor(String? condition, {String? iconCode}) {
    if (iconCode != null && iconCode.isNotEmpty) {
      return _getColorFromCode(iconCode);
    }

    if (condition == null || condition.isEmpty) {
      return Colors.amber;
    }

    return _getColorFromCondition(condition.toLowerCase());
  }

  static Color _getColorFromCode(String code) {
    final baseCode = code.length >= 2 ? code.substring(0, 2) : code;

    switch (baseCode) {
      case '01': // Clear
        return code.endsWith('n') ? Colors.indigo : Colors.amber;
      case '02': // Few clouds
        return Colors.blue.shade300;
      case '03': // Scattered clouds
      case '04': // Broken clouds
        return Colors.grey;
      case '09': // Shower rain
      case '10': // Rain
        return Colors.blue;
      case '11': // Thunderstorm
        return Colors.purple;
      case '13': // Snow
        return Colors.cyan;
      case '50': // Mist
        return Colors.blueGrey;
      default:
        return Colors.amber;
    }
  }

  static Color _getColorFromCondition(String condition) {
    if (condition.contains('clear') || condition.contains('sunny')) {
      return Colors.amber;
    } else if (condition.contains('cloud')) {
      return Colors.grey;
    } else if (condition.contains('rain') || condition.contains('drizzle')) {
      return Colors.blue;
    } else if (condition.contains('thunder') || condition.contains('storm')) {
      return Colors.purple;
    } else if (condition.contains('snow')) {
      return Colors.cyan;
    } else if (condition.contains('fog') || condition.contains('mist')) {
      return Colors.blueGrey;
    } else if (condition.contains('hot') || condition.contains('heat')) {
      return Colors.deepOrange;
    } else if (condition.contains('cold')) {
      return Colors.lightBlue;
    } else {
      return Colors.amber;
    }
  }
}

/// Weather Icon Widget - displays an animated weather icon
class WeatherIconWidget extends StatelessWidget {
  final String? condition;
  final String? iconCode;
  final double size;
  final Color? color;

  const WeatherIconWidget({
    super.key,
    this.condition,
    this.iconCode,
    this.size = 48,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final icon = WeatherIcons.getWeatherIcon(condition, iconCode: iconCode);
    final iconColor = color ?? WeatherIcons.getWeatherColor(condition, iconCode: iconCode);

    return Icon(
      icon,
      size: size,
      color: iconColor,
    );
  }
}

/// Weather Card Widget - displays weather with icon and details
class WeatherCard extends StatelessWidget {
  final String? condition;
  final String? iconCode;
  final String temperature;
  final String? location;
  final String? humidity;
  final String? windSpeed;
  final VoidCallback? onTap;

  const WeatherCard({
    super.key,
    this.condition,
    this.iconCode,
    required this.temperature,
    this.location,
    this.humidity,
    this.windSpeed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                WeatherIcons.getWeatherColor(condition, iconCode: iconCode).withOpacity(0.3),
                WeatherIcons.getWeatherColor(condition, iconCode: iconCode).withOpacity(0.1),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (location != null)
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: theme.hintColor),
                            const SizedBox(width: 4),
                            Text(
                              location!,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      Text(
                        temperature,
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (condition != null)
                        Text(
                          condition!,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                    ],
                  ),
                  WeatherIconWidget(
                    condition: condition,
                    iconCode: iconCode,
                    size: 72,
                  ),
                ],
              ),
              if (humidity != null || windSpeed != null) ...[
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    if (humidity != null)
                      _buildWeatherDetail(
                        context,
                        Icons.water_drop,
                        'Humidity',
                        humidity!,
                      ),
                    if (windSpeed != null)
                      _buildWeatherDetail(
                        context,
                        Icons.air,
                        'Wind',
                        windSpeed!,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 20, color: theme.hintColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
      ],
    );
  }
}

/// Forecast Day Widget - displays a single day in forecast
class ForecastDayWidget extends StatelessWidget {
  final String day;
  final String? condition;
  final String? iconCode;
  final String tempHigh;
  final String tempLow;

  const ForecastDayWidget({
    super.key,
    required this.day,
    this.condition,
    this.iconCode,
    required this.tempHigh,
    required this.tempLow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          Text(
            day,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          WeatherIconWidget(
            condition: condition,
            iconCode: iconCode,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            tempHigh,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            tempLow,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }
}
