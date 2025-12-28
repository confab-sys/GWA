import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const String workerUrl = 'https://gwa-main-worker.aashardcustomz.workers.dev';
  
  print('Testing Cloudflare Worker Auth Endpoints...');

  // Test Login Endpoint existence
  try {
    final loginUrl = Uri.parse('$workerUrl/api/auth/login');
    print('Probing $loginUrl ...');
    final response = await http.post(
      loginUrl,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': 'test@example.com', 'password': 'password'}),
    );
    
    print('Login Response Status: ${response.statusCode}');
    print('Login Response Body: ${response.body}');
    
    if (response.statusCode == 404) {
      print('❌ Login endpoint NOT found on Cloudflare Worker');
    } else {
      print('✅ Login endpoint FOUND (Status ${response.statusCode})');
    }
  } catch (e) {
    print('Login Probe Error: $e');
  }

  // Test Register Endpoint existence
  try {
    final registerUrl = Uri.parse('$workerUrl/api/auth/register');
    print('Probing $registerUrl ...');
    // Send invalid data to trigger validation error (400) or 404 if missing
    final response = await http.post(
      registerUrl,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({}), 
    );
    
    print('Register Response Status: ${response.statusCode}');
    print('Register Response Body: ${response.body}');
    
    if (response.statusCode == 404) {
      print('❌ Register endpoint NOT found on Cloudflare Worker');
    } else {
      print('✅ Register endpoint FOUND (Status ${response.statusCode})');
    }
  } catch (e) {
    print('Register Probe Error: $e');
  }
}
