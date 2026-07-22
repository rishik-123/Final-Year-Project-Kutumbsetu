import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Base API URL pointing to the local Node.js Express server.
  /// Resolves to http://10.0.2.2:5000/api on Android Emulator
  /// and http://localhost:5000/api on iOS, Web, or standard hosts.
  static String get baseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api';
    }
    return 'http://localhost:5000/api';
  }
}
