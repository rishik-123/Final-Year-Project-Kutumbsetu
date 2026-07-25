class Member {
  final String id;
  final String fullName;
  final String initials;
  final String gender;
  final String mobileNumber;
  final String email;
  final String village;
  final String city;
  final String district;
  final String state;
  final String profession;
  final String company;
  final String education;
  final String bloodGroup;
  final int age;
  final String maritalStatus;
  final String businessCategory;
  final List<String> skills;
  final List<String> languages;
  final String avatarUrl;
  final String joinedDate;
  final bool isVerified;
  final bool isActive;

  const Member({
    required this.id,
    required this.fullName,
    required this.initials,
    required this.gender,
    required this.mobileNumber,
    required this.email,
    required this.village,
    required this.city,
    required this.district,
    required this.state,
    required this.profession,
    required this.company,
    required this.education,
    required this.bloodGroup,
    required this.age,
    required this.maritalStatus,
    required this.businessCategory,
    required this.skills,
    required this.languages,
    required this.avatarUrl,
    required this.joinedDate,
    required this.isVerified,
    required this.isActive,
  });

  String get firstLetter {
    if (fullName.isEmpty) return '#';
    final char = fullName.trim()[0].toUpperCase();
    final RegExp alpha = RegExp(r'[A-Z]');
    return alpha.hasMatch(char) ? char : '#';
  }

  String get fullLocation => '$village, $city';
  String get fullAddress => '$village, $city, Dist. $district, $state';

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      initials: json['initials'] as String? ?? '',
      gender: json['gender'] as String? ?? 'Male',
      mobileNumber: json['mobileNumber'] as String? ?? '',
      email: json['email'] as String? ?? '',
      village: json['village'] as String? ?? '',
      city: json['city'] as String? ?? '',
      district: json['district'] as String? ?? '',
      state: json['state'] as String? ?? 'Gujarat',
      profession: json['profession'] as String? ?? '',
      company: json['company'] as String? ?? '',
      education: json['education'] as String? ?? '',
      bloodGroup: json['bloodGroup'] as String? ?? '',
      age: (json['age'] as num?)?.toInt() ?? 0,
      maritalStatus: json['maritalStatus'] as String? ?? 'Married',
      businessCategory: json['businessCategory'] as String? ?? '',
      skills: (json['skills'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      languages: (json['languages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      avatarUrl: json['avatarUrl'] as String? ?? '',
      joinedDate: json['joinedDate'] as String? ?? '',
      isVerified: json['isVerified'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'initials': initials,
      'gender': gender,
      'mobileNumber': mobileNumber,
      'email': email,
      'village': village,
      'city': city,
      'district': district,
      'state': state,
      'profession': profession,
      'company': company,
      'education': education,
      'bloodGroup': bloodGroup,
      'age': age,
      'maritalStatus': maritalStatus,
      'businessCategory': businessCategory,
      'skills': skills,
      'languages': languages,
      'avatarUrl': avatarUrl,
      'joinedDate': joinedDate,
      'isVerified': isVerified,
      'isActive': isActive,
    };
  }

  Member copyWith({
    String? id,
    String? fullName,
    String? initials,
    String? gender,
    String? mobileNumber,
    String? email,
    String? village,
    String? city,
    String? district,
    String? state,
    String? profession,
    String? company,
    String? education,
    String? bloodGroup,
    int? age,
    String? maritalStatus,
    String? businessCategory,
    List<String>? skills,
    List<String>? languages,
    String? avatarUrl,
    String? joinedDate,
    bool? isVerified,
    bool? isActive,
  }) {
    return Member(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      initials: initials ?? this.initials,
      gender: gender ?? this.gender,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      email: email ?? this.email,
      village: village ?? this.village,
      city: city ?? this.city,
      district: district ?? this.district,
      state: state ?? this.state,
      profession: profession ?? this.profession,
      company: company ?? this.company,
      education: education ?? this.education,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      age: age ?? this.age,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      businessCategory: businessCategory ?? this.businessCategory,
      skills: skills ?? this.skills,
      languages: languages ?? this.languages,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      joinedDate: joinedDate ?? this.joinedDate,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Member && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
