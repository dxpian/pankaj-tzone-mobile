import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://www.ibtrace.com/tzoneserver/api"; 
  final String token;
  ApiService(this.token);

  Map<String, String> get _headers => {
        "Content-Type": "application/json",
        "accesstoken": token, 
      };

  Future<dynamic> _postRequest(String path, {Map<String, dynamic>? body}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (path.contains("Unknown")) return null;

    final url = Uri.parse('$baseUrl$path');
    try {
      final response = await http.post(url, headers: _headers, body: jsonEncode(body ?? {}));
      
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

  // 🟢 UPDATED: Returns both Probe and Ambient separately
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
          // 🟢 SPLIT LOGIC
          'temperature': safeParse(state['tempexternal']), // Probe (Primary)
          'ambient': safeParse(state['temperature']),      // Ambient (Secondary)
          
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