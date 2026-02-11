import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../main.dart'; // To access navigatorKey
import '../screens/login_screen.dart';

class ApiService {
  static const String baseUrl = "https://www.ibtrace.com/tzoneserver/api"; 
  final String token;
  
  // 🟢 SAFETY LOCK: Prevents "Thundering Herd" of logout requests
  static bool _isLoggingOut = false;

  ApiService(this.token);

  Map<String, String> get _headers => {
        "Content-Type": "application/json",
        "accesstoken": token, 
      };

  Future<dynamic> _postRequest(String path, {Map<String, dynamic>? body}) async {
    // Basic check to avoid bad URLs
    if (path.contains("Unknown")) return null;

    final url = Uri.parse('$baseUrl$path');
    try {
      final response = await http.post(url, headers: _headers, body: jsonEncode(body ?? {}));
      
      // 🟢 403 INTERCEPTOR: Detects Expired Token
      if (response.statusCode == 403) {
        print("⛔ API 403 FORBIDDEN: Token Expired.");
        _triggerForceLogout();
        return null;
      }

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print(">> API Error Status: ${response.statusCode}");
      }
    } catch (e) { 
      print("API Network Error: $e"); 
    }
    return null;
  }

  // 🟢 REFINED LOGOUT LOGIC: Uses try/finally for perfect lock timing
  void _triggerForceLogout() async {
    if (_isLoggingOut) return; // 🛑 STOP if already logging out
    _isLoggingOut = true; // 🔒 LOCK

    print("🔒 Initiating Safe Logout Sequence...");

    try {
      const storage = FlutterSecureStorage();
      await storage.deleteAll(); // Wipe old token

      // Use the Global Key to navigate without context
      if (navigatorKey.currentState != null) {
        // 🟢 AWAIT the navigation so we keep the lock held until transition is done
        await navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print("Logout Navigation Error: $e");
    } finally {
      // 🟢 RELEASE LOCK immediately after work is done
      _isLoggingOut = false; 
      print("🔓 Logout Sequence Complete. Lock Released.");
    }
  }

  // --- EXISTING LOGIC BELOW (UNTOUCHED) ---

  Future<Map<String, dynamic>?> getDeviceDetails(String serial) async {
    final data = await _postRequest('/v1/device/userDeviceDetailsWithSerial/$serial');

    if (data != null && data['object'] != null) {
      final state = data['object']['state']; 
      
      if (state != null) {
        double safeParse(dynamic val) {
          if (val == null) return 0.0;
          if (val is num) return val.toDouble();
          return double.tryParse(val.toString()) ?? 0.0;
        }

        return {
          'temperature': safeParse(state['tempexternal']), // Probe
          'ambient': safeParse(state['temperature']),      // Ambient
          'battery': safeParse(state['battery']),
          'time': state['time']?.toString() ?? "",
          'humidity': safeParse(state['humidity']),
          'light': safeParse(state['light']),
          'vibration': safeParse(state['vibration']),
          'city': state['city']?.toString() ?? "Unknown",
        };
      }
    }
    return null;
  }

  Future<Map<String, double>?> getLastPosition(String deviceId) async {
    final data = await _postRequest('/v1/log/device/$deviceId/position', body: {"did": int.tryParse(deviceId) ?? 0});
    if (data != null && data['object'] != null) {
        var obj = data['object'] is List ? data['object'][0] : data['object'];
        final parts = obj['position']?.toString().split(',');
        if (parts != null && parts.length >= 2) {
          return {
            'lat': double.tryParse(parts[0].replaceAll(RegExp(r'[^\d.-]'), '')) ?? 0.0,
            'lng': double.tryParse(parts[1].replaceAll(RegExp(r'[^\d.-]'), '')) ?? 0.0
          };
        }
    }
    return null;
  }

  Future<List<dynamic>> getDeviceHistory(String deviceId) async {
    final data = await _postRequest('/v1/log/device/$deviceId/all', body: {"did": int.tryParse(deviceId) ?? 0});
    return (data != null && data['object'] != null) ? List<dynamic>.from(data['object']) : [];
  }
}