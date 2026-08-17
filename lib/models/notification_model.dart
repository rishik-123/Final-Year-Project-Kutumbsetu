class AppNotification {
  final String id;
  final String? userId;
  final String title;
  final String message;
  final String type;
  final String referenceId;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    this.userId,
    required this.title,
    required this.message,
    this.type = 'SYSTEM',
    this.referenceId = '',
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      userId: json['userId'] as String?,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'SYSTEM',
      referenceId: json['referenceId'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
