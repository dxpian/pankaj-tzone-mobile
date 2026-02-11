import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'api_service.dart';
import 'notification_service.dart'; 
import '../models/app_features.dart';
import '../models/logger_alert.dart';
import 'backend_service.dart'; 

class SyncEngine extends ChangeNotifier {
  final UserProfile user;
  late final ApiService _api;
  Timer? _refreshTimer; 
  
  // 🟢 DISPOSAL FLAG: Prevents "notifyListeners called after dispose" crash
  bool _isDisposed = false;

  List<LoggerAlert> _alerts = [];
  List<LoggerAlert> get alerts => _alerts;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final Map<String, int> _alertStartTimes = {};

  List<String> _activeSerials = [];
  List<String> get activeSerials => _activeSerials;

  final List<String> _initialSeed = [
    "190023000000234", "190023000000236", "190023000000296",
    "190023000000243", "190024010000188", "190023000000235", "190124040001550"
  ];

  SyncEngine(this.user) {
    _api = ApiService(user.token);
    _loadDeviceList(); 
    _startAutoRefresh(); 
  }

  Future<void> _loadDeviceList() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? saved = prefs.getStringList('my_device_list');

    if (saved == null || saved.isEmpty) {
      _activeSerials = List.from(_initialSeed); 
      await prefs.setStringList('my_device_list', _activeSerials);
    } else {
      _activeSerials = saved;
    }
    
