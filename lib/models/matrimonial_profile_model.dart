import '../api_config.dart';

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
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String profilePhotoUrl;
  final String introductionVideoUrl;
  final int match; // Dynamic AI Match score calculated by server or fallback
  
  // Populated fields from the backend
  final String mobileNumber;
  final String emailAddress;
  final String fullAddressText;

  // New Matrimonial Biodata Fields
  final String workingCountry;
  final String description;
  final String partnerExpectations;
  final List<String> partnerExpectationsHobbies;
  final List<String> additionalPhotos;
  final Map<String, dynamic> socialLinks;
  final String connectionStatus;

  MatrimonialProfileModel({
    this.id = '',
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
    this.family = const {},
    this.lifestyle = const {},
    this.partnerPreferences = const {},
    this.visibility = const {},
    this.status = 'Approved',
    this.createdAt,
    this.updatedAt,
    this.profilePhotoUrl = '',
    this.introductionVideoUrl = '',
    this.match = 75,
    this.mobileNumber = '',
    this.emailAddress = '',
    this.fullAddressText = '',
    this.workingCountry = '',
    this.description = '',
    this.partnerExpectations = '',
    this.partnerExpectationsHobbies = const [],
    this.additionalPhotos = const [],
    this.socialLinks = const {},
    this.connectionStatus = 'None',
  });

  MatrimonialProfileModel copyWith({
    String? id,
    String? userId,
    String? name,
    DateTime? dateOfBirth,
    String? gender,
    int? heightCm,
    int? weightKg,
    String? bloodGroup,
    String? maritalStatus,
    String? education,
    String? occupation,
    String? company,
    double? annualIncome,
    String? village,
    String? city,
    Map<String, dynamic>? family,
    Map<String, dynamic>? lifestyle,
    Map<String, dynamic>? partnerPreferences,
    Map<String, dynamic>? visibility,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? profilePhotoUrl,
    String? introductionVideoUrl,
    int? match,
    String? mobileNumber,
    String? emailAddress,
    String? fullAddressText,
    String? workingCountry,
    String? description,
    String? partnerExpectations,
    List<String>? partnerExpectationsHobbies,
    List<String>? additionalPhotos,
    Map<String, dynamic>? socialLinks,
    String? connectionStatus,
  }) {
    return MatrimonialProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      education: education ?? this.education,
      occupation: occupation ?? this.occupation,
      company: company ?? this.company,
      annualIncome: annualIncome ?? this.annualIncome,
      village: village ?? this.village,
      city: city ?? this.city,
      family: family ?? this.family,
      lifestyle: lifestyle ?? this.lifestyle,
      partnerPreferences: partnerPreferences ?? this.partnerPreferences,
      visibility: visibility ?? this.visibility,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      introductionVideoUrl: introductionVideoUrl ?? this.introductionVideoUrl,
      match: match ?? this.match,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      emailAddress: emailAddress ?? this.emailAddress,
      fullAddressText: fullAddressText ?? this.fullAddressText,
      workingCountry: workingCountry ?? this.workingCountry,
      description: description ?? this.description,
      partnerExpectations: partnerExpectations ?? this.partnerExpectations,
      partnerExpectationsHobbies: partnerExpectationsHobbies ?? this.partnerExpectationsHobbies,
      additionalPhotos: additionalPhotos ?? this.additionalPhotos,
      socialLinks: socialLinks ?? this.socialLinks,
      connectionStatus: connectionStatus ?? this.connectionStatus,
    );
  }

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

    String photoUrl = json['profilePhoto'] as String? ?? '';
    String videoUrl = json['introductionVideo'] as String? ?? '';

    if (photoUrl.startsWith('/uploads')) {
      photoUrl = '${ApiConfig.baseUrl.replaceAll('/api', '')}$photoUrl';
    }
    if (videoUrl.startsWith('/uploads')) {
      videoUrl = '${ApiConfig.baseUrl.replaceAll('/api', '')}$videoUrl';
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
      profilePhotoUrl: photoUrl,
      introductionVideoUrl: videoUrl,
      match: (json['match'] as num?)?.toInt() ?? 75,
      mobileNumber: json['mobileNumber'] as String? ?? '',
      emailAddress: json['emailAddress'] as String? ?? '',
      fullAddressText: json['fullAddressText'] as String? ?? '',
      workingCountry: json['workingCountry'] as String? ?? '',
      description: json['description'] as String? ?? '',
      partnerExpectations: json['partnerExpectations'] as String? ?? '',
      partnerExpectationsHobbies: (json['partnerExpectationsHobbies'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      additionalPhotos: (() {
        final photos = (json['additionalPhotos'] as List?)?.map((e) => e.toString()).toList() ?? const [];
        return photos.map((p) => p.startsWith('/uploads') ? '${ApiConfig.baseUrl.replaceAll('/api', '')}$p' : p).toList();
      })(),
      socialLinks: json['socialLinks'] as Map<String, dynamic>? ?? const {},
      connectionStatus: json['connectionStatus'] as String? ?? 'None',
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
      'createdDate': createdAt?.toIso8601String(),
      'updatedDate': updatedAt?.toIso8601String(),
      'profilePhoto': profilePhotoUrl,
      'introductionVideo': introductionVideoUrl,
      'mobileNumber': mobileNumber,
      'emailAddress': emailAddress,
      'fullAddressText': fullAddressText,
      'workingCountry': workingCountry,
      'description': description,
      'partnerExpectations': partnerExpectations,
      'partnerExpectationsHobbies': partnerExpectationsHobbies,
      'additionalPhotos': additionalPhotos,
      'socialLinks': socialLinks,
      'connectionStatus': connectionStatus,
    };
  }
}
