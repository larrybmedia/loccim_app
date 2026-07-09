import 'package:flutter/material.dart';

class LiveScreen extends StatelessWidget {
  const LiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Live Service")),
      body: const Center(
        child: Text("LOCCIM Live Stream", style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
