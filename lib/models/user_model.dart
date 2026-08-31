import '../api_config.dart';

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String surname;
  final String fatherName;
  final String phoneNumber;
  final String gender;
  final String dateOfBirth;
  final String nativePlace;
  final String address;
  final String city;
  final String state;
  final String maritalStatus;
  final String occupation;
  final String education;
  final String bloodGroup;
  final String profilePhoto;
  final String memberId;
  final String maidenName;
  final String familyId;
  final String familyName;
  final String relationshipToHead;
  final String fatherId;
  final String motherId;
  final String motherName;
  final String paternalGrandfatherId;
  final String grandfather;
  final String paternalGrandmotherId;
  final String grandmother;
  final String maternalGrandfatherId;
  final String nana;
  final String maternalGrandmotherId;
  final String nani;
  final String spouseId;
  final String spouseName;
  final String familyHeadPhone;
  final String role; // 'user', 'admin', 'organizer'
  final bool isApproved;
  final bool willingToDonateBlood;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.fullName,
    this.email = '',
    this.surname = '',
    this.fatherName = '',
    required this.phoneNumber,
    required this.gender,
    required this.dateOfBirth,
    this.nativePlace = '',
    this.address = '',
    required this.city,
    this.state = '',
    this.maritalStatus = '',
    this.occupation = '',
    this.education = '',
    this.bloodGroup = '',
    this.profilePhoto = '',
    this.memberId = '',
    this.maidenName = '',
    this.familyId = '',
    this.familyName = '',
    this.relationshipToHead = '',
    this.fatherId = '',
    this.motherId = '',
    this.motherName = '',
    this.paternalGrandfatherId = '',
    this.grandfather = '',
    this.paternalGrandmotherId = '',
    this.grandmother = '',
    this.maternalGrandfatherId = '',
    this.nana = '',
    this.maternalGrandmotherId = '',
    this.nani = '',
    this.spouseId = '',
    this.spouseName = '',
    this.familyHeadPhone = '',
    this.role = 'user',
    this.isApproved = false,
    this.willingToDonateBlood = false,
    this.createdAt,
  });

  bool get isAdmin => role == 'admin' || role == 'organizer';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic dateVal) {
      if (dateVal == null) return null;
      if (dateVal is String) return DateTime.tryParse(dateVal);
      return null;
    }

    return UserModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      surname: json['surname'] as String? ?? '',
      fatherName: json['fatherName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      gender: json['gender'] as String? ?? 'Male',
      dateOfBirth: json['dateOfBirth'] as String? ?? '',
      nativePlace: json['nativePlace'] as String? ?? '',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      maritalStatus: json['maritalStatus'] as String? ?? '',
      occupation: json['occupation'] as String? ?? '',
      education: json['education'] as String? ?? '',
      bloodGroup: json['bloodGroup'] as String? ?? '',
      profilePhoto: (() {
        String pPhoto = json['profilePhoto'] as String? ?? '';
        if (pPhoto.startsWith('/uploads')) {
          pPhoto = '${ApiConfig.baseUrl.replaceAll('/api', '')}$pPhoto';
        }
        return pPhoto;
      })(),
      memberId: json['memberId'] as String? ?? '',
      maidenName: json['maidenName'] as String? ?? '',
      familyId: json['familyId'] as String? ?? '',
      familyName: json['familyName'] as String? ?? '',
      relationshipToHead: json['relationshipToHead'] as String? ?? 'Other',
      fatherId: json['fatherId'] as String? ?? '',
      motherId: json['motherId'] as String? ?? '',
      motherName: json['motherName'] as String? ?? '',
      paternalGrandfatherId: json['paternalGrandfatherId'] as String? ?? '',
      grandfather: json['grandfather'] as String? ?? '',
      paternalGrandmotherId: json['paternalGrandmotherId'] as String? ?? '',
      grandmother: json['grandmother'] as String? ?? '',
      maternalGrandfatherId: json['maternalGrandfatherId'] as String? ?? '',
      nana: json['nana'] as String? ?? '',
      maternalGrandmotherId: json['maternalGrandmotherId'] as String? ?? '',
      nani: json['nani'] as String? ?? '',
      spouseId: json['spouseId'] as String? ?? '',
      spouseName: json['spouseName'] as String? ?? '',
      familyHeadPhone: json['familyHeadPhone'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      isApproved: json['isApproved'] as bool? ?? false,
      willingToDonateBlood: json['willingToDonateBlood'] as bool? ?? false,
      createdAt: parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullName': fullName,
      'email': email,
      'surname': surname,
      'fatherName': fatherName,
      'phoneNumber': phoneNumber,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'nativePlace': nativePlace,
      'address': address,
      'city': city,
      'state': state,
      'maritalStatus': maritalStatus,
      'occupation': occupation,
      'education': education,
      'bloodGroup': bloodGroup,
      'profilePhoto': profilePhoto,
      'memberId': memberId,
      'maidenName': maidenName,
      'familyId': familyId,
      'familyName': familyName,
      'relationshipToHead': relationshipToHead,
      'fatherId': fatherId,
      'motherId': motherId,
      'motherName': motherName,
      'paternalGrandfatherId': paternalGrandfatherId,
      'grandfather': grandfather,
      'paternalGrandmotherId': paternalGrandmotherId,
      'grandmother': grandmother,
      'maternalGrandfatherId': maternalGrandfatherId,
      'nana': nana,
      'maternalGrandmotherId': maternalGrandmotherId,
      'nani': nani,
      'spouseId': spouseId,
      'spouseName': spouseName,
      'familyHeadPhone': familyHeadPhone,
      'role': role,
      'isApproved': isApproved,
      'willingToDonateBlood': willingToDonateBlood,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? surname,
    String? fatherName,
    String? phoneNumber,
    String? gender,
    String? dateOfBirth,
    String? nativePlace,
    String? address,
    String? city,
    String? state,
    String? maritalStatus,
    String? occupation,
    String? education,
    String? bloodGroup,
    String? profilePhoto,
    String? memberId,
    String? maidenName,
    String? familyId,
    String? familyName,
    String? relationshipToHead,
    String? fatherId,
    String? motherId,
    String? motherName,
    String? paternalGrandfatherId,
    String? grandfather,
    String? paternalGrandmotherId,
    String? grandmother,
    String? maternalGrandfatherId,
    String? nana,
    String? maternalGrandmotherId,
    String? nani,
    String? spouseId,
    String? spouseName,
    String? familyHeadPhone,
    String? role,
    bool? isApproved,
    bool? willingToDonateBlood,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      surname: surname ?? this.surname,
      fatherName: fatherName ?? this.fatherName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      nativePlace: nativePlace ?? this.nativePlace,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      occupation: occupation ?? this.occupation,
      education: education ?? this.education,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      memberId: memberId ?? this.memberId,
      maidenName: maidenName ?? this.maidenName,
      familyId: familyId ?? this.familyId,
      familyName: familyName ?? this.familyName,
      relationshipToHead: relationshipToHead ?? this.relationshipToHead,
      fatherId: fatherId ?? this.fatherId,
      motherId: motherId ?? this.motherId,
      motherName: motherName ?? this.motherName,
      paternalGrandfatherId: paternalGrandfatherId ?? this.paternalGrandfatherId,
      grandfather: grandfather ?? this.grandfather,
      paternalGrandmotherId: paternalGrandmotherId ?? this.paternalGrandmotherId,
      grandmother: grandmother ?? this.grandmother,
      maternalGrandfatherId: maternalGrandfatherId ?? this.maternalGrandfatherId,
      nana: nana ?? this.nana,
      maternalGrandmotherId: maternalGrandmotherId ?? this.maternalGrandmotherId,
      nani: nani ?? this.nani,
      spouseId: spouseId ?? this.spouseId,
      spouseName: spouseName ?? this.spouseName,
      familyHeadPhone: familyHeadPhone ?? this.familyHeadPhone,
      role: role ?? this.role,
      isApproved: isApproved ?? this.isApproved,
      willingToDonateBlood: willingToDonateBlood ?? this.willingToDonateBlood,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
