import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

class CloudflareStorageService {
  static const String accountId = 'd972c9d3656cd9fd1377ccd22fb6462d';
  static const String bucketName = 'videos';
  static const String publicUrl = 'https://pub-36251f5d8b4d4e1e977c867f3343dadc.r2.dev';
  static const String s3Endpoint = 'https://d972c9d3656cd9fd1377ccd22fb6462d.r2.cloudflarestorage.com';
  
  // For S3 API access, you'll need these credentials
  // static const String accessKeyId = 'YOUR_ACCESS_KEY_ID';
  // static const String secretAccessKey = 'YOUR_SECRET_ACCESS_KEY';
  
  /// Fetch videos from Cloudflare R2 bucket using S3 API
  static Future<List<CloudflareVideo>> fetchVideosFromBucket() async {
    try {
      // First, let's test if we can access the bucket with your new endpoint
      print('Testing S3 API access to: $s3Endpoint/$bucketName');
      
      // Try S3 API first to get actual bucket contents
      final s3Videos = await _fetchVideosFromS3Api();
      if (s3Videos.isNotEmpty) {
        print('Successfully loaded ${s3Videos.length} videos from S3 API');
        return s3Videos;
      }
      
      print('S3 API failed, trying public endpoint: $publicUrl');
      // Fallback to public endpoint if S3 API fails
      final publicVideos = await _fetchVideosFromPublicEndpoint();
      if (publicVideos.isNotEmpty) {
        print('Successfully loaded ${publicVideos.length} videos from public endpoint');
        return publicVideos;
      }
      
      print('All API methods failed, using configured videos');
      // Final fallback to manual configuration
      return getConfiguredVideos();
    } catch (e) {
      print('Error in fetchVideosFromBucket: $e');
      // Final fallback: return configured videos
      return getConfiguredVideos();
    }
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

  /// Parse S3 API XML response
  static List<CloudflareVideo> _parseS3XmlResponse(String xmlString) {
    try {
      final document = xml.XmlDocument.parse(xmlString);
      final contents = document.findAllElements('Contents');
      
      List<CloudflareVideo> videos = [];
      
      for (final content in contents) {
        final key = content.findElements('Key').first.innerText;
        final lastModified = content.findElements('LastModified').first.innerText;
        final size = int.parse(content.findElements('Size').first.innerText);
        
        // Only process .mp4 files
        if (key.endsWith('.mp4')) {
          videos.add(CloudflareVideo(
            key: key,
            url: '$publicUrl/$key', // Use public URL for streaming
            lastModified: DateTime.parse(lastModified),
            size: size,
            title: _generateTitleFromFilename(key),
            category: _categorizeVideo(key),
            duration: _estimateDuration(size),
          ));
        }
      }
      
      return videos;
    } catch (e) {
      return [];
    }
  }

  /// Parse XML response from Cloudflare R2 public endpoint
  static List<CloudflareVideo> _parseXmlResponse(String xmlString) {
    final document = xml.XmlDocument.parse(xmlString);
    final contents = document.findAllElements('Contents');
    
    List<CloudflareVideo> videos = [];
    
    for (final content in contents) {
      final key = content.findElements('Key').first.innerText;
      final lastModified = content.findElements('LastModified').first.innerText;
      final size = int.parse(content.findElements('Size').first.innerText);
      
      // Only process .mp4 files
      if (key.endsWith('.mp4')) {
        videos.add(CloudflareVideo(
          key: key,
          url: '$publicUrl/$key',
          lastModified: DateTime.parse(lastModified),
          size: size,
          title: _generateTitleFromFilename(key),
          category: _categorizeVideo(key),
          duration: _estimateDuration(size),
        ));
      }
    }
    
    return videos;
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

  /// Get videos based on manual configuration (recommended approach)
  static List<CloudflareVideo> getConfiguredVideos() {
    return [
      CloudflareVideo(
        key: 'understanding-addiction-psychology.mp4',
        url: 'https://pub-36251f5d8b4d4e1e977c867f3343dadc.r2.dev/understanding-addiction-psychology.mp4',
        lastModified: DateTime.now().subtract(const Duration(days: 30)),
        size: 150 * 1024 * 1024, // 150MB
        title: 'Understanding Addiction Psychology',
        category: 'Overcoming Addictions',
        duration: '15:30',
      ),
      CloudflareVideo(
        key: 'breaking-free-pornography.mp4',
        url: 'https://pub-36251f5d8b4d4e1e977c867f3343dadc.r2.dev/breaking-free-pornography.mp4',
        lastModified: DateTime.now().subtract(const Duration(days: 25)),
        size: 200 * 1024 * 1024, // 200MB
        title: 'Breaking Free from Pornography',
        category: 'Overcoming Addictions',
        duration: '22:15',
      ),
      CloudflareVideo(
        key: 'building-healthy-habits.mp4',
        url: 'https://pub-36251f5d8b4d4e1e977c867f3343dadc.r2.dev/building-healthy-habits.mp4',
        lastModified: DateTime.now().subtract(const Duration(days: 28)),
        size: 180 * 1024 * 1024, // 180MB
        title: 'Building Healthy Habits',
        category: 'Overcoming Addictions',
        duration: '18:45',
      ),
      CloudflareVideo(
        key: 'understanding-childhood-trauma.mp4',
        url: 'https://pub-36251f5d8b4d4e1e977c867f3343dadc.r2.dev/understanding-childhood-trauma.mp4',
        lastModified: DateTime.now().subtract(const Duration(days: 20)),
        size: 250 * 1024 * 1024, // 250MB
        title: 'Understanding Childhood Trauma',
        category: 'Healing Trauma',
        duration: '25:20',
      ),
      CloudflareVideo(
        key: 'emdr-therapy-explained.mp4',
        url: 'https://pub-36251f5d8b4d4e1e977c867f3343dadc.r2.dev/emdr-therapy-explained.mp4',
        lastModified: DateTime.now().subtract(const Duration(days: 15)),
        size: 300 * 1024 * 1024, // 300MB
        title: 'EMDR Therapy Explained',
        category: 'Healing Trauma',
        duration: '30:10',
      ),
      CloudflareVideo(
        key: 'self-compassion-practices.mp4',
        url: 'https://pub-36251f5d8b4d4e1e977c867f3343dadc.r2.dev/self-compassion-practices.mp4',
        lastModified: DateTime.now().subtract(const Duration(days: 18)),
        size: 120 * 1024 * 1024, // 120MB
        title: 'Self-Compassion Practices',
        category: 'Healing Trauma',
        duration: '12:30',
      ),
      CloudflareVideo(
        key: 'healthy-communication-skills.mp4',
        url: 'https://pub-36251f5d8b4d4e1e977c867f3343dadc.r2.dev/healthy-communication-skills.mp4',
        lastModified: DateTime.now().subtract(const Duration(days: 22)),
        size: 200 * 1024 * 1024, // 200MB
        title: 'Healthy Communication Skills',
        category: 'Relationships',
        duration: '20:15',
      ),
      CloudflareVideo(
        key: 'setting-boundaries.mp4',
        url: 'https://pub-36251f5d8b4d4e1e977c867f3343dadc.r2.dev/setting-boundaries.mp4',
        lastModified: DateTime.now().subtract(const Duration(days: 12)),
        size: 160 * 1024 * 1024, // 160MB
        title: 'Setting Boundaries',
        category: 'Relationships',
        duration: '16:40',
      ),
      CloudflareVideo(
        key: 'healing-from-heartbreak.mp4',
        url: 'https://pub-36251f5d8b4d4e1e977c867f3343dadc.r2.dev/healing-from-heartbreak.mp4',
        lastModified: DateTime.now().subtract(const Duration(days: 10)),
        size: 280 * 1024 * 1024, // 280MB
        title: 'Healing from Heartbreak',
        category: 'Relationships',
        duration: '28:50',
      ),
    ];
  }

  /// Get default videos if bucket access fails
  static List<CloudflareVideo> _getDefaultVideos() {
    return [
      CloudflareVideo(
        key: 'understanding-addiction-psychology.mp4',
        url: 'https://pub-36251f5d8b4d4e1e977c867f3343dadc.r2.dev/understanding-addiction-psychology.mp4',
        lastModified: DateTime.now().subtract(const Duration(days: 30)),
        size: 150 * 1024 * 1024, // 150MB
        title: 'Understanding Addiction Psychology',
        category: 'Overcoming Addictions',
        duration: '15:30',
      ),
      CloudflareVideo(
        key: 'breaking-free-pornography.mp4',
        url: 'https://pub-36251f5d8b4d4e1e977c867f3343dadc.r2.dev/breaking-free-pornography.mp4',
        lastModified: DateTime.now().subtract(const Duration(days: 25)),
        size: 200 * 1024 * 1024, // 200MB
        title: 'Breaking Free from Pornography',
        category: 'Overcoming Addictions',
        duration: '22:15',
      ),
      CloudflareVideo(
        key: 'understanding-childhood-trauma.mp4',
        url: 'https://pub-36251f5d8b4d4e1e977c867f3343dadc.r2.dev/understanding-childhood-trauma.mp4',
        lastModified: DateTime.now().subtract(const Duration(days: 20)),
        size: 250 * 1024 * 1024, // 250MB
        title: 'Understanding Childhood Trauma',
        category: 'Healing Trauma',
        duration: '25:20',
      ),
    ];
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