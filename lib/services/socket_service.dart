import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  IO.Socket? socket;

  Function(dynamic)? onEvent;
  Function(int)? onUsersOnline;
  Function(dynamic)? onDashboardUpdate;
  Function(String)? onLiveStreamUpdated;

  // 🟢 DISABLED FOR PRODUCTION SPEED (NO LAG / NO RETRIES)
  void connect() {
    debugPrint("🚀 Socket disabled for production performance");
    return;
  }

  // 🔥 DEV VERSION (UNCOMMENT WHEN NEEDED)
  /*
  void connectDev() {
    String socketUrl = "https://loccim-backend.onrender.com";

    debugPrint("🔄 Initiating Socket connection: $socketUrl");

    socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setTransports(['polling'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(2000)
          .build(),
    );

    socket!.connect();

    socket!.onConnect((_) {
      debugPrint("✅ Socket connected successfully!");
    });

    socket!.onDisconnect((_) {
      debugPrint("🔌 Socket disconnected");
    });

    socket!.onConnectError((error) {
      debugPrint("⚠️ Connection failed: $error");
    });

    socket!.on("livestream_updated", (data) {
      try {
        final url = data["live_url"]?.toString() ?? "";
        if (url.isNotEmpty) {
          onLiveStreamUpdated?.call(url);
        }
      } catch (e) {
        debugPrint("❌ Livestream update error: $e");
      }
    });

    socket!.on("dashboard_update", (data) {
      onDashboardUpdate?.call(data);
    });
  }
  */

  void disconnect() {
    if (socket != null) {
      if (socket!.connected) {
        socket!.disconnect();
      }
      socket!.dispose();
      socket = null;
    }
    debugPrint("🔌 Socket connection closed.");
  }
}
