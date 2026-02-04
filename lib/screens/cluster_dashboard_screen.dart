import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sync_engine.dart';
import '../models/app_features.dart';
import '../models/logger_alert.dart';
import '../services/backend_service.dart'; // 🟢 Added Import
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

    // Calculate Timestamp
    String lastUpdateStr = "";
    if (alerts.isNotEmpty) {
      try {
        lastUpdateStr = alerts.first.lastUpdated.split(' ')[1];
      } catch (e) {
        lastUpdateStr = "Just now";
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Slightly off-white for depth
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Image.asset('assets/images/alfresa_logo.png', height: 32),
        centerTitle: false,
        actions: [
          // 🔴 NEW TEST BUTTON START
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined, color: Colors.red),
            tooltip: "Test Local Backend",
            onPressed: () async {
              // 1. Send test signal
              await BackendService.logAlert(
                "TEST-DASHBOARD", 
                25.5,             
                "MANUAL_TEST"     
              );

              // 2. Show confirmation
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Signal Sent! Check Python Terminal."),
                    backgroundColor: Colors.redAccent, 
                    duration: Duration(milliseconds: 1500),
                  ),
                );
              }
            },
          ),
          // 🔴 NEW TEST BUTTON END

          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: () => syncEngine.syncData(),
          )
        ],
      ),
      body: Column(
        children: [
          // 🟢 1. Loading Indicator (Top Line)
          if (syncEngine.isLoading && alerts.isNotEmpty)
            const LinearProgressIndicator(minHeight: 3, backgroundColor: Colors.transparent),

          Expanded(
            child: (syncEngine.isLoading && alerts.isEmpty)
                ? _buildSkeletonLoader() // 🟢 2. NEW: Skeleton Loading State
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Text
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Hello, ${user.username}",
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                Text("System Overview", 
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              ],
                            ),
                            if (lastUpdateStr.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(15)
                                ),
                                child: Text("Updated: $lastUpdateStr", 
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // 🟢 3. NEW: Animated Health Dashboard
                        _buildHealthDashboard(context, alerts),
                        
                        const SizedBox(height: 25),

                        Text(useClusters ? "Cluster Groups" : "Active Loggers",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),

                        // List / Grid
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

  // ---------------------------------------------------------------------------
  // 🟢 NEW: ANIMATED HEALTH WIDGET
  // ---------------------------------------------------------------------------
  Widget _buildHealthDashboard(BuildContext context, List<LoggerAlert> alerts) {
    int total = alerts.length;
    int critical = alerts.where((a) => a.minutesInAlert > 0).length;
    int healthy = total - critical;
    
    // Prevent division by zero
    double healthPercent = total == 0 ? 0 : (healthy / total);

    // Determine Color State
    Color statusColor = Colors.green;
    String statusText = "System Healthy";
    if (healthPercent < 0.9) {
      statusColor = Colors.orange;
      statusText = "Warnings Active";
    }
    if (healthPercent < 0.8 || critical > 0) {
      statusColor = Colors.red;
      statusText = "Action Required";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        children: [
          // Left: Animated Ring
          SizedBox(
            height: 100,
            width: 100,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: healthPercent),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeOutExpo,
              builder: (context, value, _) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: 1.0, // Background Ring
                      valueColor: AlwaysStoppedAnimation(Colors.grey.shade100),
                      strokeWidth: 10,
                    ),
                    CircularProgressIndicator(
                      value: value, // Animated Value
                      valueColor: AlwaysStoppedAnimation(statusColor),
                      strokeWidth: 10,
                      strokeCap: StrokeCap.round,
                    ),
                    Center(
                      child: Text(
                        "${(value * 100).toInt()}%",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: statusColor),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          
          const SizedBox(width: 25),

          // Right: The "Big Numbers"
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 5),
                const Text("Critical / Monitored", style: TextStyle(color: Colors.grey, fontSize: 12)),
                
                // Animated Number Counter for Alerts
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: critical.toDouble()),
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.easeOutExpo,
                      builder: (ctx, val, _) {
                         return Text(
                           val.toInt().toString(), 
                           style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: statusColor)
                         );
                      },
                    ),
                    Text("/$total", style: const TextStyle(fontSize: 20, color: Colors.grey, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 🟢 NEW: SKELETON LOADER (Smooth Loading)
  // ---------------------------------------------------------------------------
  Widget _buildSkeletonLoader() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Header Skeleton
        Container(height: 140, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(24))),
        const SizedBox(height: 30),
        // Title Skeleton
        Container(height: 20, width: 100, color: Colors.grey.shade200),
        const SizedBox(height: 15),
        // List Item Skeletons
        for (int i = 0; i < 5; i++)
          Container(
            height: 80, 
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12))
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // EXISTING: Grid & List Builders
  // ---------------------------------------------------------------------------

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
              border: Border.all(color: alertCount > 0 ? Colors.red.shade200 : Colors.transparent),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 5, offset: const Offset(0, 3))]
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: alertCount > 0 ? Colors.red : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(10)
                  ),
                  child: Text(
                    alertCount > 0 ? "$alertCount Issues" : "Secure", 
                    style: TextStyle(color: alertCount > 0 ? Colors.white : Colors.green.shade800, fontSize: 12, fontWeight: FontWeight.bold)
                  ),
                ),
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
        
        // 🟢 DYNAMIC SUBTITLE LOGIC (PROBE vs AMBIENT)
        String subText;
        if (alert.isProbeActive) {
          // Probe is Main. Show Ambient as secondary if enabled.
          subText = "Probe: ${alert.temperature}°C";
          if (alert.showAmbient) {
            subText += " | Amb: ${alert.ambientTemp}°C";
          }
        } else {
          // Ambient is Main. No secondary needed.
          subText = "Ambient: ${alert.temperature}°C";
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 5, offset: const Offset(0, 2))]
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: isAlert ? Colors.red.shade100 : Colors.green.shade100,
              child: Icon(
                alert.isProbeActive ? Icons.thermostat : Icons.cloud, // Icon matches sensor
                color: isAlert ? Colors.red : Colors.green
              ),
            ),
            title: Text("Logger: ${alert.serial}", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(subText, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            trailing: isAlert 
              ? const Icon(Icons.warning_amber_rounded, color: Colors.red) 
              : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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