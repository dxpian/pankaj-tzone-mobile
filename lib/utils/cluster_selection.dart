import '../models/logger_alert.dart';

class ClusterSelection {
  /// Last selected cluster name (shown in Alerts tab title)
  static String? selectedClusterName;

  /// Last selected list of alerts for that cluster
  static List<LoggerAlert> selectedAlerts = [];

  /// Helper to set both at once
  static void setSelection(String name, List<LoggerAlert> alerts) {
    selectedClusterName = name;
    selectedAlerts = alerts;
  }
}
