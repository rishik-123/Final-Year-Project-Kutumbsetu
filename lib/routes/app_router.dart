import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/campaign_model.dart';
import '../models/member_model.dart';
import '../screens/admin_registrations_screen.dart';
import '../screens/campaign_create_screen.dart';
import '../screens/campaign_detail_screen.dart';
import '../screens/campaign_listing_screen.dart';
import '../screens/campaign_registration_screen.dart';
import '../screens/member_directory_screen.dart';
import '../screens/member_profile_screen.dart';
import '../screens/my_registrations_screen.dart';
import '../screens/registration_success_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
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
