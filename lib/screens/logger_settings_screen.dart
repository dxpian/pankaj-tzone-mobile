import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/logger_alert.dart';

class LoggerSettingsScreen extends StatefulWidget {
  final LoggerAlert logger;

  const LoggerSettingsScreen({super.key, required this.logger});

  @override
  State<LoggerSettingsScreen> createState() => _LoggerSettingsScreenState();
}

class _LoggerSettingsScreenState extends State<LoggerSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Temperature Controllers
  late TextEditingController _minController;
  late TextEditingController _maxController;
  
  // Battery Controller
  late TextEditingController _battMinController;

  // Toggles
  bool _tempAlertsEnabled = false;
  bool _battAlertsEnabled = false;
  bool _showAmbient = true;
  bool _showHumidity = true;
  bool _showLight = true;
  bool _showVibration = true;

  @override
  void initState() {
    super.initState();
    _minController = TextEditingController();
    _maxController = TextEditingController();
    _battMinController = TextEditingController();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final s = widget.logger.serial;

    setState(() {
      _tempAlertsEnabled = prefs.getBool('alert_enabled_$s') ?? false;
      _minController.text = (prefs.getDouble('alert_min_$s') ?? 2.0).toString();
      _maxController.text = (prefs.getDouble('alert_max_$s') ?? 8.0).toString();

      _battAlertsEnabled = prefs.getBool('batt_enabled_$s') ?? false;
      _battMinController.text = (prefs.getDouble('batt_min_$s') ?? 20.0).toString();

      _showAmbient = prefs.getBool('show_ambient_$s') ?? true;
      _showHumidity = prefs.getBool('show_humidity_$s') ?? true;
      _showLight = prefs.getBool('show_light_$s') ?? true;
      _showVibration = prefs.getBool('show_vibration_$s') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final s = widget.logger.serial;

    await prefs.setBool('alert_enabled_$s', _tempAlertsEnabled);
    await prefs.setDouble('alert_min_$s', double.parse(_minController.text));
    await prefs.setDouble('alert_max_$s', double.parse(_maxController.text));

    await prefs.setBool('batt_enabled_$s', _battAlertsEnabled);
    await prefs.setDouble('batt_min_$s', double.parse(_battMinController.text));

    await prefs.setBool('show_ambient_$s', _showAmbient);
    await prefs.setBool('show_humidity_$s', _showHumidity);
    await prefs.setBool('show_light_$s', _showLight);
    await prefs.setBool('show_vibration_$s', _showVibration);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Settings: ${widget.logger.serial}", style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            onPressed: _saveSettings, 
            icon: const Icon(Icons.check, color: Colors.green)
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader("Temperature Thresholds"),
            SwitchListTile(
              title: const Text("Enable Temperature Alerts"),
              value: _tempAlertsEnabled,
              onChanged: (v) => setState(() => _tempAlertsEnabled = v),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minController,
                    decoration: const InputDecoration(labelText: "Min Temp (°C)", border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    enabled: _tempAlertsEnabled,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _maxController,
                    decoration: const InputDecoration(labelText: "Max Temp (°C)", border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    enabled: _tempAlertsEnabled,
                    validator: (v) {
                      if (double.parse(v!) <= double.parse(_minController.text)) return "Must be > Min";
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const Divider(height: 40),
            _buildSectionHeader("Battery Management"),
            SwitchListTile(
              title: const Text("Enable Battery Alerts"),
              value: _battAlertsEnabled,
              onChanged: (v) => setState(() => _battAlertsEnabled = v),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _battMinController,
              decoration: const InputDecoration(labelText: "Critical Battery Level (%)", border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              enabled: _battAlertsEnabled,
            ),
            const Divider(height: 40),
            _buildSectionHeader("Graph Display Preferences"),
            // Display Toggles
            _buildToggle("Show Ambient Temperature", _showAmbient, (v) => setState(() => _showAmbient = v)),
            _buildToggle("Show Humidity", _showHumidity, (v) => setState(() => _showHumidity = v)),
            _buildToggle("Show Light", _showLight, (v) => setState(() => _showLight = v)),
            _buildToggle("Show Vibration", _showVibration, (v) => setState(() => _showVibration = v)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
    );
  }

  // 🟢 FIXED: Replaced 'controlType' with 'controlAffinity'
  Widget _buildToggle(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: (v) => onChanged(v),
      controlAffinity: ListTileControlAffinity.trailing, 
    );
  }
}