import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/notification.dart';
import '../models/content.dart';
import '../services/notification_service.dart';
import 'post_detail_screen.dart';
import 'qa_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _notificationService = Provider.of<NotificationService>(context, listen: false);
    // Mark all notifications as read when opening the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationService.markAllAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD3E4DE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Notifications',
          style: GoogleFonts.judson(
            textStyle: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Provider.of<NotificationService>(context, listen: false).clearAll();
            },
            child: Text(
              'Clear All',
              style: GoogleFonts.judson(
                textStyle: TextStyle(
                  color: Colors.red[600],
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<NotificationService>(
        builder: (context, notificationService, child) {
          final notifications = notificationService.notifications;
          
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: GoogleFonts.judson(
                      textStyle: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'New posts and questions will appear here',
                    style: GoogleFonts.judson(
                      textStyle: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: notification.isRead ? Colors.white : Colors.blue[50],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon based on notification type
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getIconBackgroundColor(notification.type),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: _getIconColor(notification.type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Notification content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: GoogleFonts.judson(
                              textStyle: TextStyle(
                                fontSize: 16,
                                fontWeight: notification.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.content,
                      style: GoogleFonts.judson(
                        textStyle: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (notification.authorAvatar != null)
                          CircleAvatar(
                            backgroundImage: AssetImage(notification.authorAvatar!),
                            radius: 12,
                          )
                        else
                          const CircleAvatar(
                            backgroundColor: Colors.grey,
                            radius: 12,
                            child: Icon(Icons.person, size: 12, color: Colors.white),
                          ),
                        const SizedBox(width: 6),
                        Text(
                          notification.authorName,
                          style: GoogleFonts.judson(
                            textStyle: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatTimestamp(notification.timestamp),
                          style: GoogleFonts.judson(
                            textStyle: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleNotificationTap(AppNotification notification) {
    // Mark as read
    Provider.of<NotificationService>(context, listen: false)
        .markAsRead(notification.id);

    // Navigate to appropriate screen based on notification type
    if (notification.type == NotificationType.post && notification.postId != null) {
      // Navigate to post detail
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostDetailScreen(
            post: Content(
              id: notification.postId!,
              title: notification.title,
              body: notification.content,
              topic: notification.category,
              postType: 'text',
              imagePath: null,
              isTextOnly: true,
              authorName: notification.authorName,
              authorAvatar: notification.authorAvatar,
              likesCount: 0,
              commentsCount: 0,
              isLikedByUser: false,
              status: 'published',
              isFeatured: false,
              createdAt: notification.timestamp,
              updatedAt: notification.timestamp,
            ),
            postIndex: 0,
            onLikeToggle: (postId) {
              // Handle like toggle - you can implement this if needed
              debugPrint('Like toggled for post $postId');
            },
            onSaveToggle: (postId) {
              // Handle save toggle - you can implement this if needed
              debugPrint('Save toggled for post $postId');
            },
          ),
        ),
      );
    } else if (notification.type == NotificationType.question && notification.questionId != null) {
      // Navigate to Q&A screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const QAScreen(),
        ),
      );
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.badge:
        return Icons.emoji_events;
      case NotificationType.milestone:
        return Icons.flag;
      case NotificationType.chat:
        return Icons.chat_bubble;
      case NotificationType.event:
        return Icons.event;
      case NotificationType.post:
        return Icons.article;
      case NotificationType.question:
        return Icons.help;
      case NotificationType.system:
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.badge:
        return Colors.orange;
      case NotificationType.milestone:
        return Colors.green;
      case NotificationType.chat:
        return Colors.blue;
      case NotificationType.event:
        return Colors.purple;
      case NotificationType.post:
        return Colors.teal;
      case NotificationType.question:
        return Colors.red;
      case NotificationType.system:
      default:
        return Colors.grey[700]!;
    }
  }

  Color _getIconBackgroundColor(NotificationType type) {
    switch (type) {
      case NotificationType.badge:
        return Colors.orange.withOpacity(0.1);
      case NotificationType.milestone:
        return Colors.green.withOpacity(0.1);
      case NotificationType.chat:
        return Colors.blue.withOpacity(0.1);
      case NotificationType.event:
        return Colors.purple.withOpacity(0.1);
      case NotificationType.post:
        return Colors.teal.withOpacity(0.1);
      case NotificationType.question:
        return Colors.red.withOpacity(0.1);
      case NotificationType.system:
      default:
        return Colors.grey.withOpacity(0.1);
    }
  }
}