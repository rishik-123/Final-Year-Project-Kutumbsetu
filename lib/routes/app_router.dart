import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/member_model.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/home_screen.dart';
import '../screens/member_directory_screen.dart';
import '../screens/member_profile_screen.dart';
import '../screens/matrimonial/matrimonial_hub_screen.dart';
import '../screens/matrimonial/matrimonial_profile_list_screen.dart';
import '../screens/matrimonial/matrimonial_profile_detail_screen.dart';
import '../screens/matrimonial/matrimonial_biodata_screen.dart';
import '../screens/matrimonial/matrimonial_requests_screen.dart';
import '../screens/matrimonial/marriage_events_screen.dart';
import '../screens/matrimonial/success_stories_screen.dart';
import '../screens/matrimonial/matrimonial_admin_screen.dart';
import '../screens/matrimonial/premium_benefits_screen.dart';
import '../screens/profile_completion_screen.dart';

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
      path: '/profile/complete',
      builder: (context, state) => const ProfileCompletionScreen(),
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
    GoRoute(
      path: '/matrimonial',
      builder: (context, state) => const MatrimonialHubScreen(),
    ),
    GoRoute(
      path: '/matrimonial/profiles',
      builder: (context, state) {
        final shortlisted = state.uri.queryParameters['shortlisted'] == 'true';
        final recommendations = state.uri.queryParameters['recommendations'] == 'true';
        return MatrimonialProfileListScreen(
          showShortlistedOnly: shortlisted,
          showRecommendationsOnly: recommendations,
        );
      },
    ),
    GoRoute(
      path: '/matrimonial/profile/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return MatrimonialProfileDetailScreen(userId: id);
      },
    ),
    GoRoute(
      path: '/matrimonial/biodata',
      builder: (context, state) => const MatrimonialBiodataScreen(),
    ),
    GoRoute(
      path: '/matrimonial/requests',
      builder: (context, state) => const MatrimonialRequestsScreen(),
    ),
    GoRoute(
      path: '/matrimonial/events',
      builder: (context, state) => const MarriageEventsScreen(),
    ),
    GoRoute(
      path: '/matrimonial/stories',
      builder: (context, state) => const SuccessStoriesScreen(),
    ),
    GoRoute(
      path: '/matrimonial/admin',
      builder: (context, state) => const MatrimonialAdminScreen(),
    ),
    GoRoute(
      path: '/matrimonial/premium-benefits',
      builder: (context, state) => const PremiumBenefitsScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Page not found: ${state.error}'),
    ),
  ),
);
