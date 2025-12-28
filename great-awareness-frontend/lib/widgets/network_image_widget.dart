import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A robust network image widget that handles loading states, errors, and URL validation
class NetworkImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double? height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String? fallbackAsset;

  const NetworkImageWidget({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackAsset,
  });

  /// Helper function to validate and format image URL
  String? _getValidImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;
    
    // Clean up any double-encoded URLs
    String cleanPath = imagePath;
    if (cleanPath.contains('%25')) {
      // URL appears to be double-encoded, decode it once
      cleanPath = Uri.decodeComponent(cleanPath);
    }
    
    // If it's already a valid URL with protocol, return it
    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      return cleanPath;
    }
    
    // If it's a relative path or just a filename, try to construct full URL
    if (!cleanPath.startsWith('/')) {
      // It's likely just a filename, construct full URL for Cloudflare R2
      const baseImageUrl = 'https://pub-4eccd4b3666347ddb4717a96d01d99fc.r2.dev';
      return '$baseImageUrl/$cleanPath';
    }
    
    // If it starts with /, it's a relative path
    const baseUrl = 'https://gwa-enus.onrender.com';
    return '$baseUrl$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    final validUrl = _getValidImageUrl(imageUrl);
    
    if (validUrl == null) {
      return _buildPlaceholder();
    }

    // For web platform, use enhanced network image with better CORS handling
    if (kIsWeb) {
      return _buildWebImage(validUrl);
    }

    // For mobile platforms, use standard Image.network
    Widget imageWidget = Image.network(
      validUrl,
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('NetworkImageWidget: Failed to load image: $validUrl');
        debugPrint('Error: $error');
        return _buildErrorWidget(context, error);
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildLoadingWidget(loadingProgress);
      },
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildWebImage(String imageUrl) {
    // For web, try multiple approaches to handle CORS
    return FutureBuilder<bool>(
      future: _checkImageAvailability(imageUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingWidget(const ImageChunkEvent(cumulativeBytesLoaded: 0, expectedTotalBytes: null));
        }
        
        if (snapshot.hasData && snapshot.data == true) {
          // Image is accessible, use standard Image.network with headers
          Widget imageWidget = Image.network(
            imageUrl,
            height: height,
            width: width,
            fit: fit,
            headers: const {
              'Access-Control-Allow-Origin': '*',
            },
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Web Image failed, trying proxy approach: $error');
              return _buildPlaceholder(); // Fallback to placeholder for web
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildLoadingWidget(loadingProgress);
            },
          );

          if (borderRadius != null) {
            return ClipRRect(
              borderRadius: borderRadius!,
              child: imageWidget,
            );
          }
          return imageWidget;
        } else {
          // Image not accessible, use placeholder
          return _buildPlaceholder();
        }
      },
    );
  }

  Future<bool> _checkImageAvailability(String imageUrl) async {
    try {
      // For web, we can't easily check image availability due to CORS
      // So we'll just return true and let Image.network handle it
      return true;
    } catch (e) {
      return false;
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        color: Colors.grey[300],
      ),
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          size: 40,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, Object error) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        color: Colors.grey[300],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image,
              size: 40,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              'Image unavailable',
              style: GoogleFonts.judson(
                textStyle: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Error: ${error.toString().split(':').last}',
                  style: GoogleFonts.judson(
                    textStyle: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 8,
                    ),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget(ImageChunkEvent loadingProgress) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        color: Colors.grey[200],
      ),
      child: Center(
        child: CircularProgressIndicator(
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
              : null,
          strokeWidth: 2,
        ),
      ),
    );
  }
}