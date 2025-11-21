import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/logger_alert.dart';
import 'logger_graph_screen.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  List<LoggerAlert> get activeAlerts => [
        LoggerAlert(
          serial: "190123000001",
          temperature: 12.5,
          minutesInAlert: 26,
          latitude: 35.8617,
          longitude: 139.6452,
          clusterName: "Saitama Logistic Center",
        ),
        LoggerAlert(
          serial: "190123000150",
          temperature: 10.2,
          minutesInAlert: 14,
          latitude: 35.7128,
          longitude: 139.7310,
          clusterName: "Bunkyo Pharmaceutical Center",
        ),
        LoggerAlert(
          serial: "190123000070",
          temperature: 8.1,
          minutesInAlert: 6,
          latitude: 43.0667,
          longitude: 141.3500,
          clusterName: "Sapporo B",
        ),
      ];

  Color _alertColor(int min) {
    if (min >= 20) return Colors.red;
    if (min >= 10) return Colors.orange;
    return Colors.yellow.shade700;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Alert Map")),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: const LatLng(36.2048, 138.2529),
          initialZoom: 5.3,
        ),
        children: [
          TileLayer(
            urlTemplate:
                "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'alfresa_alert_app',
          ),

          MarkerLayer(
            markers: activeAlerts.map((alert) {
              return Marker(
                width: 40,
                height: 40,
                point: LatLng(alert.latitude, alert.longitude),
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
          )
        ],
      ),
    );
  }
}
