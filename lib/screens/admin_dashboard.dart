import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'dart:ui_web' as ui_web;

import 'package:web/web.dart' as web;

import 'package:http/http.dart' as http;

import 'dart:convert';

import 'dart:js_interop';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // Store the listener to remove it on dispose

  late final JSFunction _messageListener;

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      // 1. Define the message listener

      _messageListener = ((web.Event event) {
        final messageEvent = event as web.MessageEvent;

        try {
          final data = jsonDecode(messageEvent.data.toString());

          if (data['action'] == 'doLogin') {
            _performLogin(data['username'], data['password']);
          }
        } catch (e) {
          debugPrint("DEBUG: Listener Error: $e");
        }
      }).toJS;

      // 2. Add listener to the global window

      web.window.addEventListener('message', _messageListener);

      // 3. Register the iframe view factory

      try {
        ui_web.platformViewRegistry.registerViewFactory('admin-login-html',
            (int viewId) {
          final web.HTMLIFrameElement iframe = web.HTMLIFrameElement()
            ..src = 'https://loccim-backend.onrender.com'
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%'
            ..setAttribute('sandbox',
                'allow-forms allow-scripts allow-same-origin allow-top-navigation');

          return iframe;
        });
      } catch (e) {
        debugPrint("Factory already registered.");
      }
    }
  }

  @override
  void dispose() {
    if (kIsWeb) {
      web.window.removeEventListener('message', _messageListener);
    }

    super.dispose();
  }

  Future<void> _performLogin(String username, String password) async {
    try {
      final url = Uri.parse('https://loccim-backend.onrender.com/api/login');

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );

      final responseData = jsonDecode(response.body);

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Login Successful!"),
                backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(responseData['error'] ?? "Login failed"),
                backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      debugPrint("Error during login: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Connection error. Check Flask server."),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Management Panel"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: kIsWeb
          ? const SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: HtmlElementView(viewType: 'admin-login-html'),
            )
          : const Center(
              child: Text("Admin panel is only available on Web."),
            ),
    );
  }
}
