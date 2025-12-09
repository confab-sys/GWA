import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/content.dart';

class CacheService {
  static const String _postsCacheKey = 'cached_posts';
  static const String _cacheTimestampKey = 'posts_cache_timestamp';
  static const Duration _cacheValidityDuration = Duration(minutes: 15);

  static Future<void> cachePosts(List<Content> posts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final postsJson = posts.map((post) => post.toJson()).toList();
      final cacheData = jsonEncode(postsJson);
      
      await prefs.setString(_postsCacheKey, cacheData);
      await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
      
      if (kDebugMode) {
        debugPrint('Posts cached successfully. Count: ${posts.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error caching posts: $e');
      }
    }
  }

  static Future<List<Content>?> getCachedPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = prefs.getString(_postsCacheKey);
      final cacheTimestamp = prefs.getInt(_cacheTimestampKey);
      
      if (cacheData == null || cacheTimestamp == null) {
        if (kDebugMode) {
          debugPrint('No cached posts found');
        }
        return null;
      }
      
      // Check if cache is still valid
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(cacheTimestamp);
      final now = DateTime.now();
      
      if (now.difference(cacheTime) > _cacheValidityDuration) {
        if (kDebugMode) {
          debugPrint('Cache expired. Age: ${now.difference(cacheTime)}');
        }
        await clearCache(); // Clear expired cache
        return null;
      }
      
      // Parse cached data
      final List<dynamic> postsJson = jsonDecode(cacheData);
      final posts = postsJson.map((json) => Content.fromJson(json)).toList();
      
      if (kDebugMode) {
        debugPrint('Cached posts retrieved. Count: ${posts.length}');
      }
      
      return posts;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error retrieving cached posts: $e');
      }
      return null;
    }
  }

  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_postsCacheKey);
      await prefs.remove(_cacheTimestampKey);
      
      if (kDebugMode) {
        debugPrint('Posts cache cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error clearing cache: $e');
      }
    }
  }

  static Future<bool> isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheTimestamp = prefs.getInt(_cacheTimestampKey);
      
      if (cacheTimestamp == null) return false;
      
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(cacheTimestamp);
      final now = DateTime.now();
      
      return now.difference(cacheTime) <= _cacheValidityDuration;
    } catch (e) {
      return false;
    }
  }
}