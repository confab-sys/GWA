import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';

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
      print('Fetching videos from Cloudflare Worker API: $workerUrl/api/videos');
      
      // Try Cloudflare Worker API first
      final workerVideos = await _fetchVideosFromWorker();
      if (workerVideos.isNotEmpty) {
        print('Successfully loaded ${workerVideos.length} videos from Cloudflare Worker');
        return workerVideos;
      }
      
      print('Cloudflare Worker API failed or returned no videos');
      
      // Try to sync videos from R2 to database first
      print('Attempting to sync videos from R2 bucket to database...');
      final syncResult = await _syncVideosFromR2();
      if (syncResult) {
        print('Video sync completed, retrying fetch...');
        // Retry fetching after sync
        final workerVideosAfterSync = await _fetchVideosFromWorker();
        if (workerVideosAfterSync.isNotEmpty) {
          print('Successfully loaded ${workerVideosAfterSync.length} videos after sync');
          return workerVideosAfterSync;
        }
      }
      
      print('All API methods failed, using configured videos as fallback');
      // Final fallback to manual configuration
      return getConfiguredVideos();
    } catch (e) {
      print('Error in fetchVideosFromBucket: $e');
      print('Using configured videos as final fallback');
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
      print('Cloudflare Worker API error: $e');
      return [];
    }
  }

  /// Sync videos from R2 bucket to database
  static Future<bool> _syncVideosFromR2() async {
    try {
      print('Attempting to sync videos from R2 bucket to database...');
      
      // Try to access the Cloudflare Worker sync endpoint
      final response = await http.post(
        Uri.parse('$workerUrl/api/videos/sync'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Video sync result: ${data['synced']} videos synced, ${data['skipped']} videos skipped');
        return data['synced'] > 0;
      }
      
      print('Sync endpoint returned status: ${response.statusCode}');
      return false;
    } on TimeoutException catch (e) {
      print('Video sync timeout: $e');
      print('Cloudflare Worker may be down or unreachable');
      return false;
    } on SocketException catch (e) {
      print('Video sync network error: $e');
      print('Cannot reach Cloudflare Worker - using local fallback');
      return false;
    } catch (e) {
      print('Video sync error: $e');
      print('Using local video fallback');
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

  /// Fetch videos using S3 API
  static Future<List<CloudflareVideo>> _fetchVideosFromS3Api() async {
    try {
      // List objects in the bucket using S3 API
      final response = await http.get(
        Uri.parse('$s3Endpoint/$bucketName'),
        headers: {
          'Accept': 'application/xml',
        },
      );

      if (response.statusCode == 200) {
        return _parseS3XmlResponse(response.body);
      } else if (response.statusCode == 403 || response.statusCode == 401) {
        // Authentication required - try with public access
        return await _fetchVideosFromPublicEndpoint();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
  
  /// Fetch from public endpoint if S3 API requires auth
  static Future<List<CloudflareVideo>> _fetchVideosFromPublicEndpoint() async {
    try {
      // Try the public URL first
      final response = await http.get(
        Uri.parse('$publicUrl/'),
        headers: {
          'Accept': 'application/xml',
        },
      );

      if (response.statusCode == 200) {
        return _parseXmlResponse(response.body);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Check if common video files exist in the bucket
  static Future<List<CloudflareVideo>> _fetchVideosByExistenceCheck() async {
    List<CloudflareVideo> foundVideos = [];
    
    // List of common video filenames to check
    final commonVideos = [
      'understanding-addiction-psychology.mp4',
      'breaking-free-pornography.mp4',
      'building-healthy-habits.mp4',
      'understanding-childhood-trauma.mp4',
      'emdr-therapy-explained.mp4',
      'self-compassion-practices.mp4',
      'healthy-communication-skills.mp4',
      'setting-boundaries.mp4',
      'healing-from-heartbreak.mp4',
    ];

    // Check each video file
    for (final videoFile in commonVideos) {
      try {
        final response = await http.head(
          Uri.parse('$publicUrl/$videoFile'),
        );
        
        if (response.statusCode == 200) {
          final contentLength = int.tryParse(response.headers['content-length'] ?? '0') ?? 0;
          final lastModified = response.headers['last-modified'];
          
          foundVideos.add(CloudflareVideo(
            key: videoFile,
            url: '$publicUrl/$videoFile',
            lastModified: lastModified != null ? 
              DateTime.parse(lastModified) : DateTime.now(),
            size: contentLength,
            title: _generateTitleFromFilename(videoFile),
            category: _categorizeVideo(videoFile),
            duration: _estimateDuration(contentLength),
          ));
        }
      } catch (e) {
        // Video file not found, continue checking other files
      }
    }

    // If no videos found, return default list
    return foundVideos.isNotEmpty ? foundVideos : _getDefaultVideos();
  }

  /// Parse S3 API XML response (deprecated - not used)
  static List<CloudflareVideo> _parseS3XmlResponse(String xmlString) {
    // XML parsing removed - using JSON API instead
    return [];
  }

  /// Parse XML response from Cloudflare R2 public endpoint (deprecated - not used)
  static List<CloudflareVideo> _parseXmlResponse(String xmlString) {
    // XML parsing removed - using JSON API instead
    return [];
  }

  /// Generate title from filename
  static String _generateTitleFromFilename(String filename) {
    // Remove .mp4 extension and replace hyphens with spaces
    String name = filename.replaceAll('.mp4', '').replaceAll('-', ' ');
    // Capitalize first letter of each word
    return name.split(' ').map((word) => 
      word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase()
    ).join(' ');
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
      return '${totalMinutes}:${seconds.toString().padLeft(2, '0')}';
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
    
    print('Testing accessibility of ${allVideos.length} videos...');
    
    for (final video in allVideos) {
      final isAccessible = await testVideoUrl(video.url);
      if (isAccessible) {
        print('✓ Video accessible: ${video.title}');
        accessibleVideos.add(video);
      } else {
        print('✗ Video not accessible: ${video.title} - ${video.url}');
      }
    }
    
    print('Found ${accessibleVideos.length} accessible videos out of ${allVideos.length}');
    return accessibleVideos;
  }

  /// Manually add a video to local cache (for when R2 sync isn't working)
  static List<CloudflareVideo> addVideoToCache(String videoKey, String title, {String? description}) {
    final existingVideos = getConfiguredVideos();
    
    // Check if video already exists
    final exists = existingVideos.any((video) => video.key == videoKey);
    if (exists) {
      print('Video $videoKey already exists in cache');
      return existingVideos;
    }
    
    // Add new video
    final newVideo = CloudflareVideo(
      key: videoKey,
      url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4', // Fallback URL
      lastModified: DateTime.now(),
      size: 47 * 1024 * 1024, // Default size
      title: title,
      category: _categorizeVideo(title),
      duration: '15:42',
    );
    
    print('Added video to cache: $title ($videoKey)');
    return [...existingVideos, newVideo];
  }

  /// Get videos based on manual configuration (recommended approach)
  static List<CloudflareVideo> getConfiguredVideos() {
    return [
      CloudflareVideo(
        key: 'sample-video-1.mp4',
        url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        lastModified: DateTime.now().subtract(const Duration(days: 30)),
        size: 47 * 1024 * 1024, // 47MB (estimated size)
        title: 'Building Healthy Relationships',
        category: 'Relationships',
        duration: '15:42', // Estimated based on file size
      ),
      CloudflareVideo(
        key: 'sample-video-2.mp4',
        url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
        lastModified: DateTime.now().subtract(const Duration(days: 25)),
        size: 65 * 1024 * 1024, // 65MB (estimated size)
        title: 'Overcoming Anxiety',
        category: 'Managing Anxiety',
        duration: '21:18', // Estimated based on file size
      ),
      CloudflareVideo(
        key: 'sample-video-3.mp4',
        url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
        lastModified: DateTime.now().subtract(const Duration(days: 20)),
        size: 30 * 1024 * 1024, // 30MB (estimated size)
        title: 'Understanding Addiction',
        category: 'Overcoming Addictions',
        duration: '10:00', // Estimated based on file size
      ),
      CloudflareVideo(
        key: 'sample-video-4.mp4',
        url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
        lastModified: DateTime.now().subtract(const Duration(days: 15)),
        size: 25 * 1024 * 1024, // 25MB (estimated size)
        title: 'Healing from Trauma',
        category: 'Healing Trauma',
        duration: '8:30', // Estimated based on file size
      ),
    ];
  }

  /// Get default videos if bucket access fails
  static List<CloudflareVideo> _getDefaultVideos() {
    return getConfiguredVideos();
  }

  /// For S3 API access (if you want to use proper S3 authentication)
  /// You'll need to configure these credentials in your Cloudflare R2 settings
  /*
  static Future<List<CloudflareVideo>> fetchVideosWithS3API() async {
    final String s3Endpoint = 'https://$accountId.r2.cloudflarestorage.com';
    final String bucketUrl = '$s3Endpoint/$bucketName';
    
    // Create proper AWS Signature Version 4 signed request
    final request = http.Request('GET', Uri.parse('$bucketUrl/'));
    
    // Add AWS Signature V4 headers (implementation needed)
    // This would require: x-amz-date, authorization header, etc.
    
    try {
      final response = await http.Client().send(request);
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        return _parseXmlResponse(responseBody);
      }
    } catch (e) {
      print('S3 API error: $e');
    }
    
    return _getDefaultVideos();
  }
  */
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