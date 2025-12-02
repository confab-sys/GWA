import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notification.dart';
import '../models/content.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<AppNotification> _notifications = [];
  final StreamController<AppNotification> _notificationStream = StreamController<AppNotification>.broadcast();
  
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  Stream<AppNotification> get notificationStream => _notificationStream.stream;
  
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  
  // Add notification for new post
  void addPostNotification(Content post) {
    final notification = AppNotification(
      id: 'post_${post.id}_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.post,
      title: 'New Post in ${post.topic}',
      content: post.body,
      authorName: post.authorName,
      authorAvatar: post.authorAvatar,
      category: post.topic,
      timestamp: post.createdAt,
      postId: post.id,
    );
    
    _addNotification(notification);
  }
  
  // Add notification for new question (from Q&A)
  void addQuestionNotification(Map<String, dynamic> question) {
    final notification = AppNotification(
      id: 'question_${question['id']}_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.question,
      title: 'New Question in ${question['category']}',
      content: question['content'] ?? question['title'] ?? '',
      authorName: question['authorName'] ?? 'Anonymous',
      authorAvatar: question['authorAvatar'],
      category: question['category'] ?? 'General',
      timestamp: DateTime.parse(question['createdAt'] ?? DateTime.now().toIso8601String()),
      questionId: question['id'],
    );
    
    _addNotification(notification);
  }
  
  void _addNotification(AppNotification notification) {
    // Check if similar notification already exists (within last 5 minutes)
    final existingIndex = _notifications.indexWhere((n) => 
      n.type == notification.type &&
      n.postId == notification.postId &&
      n.questionId == notification.questionId &&
      DateTime.now().difference(n.timestamp).inMinutes < 5
    );
    
    if (existingIndex == -1) {
      _notifications.insert(0, notification); // Add to beginning (newest first)
      _notificationStream.add(notification);
      notifyListeners();
    }
  }
  
  // Mark notification as read
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }
  
  // Mark all notifications as read
  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    notifyListeners();
  }
  
  // Clear all notifications
  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }
  
  // Clear old notifications (older than 7 days)
  void clearOldNotifications() {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
    _notifications.removeWhere((n) => n.timestamp.isBefore(cutoffDate));
    notifyListeners();
  }
  
  @override
  void dispose() {
    _notificationStream.close();
    super.dispose();
  }
}