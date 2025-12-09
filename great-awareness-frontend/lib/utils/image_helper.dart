import 'package:flutter/material.dart';

/// Helper class to handle image loading from different sources (network, asset, or fallback)
class ImageHelper {
  /// Creates an ImageProvider that can handle network URLs, asset paths, and fallbacks
  static ImageProvider getImageProvider(String? imagePath, {String? fallbackAsset}) {
    if (imagePath != null && imagePath.isNotEmpty) {
      // Check if it's a network URL
      if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
        return NetworkImage(imagePath);
      }
      // Otherwise treat as asset path
      return AssetImage(imagePath);
    }
    
    // Return fallback asset if provided, otherwise return a default placeholder
    if (fallbackAsset != null) {
      return AssetImage(fallbackAsset);
    }
    
    // Return a transparent placeholder as last resort
    return const AssetImage('assets/images/main logo man.png');
  }
  
  /// Creates a CircleAvatar with proper image handling
  static Widget buildAvatar({
    required String? imagePath,
    required String fallbackAsset,
    required double radius,
    Color? backgroundColor,
    BoxBorder? border,
  }) {
    final imageProvider = getImageProvider(imagePath, fallbackAsset: fallbackAsset);
    
    Widget avatar = CircleAvatar(
      backgroundImage: imageProvider,
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.white,
      onBackgroundImageError: (exception, stackTrace) {
        debugPrint('Error loading avatar image: $exception');
      },
    );
    
    if (border != null) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: border,
        ),
        child: avatar,
      );
    }
    
    return avatar;
  }
}