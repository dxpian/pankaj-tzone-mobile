import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sync_engine.dart';
import 'logger_graph_screen.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final syncEngine = Provider.of<SyncEngine>(context);
    final alerts = syncEngine.alerts;
    final user = syncEngine.user; // 🟢 Grab User

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Logger"),
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: alerts.isEmpty
          ? const Center(child: Text("No Loggers Found"))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final device = alerts[index];
                final isCritical = device.minutesInAlert > 0;

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isCritical ? const BorderSide(color: Colors.red) : BorderSide.none,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCritical ? Colors.red.shade100 : Colors.blue.shade100,
                      child: Icon(Icons.analytics, color: isCritical ? Colors.red : Colors.blue),
                    ),
                    title: Text("Logger: ${device.serial}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(device.clusterName),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LoggerGraphScreen(
                            logger: device, 
                            user: user // 🟢 PASS USER
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