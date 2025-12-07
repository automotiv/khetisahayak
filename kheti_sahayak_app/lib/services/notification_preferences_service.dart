import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferencesService with ChangeNotifier {
  static const String _weatherAlertsKey = 'pref_weather_alerts';
  static const String _schemeUpdatesKey = 'pref_scheme_updates';
  static const String _marketplaceUpdatesKey = 'pref_marketplace_updates';
  static const String _expertMessagesKey = 'pref_expert_messages';
  static const String _forumRepliesKey = 'pref_forum_replies';
  static const String _logbookRemindersKey = 'pref_logbook_reminders';

  bool _weatherAlerts = true;
  bool _schemeUpdates = true;
  bool _marketplaceUpdates = true;
  bool _expertMessages = true;
  bool _forumReplies = false;
  bool _logbookReminders = true;

  bool get weatherAlerts => _weatherAlerts;
  bool get schemeUpdates => _schemeUpdates;
  bool get marketplaceUpdates => _marketplaceUpdates;
  bool get expertMessages => _expertMessages;
  bool get forumReplies => _forumReplies;
  bool get logbookReminders => _logbookReminders;

  NotificationPreferencesService() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _weatherAlerts = prefs.getBool(_weatherAlertsKey) ?? true;
    _schemeUpdates = prefs.getBool(_schemeUpdatesKey) ?? true;
    _marketplaceUpdates = prefs.getBool(_marketplaceUpdatesKey) ?? true;
    _expertMessages = prefs.getBool(_expertMessagesKey) ?? true;
    _forumReplies = prefs.getBool(_forumRepliesKey) ?? false;
    _logbookReminders = prefs.getBool(_logbookRemindersKey) ?? true;
    notifyListeners();
  }

  Future<void> setWeatherAlerts(bool value) async {
    _weatherAlerts = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_weatherAlertsKey, value);
    notifyListeners();
  }

  Future<void> setSchemeUpdates(bool value) async {
    _schemeUpdates = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_schemeUpdatesKey, value);
    notifyListeners();
  }

  Future<void> setMarketplaceUpdates(bool value) async {
    _marketplaceUpdates = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_marketplaceUpdatesKey, value);
    notifyListeners();
  }

  Future<void> setExpertMessages(bool value) async {
    _expertMessages = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_expertMessagesKey, value);
    notifyListeners();
  }

  Future<void> setForumReplies(bool value) async {
    _forumReplies = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_forumRepliesKey, value);
    notifyListeners();
  }

  Future<void> setLogbookReminders(bool value) async {
    _logbookReminders = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_logbookRemindersKey, value);
    notifyListeners();
  }
}
