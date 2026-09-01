import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // Helper for mission bullet points
  Widget missionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6.0, right: 8.0),
            child: Icon(Icons.circle, size: 8, color: Color(0xFF4B0082)),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLeader(String image, String name, String title) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: AssetImage(image),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About Us"),
        backgroundColor: const Color(0xFF4B0082),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Hero Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF4B0082), Color(0xFF7B1FA2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 6)),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.white,
                    backgroundImage: const AssetImage("assets/images/logo.png"),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "LOVE OF CHRIST\nCHURCH INTERNATIONAL\nMINISTRY",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Restoring Hope • Raising Disciples • Transforming Lives",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Welcome Card
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      children: [
                        Icon(Icons.church, color: Color(0xFF4B0082), size: 28),
                        SizedBox(width: 10),
                        Text("Welcome to LOCCIM",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                color: Color(0xFF4B0082))),
                      ],
                    ),
                    SizedBox(height: 20),
                    const Text(
                      "Join us in a place where faith, fellowship, and love converge. At Love of Christ Chapel International, we are a community united by our shared values and a deep connection with the divine.\n\n"
                      "Experience the warmth of our congregation as we come together to celebrate, uplift, and serve. Your presence adds to the tapestry of voices that make our community unique.\n\n"
                      "Whether you are beginning your spiritual journey or seeking a new home, our chapel offers a place to grow in faith and forge meaningful connections.\n\n"
                      "Welcome once again to Love of Christ Chapel International. Here, you will find blessings, growth, and the love of Christ.",
                      textAlign: TextAlign.justify,
                      style: TextStyle(fontSize: 16, height: 1.7),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Vision & Mission
            _buildInfoCard("Our Vision", Icons.visibility,
                "We are an end-time church of Christ..."),
            const SizedBox(height: 25),

            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.flag, color: Color(0xFF4B0082)),
                        SizedBox(width: 10),
                        Text("Mission & Purpose",
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4B0082))),
                      ],
                    ),
                    const SizedBox(height: 18),
                    missionItem(
                        "To make Heaven and take as many people as possible with us."),
                    missionItem(
                        "To destroy every activity of Satan and release people into God's divine purpose."),
                    missionItem(
                        "To raise genuine worshippers who honour God through holy living."),
                    missionItem(
                        "To become role models of Christ in character, leadership and service."),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
            buildLeader("assets/images/go.jpg",
                "Prophet Adeniyi P. Olowoporoku", "General Overseer"),
            const SizedBox(height: 40),

            // Leadership Grid
            Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: [
                _buildLeaderItem(
                    "assets/images/mrs_go.jpg",
                    "Pastor (Mrs) Grace Olowoporoku",
                    "Wife of the General Overseer"),
                // ... add other items similarly
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Refactor to reduce repetition
  Widget _buildInfoCard(String title, IconData icon, String content) {
    return Card(
      color: const Color(0xffF8F3FF),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: const Color(0xFF4B0082)),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4B0082)))
            ]),
            const SizedBox(height: 18),
            Text(content,
                textAlign: TextAlign.justify,
                style: const TextStyle(fontSize: 16, height: 1.7)),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderItem(String img, String name, String title) {
    return SizedBox(width: 180, child: buildLeader(img, name, title));
  }
}
