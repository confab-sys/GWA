import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/content.dart';
import '../utils/config.dart';
import '../utils/device.dart';

class ApiService {
  final http.Client _client = http.Client();

  Future<User?> login(String email, String password) async {
    final uri = Uri.parse('$apiBaseUrl/auth/login');
    final deviceId = await getDeviceId();
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password, 'device_id': deviceId}),
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final token = data['access_token'] ?? data['token'];
      final userJson = data['user'] ?? {};
      return User.fromJson(userJson is Map<String, dynamic> ? userJson : {}, token: token);
    }
    return null;
  }

  Future<User?> signup(String firstName, String lastName, String email, String phone, String county, String password) async {
    final uri = Uri.parse('$apiBaseUrl/auth/register');
    final deviceId = await getDeviceId();
    
    // Generate username from email (before @ symbol)
    final username = email.split('@')[0];
    
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
        'device_id': deviceId
      }),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = json.decode(res.body);
      final token = data['access_token'] ?? data['token'];
      final userJson = data['user'] ?? {};
      return User.fromJson(userJson is Map<String, dynamic> ? userJson : {}, token: token);
    }
    return null;
  }

  Future<List<Content>> fetchFeed(String token) async {
    final uri = Uri.parse('$apiBaseUrl/content');
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
}