import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/config.dart';
import 'auth_service.dart';

class WellnessStatus {
  final String userId;
  final String addictionType;
  final DateTime? startDate;
  final DateTime? lastResetDate;
  final int streakDays;
  final bool isActive;
  final List<Milestone> milestones;

  WellnessStatus({
    required this.userId,
    required this.addictionType,
    this.startDate,
    this.lastResetDate,
    this.streakDays = 0,
    this.isActive = false,
    this.milestones = const [],
  });

  factory WellnessStatus.fromJson(Map<String, dynamic> json) {
    var milestonesList = <Milestone>[];
    if (json['milestones'] != null) {
      milestonesList = (json['milestones'] as List)
          .map((m) => Milestone.fromJson(m))
          .toList();
    }

    return WellnessStatus(
      userId: json['user_id'] ?? '',
      addictionType: json['addiction_type'] ?? '',
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      lastResetDate: json['last_reset_date'] != null ? DateTime.parse(json['last_reset_date']) : null,
      streakDays: json['streak_days'] ?? 0,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      milestones: milestonesList,
    );
  }
}

class CommunityMember {
  final String userId;
  final String name;
  final String addictionType;
  final DateTime startDate;

  CommunityMember({
    required this.userId,
    required this.name,
    required this.addictionType,
    required this.startDate,
  });

  factory CommunityMember.fromJson(Map<String, dynamic> json) {
    return CommunityMember(
      userId: json['user_id'],
      name: json['name'] ?? 'Anonymous',
      addictionType: json['addiction_type'] ?? 'Unknown',
      startDate: DateTime.parse(json['start_date']),
    );
  }
}

class WellnessResource {
  final int id;
  final String type; // 'video', 'book', 'podcast', 'article'
  final String title;
  final String? subtitle;
  final String url;
  final String? thumbnailUrl;
  final DateTime createdAt;

  WellnessResource({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    required this.url,
    this.thumbnailUrl,
    required this.createdAt,
  });

