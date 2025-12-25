class Content {
  final int id;
  final String title;
  final String body;
  final String topic;
  final String postType;
  final String? imagePath;
  final bool isTextOnly;
  final String authorName;
  final String? authorAvatar;
  final int likesCount;
  final int commentsCount;
  final bool isLikedByUser;
  final String status;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;
  final int? createdBy;
  
  Content({
    required this.id,
    required this.title,
    required this.body,
    required this.topic,
    required this.postType,
    this.imagePath,
    required this.isTextOnly,
    required this.authorName,
    this.authorAvatar,
    required this.likesCount,
    required this.commentsCount,
    required this.isLikedByUser,
    required this.status,
    required this.isFeatured,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
    this.createdBy,
  });
  
  factory Content.fromJson(Map<String, dynamic> json) {
    bool toBool(dynamic val, bool def) {
      if (val == null) return def;
      if (val is bool) return val;
      if (val is int) return val == 1;
      if (val is String) return val == '1' || val.toLowerCase() == 'true';
      return def;
    }

    DateTime toDateTime(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is! String) return DateTime.now();
      // Handle SQL timestamp "YYYY-MM-DD HH:MM:SS" by replacing space with T
      String iso = val.replaceAll(' ', 'T');
      return DateTime.tryParse(iso) ?? DateTime.now();
    }

    return Content(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      topic: json['topic'] ?? '',
      postType: json['post_type'] ?? 'text',
      imagePath: json['image_path'],
      isTextOnly: toBool(json['is_text_only'], true),
      authorName: json['author_name'] ?? 'Admin',
      authorAvatar: json['author_avatar'],
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      isLikedByUser: toBool(json['is_liked_by_user'], false),
      status: json['status'] ?? 'published',
      isFeatured: toBool(json['is_featured'], false),
      createdAt: toDateTime(json['created_at']),
      updatedAt: toDateTime(json['updated_at']),
      publishedAt: json['published_at'] != null 
          ? toDateTime(json['published_at'])
          : null,
      createdBy: json['created_by'],
    );
  }
  
  // Convert to map for local storage or API calls
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'topic': topic,
      'post_type': postType,
      'image_path': imagePath,
      'is_text_only': isTextOnly,
      'author_name': authorName,
      'author_avatar': authorAvatar,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'is_liked_by_user': isLikedByUser,
      'status': status,
      'is_featured': isFeatured,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'published_at': publishedAt?.toIso8601String(),
      'created_by': createdBy,
    };
  }
}