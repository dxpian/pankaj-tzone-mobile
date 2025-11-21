import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
import '../models/logger_alert.dart';
import '../models/cluster_definitions.dart';
import 'cluster_details_page.dart';

class ClusterDashboardScreen extends StatelessWidget {
  const ClusterDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEEE, MMM d').format(DateTime.now());

    // STATIC SAMPLE SUMMARY DATA
    const activeLoggers = 128;
    const inactiveLoggers = 12;
    const emergencyLoggers = 4;

    // STATIC SAMPLE ALERTS — NOW INCLUDING LAT/LNG + clusterName
    final sampleAlerts = <LoggerAlert>[
      LoggerAlert(
        serial: "190123000001",
        temperature: 11.2,
        minutesInAlert: 14,
        latitude: 35.8617,
        longitude: 139.6452,
        clusterName: "Saitama Logistic Center",
      ),
      LoggerAlert(
        serial: "190123000011",
        temperature: 9.0,
        minutesInAlert: 6,
        latitude: 35.7081,
        longitude: 139.6625,
        clusterName: "Suginami Branch",
      ),
      LoggerAlert(
        serial: "190123000150",
        temperature: 12.5,
        minutesInAlert: 26,
        latitude: 35.7128,
        longitude: 139.7310,
        clusterName: "Bunkyo Pharmaceutical Center",
      ),
    ];

    // FILTER SAMPLE ALERTS → cluster groups
    final clustersWithAlerts = <Map<String, dynamic>>[];
    for (var cluster in clusters) {
      final alerts = sampleAlerts
          .where((a) => cluster.loggers.contains(a.serial))
          .toList();
      if (alerts.isNotEmpty) {
        clustersWithAlerts.add({
          "name": cluster.name,
          "alerts": alerts,
        });
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Image.asset('assets/images/alfresa_logo.png', height: 36),
              ]),
              const SizedBox(height: 18),

              const Text("Welcome back, Subhanshu.",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
              Text(formattedDate,
                  style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 18),

              Row(
                children: [
                  _statBox("Active Loggers", activeLoggers, Colors.green.shade600),
                  const SizedBox(width: 10),
                  _statBox("Inactive", inactiveLoggers, Colors.grey.shade600),
                  const SizedBox(width: 10),
                  _statBox("Emergency", emergencyLoggers, Colors.red.shade700),
                ],
              ),

              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Total Loggers (Nationwide)",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Text("Total: 256"),
                    Text("Min Temp: -42.5°C"),
                    Text("Max Temp: 12.6°C"),
                    Text("Avg Temp: 4.8°C"),
                  ],
                ),
              ),

              const SizedBox(height: 18),
              const Text("Cluster Alerts",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),

              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.only(bottom: 8),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: clustersWithAlerts.length,
                  itemBuilder: (context, index) {
                    final cluster = clustersWithAlerts[index];
                    final alerts = cluster["alerts"] as List<LoggerAlert>;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ClusterDetailsPage(
                              clusterName: cluster["name"],
                              alerts: alerts,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFFFC1C1), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(cluster["name"],
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 11)),

                            Column(
                              children: [
                                Text("${alerts.length}",
                                    style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 20)),
                                const SizedBox(height: 2),
                                const Text("Alerts",
                                    style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statBox(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Text("$count",
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
