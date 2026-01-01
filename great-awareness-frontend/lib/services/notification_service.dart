
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/notification.dart';
import '../services/auth_service.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final String _baseUrl = 'https://gwa-notifications-worker.aashardcustomz.workers.dev';
  final List<AppNotification> _notifications = [];
  final StreamController<AppNotification> _streamController = StreamController.broadcast();

  WebSocketChannel? _channel;
  AuthService? _authService;
  StreamSubscription? _wsSubscription;
  String? _lastConnectedUserId;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  Stream<AppNotification> get notificationStream => _streamController.stream;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  bool _isInitialized = false;

  // Initialize service
  Future<void> init(AuthService authService) async {
    _authService = authService;
    
    // Only set up FCM listeners once
    if (!_isInitialized) {
      _setupFCM();
      _isInitialized = true;
    }

    // Handle user connection state
    if (_authService?.isAuthenticated ?? false) {
      if (_lastConnectedUserId != _authService?.currentUser?.id) {
        // User changed or new login
        disconnectWebSocket();
        _lastConnectedUserId = _authService?.currentUser?.id;
        await fetchHistory();
        connectWebSocket();
        
        // Refresh FCM token association
        String? token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          _registerFCMToken(token);
        }
      } else if (_channel == null) {
        // Same user but disconnected
        connectWebSocket();
      }
    } else {
      // User logged out
      disconnectWebSocket();
      _lastConnectedUserId = null;
      _notifications.clear();
      notifyListeners();
    }
  }

  Future<void> _setupFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    
    // Request permissions
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Listen for token refreshes
      messaging.onTokenRefresh.listen((newToken) {
        if (_authService?.currentUser?.id != null) {
          _registerFCMToken(newToken);
        }
      });

      // Foreground handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.data.isNotEmpty) {
           // If we receive a data payload, treat it as a notification
           // This handles cases where WebSocket might be disconnected temporarily
           _handleIncomingData(message.data);
        }
        
        if (message.notification != null) {
           // System displayed a notification (or we might need to show a local one if we want)
           // But requirement says "Appear silently without UI interruption"
           // So we just update the list.
           // Usually data payload contains the structured data we need.
        }
      });
    }
  }

  // Called when user logs in or app resumes
  void connectWebSocket() {
    if (_channel != null) {
      debugPrint('WebSocket already connected');
      return;
    }
    
    if (_authService?.currentUser?.id == null) {
      debugPrint('Cannot connect WebSocket: User ID is null');
      return;
    }

    final userId = _authService!.currentUser!.id;
    final wsUrl = Uri.parse('$_baseUrl/notifications/ws?userId=$userId').replace(scheme: 'wss');
    
    debugPrint('Connecting to Notification WS: $wsUrl');
    
    try {
      _channel = WebSocketChannel.connect(wsUrl);
      debugPrint('WebSocket connection initiated');
      
      _wsSubscription = _channel!.stream.listen(
        (message) {
          debugPrint('WebSocket received message: $message');
          try {
            final data = json.decode(message);
            _handleIncomingData(data);
          } catch (e) {
            debugPrint('Error parsing notification: $e');
          }
        },
        onDone: () {
          debugPrint('Notification WS closed');
          _channel = null;
          _scheduleReconnect();
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _channel = null;
          _scheduleReconnect();
        },
      );
    } catch (e) {
      debugPrint('WebSocket connection failed: $e');
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    debugPrint('Scheduling WebSocket reconnect in 5 seconds...');
    Timer(const Duration(seconds: 5), () {
      if (_authService?.isAuthenticated ?? false) {
        debugPrint('Attempting WebSocket reconnect...');
        connectWebSocket();
      }
    });
  }

  void disconnectWebSocket() {
    _wsSubscription?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  Future<void> _registerFCMToken(String token) async {
    if (_authService?.currentUser?.id == null) return;
    try {
      await http.post(
        Uri.parse('$_baseUrl/notifications/fcm/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': _authService!.currentUser!.id,
          'token': token,
        }),
      );
    } catch (e) {
      debugPrint('Failed to register FCM token: $e');
    }
  }

  Future<void> fetchHistory() async {
    if (_authService?.currentUser?.id == null) return;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/notifications/history?userId=${_authService!.currentUser!.id}'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _notifications.clear();
        _notifications.addAll(data.map((json) => AppNotification.fromJson(json)).toList());
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to fetch history: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
      
      try {
        await http.post(
          Uri.parse('$_baseUrl/notifications/read'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'notificationId': notificationId}),
        );
      } catch (e) {
        debugPrint('Failed to mark read on backend: $e');
      }
    }
  }
  
  void markAllAsRead() {
    bool hasUnread = _notifications.any((n) => !n.isRead);
    if (!hasUnread) return;

    for (int i = 0; i < _notifications.length; i++) {
       _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();
    
    // Ideally call a bulk mark-read endpoint
  }
  
  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }

  void _handleIncomingData(Map<String, dynamic> data) {
    debugPrint('_handleIncomingData called with: $data');
    try {
      // Handle both nested 'notification' (from some payloads) or flat structure
      final payload = data['notification'] ?? data; 
      
      // If payload is a string (sometimes happens with FCM data fields), parse it
      final notifData = payload is String ? json.decode(payload) : payload;

      final notification = AppNotification.fromJson(notifData);
      debugPrint('Parsed notification: ${notification.title} (ID: ${notification.id})');
      
      if (!_notifications.any((n) => n.id == notification.id)) {
        debugPrint('Adding notification to list and stream');
        _notifications.insert(0, notification);
        _streamController.add(notification);
        notifyListeners();
      } else {
        debugPrint('Notification already exists in list');
      }
    } catch (e) {
      debugPrint("Error processing incoming notification data: $e");
    }
  }

  @override
  void dispose() {
    disconnectWebSocket();
    _streamController.close();
    super.dispose();
  }
}
