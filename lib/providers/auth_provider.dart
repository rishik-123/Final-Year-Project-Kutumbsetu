import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../api_config.dart';
import '../models/user_model.dart';

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
  AuthNotifier() : super(const AuthState()) {
    // Initialize default demo/guest user so application works out of the box
    _initDefaultUser();
  }

  void _initDefaultUser() {
    // Default user profile matching KutumbSetu member profile
    final defaultUser = UserModel(
      id: '6a7962b212a58c4a0e118cab',
      fullName: 'Rishi Patel',
      surname: 'Patel',
      fatherName: 'Rameshchandra Patel',
      phoneNumber: '+919888877777',
      gender: 'Male',
      dateOfBirth: '1995-05-15',
      nativePlace: 'Karamsad',
      address: 'Station Road, Karamsad',
      city: 'Anand',
      state: 'Gujarat',
      maritalStatus: 'Married',
      occupation: 'Software Engineer',
      role: 'admin', // Admin by default for campaign creation & registration testing
    );

    state = state.copyWith(user: defaultUser);
    fetchUserByPhone('+919888877777');
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
          return;
        }
      }
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setUser(UserModel user) {
    state = state.copyWith(user: user);
  }

  void toggleAdminRole() async {
    if (state.user == null) return;
    final currentRole = state.user!.role;
    final newRole = (currentRole == 'admin' || currentRole == 'organizer') ? 'user' : 'admin';
    final updatedUser = UserModel(
      id: state.user!.id,
      fullName: state.user!.fullName,
      surname: state.user!.surname,
      fatherName: state.user!.fatherName,
      phoneNumber: state.user!.phoneNumber,
      gender: state.user!.gender,
      dateOfBirth: state.user!.dateOfBirth,
      nativePlace: state.user!.nativePlace,
      address: state.user!.address,
      city: state.user!.city,
      state: state.user!.state,
      maritalStatus: state.user!.maritalStatus,
      occupation: state.user!.occupation,
      profilePhoto: state.user!.profilePhoto,
      role: newRole,
      createdAt: state.user!.createdAt,
    );

    state = state.copyWith(user: updatedUser);

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
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
