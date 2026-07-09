import 'package:flutter/material.dart';
import 'dart:convert'; // 🟢 Added for jsonEncode
import 'package:http/http.dart' as http; // 🟢 Added for HTTP POST processing

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  // Controllers to capture user input and clear them on submit
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // 🟢 Marked async to safely wait for network requests without locking the UI thread
  Future<void> _submitRequest() async {
    final String nameText = _nameController.text.trim();
    final String descriptionText = _descriptionController.text.trim();

    // 1. Basic validation check to make sure textfields aren't completely empty
    if (nameText.isEmpty || descriptionText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in both fields before submitting."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 🟢 2. Integrated API Client logic connecting straight to your Flask backend
    final url = Uri.parse('https://loccim-backend.onrender.com/api/prayers');
    bool hasError = false;

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type':
              'application/json', // Critical parameter signature matching API expectations
        },
        body: jsonEncode({
          'name': nameText,
          'message':
              descriptionText, // Matches Flask's requirement for .get("message")
        }),
      );

      if (response.statusCode != 201) {
        hasError = true;
        print("Server error payload response: ${response.body}");
      }
    } catch (networkError) {
      hasError = true;
      print("Network infrastructure routing fail: $networkError");
    }

    // Handle feedback response based on API connection status
    if (hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Could not sync with server. Check local connection endpoints.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return; // Stop execution if connection failed so data isn't lost from fields
    }

    // 3. Display the elegant green success toast message at the bottom
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text(
              "Request submitted successfully!",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );

    // 4. Wipe the text input forms clean after successful submission
    _nameController.clear();
    _descriptionController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Prayer Requests"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Submit Your Prayer Request",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "We believe in the power of agreement. Share your burden with our intercession team.",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController, // 👈 Hooked up the controller
              decoration: InputDecoration(
                labelText: "Your Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController, // 👈 Hooked up the controller
              maxLines: 4,
              decoration: InputDecoration(
                labelText: "Prayer Description",
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed:
                    _submitRequest, // 👈 Triggers the logic function up top
                child: const Text(
                  "Submit Request",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