    // Safety check before notifying
    if (!_isDisposed) notifyListeners();
    syncData(); 
  }

  // 🟢 SECURE ADD: Validates input & Verifies Save
  Future<void> addDevice(String serial) async {
    final cleanSerial = serial.trim();
    
    // 1. Validation Check
    if (cleanSerial.isEmpty) {
      print("⚠️ Add Device Failed: Serial is empty");
      return; 
    }
    
    if (_activeSerials.contains(cleanSerial)) return;
    
    // 2. Optimistic Update
    _activeSerials.add(cleanSerial);
    
    final prefs = await SharedPreferences.getInstance();
    final success = await prefs.setStringList('my_device_list', _activeSerials);
    
    // 3. Rollback if Save Failed (e.g. Disk Full)
    if (!success) {
      print("⚠️ CRITICAL: Failed to write to SharedPreferences!");
      _activeSerials.remove(cleanSerial);
      // Notify listeners to revert UI changes
      if (!_isDisposed) notifyListeners();
      return;
    }
    
    if (!_isDisposed) notifyListeners();
    syncData();
  }

  Future<void> removeDevice(String serial) async {
    _activeSerials.remove(serial);
    _alerts.removeWhere((a) => a.serial == serial); 
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('my_device_list', _activeSerials);
    
    if (!_isDisposed) notifyListeners();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (t) => syncData());
  }

  // 🟢 SAFE DISPOSE OVERRIDE
  @override
  void dispose() {
    _isDisposed = true; // Set flag immediately
    _refreshTimer?.cancel(); 
    super.dispose(); 
  }

  Future<void> syncData() async {
    if (_isDisposed) return; // Stop if dead

    if (_alerts.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    List<LoggerAlert> batchResults = [];

    for (String serial in _activeSerials) {
      if (_isDisposed) return; // Stop if disposed mid-loop

      try {
        LoggerAlert? result = await _fetchSingleLogger(serial);
        if (result != null) {
          batchResults.add(result);
        }
      } catch (e) {
        print("Error fetching $serial: $e");
      }
    }

    if (!_isDisposed) {
      _alerts = batchResults;
      _isLoading = false;
      notifyListeners(); 
    }
  }

  // --- EXISTING LOGIC BELOW (UNTOUCHED) ---

  Future<LoggerAlert?> _fetchSingleLogger(String serial) async {
    LoggerAlert logger = LoggerAlert(
      serial: serial, 
      clusterName: "Loading...", 
      temperature: 0.0, ambientTemp: 0.0, 
      battery: 0.0, latitude: 0.0, longitude: 0.0, 
      minutesInAlert: 0, lastUpdated: DateTime.now().toString(),
      humidity: 0.0, light: 0.0, vibration: 0.0, city: "Unknown",
      isProbeActive: true, 
    );

    try {
      final details = await _api.getDeviceDetails(serial);

      if (details != null) {
        double rawProbe = details['temperature'] ?? 0.0;
        double rawAmbient = details['ambient'] ?? 0.0;
        bool probeExists = rawProbe != 0.0;
        
        double primary = probeExists ? rawProbe : rawAmbient;
        double secondary = probeExists ? rawAmbient : 0.0;

        logger = logger.copyWith(
          clusterName: details['deviceName'] ?? "General Storage", 
          temperature: primary,
          ambientTemp: secondary,
          isProbeActive: probeExists, 
          battery: details['battery'],
          lastUpdated: details['time'],
          humidity: details['humidity'],
          light: details['light'],
          vibration: details['vibration'],
          city: details['city'],
        );
      } else {
        return null;
      }

      try {
        final pos = await _api.getLastPosition(serial).timeout(const Duration(seconds: 3));
        if (pos != null) {
          logger = logger.copyWith(
            latitude: pos['lat'],
            longitude: pos['lng']
          );
        }
      } catch (e) { /* Ignore */ }

      logger = await _applyDisplayPreferences(logger);
      logger = await _processWatchdog(logger);

      return logger;

    } catch (e) {
      print("Deep error processing $serial: $e");
      return null;
    }
  }

  Future<LoggerAlert> _applyDisplayPreferences(LoggerAlert alert) async {
    final prefs = await SharedPreferences.getInstance();
    final s = alert.serial;
    return alert.copyWith(
      showAmbient: prefs.getBool('show_ambient_$s') ?? true,
      showHumidity: prefs.getBool('show_humidity_$s') ?? true,
      showLight: prefs.getBool('show_light_$s') ?? true,
      showVibration: prefs.getBool('show_vibration_$s') ?? true,
      showLocation: prefs.getBool('show_location_$s') ?? true,
    );
  }

  Future<LoggerAlert> _processWatchdog(LoggerAlert alert) async {
    final prefs = await SharedPreferences.getInstance();
    final String serial = alert.serial;

    bool isTempEnabled = prefs.getBool('alert_enabled_$serial') ?? false;
    bool isBattEnabled = prefs.getBool('batt_enabled_$serial') ?? false;
    double battMin = prefs.getDouble('batt_min_$serial') ?? 20.0;

    if (!isTempEnabled && !isBattEnabled) {
      if (_alertStartTimes.containsKey(serial)) {
        _alertStartTimes.remove(serial);
        await NotificationService.cancelAlert(serial);
      }
      return alert;
    }

    if (alert.isProbeActive && alert.temperature == 0.0) {
       return alert.copyWith(minutesInAlert: 999);
    }

    bool tempViolation = false;
    if (isTempEnabled) {
      double minTemp = prefs.getDouble('alert_min_$serial') ?? 2.0;
      double maxTemp = prefs.getDouble('alert_max_$serial') ?? 8.0;
      tempViolation = (alert.temperature > maxTemp) || (alert.temperature < minTemp);
    }

    bool battViolation = false;
    if (isBattEnabled) {
      battViolation = (alert.battery < battMin);
    }

    if (tempViolation || battViolation) {
      int startTime;
      bool isNewAlert = !_alertStartTimes.containsKey(serial);
      int minutesActive = 0;

      if (isNewAlert) {
        startTime = DateTime.now().millisecondsSinceEpoch;
        _alertStartTimes[serial] = startTime;
        minutesActive = 0;
      } else {
        startTime = _alertStartTimes[serial]!;
        int diff = DateTime.now().millisecondsSinceEpoch - startTime;
        minutesActive = (diff / 60000).floor(); 
      }

      String logTypeTemp = isNewAlert ? "TEMP_VIOLATION" : "TEMP_VIOLATION_${minutesActive}MIN";
      String logTypeBatt = isNewAlert ? "BATTERY_CRITICAL" : "BATTERY_CRITICAL_${minutesActive}MIN";

      if (tempViolation) BackendService.logAlert(serial, alert.temperature, logTypeTemp);
      if (battViolation) BackendService.logAlert(serial, alert.battery, logTypeBatt);

      String customContext = alert.city;
      if (battViolation) customContext += " | ⚠ Low Batt (${alert.battery.toInt()}%)";

      await NotificationService.showCriticalAlert(
        clusterName: alert.clusterName, 
        serial: serial, 
        location: customContext, 
        temperature: alert.temperature, 
        startTimeMs: startTime,
        minutesActive: minutesActive, 
      );

      int uiMinutes = minutesActive == 0 ? 1 : minutesActive;
      return alert.copyWith(minutesInAlert: uiMinutes);
      
    } else {
      if (_alertStartTimes.containsKey(serial)) {
        _alertStartTimes.remove(serial);
        await NotificationService.cancelAlert(serial);
      }
      return alert; 
    }
  }
}