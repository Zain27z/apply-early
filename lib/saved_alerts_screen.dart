import 'package:flutter/material.dart';
import 'models/saved_alert.dart';
import 'services/saved_alerts_service.dart';

class SavedAlertsScreen extends StatefulWidget {
  const SavedAlertsScreen({super.key});

  @override
  State<SavedAlertsScreen> createState() => _SavedAlertsScreenState();
}

class _SavedAlertsScreenState extends State<SavedAlertsScreen> {
  List<SavedAlert> _alerts = [];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    final alerts = await SavedAlertsService().getAlerts();
    setState(() => _alerts = alerts);
  }

  Future<void> _deleteAlert(SavedAlert alert) async {
    await SavedAlertsService().deleteAlert(alert);
    await _loadAlerts();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Deleted alert for '${alert.query}'")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Saved Alerts")),
      body: _alerts.isEmpty
          ? const Center(child: Text("No saved alerts yet."))
          : ListView.builder(
              itemCount: _alerts.length,
              itemBuilder: (context, index) {
                final alert = _alerts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(alert.query,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        "${alert.location.toUpperCase()} • ${alert.timeFilter}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _deleteAlert(alert),
                    ),
                    onTap: () {
                      Navigator.pop(context, alert);
                    },
                  ),
                );
              },
            ),
    );
  }
}
