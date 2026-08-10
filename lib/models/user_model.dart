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
  final String familyId;
  final String familyName;
  final String relationshipToHead;
  final String motherName;
  final String spouseName;
  final String familyHeadPhone;
  final String grandfather;
  final String grandmother;
  final String nana;
  final String nani;
  final String role; // 'user', 'admin', 'organizer'
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
    this.familyId = '',
    this.familyName = '',
    this.relationshipToHead = '',
    this.motherName = '',
    this.spouseName = '',
    this.familyHeadPhone = '',
    this.grandfather = '',
    this.grandmother = '',
    this.nana = '',
    this.nani = '',
    this.role = 'user',
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
      familyId: json['familyId'] as String? ?? '',
      familyName: json['familyName'] as String? ?? '',
      relationshipToHead: json['relationshipToHead'] as String? ?? 'Other',
      motherName: json['motherName'] as String? ?? '',
      spouseName: json['spouseName'] as String? ?? '',
      familyHeadPhone: json['familyHeadPhone'] as String? ?? '',
      grandfather: json['grandfather'] as String? ?? '',
      grandmother: json['grandmother'] as String? ?? '',
      nana: json['nana'] as String? ?? '',
      nani: json['nani'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
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
      'familyId': familyId,
      'familyName': familyName,
      'relationshipToHead': relationshipToHead,
      'motherName': motherName,
      'spouseName': spouseName,
      'familyHeadPhone': familyHeadPhone,
      'grandfather': grandfather,
      'grandmother': grandmother,
      'nana': nana,
      'nani': nani,
      'role': role,
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
    String? familyId,
    String? familyName,
    String? relationshipToHead,
    String? motherName,
    String? spouseName,
    String? familyHeadPhone,
    String? grandfather,
    String? grandmother,
    String? nana,
    String? nani,
    String? role,
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
      familyId: familyId ?? this.familyId,
      familyName: familyName ?? this.familyName,
      relationshipToHead: relationshipToHead ?? this.relationshipToHead,
      motherName: motherName ?? this.motherName,
      spouseName: spouseName ?? this.spouseName,
      familyHeadPhone: familyHeadPhone ?? this.familyHeadPhone,
      grandfather: grandfather ?? this.grandfather,
      grandmother: grandmother ?? this.grandmother,
      nana: nana ?? this.nana,
      nani: nani ?? this.nani,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
