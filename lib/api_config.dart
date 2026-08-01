import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Toggle this to [true] if testing on a physical Android device connected via USB/C2C cable.
  /// You MUST run the following command in your terminal first to forward port 5000:
  /// `adb reverse tcp:5000 tcp:5000`
  static const bool useAdbReverseForPhysicalAndroid = false;

  /// If you are using a tunneling service like ngrok to expose your local backend publicly
  /// (which allows connecting even when your device is on mobile data or a different network),
  /// enter the public URL here (e.g., 'https://xxxx-xx-xx-xx.ngrok-free.app').
  /// Leave empty to use local network/emulator detection.
  static const String publicTunnelUrl = '';

  /// Alternatively, enter your computer's local Wi-Fi IP address here (e.g., '192.168.1.15')
  /// if your physical device is connected to the same Wi-Fi network.
  /// Your current local Wi-Fi IP address on the network is: '192.168.0.101'
  static const String localWifiIp = '192.168.0.101';

  /// Base API URL pointing to the local Node.js Express server.
  static String get baseUrl {
    if (publicTunnelUrl.isNotEmpty) {
      return '$publicTunnelUrl/api';
    }
    if (!kIsWeb && Platform.isAndroid && useAdbReverseForPhysicalAndroid) {
      return 'http://127.0.0.1:5000/api';
    }
    if (localWifiIp.isNotEmpty) {
      return 'http://$localWifiIp:5000/api';
    }
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api';
    }
    return 'http://localhost:5000/api';
  }
}
