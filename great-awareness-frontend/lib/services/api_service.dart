import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../models/user.dart';
import '../models/content.dart';
import '../utils/config.dart';
import '../utils/device.dart';


class ApiService {
  late final http.Client _client;
  
  ApiService() {
    // Create a client with enhanced SSL/TLS support for mobile networks
    if (!kIsWeb) {
      // For mobile platforms, create a custom HTTP client with SSL/TLS configuration
      try {
        final ioClient = HttpClient()
          ..badCertificateCallback = (X509Certificate cert, String host, int port) {
            // Allow certificates from our known backend domains
            if (host.endsWith('.onrender.com') || host == 'gwa-enus.onrender.com') {
              debugPrint('Allowing certificate for known backend: $host');
              return true;
            }
            // For development, you might want to be more permissive
            debugPrint('Certificate validation for $host: ${cert.subject}:${cert.issuer}');
            return false;
          }
          ..connectionTimeout = const Duration(seconds: 30)
          ..idleTimeout = const Duration(seconds: 30);
        
        _client = IOClient(ioClient);
        debugPrint('Created SSL-aware HTTP client for mobile');
      } catch (e) {
        debugPrint('Failed to create SSL-aware client, falling back to default: $e');
        _client = http.Client();
      }
    } else {
      // For web, use standard client
      _client = http.Client();
      debugPrint('Using standard HTTP client for web');
    }
  }

  // Enhanced connectivity check specifically for mobile networks
  Future<Map<String, dynamic>> checkMobileConnectivity() async {
    try {
      debugPrint('=== MOBILE CONNECTIVITY CHECK ===');
      
      // Step 1: Check if we can resolve any common domains
      final testDomains = [
        'google.com',
        'cloudflare.com', 
        '8.8.8.8',
        'gwa-enus.onrender.com'
      ];
      
      Map<String, bool> dnsResults = {};
      for (final domain in testDomains) {
        try {
          final result = await InternetAddress.lookup(domain).timeout(const Duration(seconds: 3));
          dnsResults[domain] = result.isNotEmpty;
          debugPrint('DNS check for $domain: ${result.isNotEmpty ? "SUCCESS" : "FAILED"}');
        } catch (e) {
          dnsResults[domain] = false;
          debugPrint('DNS check for $domain: FAILED - $e');
        }
      }
      
      // Step 2: Check if basic internet is working
      final hasBasicInternet = dnsResults['google.com'] == true || dnsResults['cloudflare.com'] == true;
      
      // Step 3: Check our specific backend
      final backendReachable = dnsResults['gwa-enus.onrender.com'] == true;
      
      return {
        'success': hasBasicInternet,
        'backend_reachable': backendReachable,
        'dns_results': dnsResults,
        'recommendations': _getConnectivityRecommendations(hasBasicInternet, backendReachable),
      };
      
    } catch (e) {
      debugPrint('Mobile connectivity check failed: $e');
      return {
        'success': false,
        'error': 'Connectivity check failed: $e',
        'recommendations': ['Restart the app', 'Check internet connection', 'Contact support'],
      };
    }
  }
  
  // Get recommendations based on connectivity issues
  List<String> _getConnectivityRecommendations(bool hasInternet, bool backendReachable) {
    final recommendations = <String>[];
    
    if (!hasInternet) {
      recommendations.add('Check your internet connection');
      recommendations.add('Try switching between WiFi and mobile data');
      recommendations.add('Restart your device');
    } else if (!backendReachable) {
      recommendations.add('Backend server may be temporarily unavailable');
      recommendations.add('Try again in a few minutes');
      recommendations.add('Contact support if the issue persists');
    } else {
      recommendations.add('Connection appears to be working');
      recommendations.add('If login still fails, check your credentials');
    }
    
    return recommendations;
  }

  // Get the appropriate API URL based on environment
  String getApiBaseUrl() {
    return currentEnvironment == 'production' ? apiBaseUrlProd : apiBaseUrlDev;
  }
  
