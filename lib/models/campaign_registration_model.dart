import 'campaign_model.dart';
import 'user_model.dart';

class CampaignRegistration {
  final String id;
  final String campaignId;
  final Campaign? campaign;
  final String userId;
  final UserModel? user;
  final String registrationNumber;
  final Map<String, dynamic> submittedData;
  final String registrationStatus; // Registered, Pending, Approved, Rejected, Cancelled, Attended
  final DateTime registeredAt;
  final DateTime? cancellationTimestamp;

  const CampaignRegistration({
    required this.id,
    required this.campaignId,
    this.campaign,
    required this.userId,
    this.user,
    required this.registrationNumber,
    this.submittedData = const {},
    this.registrationStatus = 'Registered',
    required this.registeredAt,
    this.cancellationTimestamp,
  });

  bool get isCancelled => registrationStatus == 'Cancelled';

  factory CampaignRegistration.fromJson(Map<String, dynamic> json) {
    Campaign? c;
    if (json['campaignId'] is Map) {
      c = Campaign.fromJson(json['campaignId'] as Map<String, dynamic>);
    }

    UserModel? u;
    if (json['userId'] is Map) {
      u = UserModel.fromJson(json['userId'] as Map<String, dynamic>);
    }

    final cId = json['campaignId'] is Map
        ? (json['campaignId']['_id'] as String? ?? '')
        : (json['campaignId'] as String? ?? '');

    final uId = json['userId'] is Map
        ? (json['userId']['_id'] as String? ?? '')
        : (json['userId'] as String? ?? '');

    Map<String, dynamic> subData = {};
    if (json['submittedData'] != null && json['submittedData'] is Map) {
      subData = Map<String, dynamic>.from(json['submittedData'] as Map);
    }

    return CampaignRegistration(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      campaignId: cId,
      campaign: c,
      userId: uId,
      user: u,
      registrationNumber: json['registrationNumber'] as String? ?? '',
      submittedData: subData,
      registrationStatus: json['registrationStatus'] as String? ?? 'Registered',
      registeredAt: json['registeredAt'] != null
          ? DateTime.tryParse(json['registeredAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      cancellationTimestamp: json['cancellationTimestamp'] != null
          ? DateTime.tryParse(json['cancellationTimestamp'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'campaignId': campaignId,
      'userId': userId,
      'registrationNumber': registrationNumber,
      'submittedData': submittedData,
      'registrationStatus': registrationStatus,
      'registeredAt': registeredAt.toIso8601String(),
      'cancellationTimestamp': cancellationTimestamp?.toIso8601String(),
    };
  }
}
