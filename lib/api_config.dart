import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Toggle this to [true] if testing on a physical Android device connected via USB/C2C cable.
  /// You MUST run the following command in your terminal first to forward port 5000:
  /// `adb reverse tcp:5000 tcp:5000`
  static const bool useAdbReverseForPhysicalAndroid = true;

  /// Alternatively, enter your computer's local Wi-Fi IP address here (e.g., '192.168.1.15')
  /// if your physical device is connected to the same Wi-Fi network:
  static const String localWifiIp = '10.110.9.208';

  /// Base API URL pointing to the local Node.js Express server.
  static String get baseUrl {
    if (localWifiIp.isNotEmpty) {
      return 'http://$localWifiIp:5000/api';
    }
    if (!kIsWeb && Platform.isAndroid) {
      if (useAdbReverseForPhysicalAndroid) {
        return 'http://127.0.0.1:5000/api';
      }
      return 'http://10.0.2.2:5000/api';
    }
    return 'http://localhost:5000/api';
  }
}