  // Get CORS-safe URL for web requests
  String getCorsSafeUrl(String originalUrl) {
    if (kIsWeb) {
      // For web development, we can use a CORS proxy or modify the URL
      // Option 1: Use a CORS proxy (for development only)
      // Note: These proxies may have rate limits or require activation
      
      // For now, return the original URL and let the browser handle it
      // The backend should be configured to allow CORS from your origin
      debugPrint('Using original URL for web request: $originalUrl');
      debugPrint('Note: If you encounter CORS issues, the backend needs to be configured');
      debugPrint('to allow requests from http://localhost:8081');
      
      return originalUrl;
    }
    return originalUrl;
  }

  // Check network connectivity before making requests
  Future<bool> checkNetworkConnectivity() async {
    try {
      debugPrint('Checking network connectivity...');
      debugPrint('Current API base URL: $apiBaseUrl');
      
      // For web and local development, skip DNS checks
      if (kIsWeb || apiBaseUrl.contains('localhost') || apiBaseUrl.contains('127.0.0.1')) {
        debugPrint('Web platform or local development detected, skipping DNS checks');
        return true;
      }
      
      // Try multiple DNS resolution methods for better mobile compatibility
      try {
        // Method 1: Direct lookup
        final result = await InternetAddress.lookup('gwa-enus.onrender.com');
        debugPrint('DNS lookup result: $result');
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          return true;
        }
      } catch (e) {
        debugPrint('Direct DNS lookup failed: $e');
      }
      
      // Method 2: Try alternative hostname (in case of typo)
      try {
        final altResult = await InternetAddress.lookup('gwa.enus.onrender.com');
        debugPrint('Alternative DNS lookup result: $altResult');
        if (altResult.isNotEmpty && altResult[0].rawAddress.isNotEmpty) {
          return true;
        }
      } catch (e) {
        debugPrint('Alternative DNS lookup failed: $e');
      }
      
      // Method 3: Try Google DNS as fallback
      try {
        final googleResult = await InternetAddress.lookup('8.8.8.8');
        debugPrint('Google DNS reachable: $googleResult');
        if (googleResult.isNotEmpty) {
          // If Google DNS is reachable, network is working but our hostname might be wrong
          return true;
        }
      } catch (e) {
        debugPrint('Google DNS check failed: $e');
      }
      
      return false;
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
      apiBaseUrl, // Use the current environment URL first
      apiBaseUrlProd, // Fallback to production
      apiBaseUrlDev, // Fallback to development
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
    return apiBaseUrl; // Return the current environment URL as default
  }

