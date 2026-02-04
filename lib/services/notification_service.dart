import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    await _notifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings)
    );
  }

  static Future<void> showNotification({required String title, required String body}) async {
    const androidDetails = AndroidNotificationDetails(
      'alfresa_general', 'General', importance: Importance.high, priority: Priority.high
    );
    await _notifications.show(
      DateTime.now().millisecond, title, body,
      const NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails())
    );
  }

  static Future<void> showCriticalAlert({
    required String clusterName, 
    required String serial, 
    required String location, // 🟢 Contains City + Battery Info (e.g. "Tokyo | Low Batt 20%")
    required double temperature, 
    required int startTimeMs,
    required int minutesActive, 
  }) async {
    
    // 🟢 1. SEVERITY LOGIC (0-10-15 Rule)
    Color alertColor = Colors.yellow.shade700;
    String severityTitle = "⚠️ WARNING";
    String urgencyText = "Action Required";

    if (minutesActive >= 15) {
      // 15+ Mins -> RED
      alertColor = Colors.red;
      severityTitle = "🛑 CRITICAL";
      urgencyText = "IMMEDIATE ACTION REQUIRED";
    } else if (minutesActive >= 10) {
      // 10-15 Mins -> ORANGE
      alertColor = Colors.deepOrange;
      severityTitle = "🔸 URGENT";
      urgencyText = "Escalating Issue";
    } 
    // Else 0-10 Mins -> YELLOW (Default)

    // 🟢 2. ANDROID DETAILS
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'alfresa_critical', 
      'Critical Alerts', 
      channelDescription: 'Persistent notifications for temperature violations',
      importance: Importance.max, 
      priority: Priority.max,
      
      // Dynamic Color
      color: alertColor, 
      colorized: true,          
      
      ongoing: true,            
      autoCancel: false,        
      usesChronometer: true,    
      when: startTimeMs,        
      styleInformation: BigTextStyleInformation(
        // 🟢 RESTORED: $location is included here so Battery Alerts appear in the body
        "Logger: $serial\nLocation: $location\nDuration: ${minutesActive}m\nProbe Temp: ${temperature.toStringAsFixed(1)}°C\n\n$urgencyText",
        contentTitle: "$severityTitle: $clusterName",
        summaryText: urgencyText,
      ),
    );

    // 🟢 3. iOS DETAILS
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,  
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive, 
      sound: 'default',
    );

    await _notifications.show(
      serial.hashCode, 
      "$severityTitle: $clusterName", // Dynamic Title
      // 🟢 RESTORED: $location included here for standard iOS view
      "Logger: $serial | Loc: $location\nTemp: ${temperature.toStringAsFixed(1)}°C | Active: ${minutesActive}m",
      NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  static Future<void> cancelAlert(String serial) async {
    await _notifications.cancel(serial.hashCode);
  }
}