import 'dart:convert';

enum AppModule {
  basicAlerts, // Module A
  graphData,   // Module B
  locationMap, // Module C
  checkPoints  // Module D
}

class UserProfile {
  final String userId;
  final String username;
  final String email; // 🟢 ADDED: Email field
  final String token;
  final List<AppModule> permissions;

  UserProfile({
    required this.userId,
    required this.username,
    required this.email, // 🟢 ADDED: to Constructor
    required this.token,
    required this.permissions,
  });

  bool hasAccess(AppModule module) {
    return permissions.contains(module);
  }

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