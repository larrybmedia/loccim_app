import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sermon.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "https://loccim-backend.onrender.com";

  // =========================
  // 🔐 HEADERS (WITH DEBUG)
  // =========================
  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  // =========================
  // 🔵 PING
  // =========================
  static Future<String> ping() async {
    try {
      final res =
          await http.get(Uri.parse("https://loccim-backend.onrender.com/ping"));
      return jsonDecode(res.body)["message"];
    } catch (e) {
      print("PING ERROR: $e");
      return "Offline";
    }
  }

  // =========================
  // 🎤 SERMONS (FIXED URL)
  // =========================
  static Future<List<Sermon>> getSermons() async {
    try {
      // Updated from /sermons to /api/sermons
      final response = await http.get(Uri.parse("$baseUrl/api/sermons"),
          headers: await _headers());

      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((item) => Sermon.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print("SERMON FETCH ERROR: $e");
      return [];
    }
  }

  // =========================
  // 🙏 PRAYER SUBMISSION
  // =========================
  static Future<void> submitPrayer(String name, String message) async {
    final response = await http.post(
      Uri.parse("https://loccim-backend.onrender.com/add_prayer"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"name": name, "message": message}),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to submit prayer");
    }
  }

  // =========================
  // 📥 GET PRAYERS (FIXED URL)
  // =========================
  static Future<List<dynamic>> getPrayers() async {
    try {
      // Ensure this matches your backend @app.route("/api/prayers")
      final response = await http.get(Uri.parse("$baseUrl/api/prayers"),
          headers: await _headers());
      return jsonDecode(response.body);
    } catch (e) {
      print("PRAYER FETCH ERROR: $e");
      return [];
    }
  }

  // =========================
  // 🔐 LOGIN (TOKEN + ROLE)
  // =========================
  static Future<Map<String, dynamic>?> login(
    String username,
    String password,
  ) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        final token = data["token"] ?? "no_token_provided";
        final role = data["role"] ?? "user";

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", token);
        await prefs.setString("role", role);

        return {"token": token, "role": role};
      }
      return null;
    } catch (e) {
      print("LOGIN ERROR: $e");
      return null;
    }
  }

  // =========================
  // 🔐 GET ROLE & TOKEN
  // =========================
  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("role");
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  // =========================
  // ✅ UPDATE PRAYER STATUS
  // =========================
  static Future<void> updatePrayerStatus(int id, String action) async {
    final url = action == "approve"
        ? "$baseUrl/api/prayer/$id/approve"
        : "$baseUrl/prayer/$id/reject";

    await http.put(
      Uri.parse(url),
      headers: await _headers(),
    );
  }

  // =========================
  // 📚 GET BOOKS
  // =========================
  static Future<List<dynamic>> getBooks() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/books"),
        headers: await _headers(),
      );

      print("BOOKS STATUS: ${response.statusCode}");
      print("BOOKS BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          return data;
        }

        if (data is Map && data["books"] is List) {
          return data["books"];
        }
      }

      return [];
    } catch (e) {
      print("BOOK ERROR: $e");
      return [];
    }
  }
}
