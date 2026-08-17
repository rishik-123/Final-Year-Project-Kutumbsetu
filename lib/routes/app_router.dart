import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/campaign_model.dart';
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
import '../screens/admin_registrations_screen.dart';
import '../screens/campaign_create_screen.dart';
import '../screens/campaign_detail_screen.dart';
import '../screens/campaign_listing_screen.dart';
import '../screens/campaign_registration_screen.dart';
import '../screens/my_registrations_screen.dart';
import '../screens/registration_success_screen.dart';
import '../screens/post_detail_screen.dart';
import '../screens/reel_detail_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/post/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return PostDetailScreen(postId: id);
      },
    ),
    GoRoute(
      path: '/reel/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return ReelDetailScreen(reelId: id);
      },
    ),
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
    // Matrimonial Routes
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
    // Campaign Routes
    GoRoute(
      path: '/campaigns',
      builder: (context, state) => const CampaignListingScreen(),
    ),
    GoRoute(
      path: '/campaigns/create',
      builder: (context, state) => const CampaignCreateScreen(),
    ),
    GoRoute(
      path: '/campaigns/:id',
      builder: (context, state) {
        final campaign = state.extra as Campaign?;
        final id = state.pathParameters['id'] ?? '';
        return CampaignDetailScreen(campaignId: id, initialCampaign: campaign);
      },
    ),
    GoRoute(
      path: '/campaigns/:id/register',
      builder: (context, state) {
        final campaign = state.extra as Campaign?;
        final id = state.pathParameters['id'] ?? '';
        return CampaignRegistrationScreen(campaignId: id, campaign: campaign);
      },
    ),
    GoRoute(
      path: '/campaigns/:id/success',
      builder: (context, state) {
        final regData = state.extra as Map<String, dynamic>? ?? {};
        return RegistrationSuccessScreen(registrationData: regData);
      },
    ),
    GoRoute(
      path: '/campaigns/:id/registrations',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return AdminRegistrationsScreen(campaignId: id);
      },
    ),
    GoRoute(
      path: '/my-registrations',
      builder: (context, state) => const MyRegistrationsScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Page not found: ${state.error}'),
    ),
  ),
);
