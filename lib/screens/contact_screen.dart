import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  Future<void> _call(String number) async {
    final uri = Uri.parse("tel:$number");
    await launchUrl(uri);
  }

  Future<void> _whatsapp() async {
    final uri = Uri.parse("https://wa.me/2348108647938");
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _email() async {
    final uri = Uri.parse("mailto:support@loccim.org");
    await launchUrl(uri);
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _cardTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withOpacity(0.25),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(
                  icon,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 15,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: color,
            elevation: 2,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: Icon(icon),
          label: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed: onTap,
        ),
      ),
    );
  }

  Widget _addressCard() {
    return Center(
      child: SizedBox(
        width: 500,
        child: Card(
          elevation: 6,
          color: Colors.white.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Colors.red,
                    ),
                    SizedBox(width: 6),
                    Text(
                      "Church Address",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const CircleAvatar(
                  radius: 35,
                  backgroundColor: Color(0xFFFFEBEE),
                  child: Icon(
                    Icons.location_city,
                    size: 38,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  "Love of Christ Church International Ministry (LOCCIM)",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Makogi Rd, Abule oba, Magboro 110115, Ogun State, Nigeria",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => _open(
                      "https://www.google.com/maps/place/MERCY+CAMP+Love+of+Christ+Chapel+International+Ministries+(LOCCIM)/@6.7457544,3.3858393,17z/data=!4m23!1m16!4m15!1m6!1m2!1s0x103bbf01e1e0ed2b:0x895ab2f4f6949572!2sMERCY+CAMP+Love+of+Christ+Chapel+International+Ministries+(LOCCIM),+Makogi+Rd,+Abule+oba,+Magboro+110115,+Ogun+State!2m2!1d3.3884142!2d6.7457544!1m6!1m2!1s0x103bbf01e1e0ed2b:0x895ab2f4f6949572!2sMERCY+CAMP+Love+of+Christ+Chapel+International+Ministries+(LOCCIM),+Makogi+Rd,+Abule+oba,+Magboro+110115,+Ogun+State!2m2!1d3.3884142!2d6.7457544!3e3!3m5!1s0x103bbf01e1e0ed2b:0x895ab2f4f6949572!8m2!3d6.7457544!4d3.3884142!16s%2Fg%2F11x6lcx9t_?entry=ttu&g_ep=EgoyMDI2MDcwNi4wIKXMDSoASAFQAw%3D%3D",
                    ),
                    icon: const Icon(Icons.directions),
                    label: const Text("Get Directions"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===================== BUILD =====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contact LOCCIM"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              "assets/images/contact_bg.jpg",
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.black.withOpacity(0.45),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    "We are always available to connect with you",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: SizedBox(
                      width: 500,
                      child: Card(
                        elevation: 6,
                        color: Colors.white.withOpacity(0.95),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.call, color: Colors.green),
                                  SizedBox(width: 6),
                                  Text(
                                    "Phone Lines",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _cardTile(
                                title: "Pastoral Line",
                                subtitle: "+234 810 864 7938",
                                icon: Icons.phone,
                                color: Colors.green,
                                onTap: () => _call("+2348108647938"),
                              ),
                              _cardTile(
                                title: "Office Line",
                                subtitle: "+234 803 123 4567",
                                icon: Icons.phone,
                                color: Colors.green,
                                onTap: () => _call("+2348031234567"),
                              ),
                              _cardTile(
                                title: "Ministry Line",
                                subtitle: "+234 812 555 8888",
                                icon: Icons.phone,
                                color: Colors.green,
                                onTap: () => _call("+2348125558888"),
                              ),
                              _cardTile(
                                title: "Support Line",
                                subtitle: "+234 809 444 2222",
                                icon: Icons.phone,
                                color: Colors.green,
                                onTap: () => _call("+2348094442222"),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Center(
                    child: SizedBox(
                      width: 500,
                      child: Card(
                        elevation: 6,
                        color: Colors.white.withOpacity(0.95),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.chat, color: Colors.deepPurple),
                                  SizedBox(width: 6),
                                  Text(
                                    "Messaging",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _cardTile(
                                title: "WhatsApp Chat",
                                subtitle: "Instant response support",
                                icon: Icons.chat,
                                color: Colors.green,
                                onTap: _whatsapp,
                              ),
                              _cardTile(
                                title: "Email Support",
                                subtitle: "support@loccim.org",
                                icon: Icons.email,
                                color: Colors.red,
                                onTap: _email,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  _addressCard(),
                  const SizedBox(height: 25),
                  const SizedBox(height: 30),
                  Center(
                    child: SizedBox(
                      width:
                          360, // Reduce this value to make the white card narrower
                      child: Card(
                        elevation: 6,
                        color: Colors.white.withOpacity(0.95),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.public,
                                    color: Colors.deepPurple,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    "Social Media",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _socialButton(
                                "YouTube Channel",
                                Icons.play_circle_fill,
                                Colors.red,
                                () => _open(
                                  "https://www.youtube.com/@MercyMandateTV",
                                ),
                              ),
                              _socialButton(
                                "Facebook Page",
                                Icons.facebook,
                                Colors.blue,
                                () => _open(
                                  "https://www.facebook.com/profile.php?id=61561593210358",
                                ),
                              ),
                              _socialButton(
                                "Instagram",
                                Icons.camera_alt,
                                Colors.purple,
                                () => _open(
                                  "https://www.instagram.com/prophetolowoporoku/",
                                ),
                              ),
                              _socialButton(
                                "TikTok",
                                Icons.music_note,
                                Colors.black,
                                () => _open(
                                  "https://www.tiktok.com/discover/prophet-olowoporoku-live",
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "LOCCIM Ministries responds to all inquiries within 24 hours.",
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
