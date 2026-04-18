import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../services/sync_engine.dart';
import '../models/logger_alert.dart';
import 'logger_graph_screen.dart';
import '../models/app_features.dart'; 

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  String? _mapStyle;
  LoggerAlert? _selectedAlert;

  @override
  void initState() {
    super.initState();
    rootBundle.loadString('assets/map_style.json').then((string) {
      _mapStyle = string;
    }).catchError((e) => null); 
  }

  @override
  Widget build(BuildContext context) {
    final syncEngine = Provider.of<SyncEngine>(context);
    final alerts = syncEngine.alerts;
    final user = syncEngine.user; 

    final validMarkers = alerts
        .where((a) => a.latitude != 0.0 && a.longitude != 0.0)
        .toList();

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(35.6895, 139.6917), 
              zoom: 13,
            ),
            markers: validMarkers.map((alert) {
              final isEmergency = alert.minutesInAlert > 0;
              return Marker(
                markerId: MarkerId(alert.serial),
                position: LatLng(alert.latitude, alert.longitude),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  isEmergency ? BitmapDescriptor.hueRed : BitmapDescriptor.hueAzure
                ),
                onTap: () {
                  setState(() => _selectedAlert = alert);
                }
              );
            }).toSet(),
            onMapCreated: (controller) {
              _mapController = controller;
              if (_mapStyle != null) _mapController!.setMapStyle(_mapStyle);
            },
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            padding: const EdgeInsets.only(bottom: 200),
          ),

          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search Logger or Branch...",
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  suffixIcon: IconButton(
                     icon: const Icon(Icons.refresh, color: Colors.blueAccent),
                     onPressed: () => syncEngine.syncData(),
                  ),
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 240,
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, 5))
                ],
              ),
              child: _selectedAlert == null 
                ? _buildEmptyState()
                : _buildLoggerDetails(context, _selectedAlert!, user), 
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.map_outlined, size: 48, color: Colors.grey.shade300),
        const SizedBox(height: 10),
        const Text("Select a logger on the map", 
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildLoggerDetails(BuildContext context, LoggerAlert alert, UserProfile user) {
    final isEmergency = alert.minutesInAlert > 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: Container(width: 40, height: 4, 
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 15),
        
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isEmergency ? Colors.red.shade50 : Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.thermostat, color: isEmergency ? Colors.red : Colors.blue),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.clusterName, 
                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                Text("Logger #${alert.serial}", 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                // 🟢 UPDATED UI: Explicit "Probe" label
                Text("Probe: ${alert.temperature}°C", 
                    style: const TextStyle(fontSize: 14, color: Colors.black87)),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isEmergency ? Colors.red : Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(isEmergency ? "ALERT" : "NORMAL", 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),

        const Spacer(),
        
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(
                 builder: (_) => LoggerGraphScreen(
                   logger: alert, 
                   user: user 
                 )
               ));
            },
            child: const Text("View Analytics", 
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        )
      ],
    );
  }
}