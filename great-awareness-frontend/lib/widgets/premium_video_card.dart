import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/video.dart';
import '../services/video_service.dart';

class PremiumVideoCard extends StatefulWidget {
  final Video video;
  final bool isLarge;
  final VoidCallback onTap;

  const PremiumVideoCard({
    super.key,
    required this.video,
    this.isLarge = false,
    required this.onTap,
  });

  @override
  State<PremiumVideoCard> createState() => _PremiumVideoCardState();
}

class _PremiumVideoCardState extends State<PremiumVideoCard> {
  Video? _videoWithDetails;
  bool _isLoadingDetails = false;
  String? _debugError;

  @override
  void initState() {
    super.initState();
    _loadVideoDetails();
  }

  Future<void> _loadVideoDetails() async {
    // If we already have a thumbnail URL, we might not need to fetch details,
    // but sometimes the list endpoint returns a partial object.
    // However, if the thumbnail is missing, we definitely need to fetch details.
    
    if (widget.video.thumbnailUrl != null && widget.video.thumbnailUrl!.isNotEmpty) {
       return;
    }

    if (!mounted) return;
    
    setState(() {
      _isLoadingDetails = true;
    });

    try {
      // Fetch full video details which might contain the correct thumbnail URL
      final videoDetails = await VideoService.getVideo(widget.video.id);
      
      if (mounted) {
        setState(() {
          _videoWithDetails = videoDetails;
          _isLoadingDetails = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
          _debugError = "Fetch Err"; 
          // We keep it short. User asked to remove "No URL in API" specifically.
        });
        debugPrint('Error loading video details for card: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoToUse = _videoWithDetails ?? widget.video;
    final thumbnailUrl = videoToUse.thumbnailUrl;
    final width = widget.isLarge ? 280.0 : 160.0;
    final height = widget.isLarge ? 200.0 : 220.0; // Adjusted based on usage

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail Section
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: thumbnailUrl != null && thumbnailUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: thumbnailUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[800],
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white.withOpacity(0.5),
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[900],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error, color: Colors.white54),
                                  Text("Img Err", style: GoogleFonts.judson(color: Colors.white, fontSize: 10)),
                                ],
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[900],
                            child: Center(
                              child: _isLoadingDetails
                                  ? CircularProgressIndicator(
                                      color: Colors.white.withOpacity(0.5),
                                      strokeWidth: 2,
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.movie, color: Colors.white54),
                                        if (_debugError != null)
                                          Text(
                                            _debugError!,
                                            style: const TextStyle(color: Colors.red, fontSize: 10),
                                          ),
                                      ],
                                    ),
                            ),
                          ),
                  ),
                  
                  // Duration Badge
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _formatDuration(videoToUse.createdAt),
                        style: GoogleFonts.judson(
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Play Icon Overlay
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Info Section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      videoToUse.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.judson(
                        textStyle: const TextStyle(
                          color: Colors.black, // Assuming light card, or adjust based on context
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      videoToUse.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.judson(
                        textStyle: TextStyle(
                          color: Colors.black.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(DateTime createdAt) {
    final duration = DateTime.now().difference(createdAt);
    if (duration.inDays > 0) return '${duration.inDays}d ago';
    if (duration.inHours > 0) return '${duration.inHours}h ago';
    if (duration.inMinutes > 0) return '${duration.inMinutes}m ago';
    return 'Just now';
  }
}
