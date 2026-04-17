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
    
    // Fallback for English if titleEn is missing
    if (language == 'English') {
      if (type.toLowerCase() == 'match' || type.toLowerCase() == 'found') return 'New Vehicle Match';
      if (type.toLowerCase() == 'assignment') return 'Agent Assigned';
      if (type.toLowerCase() == 'payment') return 'Payment Confirmed';
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
    
    // Fallback for English if descriptionEn is missing
    if (language == 'English') {
      if (type.toLowerCase() == 'match' || type.toLowerCase() == 'found') return 'A new match has been found for your request.';
      if (type.toLowerCase() == 'assignment') return 'An agent has been assigned to your request.';
      if (type.toLowerCase() == 'payment') return 'Your payment has been successfully processed.';
    }
    
    return description;
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? titleEn,
    String? titleFr,
    String? descriptionEn,
    String? descriptionFr,
    String? type,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      titleEn: titleEn ?? this.titleEn,
      titleFr: titleFr ?? this.titleFr,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      descriptionFr: descriptionFr ?? this.descriptionFr,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
