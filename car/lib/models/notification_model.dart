class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String? titleEn;
  final String? titleFr;
  final String? descriptionEn;
  final String? descriptionFr;
  final String type;
  final DateTime createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    this.titleEn,
    this.titleFr,
    this.descriptionEn,
    this.descriptionFr,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      titleEn: json['title_en']?.toString(),
      titleFr: json['title_fr']?.toString(),
      descriptionEn: json['description_en']?.toString(),
      descriptionFr: json['description_fr']?.toString(),
      type: json['type'].toString(),
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] ?? false,
    );
  }

  String getDisplayTitle(String language) {
    if (language == 'English' && titleEn != null && titleEn!.isNotEmpty) {
      return titleEn!;
    }
    if (language == 'Français' && titleFr != null && titleFr!.isNotEmpty) {
      return titleFr!;
    }
    return title;
  }

  String getDisplayDescription(String language) {
    if (language == 'English' && descriptionEn != null && descriptionEn!.isNotEmpty) {
      return descriptionEn!;
    }
    if (language == 'Français' && descriptionFr != null && descriptionFr!.isNotEmpty) {
      return descriptionFr!;
    }
    return description;
  }
}
