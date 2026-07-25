import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/member_model.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/home_screen.dart';
import '../screens/member_directory_screen.dart';
import '../screens/member_profile_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/directory',
      builder: (context, state) => const MemberDirectoryScreen(),
    ),
    GoRoute(
      path: '/member/:id',
      builder: (context, state) {
        final member = state.extra as Member?;
        final id = state.pathParameters['id'] ?? '';
        return MemberProfileScreen(memberId: id, member: member);
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Page not found: ${state.error}'),
    ),
  ),
);
