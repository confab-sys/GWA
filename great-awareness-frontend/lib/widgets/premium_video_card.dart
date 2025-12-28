import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/video.dart';
import '../services/video_service.dart';

class PremiumVideoCard extends StatefulWidget {
  final Video video;
  final VoidCallback onTap;
  final bool isLarge;

  const PremiumVideoCard({
    super.key,
    required this.video,
    required this.onTap,
    this.isLarge = false,
  });

  @override
  State<PremiumVideoCard> createState() => _PremiumVideoCardState();
}

class _PremiumVideoCardState extends State<PremiumVideoCard> {
  String? _thumbnailUrl;
  bool _isLoadingThumbnail = false;
  String? _debugError; // Added for on-screen debugging

  @override
  void initState() {
    super.initState();
    _thumbnailUrl = widget.video.thumbnailUrl;
    
    // Lazy load thumbnail if missing
    if (_thumbnailUrl == null || _thumbnailUrl!.isEmpty) {
      _loadThumbnail();
    }
  }

  @override
  void didUpdateWidget(PremiumVideoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.video.thumbnailUrl != oldWidget.video.thumbnailUrl) {
      setState(() {
        _thumbnailUrl = widget.video.thumbnailUrl;
      });
    }
  }

  Future<void> _loadThumbnail() async {
    if (_isLoadingThumbnail) return;

    setState(() {
      _isLoadingThumbnail = true;
      _debugError = null;
    });

    try {
      debugPrint('Fetching thumbnail for video ${widget.video.id}...');
      // Fetch full video details which includes the thumbnail URL
      final fullVideo = await VideoService.getVideo(widget.video.id);
      debugPrint('Got video details. Thumbnail: ${fullVideo.thumbnailUrl}');
      
      if (mounted) {
        if (fullVideo.thumbnailUrl != null && fullVideo.thumbnailUrl!.isNotEmpty) {
          setState(() {
            _thumbnailUrl = fullVideo.thumbnailUrl;
          });
        } else {
           debugPrint('No thumbnail URL found in detailed API response for video ${widget.video.id}');
        }
      }
    } catch (e) {
      debugPrint('Error loading thumbnail for video ${widget.video.id}: $e');
       if (mounted) {
        setState(() {
          // Show the exact exception message
          _debugError = e.toString().replaceFirst('Exception: ', '');
          // if (_debugError!.length > 50) {
          //   _debugError = _debugError!.substring(0, 50) + '...';
          // }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingThumbnail = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.isLarge ? 280 : 200,
        height: widget.isLarge ? 200 : 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background / Thumbnail Placeholder
              if (_thumbnailUrl != null && _thumbnailUrl!.isNotEmpty)
                Image.network(
                  _thumbnailUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[800],
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.white.withValues(alpha: 0.5),
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Image load error for $_thumbnailUrl: $error');
                    return Container(
                      color: Colors.grey[800],
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 24,
                              color: Colors.red,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Text(
                                'Img Err: $error', 
                                style: TextStyle(color: Colors.red, fontSize: 8), 
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )
              else
                GestureDetector(
                  onTap: _debugError != null ? _loadThumbnail : widget.onTap,
                  child: Container(
                    color: Colors.grey[800],
                    child: Center(
                      child: _isLoadingThumbnail
                          ? CircularProgressIndicator(
                              color: Colors.white.withValues(alpha: 0.5),
                              strokeWidth: 2,
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _debugError != null ? Icons.refresh : Icons.play_circle_outline,
                                  size: widget.isLarge ? 64 : 48,
                                  color: _debugError != null ? Colors.red : Colors.white.withValues(alpha: 0.5),
                                ),
                                if (_debugError != null)
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      _debugError!,
                                      style: TextStyle(color: Colors.red, fontSize: 10),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ),
                ),
              
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16), // Increased padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Size Badge (Top Right)
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3), // More transparent
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.video.formattedFileSize,
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
                    const Spacer(),
                    
                    // Title
                    Text(
                      widget.video.title,
                      style: GoogleFonts.judson(
                        textStyle: TextStyle(
                          color: Colors.white,
                          fontSize: widget.isLarge ? 18 : 14,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Metadata Row
                    Row(
                      children: [
                        if (widget.video.description.isNotEmpty)
                          Expanded(
                            child: Text(
                              widget.video.description,
                              style: GoogleFonts.judson(
                                textStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 10,
                                ),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
