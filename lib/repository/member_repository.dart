import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../api_config.dart';
import '../models/member_model.dart';
import '../models/user_model.dart';

abstract class MemberRepository {
  Future<List<Member>> getMembers();
}

class LocalMemberRepository implements MemberRepository {
  List<Member>? _cachedMembers;

  @override
  Future<List<Member>> getMembers() async {
    // We will always try to fetch fresh DB members and merge them.
    // If cache is empty, we load the JSON first.
    List<Member> localList = [];
    try {
      if (_cachedMembers != null && _cachedMembers!.isNotEmpty) {
        localList = List.from(_cachedMembers!);
      } else {
        final String response =
            await rootBundle.loadString('assets/data/members.json');
        final List<dynamic> data = json.decode(response) as List<dynamic>;
        _cachedMembers = data
            .map((item) => Member.fromJson(item as Map<String, dynamic>))
            .toList();
        localList = List.from(_cachedMembers!);
      }
    } catch (e) {
      print('Error loading members JSON: $e');
      localList = _cachedMembers ?? [];
    }

    // Now, fetch all registered users from the backend
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/users/all'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['users'] != null) {
          final List<dynamic> dbUsersJson = data['users'] as List<dynamic>;
          final dbUsers = dbUsersJson.map((u) => UserModel.fromJson(u)).toList();

          // Convert UserModel to Member
          final dbMembers = dbUsers.map((user) {
            // Calculate age from dateOfBirth (YYYY-MM-DD)
            int calculatedAge = 30;
            try {
              if (user.dateOfBirth.isNotEmpty) {
                final dob = DateTime.parse(user.dateOfBirth);
                calculatedAge = DateTime.now().year - dob.year;
              }
            } catch (_) {}

            final String initials = user.fullName.isNotEmpty
                ? user.fullName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase()
                : 'U';

            return Member(
              id: user.id.isNotEmpty ? user.id : 'DB_${user.phoneNumber}',
              fullName: user.surname.isNotEmpty
                  ? '${user.fullName} ${user.surname}'
                  : user.fullName,
              initials: initials.isNotEmpty ? initials : 'U',
              gender: user.gender.isNotEmpty ? user.gender : 'Male',
              mobileNumber: user.phoneNumber,
              email: user.email.isNotEmpty
                  ? user.email
                  : (user.fullName.isNotEmpty
                      ? '${user.fullName.toLowerCase().replaceAll(' ', '')}@kutumbsetu.org'
                      : 'member@kutumbsetu.org'),
              village: user.nativePlace.isNotEmpty ? user.nativePlace : 'Karamsad',
              city: user.city.isNotEmpty ? user.city : 'Vadodara',
              district: user.city.isNotEmpty ? user.city : 'Vadodara',
              state: user.state.isNotEmpty ? user.state : 'Gujarat',
              profession: user.occupation.isNotEmpty ? user.occupation : 'Software Architect',
              company: 'KutumbSetu Network',
              education: user.education.isNotEmpty ? user.education : 'B.E. Computer Engineering',
              bloodGroup: user.bloodGroup.isNotEmpty ? user.bloodGroup : 'B+',
              age: calculatedAge,
              maritalStatus: user.maritalStatus.isNotEmpty ? user.maritalStatus : 'Single',
              businessCategory: 'Technology & IT',
              skills: const ['Community', 'Networking'],
              languages: const ['Gujarati', 'Hindi', 'English'],
              avatarUrl: user.profilePhoto,
              joinedDate: DateTime.now().toIso8601String().substring(0, 10),
              isVerified: true,
              isActive: true,
            );
          }).toList();

          // Merge local and DB lists. DB lists overwrite local by phone number.
          final Map<String, Member> mergedMap = {};
          
          // Put local members first
          for (var member in localList) {
            mergedMap[member.mobileNumber.replaceAll(' ', '')] = member;
          }
          
          // Overwrite/add backend members
          for (var member in dbMembers) {
            mergedMap[member.mobileNumber.replaceAll(' ', '')] = member;
          }

          final mergedList = mergedMap.values.toList();
          return mergedList;
        }
      }
    } catch (e) {
      print('Error fetching registered users from backend: $e');
    }

    return localList;
  }
}
