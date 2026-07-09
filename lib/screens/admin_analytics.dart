import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_client.dart';
import '../services/socket_service.dart';

class AdminAnalytics extends StatefulWidget {
  const AdminAnalytics({super.key});

  @override
  State<AdminAnalytics> createState() => _AdminAnalyticsState();
}

class _AdminAnalyticsState extends State<AdminAnalytics> {
  int prayers = 0;
  int sermons = 0;
  int testimonies = 0;

  int onlineUsers = 0;

  bool loading = true;

  final SocketService socketService = SocketService();

  @override
  void initState() {
    super.initState();
    loadInitialData();
    connectSocket();
  }

  Future<void> loadInitialData() async {
    try {
      final data = await ApiClient.getAnalytics();

      if (!mounted) return;

      setState(() {
        prayers = (data["prayers"] ?? 0) as int;
        sermons = (data["sermons"] ?? 0) as int;
        testimonies = (data["testimonies"] ?? 0) as int;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      print("Analytics error: $e");
    }
  }

  void connectSocket() {
    socketService.connect();

    socketService.onDashboardUpdate = (data) async {
      if (!mounted) return;

      final updated = await ApiClient.getAnalytics();

      if (!mounted) return;

      setState(() {
        prayers = (updated["prayers"] ?? 0) as int;
        sermons = (updated["sermons"] ?? 0) as int;
        testimonies = (updated["testimonies"] ?? 0) as int;
      });
    };

    socketService.onUsersOnline = (count) {
      if (!mounted) return;

      setState(() {
        onlineUsers = (count ?? 0);
      });
    };
  }

  @override
  void dispose() {
    socketService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Analytics Dashboard"),
        backgroundColor: Colors.deepPurple,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    "LOCCIM Live Analytics 📊",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                  // 👥 ONLINE USERS CARD (✔ CORRECT PLACE HERE)
                  Card(
                    color: Colors.orange.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            "$onlineUsers",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const Text("Online Users"),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 📊 CHART
                  SizedBox(
                    height: 250,
                    child: BarChart(
                      BarChartData(
                        barGroups: [
                          BarChartGroupData(
                            x: 1,
                            barRods: [
                              BarChartRodData(
                                toY: prayers.toDouble(),
                                width: 20,
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 2,
                            barRods: [
                              BarChartRodData(
                                toY: sermons.toDouble(),
                                width: 20,
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 3,
                            barRods: [
                              BarChartRodData(
                                toY: testimonies.toDouble(),
                                width: 20,
                              ),
                            ],
                          ),
                        ],
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                switch (value.toInt()) {
                                  case 1:
                                    return const Text("Prayers");
                                  case 2:
                                    return const Text("Sermons");
                                  case 3:
                                    return const Text("Testimonies");
                                  default:
                                    return const Text("");
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 📊 SUMMARY CARDS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statCard("Prayers", prayers, Colors.red),
                      _statCard("Sermons", sermons, Colors.blue),
                      _statCard("Testimonies", testimonies, Colors.green),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _statCard(String title, int value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "$value",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }
}
