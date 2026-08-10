import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../api_config.dart';
import '../models/campaign_model.dart';
import '../models/campaign_registration_model.dart';
import '../models/notification_model.dart';
import 'auth_provider.dart';

// State Filter Providers
final selectedCategoryProvider = StateProvider<String>((ref) => 'All');
final selectedStatusTabProvider = StateProvider<String>((ref) => 'All');
final campaignSearchQueryProvider = StateProvider<String>((ref) => '');

// Categories Provider (Extensible DB loaded from /api/categories)
final campaignCategoriesProvider = FutureProvider<List<CampaignCategory>>((ref) async {
  try {
    final response = await http
        .get(Uri.parse('${ApiConfig.baseUrl}/categories'))
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['categories'] != null) {
        final list = (data['categories'] as List<dynamic>)
            .map((e) => CampaignCategory.fromJson(e as Map<String, dynamic>))
            .toList();
        return list;
      }
    }
  } catch (_) {}

  // Fallback default categories if server loading is delayed
  return const [
    CampaignCategory(id: '1', name: 'Blood Donation', slug: 'blood-donation', icon: 'water_drop'),
    CampaignCategory(id: '2', name: 'Education', slug: 'education', icon: 'school'),
    CampaignCategory(id: '3', name: 'Medical Help', slug: 'medical-help', icon: 'local_hospital'),
    CampaignCategory(id: '4', name: 'Community Welfare', slug: 'community-welfare', icon: 'groups'),
    CampaignCategory(id: '5', name: 'Disaster Relief', slug: 'disaster-relief', icon: 'warning'),
    CampaignCategory(id: '6', name: 'Religious/Community Events', slug: 'religious-events', icon: 'event'),
    CampaignCategory(id: '7', name: 'Social Cause', slug: 'social-cause', icon: 'volunteer_activism'),
    CampaignCategory(id: '8', name: 'Other', slug: 'other', icon: 'category'),
  ];
});

// Campaigns List Provider
final campaignsListProvider = FutureProvider<List<Campaign>>((ref) async {
  final category = ref.watch(selectedCategoryProvider);
  final status = ref.watch(selectedStatusTabProvider);
  final search = ref.watch(campaignSearchQueryProvider);

  final queryParams = <String, String>{};
  if (category != 'All') queryParams['category'] = category;
  if (status != 'All') queryParams['status'] = status;
  if (search.trim().isNotEmpty) queryParams['search'] = search.trim();

  final uri = Uri.parse('${ApiConfig.baseUrl}/campaigns').replace(queryParameters: queryParams);

  try {
    final response = await http.get(uri).timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['campaigns'] != null) {
        final list = (data['campaigns'] as List<dynamic>)
            .map((e) => Campaign.fromJson(e as Map<String, dynamic>))
            .toList();
        return list;
      }
    }
  } catch (_) {}

  return const [];
});

// Single Campaign Detail Provider
final campaignDetailProvider = FutureProvider.family<Campaign?, String>((ref, id) async {
  if (id.isEmpty) return null;
  try {
    final response = await http
        .get(Uri.parse('${ApiConfig.baseUrl}/campaigns/$id'))
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['campaign'] != null) {
        return Campaign.fromJson(data['campaign'] as Map<String, dynamic>);
      }
    }
  } catch (_) {}
  return null;
});

// My Registrations Provider
final myRegistrationsProvider = FutureProvider<List<CampaignRegistration>>((ref) async {
  final auth = ref.watch(authProvider);
  final userId = auth.user?.id;
  if (userId == null || userId.isEmpty) return const [];

  try {
    final uri = Uri.parse('${ApiConfig.baseUrl}/campaign-registrations/my');
    final response = await http.get(
      uri,
      headers: {'x-user-id': userId},
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['registrations'] != null) {
        final list = (data['registrations'] as List<dynamic>)
            .map((e) => CampaignRegistration.fromJson(e as Map<String, dynamic>))
            .toList();
        return list;
      }
    }
  } catch (_) {}

  return const [];
});

// Admin Registrations for Campaign Provider
final campaignRegistrationsAdminProvider =
    FutureProvider.family<List<CampaignRegistration>, String>((ref, campaignId) async {
  if (campaignId.isEmpty) return const [];

  try {
    final uri = Uri.parse('${ApiConfig.baseUrl}/campaigns/$campaignId/registrations');
    final response = await http.get(uri).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['registrations'] != null) {
        final list = (data['registrations'] as List<dynamic>)
            .map((e) => CampaignRegistration.fromJson(e as Map<String, dynamic>))
            .toList();
        return list;
      }
    }
  } catch (_) {}

  return const [];
});

// User Notifications Provider
final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  final auth = ref.watch(authProvider);
  final userId = auth.user?.id;

  try {
    final uri = Uri.parse('${ApiConfig.baseUrl}/notifications/my');
    final response = await http.get(
      uri,
      headers: userId != null ? {'x-user-id': userId} : {},
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['notifications'] != null) {
        final list = (data['notifications'] as List<dynamic>)
            .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
            .toList();
        return list;
      }
    }
  } catch (_) {}

  return const [];
});
