import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoggerSettingsDialog extends StatefulWidget {
  final String serial;

  const LoggerSettingsDialog({super.key, required this.serial});

  @override
  State<LoggerSettingsDialog> createState() => _LoggerSettingsDialogState();
}

class _LoggerSettingsDialogState extends State<LoggerSettingsDialog> {
  bool _isLoading = true;

  // Temp Settings
  bool _enableTempAlert = false;
  final TextEditingController _minTempController = TextEditingController();
  final TextEditingController _maxTempController = TextEditingController();

  // Battery Settings
  bool _enableBattAlert = false;
  final TextEditingController _minBattController = TextEditingController();

  // Display Settings
  bool _showAmbient = true;
  bool _showHumidity = true;
  bool _showLight = true;
  bool _showVibration = true;
  bool _showLocation = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final s = widget.serial;

    setState(() {
      // Load Temp
      _enableTempAlert = prefs.getBool('alert_enabled_$s') ?? false;
      _minTempController.text = (prefs.getDouble('alert_min_$s') ?? 2.0).toString();
      _maxTempController.text = (prefs.getDouble('alert_max_$s') ?? 8.0).toString();

      // Load Battery
      _enableBattAlert = prefs.getBool('batt_enabled_$s') ?? false;
      _minBattController.text = (prefs.getDouble('batt_min_$s') ?? 20.0).toString();

      // Load Display
      _showAmbient = prefs.getBool('show_ambient_$s') ?? true;
      _showHumidity = prefs.getBool('show_humidity_$s') ?? true;
      _showLight = prefs.getBool('show_light_$s') ?? true;
      _showVibration = prefs.getBool('show_vibration_$s') ?? true;
      _showLocation = prefs.getBool('show_location_$s') ?? true;

      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    // 1. Parse Inputs
    double? newMin = double.tryParse(_minTempController.text);
    double? newMax = double.tryParse(_maxTempController.text);
    double? newBatt = double.tryParse(_minBattController.text);

    // 2. 🛡️ VALIDATION CHECKS
    
    // Check A: valid numbers
    if (newMin == null || newMax == null || newBatt == null) {
      _showError("Please enter valid numbers.");
      return;
    }

    // Check B: Logical Consistency (Min cannot be greater than Max)
    if (newMin >= newMax) {
      _showError("Minimum Temp must be LOWER than Maximum Temp.");
      return;
    }

    // Check C: Battery Limits (0-100 only)
    if (newBatt < 0 || newBatt > 100) {
      _showError("Battery must be between 0% and 100%.");
      return;
    }

    // 3. Save Valid Data
    final prefs = await SharedPreferences.getInstance();
    final s = widget.serial;

    // Save Temp
    await prefs.setBool('alert_enabled_$s', _enableTempAlert);
    await prefs.setDouble('alert_min_$s', newMin);
    await prefs.setDouble('alert_max_$s', newMax);

    // Save Battery
    await prefs.setBool('batt_enabled_$s', _enableBattAlert);
    await prefs.setDouble('batt_min_$s', newBatt);

    // Save Display
    await prefs.setBool('show_ambient_$s', _showAmbient);
    await prefs.setBool('show_humidity_$s', _showHumidity);
    await prefs.setBool('show_light_$s', _showLight);
    await prefs.setBool('show_vibration_$s', _showVibration);
    await prefs.setBool('show_location_$s', _showLocation);

    if (mounted) {
      Navigator.pop(context, true); // Return TRUE to indicate changes were saved
    }
  }

  // 🟢 FIX 2: Use an AlertDialog instead of SnackBar so it appears ON TOP
  void _showError(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Invalid Input", style: TextStyle(color: Colors.red)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AlertDialog(
      title: const Text("Logger Configuration"),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            // --- TEMP SECTION ---
            const Text("Temperature Alerts", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            SwitchListTile(
              title: const Text("Enable Temp Alert"),
              value: _enableTempAlert,
              activeThumbColor: Colors.red,
              onChanged: (v) => setState(() => _enableTempAlert = v),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minTempController,
                    // 🟢 FIX 1: Allow Signed (+/-) and Decimal numbers
                    keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                    decoration: const InputDecoration(labelText: "Min °C"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _maxTempController,
                    // 🟢 FIX 1: Allow Signed (+/-) and Decimal numbers
                    keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                    decoration: const InputDecoration(labelText: "Max °C"),
                  ),
                ),
              ],
            ),
            
            const Divider(height: 30),

            // --- BATTERY SECTION ---
            const Text("Battery Monitoring", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            SwitchListTile(
              title: const Text("Low Battery Alert"),
              value: _enableBattAlert,
              activeThumbColor: Colors.orange,
              onChanged: (v) => setState(() => _enableBattAlert = v),
            ),
            TextField(
              controller: _minBattController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Min Battery % (e.g. 20)",
                suffixText: "%",
              ),
            ),

            const Divider(height: 30),
            
            // --- DISPLAY SECTION ---
            const Text("Display Preferences", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            _buildSwitch("Show Ambient (Secondary)", _showAmbient, (v) => _showAmbient = v),
            _buildSwitch("Show Humidity", _showHumidity, (v) => _showHumidity = v),
            _buildSwitch("Show Light", _showLight, (v) => _showLight = v),
            _buildSwitch("Show Vibration", _showVibration, (v) => _showVibration = v),
            _buildSwitch("Show Location", _showLocation, (v) => _showLocation = v),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800),
          onPressed: _saveSettings,
          child: const Text("Save"),
        )
      ],
    );
  }

  Widget _buildSwitch(String label, bool val, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: val,
      dense: true,
      onChanged: (v) {
        setState(() => onChanged(v));
      },
    );
  }
}