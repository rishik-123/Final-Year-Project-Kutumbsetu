import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../api_config.dart';
import '../models/user_model.dart';

// StateProvider used by the Directory, Matrimonial, and Family Tree features
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
      print('Error fetching user profile: $e');
    }
    return null;
  }
}

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;
  bool get isAdmin => user?.isAdmin ?? false;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;

  AuthNotifier(this.ref) : super(const AuthState()) {
    final current = ref.read(currentUserProvider);
    if (current != null) {
      state = state.copyWith(user: current);
    }
  }

  Future<void> fetchUserByPhone(String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final sanitizedPhone = phone.replaceAll(' ', '').trim();
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/users/by-phone/$sanitizedPhone'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['user'] != null) {
          final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
          state = state.copyWith(user: user, isLoading: false);
          ref.read(currentUserProvider.notifier).state = user;
          return;
        }
      }
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setUser(UserModel user) {
    if (state.user != user) {
      state = state.copyWith(user: user);
    }
  }

  void toggleAdminRole() async {
    if (state.user == null) return;
    final currentRole = state.user!.role;
    final newRole = (currentRole == 'admin' || currentRole == 'organizer') ? 'user' : 'admin';
    final updatedUser = state.user!.copyWith(role: newRole);

    state = state.copyWith(user: updatedUser);
    ref.read(currentUserProvider.notifier).state = updatedUser;

    try {
      await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/users/${updatedUser.id}/role'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'role': newRole}),
      );
    } catch (_) {}
  }

  void logout() {
    state = state.copyWith(clearUser: true);
    ref.read(currentUserProvider.notifier).state = null;
  }
}

// StateNotifierProvider used by the Campaign feature
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final notifier = AuthNotifier(ref);

  // Sync authProvider state when currentUserProvider is mutated directly (e.g. at login screen)
  ref.listen<UserModel?>(currentUserProvider, (previous, next) {
    if (notifier.state.user != next) {
      if (next != null) {
        notifier.setUser(next);
      } else {
        notifier.logout();
      }
    }
  });

  return notifier;
});
