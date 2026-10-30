import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../api_config.dart';
import '../models/user_model.dart';

/// Holds the currently logged-in user's profile across the app.
final currentUserProvider = StateProvider<UserModel?>((ref) => null);

/// Service for authentication-related network calls.
class AuthService {
  /// Fetches a user's profile from the backend using their phone number.
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

/// Authentication state including current user, loading status, and error message.
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  /// True if a user is currently authenticated.
  bool get isAuthenticated => user != null;

  /// True if the authenticated user has admin privileges.
  bool get isAdmin => user?.isAdmin ?? false;

  /// Returns a copy of this state with updated values.
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

/// Manages authentication lifecycle, profile retrieval, and role switching.
class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;

  AuthNotifier(this.ref) : super(const AuthState()) {
    final current = ref.read(currentUserProvider);
    if (current != null) {
      state = state.copyWith(user: current);
    }
  }

  /// Fetches user profile by phone number and updates the authentication state.
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

  /// Updates the currently active user profile.
  void setUser(UserModel user) {
    if (state.user != user) {
      state = state.copyWith(user: user);
    }
  }

  /// Toggles between Admin and User roles and persists changes to the backend.
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

  /// Clears user session and logs out.
  void logout() {
    state = state.copyWith(clearUser: true);
    ref.read(currentUserProvider.notifier).state = null;
  }
}

/// Provider managing authentication state and keeping it in sync with [currentUserProvider].
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final notifier = AuthNotifier(ref);

  // Sync authProvider state when currentUserProvider is updated externally
  ref.listen<UserModel?>(currentUserProvider, (previous, next) {
    if (next != null) {
      notifier.setUser(next);
    } else {
      notifier.logout();
    }
  });

  return notifier;
});
