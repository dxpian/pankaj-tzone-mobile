import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sync_engine.dart';
import '../models/app_features.dart';
import '../models/logger_alert.dart';
import 'cluster_details_page.dart';
import 'logger_graph_screen.dart';

class ClusterDashboardScreen extends StatelessWidget {
  const ClusterDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final syncEngine = Provider.of<SyncEngine>(context);
    final user = syncEngine.user;
    final alerts = syncEngine.alerts;
    final bool useClusters = user.hasAccess(AppModule.checkPoints);

    String lastUpdateStr = "";
    if (alerts.isNotEmpty) {
      try {
        lastUpdateStr = alerts.first.lastUpdated.split(' ')[1];
      } catch (e) {
        lastUpdateStr = "Just now";
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Image.asset('assets/images/alfresa_logo.png', height: 32),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: () => syncEngine.syncData(),
          )
        ],
      ),
      body: Column(
        children: [
          if (syncEngine.isLoading && alerts.isNotEmpty)
            const LinearProgressIndicator(minHeight: 3, backgroundColor: Colors.transparent),

          Expanded(
            child: (syncEngine.isLoading && alerts.isEmpty)
                ? const Center(child: CircularProgressIndicator()) 
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Welcome, ${user.username}",
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            if (lastUpdateStr.isNotEmpty)
                              Text("Updated: $lastUpdateStr", 
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        
                        _buildSummaryRow(alerts),
                        const SizedBox(height: 20),

                        Text(useClusters ? "Cluster Status" : "All Loggers",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),

                        Expanded(
                          child: useClusters
                              ? _buildClusterGrid(context, alerts, user)
                              : _buildFlatList(context, alerts, user),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(List<LoggerAlert> alerts) {
    int emergency = alerts.where((a) => a.minutesInAlert > 0).length;
    int active = alerts.length;
    
    return Row(
      children: [
        _statBox("Monitoring", active, Colors.green),
        const SizedBox(width: 10),
        _statBox("Alerts", emergency, Colors.red),
      ],
    );
  }

  Widget _statBox(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            Text("$count", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildClusterGrid(BuildContext context, List<LoggerAlert> alerts, UserProfile user) {
    final Map<String, List<LoggerAlert>> groups = {};
    for (var a in alerts) {
      if (!groups.containsKey(a.clusterName)) groups[a.clusterName] = [];
      groups[a.clusterName]!.add(a);
    }
    final keys = groups.keys.toList();

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.2),
      itemCount: keys.length,
      itemBuilder: (ctx, i) {
        final name = keys[i];
        final clusterAlerts = groups[name]!;
        final alertCount = clusterAlerts.where((a) => a.minutesInAlert > 0).length;

        return InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => ClusterDetailsPage(
                clusterName: name, 
                alerts: clusterAlerts,
                user: user, 
              )
            ));
          },
          child: Container(
            decoration: BoxDecoration(
              color: alertCount > 0 ? Colors.red.shade50 : Colors.white,
              border: Border.all(color: alertCount > 0 ? Colors.red.shade200 : Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 5),
                Text("$alertCount Issues", style: TextStyle(color: alertCount > 0 ? Colors.red : Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFlatList(BuildContext context, List<LoggerAlert> alerts, UserProfile user) {
    return ListView.builder(
      itemCount: alerts.length,
      itemBuilder: (ctx, i) {
        final alert = alerts[i];
        final isAlert = alert.minutesInAlert > 0;
        return Card(
          child: ListTile(
            leading: Icon(Icons.thermostat, color: isAlert ? Colors.red : Colors.green),
            title: Text("Logger: ${alert.serial}"),
            // 🟢 UPDATED UI: "Probe: X | Amb: Y"
            subtitle: Text("Probe: ${alert.temperature}°C | Amb: ${alert.ambientTemp}°C"),
            trailing: isAlert ? const Icon(Icons.warning, color: Colors.red) : null,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => LoggerGraphScreen(
                  logger: alert, 
                  user: user,
                )
              ));
            },
          ),
        );
      },
    );
  }
}