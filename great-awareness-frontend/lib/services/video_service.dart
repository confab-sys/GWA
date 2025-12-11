import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../models/video.dart';
import '../utils/config.dart';

class VideoService {
  static const String baseUrl = 'https://gwa-video-worker-v2.aashardcustomz.workers.dev'; // Your deployed worker domain
  static const Duration requestTimeout = Duration(seconds: 30);

  // Upload video file
  static Future<VideoUploadResponse> uploadVideo({
    required File videoFile,
    required String title,
    String description = '',
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final mimeType = lookupMimeType(videoFile.path) ?? 'video/mp4';
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/videos/upload'),
      );

      // Add video file
      final fileStream = http.ByteStream(videoFile.openRead());
      final fileLength = await videoFile.length();
      
      request.files.add(http.MultipartFile(
        'video',
        fileStream,
        fileLength,
        filename: videoFile.path.split('/').last,
        contentType: MediaType.parse(mimeType),
      ));

      // Add form fields
      request.fields['title'] = title;
      request.fields['description'] = description;

      // Send request with progress tracking
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        return VideoUploadResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = json.decode(response.body);
        return VideoUploadResponse(
          success: false,
          error: errorResponse['error'] ?? 'Upload failed',
          message: errorResponse['message'],
        );
      }
    } catch (e) {
      return VideoUploadResponse(
        success: false,
        error: 'Upload error',
        message: e.toString(),
      );
    }
  }

  // List all videos
  static Future<VideoListResponse> listVideos({
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      // Convert page/perPage to limit/offset for Cloudflare Worker compatibility
      final limit = perPage;
      final offset = (page - 1) * perPage;
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/videos?limit=$limit&offset=$offset'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return VideoListResponse.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to load videos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load videos: $e');
    }
  }

  // Get signed URL for a video
  static Future<SignedUrlResponse> getSignedUrl(String videoId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/videos/$videoId/signed-url'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return SignedUrlResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = json.decode(response.body);
        throw Exception(errorResponse['error'] ?? 'Failed to get signed URL');
      }
    } catch (e) {
      throw Exception('Failed to get signed URL: $e');
    }
  }

  // Get video details
  static Future<Video> getVideo(String videoId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/videos/$videoId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return Video.fromJson(jsonResponse);
      } else {
        final errorResponse = json.decode(response.body);
        throw Exception(errorResponse['error'] ?? 'Video not found');
      }
    } catch (e) {
      throw Exception('Failed to get video: $e');
    }
  }

  // Get video with signed URL (combines getVideo and getSignedUrl)
  static Future<Video> getVideoWithSignedUrl(String videoId) async {
    try {
      // Get video details
      final video = await getVideo(videoId);
      
      // Get signed URL
      final signedUrlResponse = await getSignedUrl(videoId);
      
      // Return video with signed URL
      return Video(
        id: video.id,
        title: video.title,
        description: video.description,
        objectKey: video.objectKey,
        createdAt: video.createdAt,
        fileSize: video.fileSize,
        contentType: video.contentType,
        originalName: video.originalName,
        signedUrl: signedUrlResponse.signedUrl,
        signedUrlExpiry: signedUrlResponse.expiry,
      );
    } catch (e) {
      throw Exception('Failed to get video with signed URL: $e');
    }
  }

  // Check if signed URL is still valid, refresh if needed
  static Future<String> getValidVideoUrl(Video video) async {
    if (video.hasValidSignedUrl) {
      return video.signedUrl!;
    }
    
    // Get new signed URL
    final signedUrlResponse = await getSignedUrl(video.id);
    return signedUrlResponse.signedUrl;
  }

  // Track video view
  static Future<ViewTrackResponse> trackView(String videoId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/videos/$videoId/track-view'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return ViewTrackResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = json.decode(response.body);
        return ViewTrackResponse(
          success: false,
          error: errorResponse['error'] ?? 'Failed to track view',
          message: errorResponse['message'],
        );
      }
    } catch (e) {
      return ViewTrackResponse(
        success: false,
        error: 'Track view error',
        message: e.toString(),
      );
    }
  }

  // Sync videos from R2 bucket to database
  static Future<VideoSyncResponse> syncVideos() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/videos/sync'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return VideoSyncResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = json.decode(response.body);
        throw Exception(errorResponse['error'] ?? 'Failed to sync videos');
      }
    } catch (e) {
      throw Exception('Failed to sync videos: $e');
    }
  }

  // Update signed URLs for videos
  static Future<UpdateSignedUrlsResponse> updateSignedUrls() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/videos/update-signed-urls'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return UpdateSignedUrlsResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = json.decode(response.body);
        throw Exception(errorResponse['error'] ?? 'Failed to update signed URLs');
      }
    } catch (e) {
      throw Exception('Failed to update signed URLs: $e');
    }
  }

  // Bulk update video URLs in database
  static Future<BulkUpdateUrlsResponse> bulkUpdateUrls(List<Map<String, dynamic>> videos) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/videos/bulk-update-urls'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'videos': videos}),
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return BulkUpdateUrlsResponse.fromJson(jsonResponse);
      } else {
        final errorResponse = json.decode(response.body);
        throw Exception(errorResponse['error'] ?? 'Failed to bulk update URLs');
      }
    } catch (e) {
      throw Exception('Failed to bulk update URLs: $e');
    }
  }
}

class ViewTrackResponse {
  final bool success;
  final int? viewCount;
  final String? error;
  final String? message;

  ViewTrackResponse({
    required this.success,
    this.viewCount,
    this.error,
    this.message,
  });

  factory ViewTrackResponse.fromJson(Map<String, dynamic> json) {
    return ViewTrackResponse(
      success: json['success'] ?? false,
      viewCount: json['viewCount'],
      error: json['error'],
      message: json['message'],
    );
  }
}

class VideoSyncResponse {
  final bool success;
  final String message;
  final int synced;
  final int skipped;
  final List<dynamic>? videos;
  final String? error;

  VideoSyncResponse({
    required this.success,
    required this.message,
    required this.synced,
    required this.skipped,
    this.videos,
    this.error,
  });

  factory VideoSyncResponse.fromJson(Map<String, dynamic> json) {
    return VideoSyncResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      synced: json['synced'] ?? 0,
      skipped: json['skipped'] ?? 0,
      videos: json['videos'],
      error: json['error'],
    );
  }
}

class UpdateSignedUrlsResponse {
  final bool success;
  final String message;
  final int updated;
  final List<dynamic>? videos;
  final String? error;

  UpdateSignedUrlsResponse({
    required this.success,
    required this.message,
    required this.updated,
    this.videos,
    this.error,
  });

  factory UpdateSignedUrlsResponse.fromJson(Map<String, dynamic> json) {
    return UpdateSignedUrlsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      updated: json['updated'] ?? 0,
      videos: json['videos'],
      error: json['error'],
    );
  }
}

class BulkUpdateUrlsResponse {
  final bool success;
  final String message;
  final int updated;
  final List<dynamic>? errors;
  final String? error;

  BulkUpdateUrlsResponse({
    required this.success,
    required this.message,
    required this.updated,
    this.errors,
    this.error,
  });

  factory BulkUpdateUrlsResponse.fromJson(Map<String, dynamic> json) {
    return BulkUpdateUrlsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      updated: json['updated'] ?? 0,
      errors: json['errors'],
      error: json['error'],
    );
  }
}