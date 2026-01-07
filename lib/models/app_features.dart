import 'dart:convert';
import 'package:flutter/foundation.dart';

enum AppModule {
  basicAlerts, // Module A
  graphData,   // Module B
  locationMap, // Module C
  checkPoints  // Module D
}

class UserProfile {
  final String userId;
  final String username;
  final String token;
  final List<AppModule> permissions;

  UserProfile({
    required this.userId,
    required this.username,
    required this.token,
    required this.permissions,
  });

  bool hasAccess(AppModule module) {
    return permissions.contains(module);
  }

  // --- NEW HELPERS (Copy this part!) ---
  
  // Encode List -> String
  static String encodePermissions(List<AppModule> perms) {
    List<String> strList = perms.map((e) => e.toString()).toList();
    return jsonEncode(strList);
  }

  // Decode String -> List
  static List<AppModule> decodePermissions(String jsonStr) {
    try {
      List<dynamic> list = jsonDecode(jsonStr);
      return list.map((e) => AppModule.values.firstWhere(
            (a) => a.toString() == e,
            orElse: () => AppModule.basicAlerts,
          )).toList();
    } catch (e) {
      return [AppModule.basicAlerts];
    }
  }
}