  // Test if the backend API is reachable
  Future<Map<String, dynamic>> testBackendConnection() async {
    try {
      debugPrint('Testing backend connection to: $apiBaseUrl');
      
      // For local development and web, skip extensive connectivity checks
      if (kIsWeb || apiBaseUrl.contains('localhost') || apiBaseUrl.contains('127.0.0.1')) {
        debugPrint('Web platform or local development detected, using simple connectivity test');
        try {
          final response = await _client.get(
            Uri.parse('$apiBaseUrl/'),
          ).timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw TimeoutException('Connection test timed out'),
          );
          
          if (response.statusCode < 500) {
            return {
              'success': true,
              'statusCode': response.statusCode,
              'message': 'Local backend is reachable',
            };
          }
        } catch (e) {
          debugPrint('Local backend test failed: $e');
          return {
            'success': false,
            'error': 'Local backend connection failed',
            'details': 'Could not connect to local server at $apiBaseUrl. Make sure your local backend is running.',
            'suggestions': [
              'Check if your local backend server is running on port 8000',
              'Try restarting your local backend server',
              'Verify the backend URL configuration'
            ]
          };
        }
      }
      
      final connectivity = await checkNetworkConnectivity();
      if (!connectivity) {
        return {
          'success': false,
          'error': 'Network connectivity check failed',
          'details': 'Cannot resolve DNS for gwa-enus.onrender.com. This may be due to:\n1. No internet connection\n2. DNS resolution issues on mobile networks\n3. Hostname configuration problem\n\nPlease check your internet connection and try again.',
          'suggestions': [
            'Check if your device has internet access',
            'Try switching between WiFi and mobile data',
            'Restart the app',
            'Contact support if the issue persists'
          ]
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
        
        // Add proper headers for CORS compatibility
        final modifiedHeaders = headers ?? {};
        if (kIsWeb) {
          // Add origin header for web requests to help with CORS
          modifiedHeaders['Origin'] = 'http://localhost:8081';
          modifiedHeaders['Referer'] = 'http://localhost:8081/';
        }
        
        final response = await _client.post(
          uri,
          headers: modifiedHeaders,
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
    debugPrint('=== LOGIN ATTEMPT (Cloudflare) ===');
    debugPrint('Email: $email');
    debugPrint('Cloudflare Worker URL: $cloudflareWorkerUrl');
    
    // Skip mobile connectivity check for web production and local development
    if (kIsWeb || apiBaseUrl.contains('localhost') || apiBaseUrl.contains('127.0.0.1')) {
      debugPrint('Web platform or local development detected, skipping mobile connectivity check');
    } else {
      // Enhanced mobile connectivity check (only for mobile production)
      debugPrint('Running mobile connectivity check...');
      final mobileConnectivity = await checkMobileConnectivity();
      debugPrint('Mobile connectivity result: $mobileConnectivity');
      
      if (!mobileConnectivity['success']) {
        debugPrint('Mobile connectivity check failed');
        final recommendations = mobileConnectivity['recommendations'] as List<String>? ?? [];
        final errorMessage = mobileConnectivity['error'] ?? 'Network connectivity failed';
        throw Exception('Network Error: $errorMessage\n\nSuggestions:\n${recommendations.map((r) => '• $r').join('\n')}');
      }
    }
    
    // Use Cloudflare Worker directly for authentication
    final uri = Uri.parse('$cloudflareWorkerUrl/api/auth/login');
    debugPrint('Login URI: $uri');
    
    try {
      final res = await _postWithRetry(
        uri.toString(),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );
      
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final token = data['token'] ?? data['access_token']; // Cloudflare uses 'token'
        final userData = data['user'];
        
        debugPrint('Login successful. User data: $userData');
        
        if (userData != null) {
          // Construct User object directly from login response
          return User.fromJson(userData as Map<String, dynamic>, token: token);
        }
        
        // Fallback if user data is missing in response (should not happen with current worker code)
        return User(
          id: email.hashCode.toString(),
          email: email,
          token: token,
          role: 'user',
        );
      } else {
        debugPrint('Login failed with status: ${res.statusCode}');
        debugPrint('Response body: ${res.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Login request failed: $e');
      
      // Enhanced error message for mobile users
      if (e is TypeError) {
        debugPrint('LOGIN TYPE ERROR: $e');
        throw Exception('Data error during login: $e. Please contact support.');
      } else if (e.toString().contains('SocketException')) {
        throw Exception('Network connection failed. Please check your internet connection and try again.\n\nIf the problem persists:\n• Try switching between WiFi and mobile data\n• Restart the app\n• Contact support');
      } else if (e.toString().contains('TimeoutException')) {
        throw Exception('Connection timeout. The server is taking too long to respond.\n\nPlease try again in a few moments.');
      } else {
        throw Exception('Login failed: ${e.toString()}');
      }
    }
  }

  Future<void> forgotPassword(String email) async {
    debugPrint('=== FORGOT PASSWORD ATTEMPT ===');
    debugPrint('Email: $email');
    
    // Find working backend URL
    final workingUrl = await getWorkingBackendUrl();
    
    final uri = Uri.parse('$workingUrl/api/auth/forgot-password');
    
    try {
      final res = await _postWithRetry(
        uri.toString(),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );
      
      if (res.statusCode == 200) {
        return;
      } else {
        if (res.statusCode == 404) {
           debugPrint('Forgot password endpoint not found, assuming success for demo');
           return;
        }
        final errorData = json.decode(res.body);
        throw Exception(errorData['detail'] ?? 'Failed to send reset link');
      }
    } catch (e) {
       rethrow;
    }
  }

  Future<User?> signup(String firstName, String lastName, String email, String phone, String county, String password) async {
    debugPrint('=== SIGNUP ATTEMPT (DEBUG MODE v2) ===');
    debugPrint('Email: $email');
    
    try {
      // 1. Prepare data
      debugPrint('Step 1: Preparing data...');
      String username = email.split('@')[0];
      if (username.length < 3) {
        username = username + firstName.toLowerCase() + lastName.toLowerCase();
      }
      if (username.length < 3) {
        username = '${username}123';
      }
      username = username + DateTime.now().millisecondsSinceEpoch.toString().substring(8);
      
      String deviceIdHash = 'unknown';
      try {
        deviceIdHash = (await getDeviceId()).toString();
      } catch (e) {
        debugPrint('Error getting device ID: $e');
      }
      debugPrint('Device ID hash: $deviceIdHash');
      
      final signupBody = {
        'username': username,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone_number': phone,
        'county': county,
        'password': password,
        'device_id_hash': deviceIdHash,
      };
      
      debugPrint('Signup Body Keys: ${signupBody.keys.toList()}');
      signupBody.forEach((key, value) {
        debugPrint('Field $key: "$value" (Type: ${value.runtimeType})');
        if (value is! String) {
           debugPrint('WARNING: Field $key is not a String! It is ${value.runtimeType}');
        }
      });
      
      // 2. Signup on Render (Primary)
      debugPrint('Step 2: Getting backend URL...');
      final baseUrl = await getWorkingBackendUrl();
      // NOTE: Backend endpoint is /register, not /signup
      final renderUri = Uri.parse('$baseUrl/api/auth/register');
      debugPrint('Primary Signup URI (Render): $renderUri');
      
      debugPrint('Step 3: Sending POST request...');
      final res = await _postWithRetry(
        renderUri.toString(),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(signupBody),
      );
      
      debugPrint('Render Signup response status: ${res.statusCode}');
      // Print response body for debugging
      debugPrint('Render Signup response body: ${res.body.length > 2000 ? res.body.substring(0, 2000) + '...' : res.body}');
      
      if (res.statusCode == 200 || res.statusCode == 201) {
        debugPrint('Signup successful on Render');
        
        // 3. Sync to Cloudflare (Critical for Login)
        debugPrint('Step 4: Syncing to Cloudflare...');
        await _syncToCloudflare(signupBody);
        debugPrint('Cloudflare sync process completed');
        
        // 4. Auto-login (using Cloudflare)
        debugPrint('Step 5: Auto-login (Cloudflare)...');
        try {
          final user = await login(email, password);
          debugPrint('Auto-login result: ${user != null ? "Success" : "Failed (null)"}');
          return user;
        } catch (e) {
          debugPrint('Auto-login failed with error: $e');
          // If login fails but signup succeeded, return basic user manually to allow progression
          // This avoids the user being stuck on signup screen when account IS created
          return User(
            id: email.hashCode.toString(),
            email: email,
            token: null, // User will need to login again or token is missing
            role: 'user',
            firstName: firstName,
            lastName: lastName,
          );
        }
      } else if (res.statusCode == 400 || res.statusCode == 409) {
        final errorData = json.decode(res.body);
        final errorMessage = errorData['detail'] ?? errorData['message'] ?? errorData['error'] ?? 'Request failed';
        throw Exception(errorMessage);
      } else {
        throw Exception('Signup failed with status ${res.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('CRITICAL SIGNUP ERROR: $e');
      debugPrint('Stack trace: $stackTrace');
      if (e is TypeError) {
         debugPrint('TYPE ERROR DETAILS: $e');
         debugPrint('This often happens when a JSON field has an unexpected type (e.g. double instead of int).');
      }
      rethrow;
    }
  }

  Future<void> _syncToCloudflare(Map<String, dynamic> body) async {
    debugPrint('=== SYNCING TO CLOUDFLARE ===');
    try {
      final cloudflareUri = Uri.parse('$cloudflareWorkerUrl/api/auth/signup');
      debugPrint('Cloudflare Sync URI: $cloudflareUri');
      
      // Use configured client instead of raw http to benefit from SSL config
      var res = await _client.post(
        cloudflareUri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(const Duration(seconds: 15));
      
      debugPrint('Cloudflare Sync status: ${res.statusCode}');
      debugPrint('Cloudflare Sync body: ${res.body}');

      // Self-healing: If 500 (Internal Server Error), it might be due to missing 'users' table
      if (res.statusCode == 500) {
        debugPrint('Cloudflare sync failed with 500. Attempting to initialize Users table...');
        try {
          final initUri = Uri.parse('$cloudflareWorkerUrl/api/db/init-users');
          final initRes = await _client.post(
            initUri,
            headers: {'Content-Type': 'application/json'},
          ).timeout(const Duration(seconds: 10));
          
          debugPrint('Init table response: ${initRes.statusCode} - ${initRes.body}');
          
          if (initRes.statusCode == 200) {
             debugPrint('Table initialized. Retrying sync...');
             res = await _client.post(
              cloudflareUri,
              headers: {'Content-Type': 'application/json'},
              body: json.encode(body),
            ).timeout(const Duration(seconds: 15));
            debugPrint('Retry Cloudflare Sync status: ${res.statusCode}');
            debugPrint('Retry Cloudflare Sync body: ${res.body}');
          }
        } catch (e) {
          debugPrint('Failed to auto-initialize table: $e');
        }
      }
      
      if (res.statusCode >= 400) {
        debugPrint('Cloudflare Sync error body: ${res.body}');
      }
    } catch (e) {
      debugPrint('Error syncing to Cloudflare: $e');
    }
  }

  Future<List<Content>> fetchFeed(String token, {int skip = 0}) async {
    debugPrint('=== FETCHING FEED (Cloudflare) ===');
    // Switch to Cloudflare Worker for content
    // final workingUrl = await getWorkingBackendUrl();
    // final uri = Uri.parse('$workingUrl/api/content?skip=$skip');
    final uri = Uri.parse('$cloudflareWorkerUrl/api/contents?skip=$skip');
    
    try {
      final res = await _getWithRetry(
        uri.toString(),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      debugPrint('fetchFeed response status: ${res.statusCode}');
      
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final list = data is List ? data : (data['items'] ?? []);
        final contentList = List<Content>.from(list.map((e) => Content.fromJson(e as Map<String, dynamic>)));
        debugPrint('Feed fetched successfully! Found ${contentList.length} items');
        return contentList;
      } else {
        debugPrint('Feed fetch failed with status ${res.statusCode}');
        debugPrint('Error response: ${res.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Exception in fetchFeed: $e');
      return [];
    }
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
    debugPrint('=== CREATING CONTENT (Cloudflare) ===');
    debugPrint('Title: $title');
    debugPrint('Topic: $topic');
    debugPrint('Post Type: $postType');
    debugPrint('Is Text Only: $isTextOnly');
    
    // Use Cloudflare Worker URL directly
    final uri = Uri.parse('$cloudflareWorkerUrl/api/contents');
    debugPrint('Content creation URI: $uri');
    
    try {
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
      
      if (res.statusCode == 201 || res.statusCode == 200) {
        final data = json.decode(res.body);
        debugPrint('Content created successfully!');
        return Content.fromJson(data as Map<String, dynamic>);
      } else {
        // Throw an exception with the actual error message
        final errorData = json.decode(res.body);
        debugPrint('Content creation failed with status ${res.statusCode}');
        debugPrint('Error details: ${errorData['detail'] ?? errorData['error'] ?? 'Unknown error'}');
        throw Exception('API Error ${res.statusCode}: ${errorData['detail'] ?? errorData['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      debugPrint('Exception in createContent: $e');
      rethrow;
    }
  }

  Future<Content?> getContent(String token, int contentId, {int? userId}) async {
    // Switch to Cloudflare Worker
    // final uri = Uri.parse('$apiBaseUrl/api/content/$contentId');
    String url = '$cloudflareWorkerUrl/api/contents/$contentId';
    if (userId != null) {
      url += '?user_id=$userId';
    }
    final uri = Uri.parse(url);
    debugPrint('Fetching content $contentId from Cloudflare API');
    
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
    debugPrint('=== DELETING CONTENT ===');
    debugPrint('Content ID: $contentId');
    
    // Find working backend URL first
    final workingUrl = await getWorkingBackendUrl();
    debugPrint('Using working backend URL: $workingUrl');
    
    final uri = Uri.parse('$workingUrl/api/content/$contentId');
    debugPrint('Delete content URI: $uri');
    
    try {
      final res = await _retryRequest<http.Response>(
        () async {
          return await _client.delete(
            uri,
            headers: {'Authorization': 'Bearer $token'},
          ).timeout(const Duration(seconds: 30));
        },
      );
      
      debugPrint('deleteContent response status: ${res.statusCode}');
      
      if (res.statusCode == 204) {
        debugPrint('Content deleted successfully!');
        return true;
      } else {
        debugPrint('Delete content failed with status ${res.statusCode}');
        debugPrint('Error response: ${res.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Exception in deleteContent: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> likeContent(String token, int contentId, int userId) async {
    debugPrint('=== LIKING CONTENT (TOGGLE) ===');
    debugPrint('Content ID: $contentId, User ID: $userId');
    
    final uri = Uri.parse('$cloudflareWorkerUrl/api/contents/$contentId/like');
    
    try {
      final res = await _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'user_id': userId}),
      );
      
      debugPrint('likeContent response status: ${res.statusCode}');
      
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return data as Map<String, dynamic>;
      } else {
        debugPrint('Like content failed. Status: ${res.statusCode}, Body: ${res.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Exception in likeContent: $e');
      return null;
    }
  }

  // Deprecated: Use likeContent for toggle
  Future<Content?> unlikeContent(String token, int contentId) async {
    return null; 
  }

  Future<Map<String, dynamic>?> createComment(String token, int contentId, int userId, String text) async {
    final uri = Uri.parse('$cloudflareWorkerUrl/api/contents/$contentId/comments');
    debugPrint('Creating comment for content $contentId');
    
    try {
      final res = await _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'text': text, 'user_id': userId}),
      );
      
      debugPrint('Create comment response status: ${res.statusCode}');
      
      if (res.statusCode == 200) {
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
    // Switch to Cloudflare Worker
    // final uri = Uri.parse('$apiBaseUrl/api/content/$contentId/comments?skip=$skip');
    final uri = Uri.parse('$cloudflareWorkerUrl/api/contents/$contentId/comments?skip=$skip');
    
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
        'isLiked': question['is_liked'] ?? false, // Map is_liked from API
        'isSaved': question['is_saved'] ?? false, // Map is_saved from API
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

  // Admin endpoints
  Future<List<dynamic>?> getAllUsers(String token) async {
    try {
      debugPrint('=== getAllUsers called ===');
      debugPrint('API Base URL: $apiBaseUrl');
      debugPrint('Token: ${token.substring(0, 20)}...');
      
      final uri = Uri.parse('$apiBaseUrl/api/admin/users');
      debugPrint('Request URI: $uri');
      
      final res = await _getWithRetry(
        uri.toString(),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      debugPrint('Response status: ${res.statusCode}');
      debugPrint('Response body: ${res.body}');
      
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        debugPrint('Successfully fetched ${(data as List).length} users');
        return data;
      } else if (res.statusCode == 403) {
        debugPrint('Admin access denied');
        throw Exception('Admin access required');
      } else {
        debugPrint('Unexpected status code: ${res.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching all users: $e');
      return null;
    }
  }

  Future<List<dynamic>?> getTopQuestions(String token, {int limit = 5}) async {
    try {
      debugPrint('=== getTopQuestions called ===');
      debugPrint('API Base URL: $apiBaseUrl');
      debugPrint('Token: ${token.substring(0, 20)}...');
      
      final uri = Uri.parse('$apiBaseUrl/api/admin/questions/top?limit=$limit');
      debugPrint('Request URI: $uri');
      
      final res = await _getWithRetry(
        uri.toString(),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      debugPrint('Response status: ${res.statusCode}');
      debugPrint('Response body: ${res.body}');
      
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        debugPrint('Successfully fetched ${(data as List).length} top questions');
        return data;
      } else if (res.statusCode == 403) {
        debugPrint('Admin access denied');
        throw Exception('Admin access required');
      } else {
        debugPrint('Unexpected status code: ${res.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching top questions: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getAdminAnalytics(String token) async {
    try {
      final uri = Uri.parse('$apiBaseUrl/api/admin/analytics');
      final res = await _getWithRetry(
        uri.toString(),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return data as Map<String, dynamic>;
      } else if (res.statusCode == 403) {
        debugPrint('Admin access denied');
        throw Exception('Admin access required');
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching admin analytics: $e');
      return null;
    }
  }
}