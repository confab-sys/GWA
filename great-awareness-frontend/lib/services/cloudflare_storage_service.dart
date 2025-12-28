import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class CloudflareStorageService {
  static const String workerUrl = 'https://gwa-video-worker-v2.aashardcustomz.workers.dev';
  static const String accountId = 'd972c9d3656cd9fd1377ccd22fb6462d';
  static const String bucketName = 'videos';
  static const String publicUrl = 'https://pub-1c8c879e41fe4ff48de96ceabce671a2.r2.dev';
  static const String s3Endpoint = 'https://d972c9d3656cd9fd1377ccd22fb6462d.r2.cloudflarestorage.com';
  
  // For S3 API access, you'll need these credentials
  // static const String accessKeyId = 'YOUR_ACCESS_KEY_ID';
  // static const String secretAccessKey = 'YOUR_SECRET_ACCESS_KEY';
  
  /// Fetch videos from Cloudflare R2 bucket using Cloudflare Worker API
  static Future<List<CloudflareVideo>> fetchVideosFromBucket() async {
    try {
      debugPrint('Fetching videos from Cloudflare Worker API: $workerUrl/api/videos');
      
      // Try Cloudflare Worker API first
      final workerVideos = await _fetchVideosFromWorker();
      if (workerVideos.isNotEmpty) {
        debugPrint('Successfully loaded ${workerVideos.length} videos from Cloudflare Worker');
        return workerVideos;
      }
      
      debugPrint('Cloudflare Worker API failed or returned no videos');
      
      // Try to sync videos from R2 to database first
      debugPrint('Attempting to sync videos from R2 bucket to database...');
      final syncResult = await _syncVideosFromR2();
      if (syncResult) {
        debugPrint('Video sync completed, retrying fetch...');
        // Retry fetching after sync
        final workerVideosAfterSync = await _fetchVideosFromWorker();
        if (workerVideosAfterSync.isNotEmpty) {
          debugPrint('Successfully loaded ${workerVideosAfterSync.length} videos after sync');
          return workerVideosAfterSync;
        }
      }
      
      debugPrint('All API methods failed, using configured videos as fallback');
      // Final fallback to manual configuration
      return getConfiguredVideos();
    } catch (e) {
      debugPrint('Error in fetchVideosFromBucket: $e');
      debugPrint('Using configured videos as final fallback');
      // Final fallback: return configured videos
      return getConfiguredVideos();
    }
  }
  
  /// Fetch videos from Cloudflare Worker API
  static Future<List<CloudflareVideo>> _fetchVideosFromWorker() async {
    try {
      final response = await http.get(
        Uri.parse('$workerUrl/api/videos'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['videos'] != null) {
          return _parseWorkerResponse(data['videos']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Cloudflare Worker API error: $e');
      return [];
    }
  }

  /// Sync videos from R2 bucket to database
  static Future<bool> _syncVideosFromR2() async {
    try {
      debugPrint('Attempting to sync videos from R2 bucket to database...');
      
      // Try to access the Cloudflare Worker sync endpoint
      final response = await http.post(
        Uri.parse('$workerUrl/api/videos/sync'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Video sync result: ${data['synced']} videos synced, ${data['skipped']} videos skipped');
        return data['synced'] > 0;
      }
      
      debugPrint('Sync endpoint returned status: ${response.statusCode}');
      return false;
    } on TimeoutException catch (e) {
      debugPrint('Video sync timeout: $e');
      debugPrint('Cloudflare Worker may be down or unreachable');
      return false;
    } on SocketException catch (e) {
      debugPrint('Video sync network error: $e');
      debugPrint('Cannot reach Cloudflare Worker - using local fallback');
      return false;
    } catch (e) {
      debugPrint('Video sync error: $e');
      debugPrint('Using local video fallback');
      return false;
    }
  }

  /// Parse Cloudflare Worker response
  static List<CloudflareVideo> _parseWorkerResponse(List<dynamic> videos) {
    return videos.map((video) {
      // Generate a signed URL for the video
      final signedUrl = '$workerUrl/api/videos/${video['id']}/stream';
      
      return CloudflareVideo(
        key: video['object_key'] ?? video['id'],
        url: signedUrl,
        lastModified: DateTime.parse(video['created_at'] ?? DateTime.now().toIso8601String()),
        size: video['file_size'] ?? 0,
        title: video['title'] ?? 'Untitled Video',
        category: _categorizeVideo(video['title'] ?? ''),
        duration: _estimateDuration(video['file_size'] ?? 0),
      );
    }).toList();
  }



  /// Categorize video based on filename or content
  static String _categorizeVideo(String filename) {
    final String lowerFilename = filename.toLowerCase();
    
    if (lowerFilename.contains('addiction') || lowerFilename.contains('habit') || lowerFilename.contains('porn')) {
      return 'Overcoming Addictions';
    } else if (lowerFilename.contains('trauma') || lowerFilename.contains('emdr') || lowerFilename.contains('compassion')) {
      return 'Healing Trauma';
    } else if (lowerFilename.contains('relationship') || lowerFilename.contains('communication') || lowerFilename.contains('boundary') || lowerFilename.contains('heartbreak')) {
      return 'Relationships';
    } else if (lowerFilename.contains('anxiety') || lowerFilename.contains('stress') || lowerFilename.contains('calm')) {
      return 'Managing Anxiety';
    } else if (lowerFilename.contains('depression') || lowerFilename.contains('mood') || lowerFilename.contains('happiness')) {
      return 'Beating Depression';
    } else {
      return 'General Wellness';
    }
  }

  /// Estimate video duration from file size (rough approximation)
  static String _estimateDuration(int sizeInBytes) {
    // Rough estimate: ~1MB per minute for 720p video
    double minutes = sizeInBytes / (1024 * 1024); // Convert to MB
    int totalMinutes = minutes.round();
    
    if (totalMinutes < 60) {
      int seconds = ((minutes - totalMinutes) * 60).round();
      return '$totalMinutes:${seconds.toString().padLeft(2, '0')}';
    } else {
      int hours = totalMinutes ~/ 60;
      int remainingMinutes = totalMinutes % 60;
      return '$hours:${remainingMinutes.toString().padLeft(2, '0')}';
    }
  }

  /// Test if a specific video URL is accessible
  static Future<bool> testVideoUrl(String videoUrl) async {
    try {
      final response = await http.head(Uri.parse(videoUrl));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  /// Get only videos that are actually accessible from the bucket
  static Future<List<CloudflareVideo>> getAccessibleVideos() async {
    final allVideos = getConfiguredVideos();
    List<CloudflareVideo> accessibleVideos = [];
    
    debugPrint('Testing accessibility of ${allVideos.length} videos...');
    
    for (final video in allVideos) {
      final isAccessible = await testVideoUrl(video.url);
      if (isAccessible) {
        debugPrint('✓ Video accessible: ${video.title}');
        accessibleVideos.add(video);
      } else {
        debugPrint('✗ Video not accessible: ${video.title} - ${video.url}');
      }
    }
    
    debugPrint('Found ${accessibleVideos.length} accessible videos out of ${allVideos.length}');
    return accessibleVideos;
  }

  static List<CloudflareVideo> getConfiguredVideos() {
    return [];
  }
}

class CloudflareVideo {
  final String key;
  final String url;
  final DateTime lastModified;
  final int size;
  final String title;
  final String category;
  final String duration;

  CloudflareVideo({
    required this.key,
    required this.url,
    required this.lastModified,
    required this.size,
    required this.title,
    required this.category,
    required this.duration,
  });
}
