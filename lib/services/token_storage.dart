import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const String tokenKey = "token";
  static const String roleKey = "role";

  // =========================
  // SAVE TOKEN
  // =========================
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  // =========================
  // GET TOKEN
  // =========================
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  // =========================
  // SAVE ROLE
  // =========================
  static Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(roleKey, role);
  }

  // =========================
  // GET ROLE
  // =========================
  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(roleKey);
  }

  // =========================
  // CHECK LOGIN STATUS
  // =========================
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // =========================
  // LOGOUT
  // =========================
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(tokenKey);
    await prefs.remove(roleKey);
  }
}
