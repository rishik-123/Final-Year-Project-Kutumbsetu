/// JSON/MongoDB-ready matrimonial profile model. Keep MongoDB access on a
/// secure server API; do not connect a mobile app directly to the database.
class MatrimonialProfileModel {
  const MatrimonialProfileModel({
    required this.userId, required this.name, required this.dateOfBirth,
    required this.gender, required this.heightCm, required this.weightKg,
    required this.bloodGroup, required this.education, required this.occupation,
    required this.company, required this.annualIncome, required this.village,
    required this.city, required this.family, required this.lifestyle,
    required this.partnerPreferences, required this.visibility,
    required this.status, required this.createdAt, required this.updatedAt,
    this.profilePhotoUrl, this.introductionVideoUrl,
  });

  final String userId, name, gender, bloodGroup, education, occupation, company;
  final String village, city, status;
  final int heightCm, weightKg;
  final double annualIncome;
  final DateTime dateOfBirth, createdAt, updatedAt;
  final String? profilePhotoUrl, introductionVideoUrl;
  final Map<String, dynamic> family, lifestyle, partnerPreferences, visibility;

  Map<String, dynamic> toMongoDocument() => {
    'userId': userId, 'profilePhoto': profilePhotoUrl, 'introductionVideo': introductionVideoUrl,
    'name': name, 'dob': dateOfBirth.toIso8601String(), 'gender': gender,
    'heightCm': heightCm, 'weightKg': weightKg, 'bloodGroup': bloodGroup,
    'education': education, 'occupation': occupation, 'company': company,
    'annualIncome': annualIncome, 'village': village, 'city': city,
    'familyInformation': family, 'lifestyle': lifestyle,
    'partnerPreferences': partnerPreferences, 'visibilitySettings': visibility,
    'profileStatus': status, 'createdDate': createdAt.toIso8601String(),
    'updatedDate': updatedAt.toIso8601String(),
  };
}
