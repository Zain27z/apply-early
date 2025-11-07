import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_alert.dart';

class SavedAlertsService {
  static const _key = "saved_alerts";

  Future<List<SavedAlert>> loadAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return [];
    List decoded = json.decode(jsonString);
    return decoded.map((e) => SavedAlert.fromJson(e)).toList();
  }

  Future<void> saveAlert(SavedAlert alert) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadAlerts();
    existing.add(alert);
    final encoded = json.encode(existing.map((e) => e.toJson()).toList());
    await prefs.setString(_key, encoded);
  }
}
