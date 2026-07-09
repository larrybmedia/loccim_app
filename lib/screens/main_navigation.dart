import 'package:flutter/material.dart';
import '../services/token_storage.dart'; // Verified storage path
import 'home_screen.dart';
import 'about_screen.dart';
import 'sermons_screen.dart';
import 'events_screen.dart';
import 'gallery_screen.dart';
import 'books_screen.dart';
import 'login_screen.dart';
import 'announcement_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;

  // 📝 Removed 'const' so sub-screens can dynamically reconstruct on state updates
  final List<Widget> pages = const [
    HomeScreen(), // Index 0
    AboutScreen(), // Index 1
    AnnouncementScreen(), // Index 2
    GalleryScreen(), // Index 3
    SermonsScreen(), // Index 4
    EventsScreen(), // Index 5
    BooksScreen(), // Index 6
  ];

  @override
  void initState() {
    super.initState();
    checkAuth();
  }

  // 🔐 FIXED: Updated to check the unified session state
  Future<void> checkAuth() async {
    final bool loggedIn = await TokenStorage.isLoggedIn();

    if (!loggedIn) {
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // 🚪 FIXED: Updated to clear the complete session footprint cleanly
  Future<void> logout() async {
    await TokenStorage.clearToken();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("LOCCIM Ministries"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
            tooltip: 'Logout Admin Session',
          ),
        ],
      ),
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType
            .fixed, // ⚙️ Keeps all 5 structural tabs balanced
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey.shade600,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: "About Us",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library),
            label: "Announcement",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library),
            label: "Gallery",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: "Sermons",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: "Events"),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_rounded),
            label: "Books",
          ),
        ],
      ),
    );
  }
}
