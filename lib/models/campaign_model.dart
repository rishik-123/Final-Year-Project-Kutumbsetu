import 'package:flutter/foundation.dart';

class CampaignCategory {
  final String id;
  final String name;
  final String slug;
  final String icon;
  final String description;

  const CampaignCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.icon = 'category',
    this.description = '',
  });

  factory CampaignCategory.fromJson(Map<String, dynamic> json) {
    return CampaignCategory(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      icon: json['icon'] as String? ?? 'category',
      description: json['description'] as String? ?? '',
    );
  }
}

class CampaignDynamicField {
  final String fieldName;
  final String label;
  final String type; // 'text', 'number', 'dropdown', 'radio', 'checkbox', 'date'
  final bool required;
  final List<String> options;
  final String validationRules;
  final int order;

  const CampaignDynamicField({
    required this.fieldName,
    required this.label,
    this.type = 'text',
    this.required = false,
    this.options = const [],
    this.validationRules = '',
    this.order = 0,
  });

  factory CampaignDynamicField.fromJson(Map<String, dynamic> json) {
    return CampaignDynamicField(
      fieldName: json['fieldName'] as String? ?? '',
      label: json['label'] as String? ?? '',
      type: json['type'] as String? ?? 'text',
      required: json['required'] as bool? ?? false,
      options: (json['options'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      validationRules: json['validationRules'] as String? ?? '',
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fieldName': fieldName,
      'label': label,
      'type': type,
      'required': required,
      'options': options,
      'validationRules': validationRules,
      'order': order,
    };
  }
}

class CampaignContactInfo {
  final String phone;
  final String email;
  final String organizerName;

  const CampaignContactInfo({
    this.phone = '',
    this.email = '',
    this.organizerName = '',
  });

  factory CampaignContactInfo.fromJson(Map<String, dynamic> json) {
    return CampaignContactInfo(
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      organizerName: json['organizerName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'email': email,
      'organizerName': organizerName,
    };
  }
}

class Campaign {
  final String id;
  final String title;
  final String description;
  final String category;
  final String bannerUrl;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // Draft, Upcoming, Active, Completed, Cancelled
  final String effectiveStatus;
  final double targetAmount;
  final double amountRaised;
  final String objective;
  final CampaignContactInfo contactInfo;
  final String additionalNotes;
  final String? createdBy;
  final List<CampaignDynamicField> dynamicFields;
  final int totalRegistrations;
  final DateTime? createdAt;

  const Campaign({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.bannerUrl = '',
    required this.startDate,
    required this.endDate,
    this.status = 'Active',
    String? effectiveStatus,
    this.targetAmount = 0.0,
    this.amountRaised = 0.0,
    this.objective = '',
    this.contactInfo = const CampaignContactInfo(),
    this.additionalNotes = '',
    this.createdBy,
    this.dynamicFields = const [],
    this.totalRegistrations = 0,
    this.createdAt,
  }) : effectiveStatus = effectiveStatus ?? status;

  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    final progress = amountRaised / targetAmount;
    return progress > 1.0 ? 1.0 : progress;
  }

  bool get isActive {
    final computed = calculatedStatus;
    return computed == 'Active';
  }

  String get calculatedStatus {
    if (status == 'Cancelled' || status == 'Draft') return status;
    final now = DateTime.now();
    if (startDate.isAfter(now)) return 'Upcoming';
    if (endDate.isBefore(now)) return 'Completed';
    return 'Active';
  }

  factory Campaign.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic dateVal) {
      if (dateVal == null) return DateTime.now();
      if (dateVal is String) return DateTime.tryParse(dateVal) ?? DateTime.now();
      return DateTime.now();
    }

    final fieldsList = (json['dynamicFields'] as List<dynamic>?)
            ?.map((e) => CampaignDynamicField.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return Campaign(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      bannerUrl: json['bannerUrl'] as String? ?? '',
      startDate: parseDate(json['startDate']),
      endDate: parseDate(json['endDate']),
      status: json['status'] as String? ?? 'Active',
      effectiveStatus: json['effectiveStatus'] as String? ?? json['status'] as String?,
      targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 0.0,
      amountRaised: (json['amountRaised'] as num?)?.toDouble() ?? 0.0,
      objective: json['objective'] as String? ?? '',
      contactInfo: json['contactInfo'] != null
          ? CampaignContactInfo.fromJson(json['contactInfo'] as Map<String, dynamic>)
          : const CampaignContactInfo(),
      additionalNotes: json['additionalNotes'] as String? ?? '',
      createdBy: json['createdBy'] is Map
          ? (json['createdBy']['_id'] as String?)
          : (json['createdBy'] as String?),
      dynamicFields: fieldsList,
      totalRegistrations: (json['totalRegistrations'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'bannerUrl': bannerUrl,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status,
      'targetAmount': targetAmount,
      'amountRaised': amountRaised,
      'objective': objective,
      'contactInfo': contactInfo.toJson(),
      'additionalNotes': additionalNotes,
      'createdBy': createdBy,
      'dynamicFields': dynamicFields.map((f) => f.toJson()).toList(),
    };
  }
}
