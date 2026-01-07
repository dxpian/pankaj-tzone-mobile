import 'package:flutter/foundation.dart';

class GroupMapper {
  // 1. Define your mappings here
  static const Map<String, String> _mappings = {
    "icebattery-group-1": "Saitama Logistic Center",
    "icebattery-group-2": "Suginami Branch",
    "icebattery-group-3": "Setagaya B",
    "icebattery-group-4": "Bunkyo Pharmaceutical Center",
    "icebattery-group-5": "Fuchu B",
    // Add more as discovered from the API
  };

  // 2. Helper to get the name
  static String getReadableName(String? apiGroupName) {
    if (apiGroupName == null || apiGroupName.isEmpty) return "Unassigned";
    return _mappings[apiGroupName] ?? apiGroupName; // Returns ID if no name found
  }
}