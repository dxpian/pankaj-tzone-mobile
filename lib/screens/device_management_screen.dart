import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sync_engine.dart';

class DeviceManagementScreen extends StatefulWidget {
  const DeviceManagementScreen({super.key});

  @override
  State<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen> {
  // 🟢 Placeholder list is removed. We now use real data.

  void _deleteDevice(String serial) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remove Device?"),
        content: Text("Are you sure you want to stop tracking $serial?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              // 🟢 CONNECTED LOGIC: Removes from SyncEngine and Storage
              Provider.of<SyncEngine>(context, listen: false).removeDevice(serial);
              Navigator.pop(ctx);
            },
            child: const Text("Remove", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _addNewDevice() {
    // 🚧 TODO: This will link to the QR Scanner screen later
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Add Device (QR/Manual) Coming Soon")));
  }

  @override
  Widget build(BuildContext context) {
    // 🟢 LISTENS TO PROVIDER
    final syncEngine = Provider.of<SyncEngine>(context);
    final devices = syncEngine.activeSerials;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Devices", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: devices.isEmpty 
        ? const Center(child: Text("No devices added yet."))
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: devices.length,
            separatorBuilder: (ctx, i) => const Divider(),
            itemBuilder: (context, index) {
              final serial = devices[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child: const Icon(Icons.sensors, color: Colors.blue),
                ),
                title: Text(serial, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Active Logger"), 
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteDevice(serial),
                ),
              );
            },
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewDevice,
        icon: const Icon(Icons.add),
        label: const Text("Add Device"),
        backgroundColor: Colors.blue,
      ),
    );
  }
}