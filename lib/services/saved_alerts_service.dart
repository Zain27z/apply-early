import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_alert.dart';
import 'dart:convert';

class SavedAlertsService {
  static const String _key = "saved_alerts";

  /// Save a new alert
  Future<void> saveAlert(SavedAlert alert) async {
    final prefs = await SharedPreferences.getInstance();
    final alerts = await getAlerts();
    // prevent duplicates
    if (!alerts.any((a) => a.query == alert.query && a.location == alert.location && a.timeFilter == alert.timeFilter)) {
      alerts.add(alert);
      final encoded = jsonEncode(alerts.map((a) => a.toJson()).toList());
      await prefs.setString(_key, encoded);
    }
  }

  /// Get all saved alerts
  Future<List<SavedAlert>> getAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return [];
    final decoded = jsonDecode(jsonString) as List<dynamic>;
    return decoded.map((e) => SavedAlert.fromJson(e)).toList();
  }

  /// Delete an alert
  Future<void> deleteAlert(SavedAlert alert) async {
    final prefs = await SharedPreferences.getInstance();
    final alerts = await getAlerts();
    alerts.removeWhere((a) =>
        a.query == alert.query &&
        a.location == alert.location &&
        a.timeFilter == alert.timeFilter);
    final encoded = jsonEncode(alerts.map((a) => a.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  /// Clear all alerts (optional helper)
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
