import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/video.dart';
import '../services/video_service.dart';

class CloudflareVideoPlayer extends StatefulWidget {
  final Video video;
  final String title;
  final String subtitle;
  final int initialLikes;
  final bool initialIsLiked;
  final Function(int likes, bool isLiked)? onLikeChanged;
  final VoidCallback? onVideoCompleted;

  const CloudflareVideoPlayer({
    super.key,
    required this.video,
    required this.title,
    required this.subtitle,
    this.initialLikes = 0,
    this.initialIsLiked = false,
    this.onLikeChanged,
    this.onVideoCompleted,
  });

  @override
  State<CloudflareVideoPlayer> createState() => _CloudflareVideoPlayerState();
}

class _CloudflareVideoPlayerState extends State<CloudflareVideoPlayer> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isRetrying = false;
  Timer? _urlRefreshTimer;
  bool _viewTracked = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void dispose() {
    _urlRefreshTimer?.cancel();
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get valid video URL (with signed URL if needed)
      final videoUrl = await VideoService.getValidVideoUrl(widget.video);
      
      // Initialize video player - use networkUrl instead of deprecated network
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      
      await _videoPlayerController!.initialize();
      
      // Set up completion listener
      _videoPlayerController!.addListener(_onVideoStateChanged);
      
      // Track view when video starts playing
      _videoPlayerController!.addListener(() {
        if (_videoPlayerController!.value.isPlaying && !_viewTracked) {
          _viewTracked = true;
          _trackVideoView();
        }
      });
      
      // Create Chewie controller
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        showControls: true,
        showControlsOnInitialize: true,
        allowFullScreen: true,
        allowMuting: true,
        autoInitialize: true,
        errorBuilder: (context, errorMessage) {
          return _buildErrorWidget(errorMessage);
        },
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.blue,
          handleColor: Colors.blueAccent,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.lightBlue.withValues(alpha: 0.5), // Use withValues instead of withOpacity
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
        aspectRatio: _videoPlayerController!.value.aspectRatio,
      );

      // Set up URL refresh timer for signed URLs
      if (widget.video.signedUrlExpiry != null) {
        final timeUntilExpiry = widget.video.signedUrlExpiry!.difference(DateTime.now());
        final refreshTime = timeUntilExpiry - const Duration(minutes: 5); // Refresh 5 minutes before expiry
        
        // Check if refreshTime is positive (greater than zero)
        if (refreshTime > Duration.zero) {
          _urlRefreshTimer = Timer(refreshTime, _refreshSignedUrl);
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load video: $e';
        });
      }
    }
  }

  void _onVideoStateChanged() {
    if (_videoPlayerController?.value.hasError ?? false) {
      final error = _videoPlayerController!.value.errorDescription;
      setState(() {
        _errorMessage = 'Video playback error: $error';
      });
    }
    
    // Check if video completed
    if (_videoPlayerController?.value.position != null &&
        _videoPlayerController?.value.duration != null &&
        _videoPlayerController!.value.position >= _videoPlayerController!.value.duration) {
      widget.onVideoCompleted?.call();
    }
  }

  Future<void> _refreshSignedUrl() async {
    try {
      final signedUrlResponse = await VideoService.getSignedUrl(widget.video.id);
      
      // Re-initialize player with new URL - no need to create updatedVideo variable
      await _reinitializeWithNewUrl(signedUrlResponse.signedUrl);
      
      // Set up next refresh timer
      final timeUntilExpiry = signedUrlResponse.expiry.difference(DateTime.now());
      final refreshTime = timeUntilExpiry - const Duration(minutes: 5);
      
      // Check if refreshTime is positive (greater than zero)
      if (refreshTime > Duration.zero) {
        _urlRefreshTimer = Timer(refreshTime, _refreshSignedUrl);
      }
    } catch (e) {
      debugPrint('Failed to refresh signed URL: $e');
    }
  }

  Future<void> _reinitializeWithNewUrl(String newUrl) async {
    try {
      // Dispose old controllers
      _chewieController?.dispose();
      _videoPlayerController?.dispose();
      
      // Create new controllers with updated URL - use networkUrl instead of deprecated network
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(newUrl));
      await _videoPlayerController!.initialize();
      
      _videoPlayerController!.addListener(_onVideoStateChanged);
      
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        showControls: true,
        showControlsOnInitialize: true,
        allowFullScreen: true,
        allowMuting: true,
        autoInitialize: true,
        errorBuilder: (context, errorMessage) {
          return _buildErrorWidget(errorMessage);
        },
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.blue,
          handleColor: Colors.blueAccent,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.lightBlue.withValues(alpha: 0.5), // Use withValues instead of withOpacity
        ),
        aspectRatio: _videoPlayerController!.value.aspectRatio,
      );
      
      if (mounted) {
        setState(() {
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to refresh video URL: $e';
        });
      }
    }
  }

  Widget _buildErrorWidget(String? errorMessage) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.white.withValues(alpha: 0.8), // Use withValues instead of withOpacity
            ),
            const SizedBox(height: 16),
            Text(
              'Video Playback Error',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Unable to play this video',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.8), // Use withValues instead of withOpacity
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isRetrying ? null : _retryPlayback,
                  icon: _isRetrying 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(
                    _isRetrying ? 'Retrying...' : 'Retry',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: Text(
                    'Back',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _retryPlayback() async {
    setState(() {
      _isRetrying = true;
      _errorMessage = null;
    });

    try {
      // Try to get a fresh signed URL
      final signedUrlResponse = await VideoService.getSignedUrl(widget.video.id);
      await _reinitializeWithNewUrl(signedUrlResponse.signedUrl);
      
      setState(() {
        _isRetrying = false;
      });
    } catch (e) {
      setState(() {
        _isRetrying = false;
        _errorMessage = 'Retry failed: $e';
      });
    }
  }

  Future<void> _trackVideoView() async {
    try {
      final response = await VideoService.trackView(widget.video.id);
      if (response.success && mounted) {
        // Optionally update the local view count if needed
        // For now, we'll just track it silently
        print('View tracked successfully. New count: ${response.viewCount}');
      }
    } catch (e) {
      // Silently fail - view tracking shouldn't interrupt video playback
      print('Failed to track view: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading video...',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null && _chewieController == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: _buildErrorWidget(_errorMessage),
      );
    }

    if (_chewieController == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: _buildErrorWidget('Failed to initialize video player'),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Video Player
          Expanded(
            child: Chewie(controller: _chewieController!),
          ),
          // Video Info
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle,
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.8), // Use withValues instead of withOpacity
                      fontSize: 14,
                    ),
                  ),
                ],
                if (widget.video.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.video.description,
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.7), // Use withValues instead of withOpacity
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.6), // Use withValues instead of withOpacity
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.video.formattedDuration,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.6), // Use withValues instead of withOpacity
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.video_file,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.6), // Use withValues instead of withOpacity
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.video.formattedFileSize,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.6), // Use withValues instead of withOpacity
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.visibility,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.6), // Use withValues instead of withOpacity
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.video.formattedViewCount,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.6), // Use withValues instead of withOpacity
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.comment,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.6), // Use withValues instead of withOpacity
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.video.formattedCommentCount,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.6), // Use withValues instead of withOpacity
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}