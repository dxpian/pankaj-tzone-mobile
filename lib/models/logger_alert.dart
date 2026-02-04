class LoggerAlert {
  final String serial;
  final String clusterName;
  
  // 🟢 CHANGED: 'temperature' is now the PRIMARY active sensor (Probe OR Ambient)
  final double temperature; 
  final double ambientTemp; 
  
  // 🟢 NEW: Flag to tell UI which sensor is primary
  final bool isProbeActive;

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

  // Display Preferences
  final bool showAmbient;
  final bool showHumidity;
  final bool showLight;
  final bool showVibration;
  final bool showLocation;

  LoggerAlert({
    required this.serial,
    required this.clusterName,
    required this.temperature,
    this.ambientTemp = 0.0, 
    required this.isProbeActive, // 🟢 Required
    required this.battery,
    required this.latitude,
    required this.longitude,
    required this.minutesInAlert,
    required this.lastUpdated,
    this.humidity = 0.0,
    this.light = 0.0,
    this.vibration = 0.0,
    this.city = "Unknown",
    // Defaults
    this.showAmbient = true,
    this.showHumidity = true,
    this.showLight = true,
    this.showVibration = true,
    this.showLocation = true,
  });

  LoggerAlert copyWith({
    String? clusterName,
    double? temperature,
    double? ambientTemp,
    bool? isProbeActive, // 🟢 Added
    double? battery,
    double? latitude,
    double? longitude,
    String? lastUpdated,
    int? minutesInAlert,
    double? humidity,
    double? light,
    double? vibration,
    String? city,
    bool? showAmbient,
    bool? showHumidity,
    bool? showLight,
    bool? showVibration,
    bool? showLocation,
  }) {
    return LoggerAlert(
      serial: serial,
      clusterName: clusterName ?? this.clusterName, 
      temperature: temperature ?? this.temperature,
      ambientTemp: ambientTemp ?? this.ambientTemp,
      isProbeActive: isProbeActive ?? this.isProbeActive, // 🟢 Added
      battery: battery ?? this.battery,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      minutesInAlert: minutesInAlert ?? this.minutesInAlert,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      humidity: humidity ?? this.humidity,
      light: light ?? this.light,
      vibration: vibration ?? this.vibration,
      city: city ?? this.city,
      showAmbient: showAmbient ?? this.showAmbient,
      showHumidity: showHumidity ?? this.showHumidity,
      showLight: showLight ?? this.showLight,
      showVibration: showVibration ?? this.showVibration,
      showLocation: showLocation ?? this.showLocation,
    );
  }

  factory LoggerAlert.fromJson(Map<String, dynamic> json) {
    // Helper to extract numeric values safely
    double getVal(List<String> keys) {
      for (var key in keys) {
        if (json[key] != null) {
          var val = json[key];
          if (val is num) return val.toDouble();
          if (val is String) return double.tryParse(val) ?? 0.0;
        }
      }
      return 0.0;
    }

    // 🟢 SMART LOGIC: Decide which is Primary
    double rawProbe = getVal(['tempexternal']);
    double rawAmbient = getVal(['temperature', 'temp']);
    
    // Check if Probe data is valid (Not 0.0). 
    bool probeExists = rawProbe != 0.0; 

    double primaryTemp;
    double secondaryTemp;

    if (probeExists) {
      primaryTemp = rawProbe;
      secondaryTemp = rawAmbient;
    } else {
      // Fallback: Ambient becomes Primary
      primaryTemp = rawAmbient;
      secondaryTemp = 0.0; 
    }

    double lat = 0.0;
    double lon = 0.0;
    if (json['position'] != null && json['position'].toString().contains(',')) {
      try {
        final parts = json['position'].toString().split(',');
        lat = double.tryParse(parts[0].replaceAll(RegExp(r'[^\d.-]'), '')) ?? 0.0;
        lon = double.tryParse(parts[1].replaceAll(RegExp(r'[^\d.-]'), '')) ?? 0.0;
      } catch (e) { print("Pos Error: $e"); }
    }

    return LoggerAlert(
      serial: json['did']?.toString() ?? json['deviceSerialNo']?.toString() ?? json['serial']?.toString() ?? "Unknown",
      clusterName: json['deviceName'] ?? "General", 
      temperature: primaryTemp,
      ambientTemp: secondaryTemp,
      isProbeActive: probeExists, // 🟢 Set the flag
      battery: getVal(['battery', 'batt']),
      latitude: lat,
      longitude: lon,
      minutesInAlert: int.tryParse(json['cond']?.toString() ?? '0') ?? 0,
      lastUpdated: json['time']?.toString() ?? "",
      humidity: getVal(['humidity']),
      light: getVal(['light']),
      vibration: getVal(['vibration']),
      city: json['city']?.toString() ?? "Unknown",
    );
  }
}