import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'api_service.dart';
import 'notification_service.dart'; 
import '../models/app_features.dart';
import '../models/logger_alert.dart';

class SyncEngine extends ChangeNotifier {
  final UserProfile user;
  late final ApiService _api;
  Timer? _refreshTimer; 
  List<LoggerAlert> _alerts = [];
  List<LoggerAlert> get alerts => _alerts;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final Map<String, int> _alertStartTimes = {};

  SyncEngine(this.user) {
    _api = ApiService(user.token);
    Future.microtask(() => syncData());
    _startAutoRefresh(); 
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (t) => syncData());
  }

  @override
  void dispose() { _refreshTimer?.cancel(); super.dispose(); }

  Future<void> syncData() async {
    if (_alerts.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    const String testSerial = "190124040001550"; 
    
    LoggerAlert testLogger = LoggerAlert(
      serial: testSerial, clusterName: "Test Device", 
      temperature: 0.0, ambientTemp: 0.0, // Init both
      battery: 0.0, latitude: 0.0, longitude: 0.0, 
      minutesInAlert: 0, lastUpdated: DateTime.now().toString(),
      humidity: 0.0, light: 0.0, vibration: 0.0, city: "Loading...",
    );

    try {
      final details = await _api.getDeviceDetails(testSerial);

      if (details != null) {
        testLogger = testLogger.copyWith(
          temperature: details['temperature'], // Probe
          ambientTemp: details['ambient'],     // Ambient (New)
          battery: details['battery'],
          lastUpdated: details['time'],
          humidity: details['humidity'],
          light: details['light'],
          vibration: details['vibration'],
          city: details['city'],
        );
      }

      // 🟢 Logic Phase: Watchdog checks Probe only
      testLogger = await _processWatchdog(testLogger);

      _alerts = [testLogger];
      _isLoading = false;
      notifyListeners(); 

      try {
        final pos = await _api.getLastPosition(testSerial).timeout(const Duration(seconds: 5));
        if (pos != null) {
          _alerts = [_alerts[0].copyWith(
            latitude: pos['lat'],
            longitude: pos['lng']
          )];
          notifyListeners(); 
        }
      } catch (e) {
        // Ignore timeout
      }

    } catch (e) {
      print("Sync Error: $e");
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<LoggerAlert> _processWatchdog(LoggerAlert alert) async {
    final prefs = await SharedPreferences.getInstance();
    final String serial = alert.serial;

    bool isEnabled = prefs.getBool('alert_enabled_$serial') ?? false;
    
    if (!isEnabled) {
      if (_alertStartTimes.containsKey(serial)) {
        _alertStartTimes.remove(serial);
        await NotificationService.cancelAlert(serial);
      }
      return alert;
    }

    // 🟢 Safety Net: Check for Probe Disconnection (0.0 or Null logic)
    // If Probe is 0.0, it's likely disconnected or broken.
    if (alert.temperature == 0.0) {
       print(">> WATCHDOG: PROBE FAILURE $serial");
       await NotificationService.showNotification(
         title: "⚠️ SENSOR ERROR: $serial",
         body: "Probe disconnected or reading 0.0°C. Check immediately."
       );
       // Return as Alert to turn UI Red
       return alert.copyWith(minutesInAlert: 999);
    }

    double minTemp = prefs.getDouble('alert_min_$serial') ?? 2.0;
    double maxTemp = prefs.getDouble('alert_max_$serial') ?? 8.0;

    // 🟢 CHECK ONLY PROBE (alert.temperature)
    bool violation = (alert.temperature > maxTemp) || (alert.temperature < minTemp);

    if (violation) {
      print(">> WATCHDOG: Probe Violation on $serial! Temp: ${alert.temperature}");
      
      int startTime;
      if (_alertStartTimes.containsKey(serial)) {
        startTime = _alertStartTimes[serial]!;
      } else {
        startTime = DateTime.now().millisecondsSinceEpoch;
        _alertStartTimes[serial] = startTime;
      }

      await NotificationService.showCriticalAlert(
        clusterName: alert.clusterName, 
        serial: serial, 
        location: alert.city, 
        temperature: alert.temperature, // Probe Temp
        startTimeMs: startTime, 
      );

      return alert.copyWith(minutesInAlert: 1);
      
    } else {
      if (_alertStartTimes.containsKey(serial)) {
        print(">> WATCHDOG: Violation subsided for $serial.");
        _alertStartTimes.remove(serial);
        await NotificationService.cancelAlert(serial);
      }
      return alert; 
    }
  }
}