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

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.surname,
    required this.fatherName,
    required this.phoneNumber,
    required this.gender,
    required this.dateOfBirth,
    required this.nativePlace,
    required this.address,
    required this.city,
    required this.state,
    required this.maritalStatus,
    required this.occupation,
    required this.education,
    required this.bloodGroup,
    required this.profilePhoto,
    required this.familyId,
    required this.familyName,
    required this.relationshipToHead,
    required this.motherName,
    required this.spouseName,
    required this.familyHeadPhone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] as String? ?? '',
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
      maritalStatus: json['maritalStatus'] as String? ?? 'Single',
      occupation: json['occupation'] as String? ?? '',
      education: json['education'] as String? ?? '',
      bloodGroup: json['bloodGroup'] as String? ?? '',
      profilePhoto: json['profilePhoto'] as String? ?? '',
      familyId: json['familyId'] as String? ?? '',
      familyName: json['familyName'] as String? ?? '',
      relationshipToHead: json['relationshipToHead'] as String? ?? 'Other',
      motherName: json['motherName'] as String? ?? '',
      spouseName: json['spouseName'] as String? ?? '',
      familyHeadPhone: json['familyHeadPhone'] as String? ?? '',
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
    );
  }
}
