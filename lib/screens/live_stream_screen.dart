import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_client.dart';

class LiveStreamScreen extends StatefulWidget {
  final String? liveUrl;

  const LiveStreamScreen({super.key, this.liveUrl});

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> {
  bool _loading = true;
  String _liveUrl = "";

  @override
  void initState() {
    super.initState();
    _loadLive();
  }

  Future<void> _loadLive() async {
    if (widget.liveUrl != null && widget.liveUrl!.isNotEmpty) {
      setState(() {
        _liveUrl = widget.liveUrl!;
        _loading = false;
      });
      return;
    }

    final url = await ApiClient.getLiveStreamUrl();

    setState(() {
      _liveUrl = url ?? "";
      _loading = false;
    });
  }

  Future<void> _watchLive() async {
    if (_liveUrl.isEmpty) return;

    await launchUrl(
      Uri.parse(_liveUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("LOCCIM Live"),
        backgroundColor: const Color(0xFF4B0082),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : _liveUrl.isEmpty
                ? const Text("No live broadcast available.")
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.live_tv,
                        size: 90,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Live Broadcast is Active",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 25),
                      ElevatedButton.icon(
                        onPressed: _watchLive,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text("Watch Live"),
                      ),
                    ],
                  ),
      ),
    );
  }
}
