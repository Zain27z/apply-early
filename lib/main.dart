import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';

import 'job_service.dart';
import 'job_storage.dart';
import 'models/saved_alert.dart';
import 'services/saved_alerts_service.dart';
import 'saved_alerts_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('ic_stat_notify');
  const InitializationSettings initSettings =
      InitializationSettings(android: androidInit);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  final androidPlugin =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  await androidPlugin?.requestNotificationsPermission();

  runApp(const ApplyFirst());
}

class ApplyFirst extends StatelessWidget {
  const ApplyFirst({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "ApplyEarly",
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        brightness: Brightness.light,
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF9FAFF),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0E111A),
      ),
      home: const JobApp(),
    );
  }
}

class JobApp extends StatefulWidget {
  const JobApp({super.key});
  @override
  State<JobApp> createState() => _JobAppState();
}

class _JobAppState extends State<JobApp> {
  final TextEditingController _searchCtrl = TextEditingController(text: '');

  String _selectedCountry = 'us';
  String _dateFilter = 'all';

  List<Job> _jobs = [];
  bool _loading = false;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _runJobCheck();
    _timer = Timer.periodic(const Duration(minutes: 5), (_) => _runJobCheck());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _runJobCheck() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final query = _searchCtrl.text.trim();

    try {
      final fetched = await JobService.fetchJobs(
        query: query,
        country: _selectedCountry,
        perPage: 25,
      );

      final now = DateTime.now();
      List<Job> filtered = fetched.where((j) {
        if (_dateFilter == 'all' || j.created == null) return true;
        final diff = now.difference(j.created!);
        switch (_dateFilter) {
          case '1d':
            return diff.inHours <= 24;
          case '3d':
            return diff.inDays <= 3;
          case '7d':
            return diff.inDays <= 7;
        }
        return true;
      }).toList();

      final savedIds = await JobStorage.getSavedJobIds(query);
      final newOnes = filtered.where((j) => !savedIds.contains(j.id)).toList();

      if (newOnes.isNotEmpty && savedIds.isNotEmpty) {
        await flutterLocalNotificationsPlugin.show(
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          "New ${query.isEmpty ? 'jobs' : '"$query" jobs'}",
          "${newOnes.length} new in ${_selectedCountry.toUpperCase()}",
          const NotificationDetails(
            android: AndroidNotificationDetails(
              "job_channel",
              "Job Alerts",
              importance: Importance.max,
              priority: Priority.high,
              icon: 'ic_stat_notify',
            ),
          ),
        );
      }

      final updatedIds = {...savedIds, ...filtered.map((j) => j.id)};
      await JobStorage.saveJobIds(query, updatedIds);

      setState(() {
        _jobs = filtered;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = "Error loading jobs";
      });
    }
  }

  Future<void> _openJob(Job job) async {
    final uri = Uri.tryParse(job.url);
    if (uri == null) return;

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _saveAlert() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a job title before saving.")),
      );
      return;
    }

    final alert = SavedAlert(
      query: query,
      location: _selectedCountry,
      timeFilter: _dateFilter,
    );

    await SavedAlertsService().saveAlert(alert);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Alert saved for \"$query\" ✅"),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _gradientButton(VoidCallback onTap, String label) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF8B5CF6)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchCtrl,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _runJobCheck(),
            decoration: InputDecoration(
              hintText: 'Search “software engineer”, “cashier”…',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceVariant,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 10),
        _gradientButton(_runJobCheck, "Search"),
      ],
    );
  }

  Widget _buildFilters() {
    InputDecoration deco(String label) => InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        );

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField(
            value: _selectedCountry,
            decoration: deco("Country"),
            items: const [
              DropdownMenuItem(value: 'us', child: Text("🇺🇸 USA")),
              DropdownMenuItem(value: 'ca', child: Text("🇨🇦 Canada")),
              DropdownMenuItem(value: 'uk', child: Text("🇬🇧 UK")),
              DropdownMenuItem(value: 'au', child: Text("🇦🇺 Australia")),
              DropdownMenuItem(value: 'ie', child: Text("🇮🇪 Ireland")),
              DropdownMenuItem(value: 'nz', child: Text("🇳🇿 NZ")),
            ],
            onChanged: (v) {
              setState(() => _selectedCountry = v!);
              _runJobCheck();
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField(
            value: _dateFilter,
            decoration: deco("Posted"),
            items: const [
              DropdownMenuItem(value: 'all', child: Text("Any time")),
              DropdownMenuItem(value: '1d', child: Text("Last 24h")),
              DropdownMenuItem(value: '3d', child: Text("Last 3 days")),
              DropdownMenuItem(value: '7d', child: Text("Last 7 days")),
            ],
            onChanged: (v) {
              setState(() => _dateFilter = v!);
              _runJobCheck();
            },
          ),
        ),
      ],
    );
  }

  Widget _jobCard(Job j) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _openJob(j),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(j.title,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 5),
            Text(
              "${j.company} — ${j.location}",
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.public,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 4),
                Text(j.country.toUpperCase()),
                const Spacer(),
                Text(
                  j.created != null
                      ? j.created!.toIso8601String().substring(0, 10)
                      : "New",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Apply Early"),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: "Saved Alerts",
            onPressed: () async {
              final alert = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavedAlertsScreen()),
              );
              if (alert != null && alert is SavedAlert) {
                setState(() {
                  _searchCtrl.text = alert.query;
                  _selectedCountry = alert.location;
                  _dateFilter = alert.timeFilter;
                });
                _runJobCheck();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              _buildSearchBar(),
              const SizedBox(height: 12),
              _buildFilters(),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _gradientButton(_saveAlert, "Save Alert")),
                ],
              ),
              const SizedBox(height: 10),
              if (_loading) const LinearProgressIndicator(),
              Expanded(
                child: _jobs.isEmpty && !_loading
                    ? const Center(child: Text("No jobs found"))
                    : RefreshIndicator(
                        onRefresh: _runJobCheck,
                        child: ListView.builder(
                          itemCount: _jobs.length,
                          itemBuilder: (_, i) => _jobCard(_jobs[i]),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
