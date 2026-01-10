import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kheti_sahayak_app/models/weather_alert.dart';
import 'package:kheti_sahayak_app/services/weather_alert_service.dart';
import 'package:kheti_sahayak_app/widgets/weather/alert_card.dart';
import 'package:kheti_sahayak_app/utils/logger.dart';

/// Weather Alerts Screen
///
/// Displays active weather alerts, subscription management,
/// and alert type preferences.
class WeatherAlertsScreen extends StatefulWidget {
  const WeatherAlertsScreen({super.key});

  @override
  State<WeatherAlertsScreen> createState() => _WeatherAlertsScreenState();
}

class _WeatherAlertsScreenState extends State<WeatherAlertsScreen>
    with SingleTickerProviderStateMixin {
  List<WeatherAlert> _alerts = [];
  bool _isLoading = true;
  bool _isSubscribed = false;
  List<String> _subscribedTypes = [];
  String? _errorMessage;
  Position? _currentPosition;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _loadSubscriptionStatus();
    await _loadAlerts();
  }

  Future<void> _loadSubscriptionStatus() async {
    try {
      final isSubscribed = await WeatherAlertService.isSubscribed();
      final subscribedTypes = await WeatherAlertService.getSubscribedAlertTypes();
      
      if (mounted) {
        setState(() {
          _isSubscribed = isSubscribed;
          _subscribedTypes = subscribedTypes;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading subscription status', e);
    }
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _currentPosition = await _determinePosition();
      
      final alerts = await WeatherAlertService.getActiveAlerts(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      if (mounted) {
        setState(() {
          _alerts = alerts;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading alerts', e);
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _toggleSubscription() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to get current location')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isSubscribed) {
        await WeatherAlertService.unsubscribeFromAlerts();
      } else {
        await WeatherAlertService.subscribeToAlerts(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          _subscribedTypes.isEmpty ? AlertType.all : _subscribedTypes,
        );
      }

      await _loadSubscriptionStatus();
      
      if (mounted) {
        final snackBarContext = context;
        ScaffoldMessenger.of(snackBarContext).showSnackBar(
          SnackBar(
            content: Text(
              _isSubscribed
                  ? 'Subscribed to weather alerts'
                  : 'Unsubscribed from weather alerts',
            ),
            backgroundColor: _isSubscribed ? Colors.green : Colors.grey,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Error toggling subscription', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateAlertTypes(List<String> types) async {
    if (_currentPosition == null) return;

    try {
      await WeatherAlertService.subscribeToAlerts(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        types,
      );

      if (mounted) {
        setState(() {
          _subscribedTypes = types;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alert preferences updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Error updating alert types', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Alerts'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Active Alerts', icon: Icon(Icons.warning_amber)),
            Tab(text: 'Settings', icon: Icon(Icons.settings)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadAlerts,
            tooltip: 'Refresh alerts',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAlertsTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildAlertsTab() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading weather alerts...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Unable to load alerts',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadAlerts,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_alerts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, size: 80, color: Colors.green[400]),
              const SizedBox(height: 24),
              Text(
                'No Active Alerts',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Weather conditions are favorable in your area.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: _loadAlerts,
                icon: const Icon(Icons.refresh),
                label: const Text('Check Again'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAlerts,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _alerts.length + 1, // +1 for header
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildAlertsHeader();
          }
          return AlertCard(
            alert: _alerts[index - 1],
            showAnimation: true,
          );
        },
      ),
    );
  }

  Widget _buildAlertsHeader() {
    final severeCount = _alerts.where((a) => a.severityLevel >= 3).length;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: severeCount > 0
                  ? const Color(0xFFDC2626).withOpacity(0.1)
                  : const Color(0xFFF97316).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.notifications_active,
              color: severeCount > 0
                  ? const Color(0xFFDC2626)
                  : const Color(0xFFF97316),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_alerts.length} Active Alert${_alerts.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (severeCount > 0)
                  Text(
                    '$severeCount require immediate attention',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subscription Toggle Card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isSubscribed
                              ? Colors.green.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _isSubscribed
                              ? Icons.notifications_active
                              : Icons.notifications_off,
                          color: _isSubscribed ? Colors.green : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Alert Notifications',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _isSubscribed
                                  ? 'You will receive push notifications'
                                  : 'Enable to get weather alerts',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isSubscribed,
                        onChanged: (_) => _toggleSubscription(),
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Alert Types Section
          Text(
            'Alert Types',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the types of weather alerts you want to receive',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          
          // Alert Type Checkboxes
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: AlertType.all.map((type) {
                return _buildAlertTypeCheckbox(type);
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Weather alerts are checked every 30 minutes in the background to keep you informed about severe weather conditions.',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertTypeCheckbox(String type) {
    final isSelected = _subscribedTypes.contains(type);
    final icon = _getAlertTypeIcon(type);
    final color = _getAlertTypeColor(type);

    return InkWell(
      onTap: () {
        final newTypes = List<String>.from(_subscribedTypes);
        if (isSelected) {
          newTypes.remove(type);
        } else {
          newTypes.add(type);
        }
        _updateAlertTypes(newTypes);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                AlertType.getDisplayName(type),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Checkbox(
              value: isSelected,
              onChanged: (value) {
                final newTypes = List<String>.from(_subscribedTypes);
                if (value == true) {
                  newTypes.add(type);
                } else {
                  newTypes.remove(type);
                }
                _updateAlertTypes(newTypes);
              },
              activeColor: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAlertTypeIcon(String type) {
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
        return Icons.warning;
    }
  }

  Color _getAlertTypeColor(String type) {
    switch (type) {
      case 'heat_wave':
        return const Color(0xFFDC2626);
      case 'heavy_rain':
        return const Color(0xFF3B82F6);
      case 'frost':
        return const Color(0xFF06B6D4);
      case 'storm':
        return const Color(0xFF8B5CF6);
      case 'drought':
        return const Color(0xFFF97316);
      case 'flood':
        return const Color(0xFF0891B2);
      case 'hailstorm':
        return const Color(0xFF6B7280);
      case 'strong_wind':
        return const Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }
}
