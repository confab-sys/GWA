import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/video.dart';

class PremiumVideoCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isLarge ? 280 : 200,
        height: isLarge ? 200 : 160,
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
              Container(
                color: Colors.grey[800],
                child: Center(
                  child: Icon(
                    Icons.play_circle_outline,
                    size: isLarge ? 64 : 48,
                    color: Colors.white.withValues(alpha: 0.5),
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
                          video.formattedFileSize,
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
                      video.title,
                      style: GoogleFonts.judson(
                        textStyle: TextStyle(
                          color: Colors.white,
                          fontSize: isLarge ? 18 : 14,
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
                        if (video.description.isNotEmpty)
                          Expanded(
                            child: Text(
                              video.description,
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
