import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BackendService {
  // ⚠️ Ensure this matches your Python Server IP
  static const String baseUrl = "http://172.25.6.175:8000"; 
  static const String _queueKey = "offline_alert_queue";

  /// Tries to send an alert. If offline, saves it for later.
  static Future<void> logAlert(String serial, double value, String type) async {
    final url = Uri.parse("$baseUrl/alerts/");
    
    final Map<String, dynamic> payload = {
      "serial": serial,
      "type": type,
      "temp": value
    };

    try {
      print("📡 Sending Alert: $serial | $type...");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        print("✅ Alert Sent Successfully!");
        // If we successfully sent one, let's try to flush any old pending ones!
        await _flushQueue();
      } else {
        print("⚠️ Server Error: ${response.statusCode}. Saving to queue.");
        await _addToQueue(payload);
      }
    } catch (e) {
      print("🔌 Network Error: $e. Saving to queue.");
      await _addToQueue(payload);
    }
  }

  // --- 🔒 PRIVATE OFFLINE LOGIC ---

  static Future<void> _addToQueue(Map<String, dynamic> alert) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> queue = prefs.getStringList(_queueKey) ?? [];
    
    // Add new alert as JSON string
    queue.add(jsonEncode(alert));
    
    await prefs.setStringList(_queueKey, queue);
    print("💾 Alert saved to offline queue. Total pending: ${queue.length}");
  }

  static Future<void> _flushQueue() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> queue = prefs.getStringList(_queueKey) ?? [];

    if (queue.isEmpty) return;

    print("🔄 Flushing ${queue.length} offline alerts...");
    List<String> remaining = [];
    final url = Uri.parse("$baseUrl/alerts/");

    for (String item in queue) {
      try {
        // Decode the saved request
        Map<String, dynamic> payload = jsonDecode(item);
        
        // Try to send it again
        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(payload),
        ).timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) {
          print("✅ Recovered Alert Sent: ${payload['serial']}");
        } else {
          remaining.add(item); // Keep it if server rejected
        }
      } catch (e) {
        remaining.add(item); // Keep it if network still fails
      }
    }

    // Save the ones we couldn't send
    await prefs.setStringList(_queueKey, remaining);
    
    if (remaining.isEmpty) {
      print("🎉 Offline Queue Cleared!");
    } else {
      print("⚠️ Queue partially flushed. Remaining: ${remaining.length}");
    }
  }
} 