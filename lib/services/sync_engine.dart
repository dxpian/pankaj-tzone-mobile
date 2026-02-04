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
  
  List<LoggerAlert> _alerts = [];
  List<LoggerAlert> get alerts => _alerts;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final Map<String, int> _alertStartTimes = {};

  // 泙 1. The Hardcoded Test Fleet
  final List<String> _testSerials = [
    "190023000000234",
    "190023000000236",
    "190023000000296",
    "190023000000243",
    "190024010000188",
    "190023000000235",
    "190124040001550",
  ];

  SyncEngine(this.user) {
    _api = ApiService(user.token);
    Future.microtask(() => syncData());
    _startAutoRefresh(); 
  }

  void _startAutoRefresh() {
    // 🟢 SYNC INTERVAL: 5 Minutes
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (t) => syncData());
  }

  @override
  void dispose() { _refreshTimer?.cancel(); super.dispose(); }

  Future<void> syncData() async {
    // Only show full loading spinner if we have NO data yet
    if (_alerts.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    List<LoggerAlert> batchResults = [];

    // 泙 2. The Loop (Simulating a full fleet fetch)
    for (String serial in _testSerials) {
      try {
        LoggerAlert? result = await _fetchSingleLogger(serial);
        if (result != null) {
          batchResults.add(result);
        }
      } catch (e) {
        print("Error fetching $serial: $e");
      }
    }

    // 泙 3. Update the UI with the full batch
    _alerts = batchResults;
    _isLoading = false;
    notifyListeners(); 
  }

  // 泙 4. Helper Function: Fetches & Processes ONE Logger
  Future<LoggerAlert?> _fetchSingleLogger(String serial) async {
    // Default / Placeholder Object
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
      // Step A: Get Sensor Data
      final details = await _api.getDeviceDetails(serial);

      if (details != null) {
        double rawProbe = details['temperature'] ?? 0.0;
        double rawAmbient = details['ambient'] ?? 0.0;
        bool probeExists = rawProbe != 0.0;
        
        // Logic match with Model:
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

      // Step B: Get Location
      try {
        final pos = await _api.getLastPosition(serial).timeout(const Duration(seconds: 3));
        if (pos != null) {
          logger = logger.copyWith(
            latitude: pos['lat'],
            longitude: pos['lng']
          );
        }
      } catch (e) {
        // Ignore location errors
      }

      // Step C: Apply Local User Preferences
      logger = await _applyDisplayPreferences(logger);

      // Step D: Run Safety Watchdog (Now with Escalation Logic)
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

    // 1. Check if Alerts are globally enabled for this logger
    bool isTempEnabled = prefs.getBool('alert_enabled_$serial') ?? false;
    bool isBattEnabled = prefs.getBool('batt_enabled_$serial') ?? false;
    double battMin = prefs.getDouble('batt_min_$serial') ?? 20.0;

    // If EVERYTHING is disabled, clear critical state and return
    if (!isTempEnabled && !isBattEnabled) {
      if (_alertStartTimes.containsKey(serial)) {
        _alertStartTimes.remove(serial);
        await NotificationService.cancelAlert(serial);
      }
      return alert;
    }

    // Safety Check: Probe Failure 
    if (alert.isProbeActive && alert.temperature == 0.0) {
       print(">> WATCHDOG: PROBE FAILURE $serial");
       return alert.copyWith(minutesInAlert: 999);
    }

    // 2. Evaluate Violations
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

    // 3. 🟢 ESCALATION LOGIC (0-10-15 Rule)
    if (tempViolation || battViolation) {
      int startTime;
      bool isNewAlert = !_alertStartTimes.containsKey(serial);
      int minutesActive = 0;

      if (isNewAlert) {
        // NEW ALERT: Start the clock
        startTime = DateTime.now().millisecondsSinceEpoch;
        _alertStartTimes[serial] = startTime;
        minutesActive = 0;
      } else {
        // ONGOING ALERT: Calculate Duration
        startTime = _alertStartTimes[serial]!;
        int diff = DateTime.now().millisecondsSinceEpoch - startTime;
        minutesActive = (diff / 60000).floor(); // Convert ms to minutes
      }

      // --- LOGGING ---
      // We explicitly append the duration to the Log Type for the backend
      String logTypeTemp = isNewAlert ? "TEMP_VIOLATION" : "TEMP_VIOLATION_${minutesActive}MIN";
      String logTypeBatt = isNewAlert ? "BATTERY_CRITICAL" : "BATTERY_CRITICAL_${minutesActive}MIN";

      // UNCONDITIONAL LOGGING: We log EVERY time sync runs (Every 5 mins)
      if (tempViolation) {
        print("🚀 ESCALATION: $logTypeTemp for $serial");
        BackendService.logAlert(serial, alert.temperature, logTypeTemp);
      }
      
      if (battViolation) {
         print("🚀 ESCALATION: $logTypeBatt for $serial");
         BackendService.logAlert(serial, alert.battery, logTypeBatt);
      }

      // --- NOTIFICATION ---
      // We modify the "Location" field to act as our status line
      String customContext = alert.city;
      
      if (battViolation) {
        customContext += " | ⚠ Low Batt (${alert.battery.toInt()}%)";
      }

      // UNCONDITIONAL NOTIFICATION: Nag the user every 5 mins
      // 🟢 PASS THE MINUTES ACTIVE SO NOTIFICATION SERVICE CAN CHOOSE COLOR
      await NotificationService.showCriticalAlert(
        clusterName: alert.clusterName, 
        serial: serial, 
        location: customContext, 
        temperature: alert.temperature, 
        startTimeMs: startTime,
        minutesActive: minutesActive, // 🟢 Passed here
      );

      // Return RED state with REAL minutes
      // We use '1' minimum to ensure the UI flags it as critical (>0) even in the first minute
      int uiMinutes = minutesActive == 0 ? 1 : minutesActive;
      return alert.copyWith(minutesInAlert: uiMinutes);
      
    } else {
      // 4. Recovery Logic (Back to Green)
      if (_alertStartTimes.containsKey(serial)) {
        _alertStartTimes.remove(serial);
        await NotificationService.cancelAlert(serial);
        // Optional: Log Recovery?
        print("✅ RECOVERY: $serial is back to normal");
      }
      return alert; 
    }
  }
}