  factory WellnessResource.fromJson(Map<String, dynamic> json) {
    return WellnessResource(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      subtitle: json['subtitle'],
      url: json['url'],
      thumbnailUrl: json['thumbnail_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class Milestone {
  final int id;
  final String label;
  final int durationSeconds;
  final int iconCode;
  final String colorHex;
  final String description;
  final bool isUnlocked;

  Milestone({
    required this.id,
    required this.label,
    required this.durationSeconds,
    required this.iconCode,
    required this.colorHex,
    required this.description,
    required this.isUnlocked,
  });

  factory Milestone.fromJson(Map<String, dynamic> json) {
    return Milestone(
      id: json['id'],
      label: json['label'],
      durationSeconds: json['duration_seconds'],
      iconCode: json['icon_code'],
      colorHex: json['color_hex'],
      description: json['description'],
      isUnlocked: json['is_unlocked'] == true || json['is_unlocked'] == 1,
    );
  }
}

class WellnessEvent {
  final int id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? location;
  final DateTime eventDate;
  final String createdBy;
  final bool isJoined;
  final int participantCount;

  WellnessEvent({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.location,
    required this.eventDate,
    required this.createdBy,
    this.isJoined = false,
    this.participantCount = 0,
  });

  factory WellnessEvent.fromJson(Map<String, dynamic> json) {
    return WellnessEvent(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['image_url'],
      location: json['location'],
      eventDate: DateTime.parse(json['event_date']),
      createdBy: json['created_by'],
      isJoined: json['is_joined'] == true || json['is_joined'] == 1,
      participantCount: json['participant_count'] ?? 0,
    );
  }
}

class WellnessService extends ChangeNotifier {
  final AuthService _authService;
  
  WellnessService(this._authService);

  Future<WellnessStatus?> getStatus() async {
    final user = _authService.currentUser;
    if (user == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$wellnessWorkerUrl/api/wellness/status?user_id=${user.id}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['is_active'] == false) return null;
        return WellnessStatus.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching wellness status: $e');
      return null;
    }
  }

  Future<void> joinProgram(String addictionType) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception("User not logged in");

    try {
      final response = await http.post(
        Uri.parse('$wellnessWorkerUrl/api/wellness/join'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': user.id,
          'addiction_type': addictionType,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to join program: ${response.body}");
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error joining wellness program: $e');
      rethrow;
    }
  }

  Future<void> resetTimer() async {
    final user = _authService.currentUser;
    if (user == null) throw Exception("User not logged in");

    try {
      final response = await http.post(
        Uri.parse('$wellnessWorkerUrl/api/wellness/reset'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': user.id,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to reset timer: ${response.body}");
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error resetting timer: $e');
      rethrow;
    }
  }

  Future<List<CommunityMember>> getCommunity() async {
    try {
      final response = await http.get(
        Uri.parse('$wellnessWorkerUrl/api/wellness/community'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => CommunityMember.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching community: $e');
      return [];
    }
  }

  Future<List<WellnessResource>> getResources({String? type}) async {
    try {
      final uri = Uri.parse('$wellnessWorkerUrl/api/wellness/resources')
          .replace(queryParameters: type != null ? {'type': type} : null);
      
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => WellnessResource.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching resources: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getMilestones() async {
    final user = _authService.currentUser;
    if (user == null) return {'milestones': <Milestone>[], 'new_unlocks': <String>[]};

    try {
      final response = await http.get(
        Uri.parse('$wellnessWorkerUrl/api/wellness/milestones?user_id=${user.id}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> milestonesData = data['milestones'];
        final List<dynamic> newUnlocksData = data['new_unlocks'];
        
        return {
          'milestones': milestonesData.map((json) => Milestone.fromJson(json)).toList(),
          'new_unlocks': newUnlocksData.map((e) => e.toString()).toList(),
        };
      }
      return {'milestones': <Milestone>[], 'new_unlocks': <String>[]};
    } catch (e) {
      debugPrint('Error fetching milestones: $e');
      return {'milestones': <Milestone>[], 'new_unlocks': <String>[]};
    }
  }

  Future<void> addResource({
    required String type,
    required String title,
    String? subtitle,
    required String url,
    String? thumbnailUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$wellnessWorkerUrl/api/wellness/resources'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'type': type,
          'title': title,
          'subtitle': subtitle,
          'url': url,
          'thumbnail_url': thumbnailUrl,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to add resource: ${response.body}");
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding resource: $e');
      rethrow;
    }
  }

  // --- EVENTS METHODS ---

  Future<List<WellnessEvent>> getEvents() async {
    final user = _authService.currentUser;
    // Even if user is null, we can fetch public events, but 'isJoined' will be false
    final userIdParam = user != null ? '?user_id=${user.id}' : '';

    try {
      final response = await http.get(
        Uri.parse('$wellnessWorkerUrl/api/wellness/events$userIdParam'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => WellnessEvent.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching events: $e');
      return [];
    }
  }

  Future<void> createEvent({
    required String title,
    required String description,
    String? imageUrl,
    String? location,
    required DateTime eventDate,
  }) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception("User not logged in");

    try {
      final response = await http.post(
        Uri.parse('$wellnessWorkerUrl/api/wellness/events'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'title': title,
          'description': description,
          'image_url': imageUrl,
          'location': location,
          'event_date': eventDate.toIso8601String(),
          'created_by': user.id,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to create event: ${response.body}");
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating event: $e');
      rethrow;
    }
  }

  Future<void> joinEvent(int eventId) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception("User not logged in");

    try {
      final response = await http.post(
        Uri.parse('$wellnessWorkerUrl/api/wellness/events/join'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': user.id,
          'event_id': eventId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to join event: ${response.body}");
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error joining event: $e');
      rethrow;
    }
  }

  Future<void> leaveEvent(int eventId) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception("User not logged in");

    try {
      final response = await http.post(
        Uri.parse('$wellnessWorkerUrl/api/wellness/events/leave'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': user.id,
          'event_id': eventId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to leave event: ${response.body}");
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error leaving event: $e');
      rethrow;
    }
  }
}
