import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../api_config.dart';
import '../models/user_model.dart';

final currentUserProvider = StateProvider<UserModel?>((ref) => null);

class AuthService {
  static Future<UserModel?> fetchUserProfile(String phoneNumber) async {
    try {
      final sanitizedPhone = phoneNumber.replaceAll(' ', '').trim();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/users/profile/$sanitizedPhone'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['user'] != null) {
          return UserModel.fromJson(data['user']);
        }
      }
    } catch (e) {
      // Log/ignore errors
      print('Error fetching user profile: $e');
    }
    return null;
  }
}
