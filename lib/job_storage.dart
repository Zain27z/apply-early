import 'package:shared_preferences/shared_preferences.dart';

class JobStorage {
  // Namespaces saved IDs by query (so "plumber" has its own set).
  static String _keyFor(String query) =>
      'saved_job_ids_${query.trim().toLowerCase().isEmpty ? 'all' : query.trim().toLowerCase()}';

  static Future<Set<String>> getSavedJobIds(String query) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyFor(query))?.toSet() ?? {};
  }

  static Future<void> saveJobIds(String query, Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyFor(query), ids.toList());
  }
}
