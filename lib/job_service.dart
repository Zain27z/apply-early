import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class Job {
  final String id;
  final String title;
  final String company;
  final String location;
  final String url;
  final DateTime? created;
  final String country;

  Job({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.url,
    required this.country,
    this.created,
  });

  factory Job.fromAdzuna(Map<String, dynamic> j, String country) {
    return Job(
      id: (j['id'] ?? '').toString(),
      title: (j['title'] ?? '').toString(),
      company: (j['company']?['display_name'] ?? '').toString(),
      location: (j['location']?['display_name'] ?? '').toString(),
      url: (j['redirect_url'] ?? '').toString(),
      created: j['created'] != null ? DateTime.tryParse(j['created']) : null,
      country: country,
    );
  }
}

class JobService {
  static String get _appId => dotenv.env['ADZUNA_APP_ID'] ?? '';
  static String get _apiKey => dotenv.env['ADZUNA_API_KEY'] ?? '';

  static Future<List<Job>> fetchJobs({
    required String query,
    required String country,
    int perPage = 25,
  }) async {
    if (_appId.isEmpty || _apiKey.isEmpty) {
      debugPrint('❌ Missing Adzuna API keys');
      return [];
    }

    // ✅ Map app country to Adzuna country code
    final countryMap = {
      'us': 'us',
      'ca': 'ca',
      'uk': 'gb', // UK must be "gb"
      'au': 'au',
      'ie': 'ie',
      'nz': 'nz',
    };

    final cc = countryMap[country.toLowerCase()] ?? 'us';

    final uri = Uri.https(
      'api.adzuna.com',
      '/v1/api/jobs/$cc/search/1',
      {
        'app_id': _appId,
        'app_key': _apiKey,
        if (query.isNotEmpty) 'what': query,
        'results_per_page': perPage.toString(),
        'sort_by': 'date',
        'content-type': 'application/json',
      },
    );

    try {
      final res = await http.get(uri);

      if (res.statusCode != 200) {
        debugPrint('⚠️ ${cc.toUpperCase()} API error: ${res.statusCode}');
        return [];
      }

      final data = json.decode(res.body);
      final results = (data['results'] as List? ?? []);

      return results
          .map((e) => Job.fromAdzuna(e as Map<String, dynamic>, cc))
          .toList();
    } catch (e) {
      debugPrint('⚠️ Request failed: $e');
      return [];
    }
  }
}
