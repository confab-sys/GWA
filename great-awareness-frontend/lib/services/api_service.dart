import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/content.dart';
import '../utils/config.dart';


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
      // Backend doesn't return user data, create a basic user object
      return User(
        id: 'temp_id',
        email: email,
        token: token,
        role: 'user', // Default role, will be updated when we get user data
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
    
    print('Attempting signup with username: $username, email: $email');
    
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
    
    print('Signup response status: ${res.statusCode}');
    print('Signup response body: ${res.body}');
    
    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = json.decode(res.body);
      print('Signup successful, user data: $data');
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
    return null;
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
    
    print('createContent response status: ${res.statusCode}');
    print('createContent response body: ${res.body}');
    
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
    final res = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return Content.fromJson(data as Map<String, dynamic>);
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
}