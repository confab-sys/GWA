
class Comment {
  final int id;
  final int contentId;
  final int userId;
  final String text;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> user;

  Comment({
    required this.id,
    required this.contentId,
    required this.userId,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
    required this.user,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? 0,
      contentId: json['content_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      text: json['text'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at']) ?? DateTime.now()
          : DateTime.now(),
      user: json['user'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content_id': contentId,
      'user_id': userId,
      'text': text,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user': user,
    };
  }
}