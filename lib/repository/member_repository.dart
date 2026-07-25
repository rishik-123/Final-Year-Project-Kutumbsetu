import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/member_model.dart';

abstract class MemberRepository {
  Future<List<Member>> getMembers();
}

class LocalMemberRepository implements MemberRepository {
  List<Member>? _cachedMembers;

  @override
  Future<List<Member>> getMembers() async {
    if (_cachedMembers != null && _cachedMembers!.isNotEmpty) {
      return _cachedMembers!;
    }

    try {
      final String response =
          await rootBundle.loadString('assets/data/members.json');
      final List<dynamic> data = json.decode(response) as List<dynamic>;

      _cachedMembers = data
          .map((item) => Member.fromJson(item as Map<String, dynamic>))
          .toList();

      return _cachedMembers!;
    } catch (e) {
      // Fallback empty list or basic fallback if asset fails to load
      return _cachedMembers ?? [];
    }
  }
}
