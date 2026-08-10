class UserModel {
  final String id;
  final String fullName;
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
  final String profilePhoto;
  final String role; // 'user', 'admin', 'organizer'
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.fullName,
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
    this.profilePhoto = '',
    this.role = 'user',
    this.createdAt,
  });

  bool get isAdmin => role == 'admin' || role == 'organizer';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
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
      profilePhoto: json['profilePhoto'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullName': fullName,
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
      'profilePhoto': profilePhoto,
      'role': role,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
