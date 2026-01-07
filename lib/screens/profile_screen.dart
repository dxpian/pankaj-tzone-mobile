import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/sync_engine.dart';
import '../models/app_features.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    const storage = FlutterSecureStorage();
    await storage.deleteAll(); // Clear session

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<SyncEngine>(context).user;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue.shade100,
              child: Text(user.username[0], style: TextStyle(fontSize: 32, color: Colors.blue.shade800)),
            ),
            const SizedBox(height: 10),
            Text(user.username, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text("ID: ${user.userId}", style: const TextStyle(color: Colors.grey)),
            
            const SizedBox(height: 30),
            
            // Subscriptions Card (Modular Proof)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Active Subscriptions", 
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(),
                  _buildModuleRow("Basic Alerts (Module A)", user.hasAccess(AppModule.basicAlerts)),
                  _buildModuleRow("Analytics Graphs (Module B)", user.hasAccess(AppModule.graphData)),
                  _buildModuleRow("GPS Tracking (Module C)", user.hasAccess(AppModule.locationMap)),
                  _buildModuleRow("Cluster View (Module D)", user.hasAccess(AppModule.checkPoints)),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text("Logout", style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: const BorderSide(color: Colors.red),
                ),
                onPressed: () => _logout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleRow(String name, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(isActive ? Icons.check_circle : Icons.lock, 
               color: isActive ? Colors.green : Colors.grey, size: 20),
          const SizedBox(width: 10),
          Text(name, style: TextStyle(
            color: isActive ? Colors.black87 : Colors.grey,
            decoration: isActive ? null : TextDecoration.lineThrough,
          )),
        ],
      ),
    );
  }
}