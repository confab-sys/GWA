
import 'dart:convert';

enum NotificationType {
  post,
  question,
  comment,
  like,
  badge,
  milestone,
  chat,
  event,
  system,
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

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'] != null 
        ? (json['metadata'] is String ? jsonDecode(json['metadata']) : json['metadata']) 
        : {};
    
    NotificationType parseType(String typeStr) {
      switch (typeStr) {
        case 'post': return NotificationType.post;
        case 'question': return NotificationType.question;
        case 'comment': return NotificationType.comment;
        case 'like': return NotificationType.like;
        case 'badge': return NotificationType.badge;
        case 'milestone': return NotificationType.milestone;
        case 'chat': return NotificationType.chat;
        case 'event': return NotificationType.event;
        default: return NotificationType.system;
      }
    }

    return AppNotification(
      id: json['id']?.toString() ?? '',
      type: parseType(json['type'] ?? 'system'),
      title: json['title'] ?? '',
      content: json['body'] ?? '',
      authorName: metadata['authorName'] ?? 'System',
      authorAvatar: metadata['authorAvatar'],
      category: metadata['category'] ?? 'General',
      timestamp: json['created_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['created_at']) 
          : (json['createdAt'] != null ? DateTime.fromMillisecondsSinceEpoch(json['createdAt']) : DateTime.now()),
      isRead: json['is_read'] == 1 || json['isRead'] == true,
      postId: metadata['postId'] != null ? int.tryParse(metadata['postId'].toString()) : null,
      questionId: metadata['questionId'] != null ? int.tryParse(metadata['questionId'].toString()) : null,
    );
  }

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
}
