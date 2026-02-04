import 'package:flutter/material.dart';
import '../models/logger_alert.dart';
import '../models/app_features.dart';
import 'logger_graph_screen.dart';

class ClusterDetailsPage extends StatelessWidget {
  final String clusterName;
  final List<LoggerAlert> alerts; // The full list passed from Dashboard
  final UserProfile user;

  const ClusterDetailsPage({
    super.key, 
    required this.clusterName, 
    required this.alerts, 
    required this.user
  });

  @override
  Widget build(BuildContext context) {
    // 🟢 FILTER LOGIC:
    // Only show loggers that have an active alert (Temp OR Battery).
    // The SyncEngine sets 'minutesInAlert > 0' for both cases.
    final List<LoggerAlert> criticalLoggers = alerts
        .where((logger) => logger.minutesInAlert > 0)
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(clusterName, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue, // Matching your screenshot header
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: criticalLoggers.isEmpty
          ? _buildEmptyState() // Show "All Clear" if list is empty
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: criticalLoggers.length,
              itemBuilder: (ctx, i) {
                return _buildLoggerCard(context, criticalLoggers[i]);
              },
            ),
    );
  }

  Widget _buildLoggerCard(BuildContext context, LoggerAlert alert) {
    // Logic for Subtitle (Probe vs Ambient)
    String subText;
    if (alert.isProbeActive) {
      subText = "Probe: ${alert.temperature}°C";
      if (alert.showAmbient) subText += " | Amb: ${alert.ambientTemp}°C";
    } else {
      subText = "Ambient: ${alert.temperature}°C";
    }

    // Since we only show critical items here, the styling is always "Red/Warning"
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100), // Subtle red border
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.05), 
            blurRadius: 10, 
            offset: const Offset(0, 4)
          )
        ]
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.warning_amber_rounded, color: Colors.red),
        ),
        title: Text(
          "Serial: ${alert.serial}", 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(subText, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              "CRITICAL ALERT", 
              style: TextStyle(color: Colors.red.shade700, fontSize: 10, fontWeight: FontWeight.bold)
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => LoggerGraphScreen(logger: alert, user: user)
          ));
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.green.shade300),
          const SizedBox(height: 20),
          Text(
            "All Systems Normal",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 10),
          Text(
            "No active alarms in $clusterName",
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}