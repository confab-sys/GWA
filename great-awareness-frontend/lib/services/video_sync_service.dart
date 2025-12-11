import '../models/video.dart';
import 'video_service.dart';

/// Service for syncing videos between R2 bucket and database
/// Handles signed URL generation and video metadata updates
class VideoSyncService {
  static const Duration requestTimeout = Duration(seconds: 30);
  
  /// Sync videos from R2 bucket to database
  /// This will scan the R2 bucket and create database entries for any videos
  /// that exist in the bucket but not in the database
  static Future<VideoSyncResponse> syncVideosFromBucket() async {
    try {
      final response = await VideoService.syncVideos();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Update signed URLs for all videos in the database
  /// This generates new signed URLs for videos that need them
  static Future<UpdateSignedUrlsResponse> updateVideoSignedUrls() async {
    try {
      final response = await VideoService.updateSignedUrls();
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Complete sync process:
  /// 1. Sync videos from bucket to database
  /// 2. Update signed URLs for all videos
  static Future<Map<String, dynamic>> completeSync() async {
    final results = {
      'syncSuccess': false,
      'signedUrlsSuccess': false,
      'totalSynced': 0,
      'totalSignedUrls': 0,
      'errors': <String>[],
    };

    try {
      // Step 1: Sync videos from bucket
      final syncResponse = await syncVideosFromBucket();
      results['syncSuccess'] = true;
      results['totalSynced'] = syncResponse.synced;
      
      // Step 2: Update signed URLs
      final signedUrlsResponse = await updateVideoSignedUrls();
      results['signedUrlsSuccess'] = true;
      results['totalSignedUrls'] = signedUrlsResponse.updated;
      
    } catch (e) {
      (results['errors'] as List<String>).add(e.toString());
    }

    return results;
  }

  /// Get video with signed URL, refreshing if necessary
  /// This ensures the video has a valid signed URL before playback
  static Future<Video> getVideoWithFreshSignedUrl(String videoId) async {
    try {
      // First try to get the video with signed URL
      final video = await VideoService.getVideoWithSignedUrl(videoId);
      
      // Check if the signed URL is valid
      if (video.hasValidSignedUrl) {
        return video;
      }
      
      // If no valid signed URL, try to refresh it
      final signedUrlResponse = await VideoService.getSignedUrl(videoId);
      
      // Return video with new signed URL
      return Video(
        id: video.id,
        title: video.title,
        description: video.description,
        objectKey: video.objectKey,
        createdAt: video.createdAt,
        fileSize: video.fileSize,
        contentType: video.contentType,
        originalName: video.originalName,
        viewCount: video.viewCount,
        commentCount: video.commentCount,
        signedUrl: signedUrlResponse.signedUrl,
        signedUrlExpiry: signedUrlResponse.expiry,
      );
      
    } catch (e) {
      rethrow;
    }
  }

  /// Check if videos need sync and perform sync if necessary
  /// This can be called periodically or when videos fail to play
  static Future<bool> checkAndSyncIfNeeded() async {
    try {
      // Try to get a list of videos to see if any exist
      final videosResponse = await VideoService.listVideos(page: 1, perPage: 1);
      
      if (videosResponse.videos.isEmpty) {
        // No videos found in database, syncing from bucket
        await completeSync();
        return true;
      }
      
      // Check if the first video has a valid signed URL
      final firstVideo = videosResponse.videos.first;
      if (!firstVideo.hasValidSignedUrl) {
        // Videos missing valid signed URLs, updating
        await updateVideoSignedUrls();
        return true;
      }
      
      // Videos appear to be properly synced
      return false;
      
    } catch (e) {
      // If we can't check, try a full sync
      try {
        await completeSync();
        return true;
      } catch (syncError) {
        return false;
      }
    }
  }
}