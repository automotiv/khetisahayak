import 'package:flutter/material.dart';
import 'package:kheti_sahayak_app/models/notification_item.dart';
import 'package:kheti_sahayak_app/services/notification_service.dart';
import 'package:intl/intl.dart';
import 'package:kheti_sahayak_app/services/language_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final notifications = await NotificationService.getNotifications();
    if (mounted) {
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(int id) async {
    final success = await NotificationService.markAsRead(id);
    if (success) {
      setState(() {
        // Optimistically update UI
        // In a real app, we might want to re-fetch or update the local list
        _loadNotifications(); 
      });
    }
  }

  Future<void> _markAllAsRead() async {
    final success = await NotificationService.markAllAsRead();
    if (success) {
      _loadNotifications();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context).success}: All marked as read')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.notifications),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read', // Add to translations
            onPressed: _notifications.isNotEmpty ? _markAllAsRead : null,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(localizations.noData, style: const TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final item = _notifications[index];
                      return Card(
                        color: item.isRead ? Colors.white : Colors.green[50],
                        child: ListTile(
                          leading: _getIconForType(item.type),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(item.message),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(item.createdAt, localizations),
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          onTap: !item.isRead ? () => _markAsRead(item.id) : null,
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Icon _getIconForType(String type) {
    switch (type) {
      case 'warning':
        return const Icon(Icons.warning, color: Colors.orange);
      case 'error':
        return const Icon(Icons.error, color: Colors.red);
      case 'success':
        return const Icon(Icons.check_circle, color: Colors.green);
      default:
        return const Icon(Icons.info, color: Colors.blue);
    }
  }

  String _formatDate(String dateStr, AppLocalizations localizations) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return DateFormat.jm(localizations.locale.toString()).format(date);
      } else if (difference.inDays < 7) {
        return DateFormat.E(localizations.locale.toString()).add_jm().format(date);
      } else {
        return DateFormat.yMMMd(localizations.locale.toString()).format(date);
      }
    } catch (e) {
      return dateStr;
    }
  }
}
