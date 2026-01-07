import 'package:flutter/material.dart';
import '../models/logger_alert.dart';
import '../models/app_features.dart';
import 'logger_graph_screen.dart';

class ClusterDetailsPage extends StatelessWidget {
  final String clusterName;
  final List<LoggerAlert> alerts;
  final UserProfile user; 

  const ClusterDetailsPage({
    super.key,
    required this.clusterName,
    required this.alerts,
    required this.user, 
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(clusterName)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: alerts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final alert = alerts[index];
          final isEmergency = alert.minutesInAlert > 0;

          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isEmergency ? const BorderSide(color: Colors.red) : BorderSide.none,
            ),
            child: ListTile(
              leading: Icon(Icons.thermostat, color: isEmergency ? Colors.red : Colors.green),
              title: Text("Serial: ${alert.serial}"),
              // 🟢 UPDATED: Show Probe and Ambient clearly
              subtitle: Text(
                "Probe: ${alert.temperature}°C  (Amb: ${alert.ambientTemp}°C)\n${isEmergency ? "CRITICAL" : "Normal"}",
                style: TextStyle(color: isEmergency ? Colors.red : Colors.grey[700]),
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LoggerGraphScreen(
                      logger: alert, 
                      user: user 
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}