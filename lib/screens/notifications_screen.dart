import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/logger_alert.dart';
import '../models/cluster_definitions.dart';
import 'logger_graph_screen.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  // ❗ TEMP STATIC — Replace with API later
  List<LoggerAlert> get activeAlerts => [
        LoggerAlert(
            serial: "190123000001",
            temperature: 12.5,
            minutesInAlert: 26,
            latitude: 35.8617,
            longitude: 139.6452), // Saitama Approx
        LoggerAlert(
            serial: "190123000150",
            temperature: 10.2,
            minutesInAlert: 14,
            latitude: 35.7128,
            longitude: 139.7310), // Tokyo Approx
        LoggerAlert(
            serial: "190123000070",
            temperature: 8.1,
            minutesInAlert: 6,
            latitude: 43.0667,
            longitude: 141.3500), // Sapporo Approx
      ];

  Color _alertColor(int minutes) {
    if (minutes >= 20) return Colors.red;
    if (minutes >= 10) return Colors.orange;
    return Colors.yellow.shade700;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Alert Map")),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: const LatLng(36.2048, 138.2529), // JAPAN CENTER
          initialZoom: 5.3,
          maxZoom: 18,
          minZoom: 3,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'alfresa_alert_app',
          ),

          // --- ALERT MARKERS ---
          MarkerLayer(
            markers: activeAlerts.map((alert) {
              return Marker(
                point: LatLng(alert.latitude, alert.longitude),
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LoggerGraphScreen(logger: alert),
                      ),
                    );
                  },
                  child: Icon(
                    Icons.location_on,
                    color: _alertColor(alert.minutesInAlert),
                    size: 40,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
