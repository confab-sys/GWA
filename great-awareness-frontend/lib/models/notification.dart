
enum NotificationType {
  post,
  question,
  comment,
  like,
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String content;
  final String authorName;
  final String? authorAvatar;
  final String category;
  final DateTime timestamp;
  final bool isRead;
  final int? postId;
  final int? questionId;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.authorName,
    this.authorAvatar,
    required this.category,
    required this.timestamp,
    this.isRead = false,
    this.postId,
    this.questionId,
  });

  AppNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? content,
    String? authorName,
    String? authorAvatar,
    String? category,
    DateTime? timestamp,
    bool? isRead,
    int? postId,
    int? questionId,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      postId: postId ?? this.postId,
      questionId: questionId ?? this.questionId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is AppNotification &&
      other.id == id &&
      other.type == type &&
      other.title == title &&
      other.content == content &&
      other.authorName == authorName &&
      other.authorAvatar == authorAvatar &&
      other.category == category &&
      other.timestamp == timestamp &&
      other.isRead == isRead &&
      other.postId == postId &&
      other.questionId == questionId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      type.hashCode ^
      title.hashCode ^
      content.hashCode ^
      authorName.hashCode ^
      authorAvatar.hashCode ^
      category.hashCode ^
      timestamp.hashCode ^
      isRead.hashCode ^
      postId.hashCode ^
      questionId.hashCode;
  }
}