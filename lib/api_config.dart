import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Toggle this to [true] only if testing with USB cable ADB reverse.
  /// When using the deployed cloud backend, keep this [false].
  static const bool useAdbReverseForPhysicalAndroid = false;

  /// Deployed cloud backend URL (Render.com)
  static const String publicTunnelUrl = 'https://final-year-project-kutumbsetu-backned.onrender.com';

  /// Alternatively, enter your computer's local Wi-Fi IP address here (e.g., '192.168.1.15')
  static const String localWifiIp = '';

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
