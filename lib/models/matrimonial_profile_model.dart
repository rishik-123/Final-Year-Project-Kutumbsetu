class MatrimonialProfileModel {
  final String id;
  final String userId;
  final String name;
  final DateTime dateOfBirth;
  final String gender;
  final int heightCm;
  final int weightKg;
  final String bloodGroup;
  final String maritalStatus;
  final String education;
  final String occupation;
  final String company;
  final double annualIncome;
  final String village;
  final String city;
  final Map<String, dynamic> family;
  final Map<String, dynamic> lifestyle;
  final Map<String, dynamic> partnerPreferences;
  final Map<String, dynamic> visibility;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String profilePhotoUrl;
  final String introductionVideoUrl;
  final int match; // Dynamic AI Match score calculated by server or fallback
  
  // Populated fields from the backend
  final String mobileNumber;
  final String emailAddress;
  final String fullAddressText;

  const MatrimonialProfileModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.dateOfBirth,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.bloodGroup,
    required this.maritalStatus,
    required this.education,
    required this.occupation,
    required this.company,
    required this.annualIncome,
    required this.village,
    required this.city,
    required this.family,
    required this.lifestyle,
    required this.partnerPreferences,
    required this.visibility,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.profilePhotoUrl,
    required this.introductionVideoUrl,
    this.match = 75,
    this.mobileNumber = '',
    this.emailAddress = '',
    this.fullAddressText = '',
  });

  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month || (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  factory MatrimonialProfileModel.fromJson(Map<String, dynamic> json) {
    String extractedUserId = '';
    if (json['userId'] is Map) {
      extractedUserId = json['userId']['_id']?.toString() ?? '';
    } else {
      extractedUserId = json['userId']?.toString() ?? '';
    }

    return MatrimonialProfileModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      userId: extractedUserId,
      name: json['name'] as String? ?? '',
      dateOfBirth: json['dob'] != null ? DateTime.parse(json['dob'].toString()) : DateTime(2000, 1, 1),
      gender: json['gender'] as String? ?? 'Male',
      heightCm: (json['heightCm'] as num?)?.toInt() ?? 165,
      weightKg: (json['weightKg'] as num?)?.toInt() ?? 60,
      bloodGroup: json['bloodGroup'] as String? ?? 'B+',
      maritalStatus: json['maritalStatus'] as String? ?? 'Never Married',
      education: json['education'] as String? ?? '',
      occupation: json['occupation'] as String? ?? '',
      company: json['company'] as String? ?? '',
      annualIncome: (json['annualIncome'] as num?)?.toDouble() ?? 0.0,
      village: json['village'] as String? ?? '',
      city: json['city'] as String? ?? '',
      family: json['familyInformation'] as Map<String, dynamic>? ?? const {},
      lifestyle: json['lifestyle'] as Map<String, dynamic>? ?? const {},
      partnerPreferences: json['partnerPreferences'] as Map<String, dynamic>? ?? const {},
      visibility: json['visibilitySettings'] as Map<String, dynamic>? ?? const {},
      status: json['profileStatus'] as String? ?? 'Approved',
      createdAt: json['createdDate'] != null ? DateTime.parse(json['createdDate'].toString()) : DateTime.now(),
      updatedAt: json['updatedDate'] != null ? DateTime.parse(json['updatedDate'].toString()) : DateTime.now(),
      profilePhotoUrl: json['profilePhoto'] as String? ?? '',
      introductionVideoUrl: json['introductionVideo'] as String? ?? '',
      match: (json['match'] as num?)?.toInt() ?? 75,
      mobileNumber: json['mobileNumber'] as String? ?? '',
      emailAddress: json['emailAddress'] as String? ?? '',
      fullAddressText: json['fullAddressText'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'name': name,
      'dob': dateOfBirth.toIso8601String(),
      'gender': gender,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'bloodGroup': bloodGroup,
      'maritalStatus': maritalStatus,
      'education': education,
      'occupation': occupation,
      'company': company,
      'annualIncome': annualIncome,
      'village': village,
      'city': city,
      'familyInformation': family,
      'lifestyle': lifestyle,
      'partnerPreferences': partnerPreferences,
      'visibilitySettings': visibility,
      'profileStatus': status,
      'createdDate': createdAt.toIso8601String(),
      'updatedDate': updatedAt.toIso8601String(),
      'profilePhoto': profilePhotoUrl,
      'introductionVideo': introductionVideoUrl,
      'mobileNumber': mobileNumber,
      'emailAddress': emailAddress,
      'fullAddressText': fullAddressText,
    };
  }
}
