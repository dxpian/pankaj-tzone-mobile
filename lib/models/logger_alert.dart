class LoggerAlert {
  final String serial;
  final double temperature;
  final int minutesInAlert;

  final double latitude;
  final double longitude;

  final String clusterName;

  LoggerAlert({
    required this.serial,
    required this.temperature,
    required this.minutesInAlert,
    required this.latitude,
    required this.longitude,
    required this.clusterName,
  });
}
