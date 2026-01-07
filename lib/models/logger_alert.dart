class LoggerAlert {
  final String serial;
  final String clusterName;
  final double temperature; // Primary (Probe)
  final double ambientTemp; // Secondary (Ambient)
  final double battery;
  final double latitude;
  final double longitude;
  final int minutesInAlert;
  final String lastUpdated;
  
  // Extended Data
  final double humidity;
  final double light;
  final double vibration;
  final String city;

  LoggerAlert({
    required this.serial,
    required this.clusterName,
    required this.temperature,
    this.ambientTemp = 0.0, // Default for safety
    required this.battery,
    required this.latitude,
    required this.longitude,
    required this.minutesInAlert,
    required this.lastUpdated,
    this.humidity = 0.0,
    this.light = 0.0,
    this.vibration = 0.0,
    this.city = "Unknown",
  });

  LoggerAlert copyWith({
    double? temperature,
    double? ambientTemp,
    double? battery,
    double? latitude,
    double? longitude,
    String? lastUpdated,
    int? minutesInAlert,
    double? humidity,
    double? light,
    double? vibration,
    String? city,
  }) {
    return LoggerAlert(
      serial: serial,
      clusterName: clusterName,
      temperature: temperature ?? this.temperature,
      ambientTemp: ambientTemp ?? this.ambientTemp,
      battery: battery ?? this.battery,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      minutesInAlert: minutesInAlert ?? this.minutesInAlert,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      humidity: humidity ?? this.humidity,
      light: light ?? this.light,
      vibration: vibration ?? this.vibration,
      city: city ?? this.city,
    );
  }

  factory LoggerAlert.fromJson(Map<String, dynamic> json) {
    double lat = 0.0;
    double lon = 0.0;
    
    if (json['position'] != null && json['position'].toString().contains(',')) {
      try {
        final parts = json['position'].toString().split(',');
        String rawLat = parts[0].replaceAll(RegExp(r'[^\d.-]'), '');
        String rawLon = parts[1].replaceAll(RegExp(r'[^\d.-]'), '');
        lat = double.tryParse(rawLat) ?? 0.0;
        lon = double.tryParse(rawLon) ?? 0.0;
      } catch (e) { print("Pos Error: $e"); }
    }

    // 🟢 UPDATED: Strict separation of Probe vs Ambient
    // Probe is usually 'tempexternal'. 
    double probeVal = _parseDouble(json, ['tempexternal']);
    // Ambient is 'temperature' or 'temp'.
    double ambientVal = _parseDouble(json, ['temperature', 'temp']);

    return LoggerAlert(
      serial: json['did']?.toString() ?? json['deviceSerialNo']?.toString() ?? json['serial']?.toString() ?? "Unknown",
      clusterName: json['deviceName'] ?? "General", 
      temperature: probeVal,
      ambientTemp: ambientVal,
      battery: _parseDouble(json, ['battery', 'batt']),
      latitude: lat,
      longitude: lon,
      minutesInAlert: int.tryParse(json['cond']?.toString() ?? '0') ?? 0,
      lastUpdated: json['time']?.toString() ?? "",
      humidity: _parseDouble(json, ['humidity']),
      light: _parseDouble(json, ['light']),
      vibration: _parseDouble(json, ['vibration']),
      city: json['city']?.toString() ?? "Unknown",
    );
  }

  static double _parseDouble(Map<String, dynamic> json, List<String> keys) {
    for (var key in keys) {
      if (json[key] != null) {
        var val = json[key];
        if (val is num) return val.toDouble();
        if (val is String) return double.tryParse(val) ?? 0.0;
      }
    }
    return 0.0;
  }
}