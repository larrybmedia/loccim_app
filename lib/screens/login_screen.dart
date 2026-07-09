import 'package:flutter/material.dart';
import 'package:loccim_app/services/api_client.dart'; // 📥 Connected directly to your central API manager

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // 🛠️ REFACTORED LOGIN DISPATCHER
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // 📡 Offload network operation entirely to our verified ApiClient
    final loginResult = await ApiClient.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (loginResult != null && loginResult["success"] == true) {
      // 🎉 Handshake complete! Redirecting safely via named routes in main.dart
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      // ❌ Fallback on unauthorized response statuses
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid username or password credentials supplied."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "LOCCIM ADMIN LOGIN",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4B0082),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 35),

                // Username field
                TextFormField(
                  controller: _usernameController,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Username cannot be blank'
                      : null,
                  decoration: const InputDecoration(
                    labelText: "Username",
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: Color(0xFF4B0082),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Password cannot be blank'
                      : null,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: Color(0xFF4B0082),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF4B0082),
                        ),
                      )
                    : SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4B0082),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _handleLogin,
                          child: const Text(
                            "LOGIN TO LOCCIM",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
