import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:just_audio/just_audio.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/foundation.dart';

class SermonsScreen extends StatefulWidget {
  const SermonsScreen({super.key});

  @override
  State<SermonsScreen> createState() => _SermonsScreenState();
}

class _SermonsScreenState extends State<SermonsScreen> {
  final String apiUrl = "https://loccim-backend.onrender.com/api/sermons";

  final AudioPlayer _player = AudioPlayer();

  // 🟢 Track which sermon cards are expanded by saving their indexes
  final Map<int, bool> _expandedNotes = {};

  Future<List<dynamic>> fetchSermons() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      // These logs will appear in your Debug Console to help you diagnose the connection
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching data: $e");
      throw Exception("Failed to connect: $e");
    }
  }

  Future<void> downloadAudioFile(String url) async {
    try {
      // Flutter Web
      if (kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Downloading is available in the browser.",
            ),
          ),
        );

        return;
      }

      // Android permissions
      if (Platform.isAndroid) {
        await Permission.storage.request();
        await Permission.manageExternalStorage.request();
      }

      final dir = await getApplicationDocumentsDirectory();

      final fileName = "LOCCIM_${DateTime.now().millisecondsSinceEpoch}.mp3";

      final savePath = "${dir.path}/$fileName";

      await Dio().download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            debugPrint(
              "Downloading ${(received / total * 100).toStringAsFixed(0)}%",
            );
          }
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Download complete!\n$fileName"),
          ),
        );
      }

      await OpenFilex.open(savePath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Download failed: $e"),
          ),
        );
      }
    }
  }

  Future<void> playAudio(String url) async {
    try {
      await _player.stop();
      await _player.setUrl(url);
      await _player.play();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Unable to play audio: $e"),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📚 Sermon Archive & Media"),
        backgroundColor: const Color(0xFF4B0082),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: fetchSermons(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text("Error fetching records: ${snapshot.error}",
                    textAlign: TextAlign.center),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No sermons uploaded yet."));
          }

          final sermons = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: sermons.length,
            itemBuilder: (context, index) {
              final sermon = sermons[index];

              final int id = sermon['id'] ?? index;
              final String title = sermon['title'] ?? 'Untitled Sermon';
              final String notes = sermon['notes'] ?? '';

              final String audioUrl1 = sermon['audio_url_1']?.toString() ?? "";
              final String audioUrl2 = sermon['audio_url_2']?.toString() ?? "";
              final String sermonDate = sermon['sermon_date']?.toString() ?? "";

              // Debug logs
              print("Track 1: $audioUrl1");
              print("Track 2: $audioUrl2");
              print("Date: $sermonDate");

              bool isExpanded = _expandedNotes[id] ?? false;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.audiotrack,
                            color: Color(0xFF4B0082),
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (sermonDate.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 15,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              sermonDate,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (notes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notes,
                                maxLines: isExpanded ? null : 3,
                                overflow: isExpanded
                                    ? TextOverflow.visible
                                    : TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                  height: 1.4,
                                ),
                              ),
                              if (notes.length > 120)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _expandedNotes[id] = !isExpanded;
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(50, 30),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      isExpanded ? "See Less" : "See More",
                                      style: const TextStyle(
                                        color: Color(0xFF4B0082),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Divider(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ================= TRACK 1 =================
                          if (audioUrl1.isNotEmpty)
                            Card(
                              elevation: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Track 1",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                            ),
                                            onPressed: () =>
                                                playAudio(audioUrl1),
                                            icon: const Icon(Icons.play_arrow),
                                            label: const Text("Play"),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFF4B0082),
                                              foregroundColor: Colors.white,
                                            ),
                                            onPressed: () =>
                                                downloadAudioFile(audioUrl1),
                                            icon: const Icon(Icons.download),
                                            label: const Text("Download"),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                "No Track 1 uploaded",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),

                          const SizedBox(height: 12),

                          // ================= TRACK 2 =================
                          if (audioUrl2.isNotEmpty)
                            Card(
                              elevation: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Track 2",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              foregroundColor: Colors.white,
                                            ),
                                            onPressed: () =>
                                                playAudio(audioUrl2),
                                            icon: const Icon(Icons.play_arrow),
                                            label: const Text("Play"),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFF4B0082),
                                              foregroundColor: Colors.white,
                                            ),
                                            onPressed: () =>
                                                downloadAudioFile(audioUrl2),
                                            icon: const Icon(Icons.download),
                                            label: const Text("Download"),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                "No Track 2 uploaded",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
