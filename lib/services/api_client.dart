import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'token_storage.dart';

class ApiClient {
  // =========================
  // BASE URL
  // =========================
  static String get baseUrl {
    return "https://loccim-backend.onrender.com";
  }

  // =========================
  // INTERNAL URL BUILDER
  // =========================
  static Uri _url(String path) => Uri.parse("$baseUrl$path");

  // =========================
  // HEADERS
  // =========================
  static Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getToken();

    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
    };
  }

  // =========================
  // LOGIN
  // =========================
  static Future<Map<String, dynamic>?> login(
    String username,
    String password,
  ) async {
    try {
      final response = await http.post(
        _url("/api/login"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "username": username,
          "password": password,
        }),
      );

      print("LOGIN STATUS: ${response.statusCode}");
      print("LOGIN RESPONSE: ${response.body}");

      Map<String, dynamic> data;

      try {
        data = jsonDecode(response.body);
      } catch (_) {
        return {
          "success": false,
          "error": "Invalid response from server",
        };
      }

      if (response.statusCode == 200 && data["success"] == true) {
        final token = data["access_token"]?.toString();

        if (token == null || token.isEmpty) {
          return {
            "success": false,
            "error": "Login succeeded but no access token was returned.",
          };
        }

        final role = data["role"]?.toString() ?? "user";
        final returnedUsername = data["username"]?.toString() ?? username;

        // Save JWT token
        await TokenStorage.saveToken(token);

        // Save role
        await TokenStorage.saveRole(role);

        return {
          "success": true,
          "token": token,
          "role": role,
          "username": returnedUsername,
        };
      }

      return {
        "success": false,
        "error": data["error"]?.toString() ??
            data["message"]?.toString() ??
            "Invalid username or password",
      };
    } catch (e) {
      print("LOGIN ERROR: $e");

      return {
        "success": false,
        "error": "Unable to connect to the server",
      };
    }
  }

  // =========================
  // ANALYTICS
  // =========================
  static Future<Map<String, dynamic>> getAnalytics() async {
    try {
      final response = await http.get(
        _url("/api/analytics"),
        headers: await _headers(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {
        "prayers": 0,
        "sermons": 0,
        "testimonies": 0,
      };
    } catch (_) {
      return {
        "prayers": 0,
        "sermons": 0,
        "testimonies": 0,
      };
    }
  }

  // =========================
  // LIVE STREAM URL
  // =========================
  static Future<String?> getLiveStreamUrl() async {
    try {
      final response = await http.get(
        _url("/api/live"),
        headers: await _headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["live_url"]?.toString();
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  // =========================
  // UPDATE LIVE STREAM
  // =========================
  static Future<bool> updateLiveStream(String liveUrl) async {
    try {
      final response = await http.post(
        _url("/api/set_live"),
        headers: await _headers(),
        body: jsonEncode({
          "live_url": liveUrl,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Error updating live stream: $e");
      return false;
    }
  }

  // =========================
  // SUBMIT PRAYER REQUEST
  // =========================
  static Future<bool> submitPrayer(
    String name,
    String message,
  ) async {
    try {
      final response = await http.post(
        _url("/api/prayers"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "name": name,
          "message": message,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Prayer submission error: $e");
      return false;
    }
  }

  // =========================
  // APPROVE PRAYER
  // =========================
  static Future<bool> approvePrayer(int prayerId) async {
    try {
      final response = await http.put(
        _url("/prayer/$prayerId/approve"),
        headers: await _headers(),
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // =========================
  // REJECT PRAYER
  // =========================
  static Future<bool> rejectPrayer(int prayerId) async {
    try {
      final response = await http.put(
        _url("/prayer/$prayerId/reject"),
        headers: await _headers(),
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // =========================
  // GET SERMONS
  // =========================
  Future<List<dynamic>> fetchSermons() async {
    try {
      final response = await http.get(
        _url("/api/sermons"),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      throw Exception(
        "Server error: ${response.statusCode}",
      );
    } catch (e) {
      print("Error fetching sermons: $e");
      rethrow;
    }
  }

  // =========================
  // GET TESTIMONIES
  // =========================
  static Future<List<dynamic>> getTestimonies() async {
    try {
      final response = await http.get(
        _url("/api/testimonies"),
        headers: await _headers(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return [];
    } catch (e) {
      print("TESTIMONY ERROR: $e");
      return [];
    }
  }

  // =========================
  // GET EVENTS
  // =========================
  static Future<List<dynamic>> getEvents() async {
    try {
      final response = await http.get(
        _url("/api/events"),
        headers: await _headers(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return [];
    } catch (_) {
      return [];
    }
  }

  // =========================
  // GET GALLERY MEDIA
  // =========================
  static Future<List<dynamic>> getGallery() async {
    try {
      final response = await http.get(
        _url("/api/gallery"),
        headers: await _headers(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return [];
    } catch (e) {
      print("Gallery Error: $e");
      return [];
    }
  }

  // =========================
  // GET ABOUT
  // =========================
  Future<Map<String, dynamic>> fetchAbout() async {
    print("Loading About Us...");

    final response = await http.get(
      _url("/api/about"),
    );

    print("Status: ${response.statusCode}");
    print("Body: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(
      "Failed to load About Us: ${response.statusCode}",
    );
  }

  // =========================
  // GET BOOKS
  // =========================
  static Future<List<dynamic>> getBooks() async {
    try {
      final response = await http.get(
        _url("/api/books"),
        headers: await _headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          return data;
        }

        if (data is Map && data["books"] is List) {
          return data["books"];
        }

        return [];
      }

      return [];
    } catch (e) {
      print("BOOK ERROR: $e");
      return [];
    }
  }

  // =========================
  // SAVE ROLE
  // =========================
  static Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("role", role);
  }

  // =========================
  // GET ROLE
  // =========================
  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("role");
  }

  // =========================
  // GET TOKEN
  // =========================
  static Future<String?> getToken() async {
    return await TokenStorage.getToken();
  }

  // =========================
  // LOGOUT
  // =========================
  static Future<void> logout() async {
    await TokenStorage.clearToken();
  }
}
