import 'dart:convert';
import 'package:http/http.dart' as http;

class HistoryService {
  // 泙 Verified Endpoint URL (Must include 'www')
  static const String _baseUrl = "https://www.ibtrace.com/tzoneserver/api/v1/log/range";
  
  final String token;

  HistoryService(this.token);

  /// Fetches temperature history for a specific device serial.
  /// 泙 STRATEGY: Fetch last 24 Hours (1 Day) to show a full daily cycle.
  Future<List<dynamic>> getTemperatureHistory(String serial) async {
    final now = DateTime.now();
    
    // 🟢 CHANGED: Fetch 1 Day instead of 3 Hours
    final startDate = now.subtract(const Duration(days: 1));

    final url = Uri.parse("$_baseUrl/$serial/temperature");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "accesstoken": token, 
        },
        body: jsonEncode({
          // 泙 Timezone: Use Local Time (JST).
          "from": _formatDate(startDate),
          "to": _formatDate(now),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['object'] != null) {
          return List<dynamic>.from(data['object']);
        }
      } else {
        print(">> History API Error: ${response.statusCode} | ${response.body}");
      }
    } catch (e) {
      print(">> History Network Error: $e");
    }
    return [];
  }

  // 泙 Helper to format dates as "yyyy-MM-dd HH:mm:ss"
  String _formatDate(DateTime d) {
    return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} "
           "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:"
           "${d.second.toString().padLeft(2, '0')}";
  }
}