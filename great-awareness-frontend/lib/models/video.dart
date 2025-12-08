import 'dart:convert';

class Video {
  final String id;
  final String title;
  final String description;
  final String objectKey;
  final DateTime createdAt;
  final int fileSize;
  final String contentType;
  final String originalName;
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
    this.signedUrl,
    this.signedUrlExpiry,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'] ?? json['video']['id'],
      title: json['title'] ?? json['video']['title'],
      description: json['description'] ?? json['video']['description'] ?? '',
      objectKey: json['object_key'] ?? json['video']['objectKey'] ?? json['objectKey'],
      createdAt: DateTime.parse(json['created_at'] ?? json['video']['createdAt'] ?? json['createdAt']),
      fileSize: json['file_size'] ?? json['video']['fileSize'] ?? json['fileSize'] ?? 0,
      contentType: json['content_type'] ?? json['video']['contentType'] ?? json['contentType'] ?? 'video/mp4',
      originalName: json['original_name'] ?? json['video']['originalName'] ?? json['originalName'] ?? '',
      signedUrl: json['signedUrl'],
      signedUrlExpiry: json['signedUrlExpiry'] != null ? DateTime.parse(json['signedUrlExpiry']) : null,
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
      'signedUrl': signedUrl,
      'signedUrlExpiry': signedUrlExpiry?.toIso8601String(),
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
    return VideoListResponse(
      videos: (json['videos'] as List<dynamic>?)
              ?.map((videoJson) => Video.fromJson(videoJson))
              .toList() ??
          [],
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