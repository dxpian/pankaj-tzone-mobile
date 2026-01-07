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
    required String location,
    required double temperature, 
    required int startTimeMs, 
  }) async {
    
    // 🟢 UPDATED TEXT: "Probe Temp"
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'alfresa_critical', 
      'Critical Alerts', 
      channelDescription: 'Persistent notifications for temperature violations',
      importance: Importance.max, 
      priority: Priority.max,
      color: Colors.red, 
      colorized: true,          
      ongoing: true,            
      autoCancel: false,        
      usesChronometer: true,    
      when: startTimeMs,        
      styleInformation: BigTextStyleInformation(
        "Logger: $serial\nLocation: $location\nProbe Temp: ${temperature.toStringAsFixed(1)}°C\n\nAction Required Immediately.",
      ),
    );

    final DateTime startDt = DateTime.fromMillisecondsSinceEpoch(startTimeMs);
    final String timeStr = "${startDt.hour}:${startDt.minute.toString().padLeft(2, '0')}";

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,  
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive, 
      sound: 'default',
    );

    await _notifications.show(
      serial.hashCode, 
      "🛑 CRITICAL: $clusterName", 
      "Logger: $serial | Probe: ${temperature.toStringAsFixed(1)}°C\nStarted: $timeStr | Loc: $location",
      NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  static Future<void> cancelAlert(String serial) async {
    await _notifications.cancel(serial.hashCode);
  }
}