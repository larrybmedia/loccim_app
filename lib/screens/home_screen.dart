import 'package:flutter/material.dart';
import 'live_stream_screen.dart';
import 'prayer_screen.dart';
import 'testimony_screen.dart';
import 'offering_screen.dart';
// If these cause errors, ensure the files exist in the same directory:
import 'books_screen.dart';
import '../services/api_client.dart';
import '../services/socket_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'contact_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String liveUrl = "";
  bool loadingLive = true;

  final SocketService socketService = SocketService();

  @override
  void initState() {
    super.initState();
    loadLiveStream();
    socketService.connect();

    socketService.onLiveStreamUpdated = (url) {
      if (!mounted) return;

      setState(() {
        liveUrl = url;
        loadingLive = false;
      });
    };
  }

  Future<void> loadLiveStream() async {
    try {
      final url = await ApiClient.getLiveStreamUrl();
      if (!mounted) return;
      setState(() {
        liveUrl = url ?? "";
        loadingLive = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        liveUrl = "";
        loadingLive = false;
      });
    }
  }

  Future<void> openAdminLogin() async {
    final Uri url = Uri.parse("https://loccim-backend.onrender.com");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    socketService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 800 ? 3 : 2;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              "assets/images/church_background.jpg",
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.black.withOpacity(0.25),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 📺 LIVE BANNER SECTION
                // 📺 HERO BANNER SECTION
                Container(
                  width: double.infinity,
                  height: 320,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: const DecorationImage(
                      image: AssetImage(
                        "assets/images/church_background.jpg",
                      ),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black54,
                        BlendMode.darken,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "WELCOME TO LOCCIM",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Love of Christ Church\nInternational Ministry",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Raising Disciples • Restoring Lives • Impacting Communities",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF4B0082),
                              ),
                              onPressed: liveUrl.isEmpty
                                  ? null
                                  : () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => LiveStreamScreen(
                                              liveUrl: liveUrl),
                                        ),
                                      ),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text("WATCH LIVE"),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white),
                              ),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ContactScreen(),
                                ),
                              ),
                              icon: const Icon(Icons.phone),
                              label: const Text("CONTACT"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 📺 BROADCAST STATUS CARD
                Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    avatar: const Icon(
                      Icons.live_tv,
                      color: Colors.red,
                      size: 20,
                    ),
                    label: Text(
                      loadingLive
                          ? "Loading livestream..."
                          : (liveUrl.isEmpty
                              ? "No active livestream"
                              : "Current Broadcast"),
                    ),
                    backgroundColor: Colors.white,
                    elevation: 2,
                  ),
                ),

                const SizedBox(height: 30),

                // ⛪ MINISTRIES & TOOLS GRID
                const Text(
                  "Church Ministries & Tools",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.55,
                  children: [
                    _menuButton(
                      context,
                      title: "Prayer Request",
                      icon: Icons.favorite,
                      bgColor: Colors.pink.shade50,
                      iconColor: Colors.pink,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PrayerScreen()),
                      ),
                    ),
                    _menuButton(
                      context,
                      title: "Testimonies",
                      icon: Icons.record_voice_over,
                      bgColor: Colors.orange.shade50,
                      iconColor: Colors.orange,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const TestimonyScreen()),
                      ),
                    ),
                    _menuButton(
                      context,
                      title: "Tithes & Offering",
                      icon: Icons.volunteer_activism,
                      bgColor: Colors.green.shade50,
                      iconColor: Colors.green,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const OfferingScreen()),
                      ),
                    ),
                    _menuButton(
                      context,
                      title: "Watch Live",
                      icon: Icons.live_tv_rounded,
                      bgColor: Colors.red.shade50,
                      iconColor: Colors.red,
                      onTap: liveUrl.isEmpty
                          ? null
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      LiveStreamScreen(liveUrl: liveUrl),
                                ),
                              ),
                    ),
                    _menuButton(
                      context,
                      title: "Dashboard Panel",
                      icon: Icons.dashboard_customize,
                      bgColor: Colors.purple.shade50,
                      iconColor: Colors.purple,
                      onTap: openAdminLogin,
                    ),
                    // Added Books link back here to ensure the import is used:
                    _menuButton(
                      context,
                      title: "Books",
                      icon: Icons.book,
                      bgColor: Colors.blue.shade50,
                      iconColor: Colors.blue,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BooksScreen()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ), // SingleChildScrollView
        ), // Dark overlay Container
      ), // Background image Container
    ); // Scaffold
  }

  Widget _menuButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback? onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: onTap == null ? Colors.grey.shade200 : bgColor,
                child: Icon(
                  icon,
                  size: 22,
                  color: onTap == null ? Colors.grey : iconColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
