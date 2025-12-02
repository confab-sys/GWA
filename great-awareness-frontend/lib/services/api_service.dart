import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/content.dart';
import '../utils/config.dart';


class ApiService {
  late final http.Client _client;
  
  ApiService() {
    // Create a client with proper timeouts for mobile networks
    _client = http.Client();
  }

  // Get the appropriate API URL based on environment
  String getApiBaseUrl() {
    return currentEnvironment == 'production' ? apiBaseUrlProd : apiBaseUrlDev;
  }

  // Check network connectivity before making requests
  Future<bool> checkNetworkConnectivity() async {
    try {
      debugPrint('Checking network connectivity...');
      final result = await InternetAddress.lookup('gwa-enus.onrender.com');
      debugPrint('DNS lookup result: $result');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (e) {
      debugPrint('Network connectivity check failed: $e');
      return false;
    } catch (e) {
      debugPrint('Unexpected error during connectivity check: $e');
      return false;
    }
  }

  // Try alternative backend URLs if the main one fails
  Future<String> getWorkingBackendUrl() async {
    final urls = [
      apiBaseUrlProd,
      // Add IP-based fallback if configured
      if (apiBaseUrlProdIP != 'https://your-render-ip-here.onrender.com') apiBaseUrlProdIP,
    ];
    
    for (final url in urls) {
      try {
        debugPrint('Testing backend URL: $url');
        final response = await _client.get(
          Uri.parse('$url/'),
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException('URL test timeout'),
        );
        
        if (response.statusCode < 500) { // Not a server error
          debugPrint('Working backend URL found: $url');
          return url;
        }
      } catch (e) {
        debugPrint('URL $url failed: $e');
        continue;
      }
    }
    
    debugPrint('No working backend URL found, returning default');
    return apiBaseUrlProd; // Return default even if it might not work
  }

  // Test if the backend API is reachable
  Future<Map<String, dynamic>> testBackendConnection() async {
    try {
      debugPrint('Testing backend connection to: $apiBaseUrl');
      final connectivity = await checkNetworkConnectivity();
      if (!connectivity) {
        return {
          'success': false,
          'error': 'Network connectivity check failed',
          'details': 'Cannot resolve DNS for gwa-enus.onrender.com',
        };
      }

      // Try to make a simple GET request to the base URL
      final response = await _client.get(
        Uri.parse('$apiBaseUrl/'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Connection test timed out'),
      );

      debugPrint('Backend connection test successful, status: ${response.statusCode}');
      return {
        'success': true,
        'statusCode': response.statusCode,
        'message': 'Backend is reachable',
      };
    } on SocketException catch (e) {
      debugPrint('Backend connection test failed - SocketException: $e');
      return {
        'success': false,
        'error': 'Cannot connect to backend',
        'details': 'SocketException: $e',
      };
    } on TimeoutException catch (e) {
      debugPrint('Backend connection test failed - Timeout: $e');
      return {
        'success': false,
        'error': 'Connection timeout',
        'details': 'TimeoutException: $e',
      };
    } catch (e) {
      debugPrint('Backend connection test failed - Unexpected error: $e');
      return {
        'success': false,
        'error': 'Unexpected error',
        'details': 'Error: $e',
      };
    }
  }
  
  // Retry mechanism for mobile networks
  Future<T> _retryRequest<T>(Future<T> Function() request, {int maxRetries = 3}) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        return await request();
      } catch (e) {
        if (i == maxRetries - 1) {
          // Last attempt, rethrow the error
          rethrow;
        }
        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(seconds: i + 1));
        debugPrint('Request failed, retrying attempt ${i + 2}/$maxRetries');
      }
    }
    throw Exception('Max retries exceeded');
  }
  
  // Enhanced POST request with proper error handling
  Future<http.Response> _postWithRetry(String url, {Map<String, String>? headers, Object? body}) async {
    return await _retryRequest(() async {
      try {
        debugPrint('Attempting POST request to: $url');
        final uri = Uri.parse(url);
        final response = await _client.post(
          uri,
          headers: headers,
          body: body,
        ).timeout(
          const Duration(seconds: 30), // Increased timeout for mobile networks
          onTimeout: () {
            debugPrint('Request timed out after 30 seconds');
            throw TimeoutException('Request timed out after 30 seconds');
          },
        );
        debugPrint('POST request successful, status: ${response.statusCode}');
        return response;
      } on SocketException catch (e) {
        debugPrint('SocketException: $e');
        debugPrint('URL: $url');
        debugPrint('This usually means DNS resolution failed or network is unreachable');
        throw Exception('Network connection failed. Please check your internet connection. (Error: $e)');
      } on FormatException catch (e) {
        debugPrint('URL format error: $e');
        throw Exception('Invalid server URL format: $e');
      } on TimeoutException catch (e) {
        debugPrint('Request timeout: $e');
        throw Exception('Request timed out. Please check your internet connection. (Error: $e)');
      } catch (e) {
        debugPrint('Unexpected error: $e');
        throw Exception('An unexpected error occurred: $e');
      }
    });
  }

  // Enhanced GET request with proper error handling
  Future<http.Response> _getWithRetry(String url, {Map<String, String>? headers}) async {
    return await _retryRequest(() async {
      try {
        final uri = Uri.parse(url);
        final response = await _client.get(
          uri,
          headers: headers,
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException('Request timed out after 30 seconds');
          },
        );
        return response;
      } on SocketException catch (e) {
        debugPrint('Network error: $e');
        throw Exception('Network connection failed. Please check your internet connection.');
      } on FormatException catch (e) {
        debugPrint('URL format error: $e');
        throw Exception('Invalid server URL format');
      } on TimeoutException catch (e) {
        debugPrint('Request timeout: $e');
        throw Exception('Request timed out. Please check your internet connection.');
      } catch (e) {
        debugPrint('Unexpected error: $e');
        throw Exception('An unexpected error occurred: $e');
      }
    });
  }

  Future<User?> login(String email, String password) async {
    debugPrint('=== LOGIN ATTEMPT ===');
    debugPrint('Email: $email');
    debugPrint('Default API Base URL: $apiBaseUrl');
    
    // Find working backend URL
    final workingUrl = await getWorkingBackendUrl();
    debugPrint('Using working backend URL: $workingUrl');
    
    // Test backend connection first
    debugPrint('Testing backend connection before login...');
    final connectionTest = await testBackendConnection();
    debugPrint('Connection test result: $connectionTest');
    
    if (!connectionTest['success']) {
      debugPrint('Backend connection test failed, attempting login anyway...');
      // Continue with login attempt even if connection test fails
      // This allows for cases where the connection test might be blocked but login works
    }
    
    final uri = Uri.parse('$workingUrl/api/auth/login');
    debugPrint('Login URI: $uri');
    
    final res = await _postWithRetry(
      uri.toString(),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final token = data['access_token'] ?? data['token'];
      
      // Try to get user data using the token
      try {
        final userUri = Uri.parse('$workingUrl/api/auth/me');
        final userRes = await _getWithRetry(
          userUri.toString(),
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
    debugPrint('=== SIGNUP ATTEMPT ===');
    debugPrint('Email: $email');
    
    // Find working backend URL
    final workingUrl = await getWorkingBackendUrl();
    debugPrint('Using working backend URL: $workingUrl');
    
    final uri = Uri.parse('$workingUrl/api/auth/register');
    
    // Generate username from email (before @ symbol)
    String username = email.split('@')[0];
    
    // Ensure username meets minimum length requirement (at least 3 characters)
    if (username.length < 3) {
      username = username + firstName.toLowerCase() + lastName.toLowerCase();
    }
    
    // If still too short, add numbers
    if (username.length < 3) {
      username = '${username}123';
    }
    
    // Add timestamp to ensure uniqueness and avoid conflicts
    username = username + DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    
    debugPrint('Attempting signup with username: $username, email: $email');
    
    final res = await _postWithRetry(
      uri.toString(),
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