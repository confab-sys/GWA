import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/content.dart';
import '../utils/config_updated.dart';


class ApiService {
  final http.Client _client = http.Client();

  Future<User?> login(String email, String password) async {
    final uri = Uri.parse('$apiBaseUrl/api/auth/login');
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final token = data['access_token'] ?? data['token'];
      
      // Try to get user data using the token
      try {
        final userUri = Uri.parse('$apiBaseUrl/api/auth/me');
        final userRes = await _client.get(
          userUri,
          headers: {'Authorization': 'Bearer $token'},
        );
        
        if (userRes.statusCode == 200) {
          final userData = json.decode(userRes.body);
          return User.fromJson(userData, token: token);
        }
      } catch (e) {
        debugPrint('Error fetching user data: $e');
      }
      
      // Fallback: create basic user object
      return User(
        id: email.hashCode.toString(),
        email: email,
        token: token,
        role: 'user',
      );
    }
    return null;
  }

  Future<User?> signup(String firstName, String lastName, String email, String phone, String county, String password) async {
    final uri = Uri.parse('$apiBaseUrl/api/auth/register');
    
    // Generate username from email (before @ symbol)
    String username = email.split('@')[0];
    
    // Ensure username meets minimum length requirement (at least 3 characters)
    if (username.length < 3) {
      username = username + firstName.toLowerCase() + lastName.toLowerCase();
    }
    
    // If still too short, add numbers
    if (username.length < 3) {
      username = username + '123';
    }
    
    // Add timestamp to ensure uniqueness and avoid conflicts
    username = username + DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    
    debugPrint('Attempting signup with username: $username, email: $email');
    
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone_number': phone,
        'county': county,
        'password': password,
      }),
    );
    
    debugPrint('Signup response status: ${res.statusCode}');
    debugPrint('Signup response body: ${res.body}');
    
    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = json.decode(res.body);
      debugPrint('Signup successful, user data: $data');
      // The backend returns user data directly, not wrapped in a 'user' key
      return User.fromJson(data is Map<String, dynamic> ? data : {}, token: null);
    } else if (res.statusCode == 400) {
      final errorData = json.decode(res.body);
      final errorMessage = errorData['detail'] ?? errorData['message'] ?? 'Bad request';
      throw Exception('Signup failed: $errorMessage');
    } else if (res.statusCode == 409) {
      throw Exception('Email or username already exists');
    } else {
      // Handle other status codes
      throw Exception('Signup failed with status ${res.statusCode}: ${res.body}');
    }
  }

  Future<List<Content>> fetchFeed(String token, {int skip = 0}) async {
    final uri = Uri.parse('$apiBaseUrl/api/content?skip=$skip');
    final res = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final list = data is List ? data : (data['items'] ?? []);
      return List<Content>.from(list.map((e) => Content.fromJson(e as Map<String, dynamic>)));
    }
    return [];
  }

  Future<Content?> createContent(String token, {
    required String title,
    required String body,
    required String topic,
    String postType = 'text',
    String? imagePath,
    bool isTextOnly = true,
    String status = 'published',
  }) async {
    final uri = Uri.parse('$apiBaseUrl/api/content');
    final res = await _client.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'title': title,
        'body': body,
        'topic': topic,
        'post_type': postType,
        'image_path': imagePath,
        'is_text_only': isTextOnly,
        'status': status,
      }),
    );
    
    debugPrint('createContent response status: ${res.statusCode}');
    debugPrint('createContent response body: ${res.body}');
    
    if (res.statusCode == 201) {
      final data = json.decode(res.body);
      return Content.fromJson(data as Map<String, dynamic>);
    } else {
      // Throw an exception with the actual error message
      final errorData = json.decode(res.body);
      throw Exception('API Error ${res.statusCode}: ${errorData['detail'] ?? 'Unknown error'}');
    }
  }

  Future<Content?> getContent(String token, int contentId) async {
    final uri = Uri.parse('$apiBaseUrl/api/content/$contentId');
    debugPrint('Fetching content $contentId from API');
    
    try {
      final res = await _client.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      
      debugPrint('Get content response status: ${res.statusCode}');
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return Content.fromJson(data as Map<String, dynamic>);
      } else {
        debugPrint('Failed to get content. Status: ${res.statusCode}, Body: ${res.body}');
      }
    } catch (e) {
      debugPrint('Exception in getContent: $e');
    }
    return null;
  }

  Future<Content?> updateContent(String token, int contentId, {
    String? title,
    String? body,
    String? topic,
    String? postType,
    String? imagePath,
    bool? isTextOnly,
    String? status,
  }) async {
    final uri = Uri.parse('$apiBaseUrl/api/content/$contentId');
    final Map<String, dynamic> updateData = {};
    
    if (title != null) updateData['title'] = title;
    if (body != null) updateData['body'] = body;
    if (topic != null) updateData['topic'] = topic;
    if (postType != null) updateData['post_type'] = postType;
    if (imagePath != null) updateData['image_path'] = imagePath;
    if (isTextOnly != null) updateData['is_text_only'] = isTextOnly;
    if (status != null) updateData['status'] = status;
    
    final res = await _client.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(updateData),
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return Content.fromJson(data as Map<String, dynamic>);
    }
    return null;
  }

  Future<bool> deleteContent(String token, int contentId) async {
    final uri = Uri.parse('$apiBaseUrl/api/content/$contentId');
    final res = await _client.delete(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    return res.statusCode == 204;
  }

  Future<Content?> likeContent(String token, int contentId) async {
    final uri = Uri.parse('$apiBaseUrl/api/content/$contentId/like');
    final res = await _client.post(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return Content.fromJson(data as Map<String, dynamic>);
    }
    return null;
  }

  Future<Content?> unlikeContent(String token, int contentId) async {
    final uri = Uri.parse('$apiBaseUrl/api/content/$contentId/unlike');
    final res = await _client.post(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return Content.fromJson(data as Map<String, dynamic>);
    }
    return null;
  }

  Future<Map<String, dynamic>?> createComment(String token, int contentId, String text) async {
    final uri = Uri.parse('$apiBaseUrl/api/content/$contentId/comments');
    debugPrint('Creating comment for content $contentId with text: $text');
    
    try {
      final res = await _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'text': text, 'content_id': contentId}),
      );
      
      debugPrint('Create comment response status: ${res.statusCode}');
      debugPrint('Create comment response body: ${res.body}');
      
      if (res.statusCode == 201) {
        final data = json.decode(res.body);
        return data as Map<String, dynamic>;
      } else {
        debugPrint('Failed to create comment. Status: ${res.statusCode}, Body: ${res.body}');
      }
    } catch (e) {
      debugPrint('Exception in createComment: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>?> getComments(String token, int contentId, {int skip = 0}) async {
    final uri = Uri.parse('$apiBaseUrl/api/content/$contentId/comments?skip=$skip');
    final res = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final items = data['items'] ?? [];
      
      // Transform the API data to match the expected format in the main feed
      return List<Map<String, dynamic>>.from(items.map((comment) => {
        'id': comment['id'],
        'text': comment['text'], // API uses 'text', app expects 'text'
        'user': comment['user'] ?? {'username': 'Anonymous'}, // API uses 'user', app expects 'user'
        'created_at': comment['created_at'] ?? 'Just now', // API uses 'created_at', app expects 'created_at'
        'is_anonymous': comment['is_anonymous'] ?? false,
      }));
    }
    return null;
  }

  // Q&A related methods
  Future<List<Map<String, dynamic>>?> getQuestions(String token, {int skip = 0, String? category}) async {
    final uri = Uri.parse('$apiBaseUrl/api/qa/questions?skip=$skip${category != null ? '&category=$category' : ''}');
    final res = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final questions = data['questions'] ?? [];
      
      // Transform the API data to match the expected format
      return List<Map<String, dynamic>>.from(questions.map((question) => {
        'id': question['id'],
        'category': question['category'],
        'title': question['title'], // Keep title for the card header
        'question': question['content'], // API uses 'content', app expects 'question' (full content)
        'author': question['author_name'], // API uses 'author_name', app expects 'author'
        'time': question['created_at'], // API uses 'created_at', app expects 'time'
        'likes': question['likes_count'] ?? 0, // API uses 'likes_count', app expects 'likes'
        'comments': question['comments_count'] ?? 0, // API uses 'comments_count', app expects 'comments'
        'isLiked': false, // Default value, could be enhanced with user-specific data
        'isSaved': false, // Default value, could be enhanced with user-specific data
        'hasImage': question['has_image'] ?? false, // API uses 'has_image', app expects 'hasImage'
      }));
    }
    return null;
  }

  Future<Map<String, dynamic>?> getQuestion(String token, int questionId) async {
    final uri = Uri.parse('$apiBaseUrl/api/qa/questions/$questionId');
    final res = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return data as Map<String, dynamic>;
    }
    return null;
  }

  Future<Map<String, dynamic>?> likeQuestion(String token, int questionId) async {
    final uri = Uri.parse('$apiBaseUrl/api/qa/questions/$questionId/like');
    final res = await _client.post(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return data as Map<String, dynamic>;
    }
    return null;
  }

  Future<Map<String, dynamic>?> createQuestionComment(String token, int questionId, String text, {bool isAnonymous = false}) async {
    final uri = Uri.parse('$apiBaseUrl/api/qa/questions/$questionId/comments');
    final res = await _client.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'text': text,
        'is_anonymous': isAnonymous,
      }),
    );
    
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return data as Map<String, dynamic>;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>?> getQuestionComments(String token, int questionId, {int page = 1, int perPage = 20}) async {
    final uri = Uri.parse('$apiBaseUrl/api/qa/questions/$questionId/comments?page=$page&per_page=$perPage');
    final res = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final comments = data['comments'] ?? [];
      
      // Transform the API data to match the expected format in the app
      return List<Map<String, dynamic>>.from(comments.map((comment) => {
        'id': comment['id'],
        'comment': comment['text'], // API uses 'text', app expects 'comment'
        'author': comment['user']?['username'] ?? (comment['is_anonymous'] ? 'Anonymous' : 'Unknown'), // Use actual user data when available
        'time': comment['created_at'] ?? 'Just now', // API uses 'created_at', app expects 'time'
        'isAnonymous': comment['is_anonymous'] ?? false,
      }));
    }
    return null;
  }

  Future<Map<String, dynamic>?> createQuestion(String token, {
    required String title,
    required String body,
    String? category,
    String? imagePath,
    bool isAnonymous = false,
  }) async {
    final uri = Uri.parse('$apiBaseUrl/api/qa/questions');
    final res = await _client.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'title': title,
        'content': body,
        'category': category,
        'image_path': imagePath,
        'is_anonymous': isAnonymous,
      }),
    );
    
    debugPrint('createQuestion response status: ${res.statusCode}');
    debugPrint('createQuestion response body: ${res.body}');
    
    if (res.statusCode == 201 || res.statusCode == 200) {
      final data = json.decode(res.body);
      return data as Map<String, dynamic>;
    } else {
      final errorData = json.decode(res.body);
      throw Exception('API Error ${res.statusCode}: ${errorData['detail'] ?? 'Unknown error'}');
    }
  }

  Future<Map<String, dynamic>?> unlikeQuestion(String token, int questionId) async {
    final uri = Uri.parse('$apiBaseUrl/api/qa/questions/$questionId/unlike');
    final res = await _client.post(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return data as Map<String, dynamic>;
    }
    return null;
  }

  Future<Map<String, dynamic>?> saveQuestion(String token, int questionId) async {
    final uri = Uri.parse('$apiBaseUrl/api/qa/questions/$questionId/save');
    final res = await _client.post(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return data as Map<String, dynamic>;
    }
    return null;
  }

  Future<Map<String, dynamic>?> unsaveQuestion(String token, int questionId) async {
    final uri = Uri.parse('$apiBaseUrl/api/qa/questions/$questionId/unsave');
    final res = await _client.post(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return data as Map<String, dynamic>;
    }
    return null;
  }

  Future<List<String>?> getQuestionCategories() async {
    final uri = Uri.parse('$apiBaseUrl/api/qa/questions/categories');
    final res = await _client.get(uri);
    
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return List<String>.from(data.map((item) => item as String));
    }
    return null;
  }
}