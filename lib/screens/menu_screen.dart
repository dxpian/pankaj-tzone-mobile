import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 🟢 ADDED
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/app_features.dart';
import '../services/sync_engine.dart'; // 🟢 ADDED
import 'device_management_screen.dart';
import 'login_screen.dart';

class MenuScreen extends StatelessWidget {
  final UserProfile user;

  const MenuScreen({super.key, required this.user});

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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Menu", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, 
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildUserHeader(context),
            const Divider(height: 30, thickness: 8, color: Color(0xFFF5F5F5)),
            
            _buildSectionHeader("Device Management"),
            _buildMenuItem(
              context,
              icon: Icons.phonelink_setup,
              title: "Manage Devices",
              subtitle: "Add new loggers or remove old ones",
              onTap: () {
                // 🟢 FIX: We must pass the EXISTING SyncEngine to the new route
                final engine = Provider.of<SyncEngine>(context, listen: false);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangeNotifierProvider.value(
                      value: engine, // Pass the instance explicitly
                      child: const DeviceManagementScreen(),
                    ),
                  ),
                );
              },
            ),

            const Divider(height: 30, thickness: 1),

            _buildSectionHeader("App Settings"),
            _buildMenuItem(
              context,
              icon: Icons.notifications_outlined,
              title: "Notifications",
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Notification Settings Coming Soon")));
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.dark_mode_outlined,
              title: "Appearance",
              trailing: const Text("Light", style: TextStyle(color: Colors.grey)),
              onTap: () {
                 // Future toggle logic
              },
            ),

             const Divider(height: 30, thickness: 1),

            _buildSectionHeader("Information"),
             _buildMenuItem(
              context,
              icon: Icons.info_outline,
              title: "About App",
              subtitle: "Version 1.0.2",
              onTap: () {},
            ),
             _buildMenuItem(
              context,
              icon: Icons.privacy_tip_outlined,
              title: "Privacy Policy",
              onTap: () {},
            ),
            
            const SizedBox(height: 40),
            
            TextButton(
              onPressed: () => _logout(context), 
              child: const Text("Log Out", style: TextStyle(color: Colors.red))
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blue.shade100,
            child: Text(
              user.username.isNotEmpty ? user.username[0].toUpperCase() : "U",
              style: TextStyle(fontSize: 24, color: Colors.blue.shade800, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.username, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(user.email, style: const TextStyle(color: Colors.grey), overflow: TextOverflow.ellipsis),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String title, String? subtitle, Widget? trailing, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueGrey),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
    );
  }
}