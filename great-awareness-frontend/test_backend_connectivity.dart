import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;

// Simple script to test backend connectivity
void main() async {
  print('=== BACKEND CONNECTIVITY TEST ===');
  
  // Test different variations of the hostname
  final testUrls = [
    'https://gwa-enus.onrender.com',
    'https://great-awareness-backend.onrender.com',
  ];
  
  for (final url in testUrls) {
    print('\nTesting URL: $url');
    try {
      final response = await http.get(Uri.parse('$url/')).timeout(Duration(seconds: 10));
      print('✅ SUCCESS - Status: ${response.statusCode}');
      print('Response length: ${response.body.length}');
    } on SocketException catch (e) {
      print('❌ SOCKET ERROR - $e');
    } on TimeoutException catch (e) {
      print('❌ TIMEOUT - $e');
    } catch (e) {
      print('❌ OTHER ERROR - $e');
    }
  }
  
  // Test DNS resolution
  print('\n=== DNS RESOLUTION TEST ===');
  final testDomains = [
    'gwa-enus.onrender.com',
    'google.com',
    '8.8.8.8'
  ];
  
  for (final domain in testDomains) {
    print('\nResolving: $domain');
    try {
      final result = await InternetAddress.lookup(domain);
      print('✅ SUCCESS - Addresses: ${result.map((a) => a.address).join(', ')}');
    } catch (e) {
      print('❌ FAILED - $e');
    }
  }
  
  print('\n=== TEST COMPLETE ===');
}