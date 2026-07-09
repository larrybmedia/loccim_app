import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final String apiUrl = "https://loccim-backend.onrender.com/api/events";

  static const String baseUrl = "https://loccim-backend.onrender.com";
  Future<List<dynamic>> fetchEvents() async {
    print("🔥 fetchEvents() called");

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
      );

      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to load events");
      }
    } catch (e) {
      print("Event Error: $e");
      throw Exception("Connection Error: $e");
    }
  }

  void _showEventDetails(BuildContext context, mapData) {
    final String imageUrl = mapData['image_url'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              if (imageUrl.isNotEmpty && imageUrl != "null")
                Expanded(
                  flex: 4,
                  child: Container(
                    color: Colors.black,
                    width: double.infinity,
                    child: InteractiveViewer(
                      child: Image.network(
                        imageUrl.startsWith("http")
                            ? imageUrl
                            : "$baseUrl$imageUrl",
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.broken_image,
                                color: Colors.grey, size: 40),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mapData['title'] ?? 'No Title',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4B0082),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text("📅 ${mapData['date'] ?? 'N/A'}"),
                      const SizedBox(height: 12),
                      Text("📍 ${mapData['location'] ?? 'N/A'}"),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("✨ Upcoming Church Events"),
        backgroundColor: const Color(0xFF4B0082),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: fetchEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Error loading events"),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("No upcoming church events scheduled at this time."),
            );
          }

          final events = snapshot.data!;

          print("EVENT COUNT: ${events.length}");

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: events.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.80,
            ),
            itemBuilder: (context, index) {
              final event = events[index];

              final String title = event['title'] ?? 'No Title';
              final String date = event['date'] ?? 'N/A';
              final String location = event['location'] ?? 'N/A';

              final String imageUrl = (event['image_url'] ?? '').toString();

              print("EVENT [$index]: $title");

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _showEventDetails(context, event),
                        child: (imageUrl.isNotEmpty && imageUrl != "null")
                            ? Image.network(
                                imageUrl.startsWith("http")
                                    ? imageUrl
                                    : "https://loccim-backend.onrender.com$imageUrl",
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: Icon(Icons.broken_image),
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Text("No Flyer"),
                                ),
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4B0082),
                            ),
                          ),
                          Text("📅 $date"),
                          Text("📍 $location"),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
