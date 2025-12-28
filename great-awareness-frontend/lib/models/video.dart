import 'package:flutter/foundation.dart';

class Video {
  final String id;
  final String title;
  final String description;
  final String objectKey;
  final DateTime createdAt;
  final int fileSize;
  final String contentType;
  final String originalName;
  final int viewCount;
  final int commentCount;
  final String? category;
  String? signedUrl;
  DateTime? signedUrlExpiry;

  Video({
    required this.id,
    required this.title,
    required this.description,
    required this.objectKey,
    required this.createdAt,
    required this.fileSize,
    required this.contentType,
    required this.originalName,
    this.viewCount = 0,
    this.commentCount = 0,
    this.category,
    this.signedUrl,
    this.signedUrlExpiry,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    final nestedVideo = json['video'] is Map<String, dynamic> ? json['video'] as Map<String, dynamic> : null;

    return Video(
      id: json['id'] ?? nestedVideo?['id'],
      title: json['title'] ?? nestedVideo?['title'],
      description: json['description'] ?? nestedVideo?['description'] ?? '',
      objectKey: json['object_key'] ?? nestedVideo?['objectKey'] ?? json['objectKey'],
      createdAt: DateTime.parse(json['created_at'] ?? nestedVideo?['createdAt'] ?? json['createdAt']),
      fileSize: json['file_size'] ?? nestedVideo?['fileSize'] ?? json['fileSize'] ?? 0,
      contentType: json['content_type'] ?? nestedVideo?['contentType'] ?? json['contentType'] ?? 'video/mp4',
      originalName: json['original_name'] ?? nestedVideo?['originalName'] ?? json['originalName'] ?? '',
      viewCount: json['view_count'] ?? nestedVideo?['viewCount'] ?? json['viewCount'] ?? 0,
      commentCount: json['comment_count'] ?? nestedVideo?['commentCount'] ?? json['commentCount'] ?? 0,
      category: json['category'] ?? nestedVideo?['category'],
      signedUrl: json['signed_url'] ?? json['signedUrl'],
      signedUrlExpiry: (json['signed_url_expires_at'] ?? json['signedUrlExpiry']) != null ? DateTime.parse(json['signed_url_expires_at'] ?? json['signedUrlExpiry']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'object_key': objectKey,
      'created_at': createdAt.toIso8601String(),
      'file_size': fileSize,
      'content_type': contentType,
      'original_name': originalName,
      'view_count': viewCount,
      'comment_count': commentCount,
      'category': category,
      'signed_url': signedUrl,
      'signed_url_expires_at': signedUrlExpiry?.toIso8601String(),
    };
  }

  bool get hasValidSignedUrl {
    return signedUrl != null && 
           signedUrlExpiry != null && 
           signedUrlExpiry!.isAfter(DateTime.now());
  }

  String get displayName {
    return title.isNotEmpty ? title : originalName;
  }

  String get formattedFileSize {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    if (fileSize < 1024 * 1024 * 1024) return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  String get formattedDuration {
    final duration = DateTime.now().difference(createdAt);
    if (duration.inDays > 0) return '${duration.inDays} days ago';
    if (duration.inHours > 0) return '${duration.inHours} hours ago';
    if (duration.inMinutes > 0) return '${duration.inMinutes} minutes ago';
    return 'Just now';
  }

  String get formattedViewCount {
    if (viewCount < 1000) return viewCount.toString();
    if (viewCount < 1000000) return '${(viewCount / 1000).toStringAsFixed(1)}K';
    return '${(viewCount / 1000000).toStringAsFixed(1)}M';
  }

  String get formattedCommentCount {
    if (commentCount < 1000) return commentCount.toString();
    if (commentCount < 1000000) return '${(commentCount / 1000).toStringAsFixed(1)}K';
    return '${(commentCount / 1000000).toStringAsFixed(1)}M';
  }
}

class VideoUploadResponse {
  final bool success;
  final Video? video;
  final String? error;
  final String? message;

  VideoUploadResponse({
    required this.success,
    this.video,
    this.error,
    this.message,
  });

  factory VideoUploadResponse.fromJson(Map<String, dynamic> json) {
    return VideoUploadResponse(
      success: json['success'] ?? false,
      video: json['video'] != null ? Video.fromJson(json['video']) : null,
      error: json['error'],
      message: json['message'],
    );
  }
}

class VideoListResponse {
  final List<Video> videos;
  final int total;
  final int page;
  final int perPage;

  VideoListResponse({
    required this.videos,
    required this.total,
    required this.page,
    required this.perPage,
  });

  factory VideoListResponse.fromJson(Map<String, dynamic> json) {
    final videosList = (json['videos'] as List<dynamic>?) ?? [];
    final videos = <Video>[];
    
    for (final videoJson in videosList) {
      try {
        videos.add(Video.fromJson(videoJson));
      } catch (e) {
        debugPrint('Error parsing video: $e');
        // debugPrint('Video JSON: $videoJson'); // Uncomment for debugging
      }
    }

    return VideoListResponse(
      videos: videos,
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      perPage: json['perPage'] ?? 10,
    );
  }
}

class SignedUrlResponse {
  final String signedUrl;
  final DateTime expiry;
  final String videoId;

  SignedUrlResponse({
    required this.signedUrl,
    required this.expiry,
    required this.videoId,
  });

  factory SignedUrlResponse.fromJson(Map<String, dynamic> json) {
    return SignedUrlResponse(
      signedUrl: json['signedUrl'],
      expiry: DateTime.parse(json['expiry']),
      videoId: json['videoId'],
    );
  }
}