/// ============================================================================
/// KutumbSetu - Authentication & User State Providers
/// ============================================================================
/// Handles user authentication, persistent session tracking, role-based
/// authorization (Admin vs. Community Member), and global user profile caching.
///
/// Features:
/// - Synchronized dual-provider architecture (`currentUserProvider` & `authProvider`).
/// - Real-time role switching and patching for administration features.
/// - REST API integration for phone-based profile resolution.
/// ============================================================================

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../api_config.dart';
import '../models/user_model.dart';

/// Global [StateProvider] holding the currently active [UserModel].
/// Used directly across Member Directory, Matrimonial, and Family Tree modules.
final currentUserProvider = StateProvider<UserModel?>((ref) => null);

/// Service providing helper methods for fetching and resolving user profiles over HTTP.
class AuthService {
  /// Fetches a user's complete profile by their registered phone number.
  /// Cleanses phone formatting and decodes the backend JSON response.
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

/// Immutable state model representing authentication status, active user data, and errors.
class AuthState {
  /// Currently authenticated user, or null if unauthenticated.
  final UserModel? user;

  /// True during active background authentication or profile loading operations.
  final bool isLoading;

  /// Human-readable error message if the last operation failed.
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  /// Quick helper checking if a valid session exists.
  bool get isAuthenticated => user != null;

  /// Quick helper verifying administrator privileges.
  bool get isAdmin => user?.isAdmin ?? false;

  /// Creates a copy of [AuthState] with optional overrides.
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

/// State notifier managing login state, profile updates, and role toggles.
class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;

  AuthNotifier(this.ref) : super(const AuthState()) {
    // Synchronize initial state with currentUserProvider if already populated
    final current = ref.read(currentUserProvider);
    if (current != null) {
      state = state.copyWith(user: current);
    }
  }

  /// Asynchronously fetches a user record by phone number and updates global state.
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

  /// Manually assigns a new active [UserModel] to the authentication state.
  void setUser(UserModel user) {
    if (state.user != user) {
      state = state.copyWith(user: user);
    }
  }

  /// Toggles between Admin/Organizer and regular User roles for testing/administration.
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

  /// Clears the authentication session and resets both providers.
  void logout() {
    state = state.copyWith(clearUser: true);
    ref.read(currentUserProvider.notifier).state = null;
  }
}

/// [StateNotifierProvider] managing authentication state, listening for external updates.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final notifier = AuthNotifier(ref);

  // Sync authProvider state when currentUserProvider is mutated directly (e.g. at login screen)
  ref.listen<UserModel?>(currentUserProvider, (previous, next) {
    if (next != null) {
      notifier.setUser(next);
    } else {
      notifier.logout();
    }
  });

  return notifier;
});

