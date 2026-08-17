import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api_config.dart';
import '../models/matrimonial_profile_model.dart';
import 'auth_provider.dart';

class MatrimonialService {
  final String baseUrl = ApiConfig.baseUrl;

  // 1. Fetch profiles with filters
  Future<List<MatrimonialProfileModel>> fetchProfiles({
    String? search,
    String? gender,
    String? requesterId,
    String? maritalStatus,
    String? city,
    String? village,
    String? education,
    String? occupation,
    int? ageMin,
    int? ageMax,
    int? heightMin,
    int? heightMax,
    double? incomeMin,
    double? incomeMax,
    int? weightMin,
    int? weightMax,
    String? workLocation,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (gender != null && gender.isNotEmpty) queryParams['gender'] = gender;
    if (requesterId != null && requesterId.isNotEmpty) queryParams['requesterId'] = requesterId;
    if (maritalStatus != null && maritalStatus.isNotEmpty) queryParams['maritalStatus'] = maritalStatus;
    if (city != null && city.isNotEmpty) queryParams['city'] = city;
    if (village != null && village.isNotEmpty) queryParams['village'] = village;
    if (education != null && education.isNotEmpty) queryParams['education'] = education;
    if (occupation != null && occupation.isNotEmpty) queryParams['occupation'] = occupation;
    if (ageMin != null) queryParams['ageMin'] = ageMin.toString();
    if (ageMax != null) queryParams['ageMax'] = ageMax.toString();
    if (heightMin != null) queryParams['heightMin'] = heightMin.toString();
    if (heightMax != null) queryParams['heightMax'] = heightMax.toString();
    if (incomeMin != null) queryParams['incomeMin'] = incomeMin.toString();
    if (incomeMax != null) queryParams['incomeMax'] = incomeMax.toString();
    if (weightMin != null) queryParams['weightMin'] = weightMin.toString();
    if (weightMax != null) queryParams['weightMax'] = weightMax.toString();
    if (workLocation != null && workLocation.isNotEmpty) queryParams['workLocation'] = workLocation;

    final uri = Uri.parse('$baseUrl/matrimonial/profiles').replace(queryParameters: queryParams);
    
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List list = data['profiles'] ?? [];
          return list.map((item) => MatrimonialProfileModel.fromJson(item)).toList();
        }
      }
    } catch (e) {
      print('Error fetching matrimonial profiles: $e');
    }
    return [];
  }

  // 2. Fetch specific profile (populated user, masked sensitive details)
  Future<MatrimonialProfileModel?> fetchProfile(String userId, {String? requesterId}) async {
    final uri = Uri.parse('$baseUrl/matrimonial/profile/$userId').replace(
      queryParameters: requesterId != null ? {'requesterId': requesterId} : null,
    );
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return MatrimonialProfileModel.fromJson(data['profile']);
        }
      }
    } catch (e) {
      print('Error fetching profile: $e');
    }
    return null;
  }

  // 3. Create or Update Biodata
  Future<bool> saveProfile(Map<String, dynamic> payload) async {
    final uri = Uri.parse('$baseUrl/matrimonial/profile');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
    } catch (e) {
      print('Error saving profile: $e');
    }
    return false;
  }

  // 4. Send interest request
  Future<bool> sendRequest(String senderId, String receiverId) async {
    final uri = Uri.parse('$baseUrl/matrimonial/request');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'senderId': senderId, 'receiverId': receiverId}),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
    } catch (e) {
      print('Error sending request: $e');
    }
    return false;
  }

  // 5. Respond to request
  Future<bool> respondToRequest(String requestId, String status) async {
    final uri = Uri.parse('$baseUrl/matrimonial/request/respond');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'requestId': requestId, 'status': status}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
    } catch (e) {
      print('Error responding to request: $e');
    }
    return false;
  }

  // 6. Get requests
  Future<Map<String, List<dynamic>>> fetchRequests(String userId) async {
    final uri = Uri.parse('$baseUrl/matrimonial/requests').replace(queryParameters: {'userId': userId});
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {
            'sent': data['sent'] as List? ?? [],
            'received': data['received'] as List? ?? [],
          };
        }
      }
    } catch (e) {
      print('Error fetching requests: $e');
    }
    return {'sent': [], 'received': []};
  }

  // 7. Toggle shortlist
  Future<bool> toggleShortlist(String userId, String shortlistedUserId) async {
    final uri = Uri.parse('$baseUrl/matrimonial/shortlist');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'shortlistedUserId': shortlistedUserId}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
    } catch (e) {
      print('Error toggling shortlist: $e');
    }
    return false;
  }

  // 8. Fetch shortlisted profiles
  Future<List<MatrimonialProfileModel>> fetchShortlisted(String userId) async {
    final uri = Uri.parse('$baseUrl/matrimonial/shortlisted').replace(queryParameters: {'userId': userId});
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List list = data['profiles'] ?? [];
          return list.map((item) => MatrimonialProfileModel.fromJson(item)).toList();
        }
      }
    } catch (e) {
      print('Error fetching shortlisted: $e');
    }
    return [];
  }

  // 9. Fetch events
  Future<List<dynamic>> fetchEvents() async {
    final uri = Uri.parse('$baseUrl/matrimonial/events');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['events'] as List? ?? [];
        }
      }
    } catch (e) {
      print('Error fetching events: $e');
    }
    return [];
  }

  // 10. Fetch success stories
  Future<List<dynamic>> fetchSuccessStories() async {
    final uri = Uri.parse('$baseUrl/matrimonial/success-stories');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['stories'] as List? ?? [];
        }
      }
    } catch (e) {
      print('Error fetching success stories: $e');
    }
    return [];
  }
}

final matrimonialServiceProvider = Provider((ref) => MatrimonialService());

// Own Profile Provider
final myMatrimonialProfileProvider = FutureProvider.autoDispose<MatrimonialProfileModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final service = ref.watch(matrimonialServiceProvider);
  return service.fetchProfile(user.id, requesterId: user.id);
});

// Shortlisted Favorites Provider
final myShortlistedProfilesProvider = FutureProvider.autoDispose<List<MatrimonialProfileModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final service = ref.watch(matrimonialServiceProvider);
  return service.fetchShortlisted(user.id);
});

// Requests Tracker Provider
final matrimonialRequestsProvider = FutureProvider.autoDispose<Map<String, List<dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return {'sent': [], 'received': []};
  final service = ref.watch(matrimonialServiceProvider);
  return service.fetchRequests(user.id);
});

// Events Provider
final matrimonialEventsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final service = ref.watch(matrimonialServiceProvider);
  return service.fetchEvents();
});

// Stories Provider
final matrimonialStoriesProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final service = ref.watch(matrimonialServiceProvider);
  return service.fetchSuccessStories();
});
