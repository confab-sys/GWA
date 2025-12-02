import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NetworkTestWidget extends StatefulWidget {
  const NetworkTestWidget({Key? key}) : super(key: key);

  @override
  _NetworkTestWidgetState createState() => _NetworkTestWidgetState();
}

class _NetworkTestWidgetState extends State<NetworkTestWidget> {
  final ApiService _apiService = ApiService();
  String _testResult = 'Tap button to test network connectivity';
  bool _isTesting = false;

  Future<void> _testNetwork() async {
    setState(() {
      _isTesting = true;
      _testResult = 'Testing network connectivity...';
    });

    try {
      // Test backend connection
      final result = await _apiService.testBackendConnection();
      
      setState(() {
        _isTesting = false;
        if (result['success']) {
          _testResult = '''✅ Network Test Successful!

Status: ${result['statusCode']}
Message: ${result['message']}

Your phone can reach the backend server.
Try logging in now.''';
        } else {
          _testResult = '''❌ Network Test Failed!

Error: ${result['error']}
Details: ${result['details']}

Possible solutions:
1. Switch from mobile data to WiFi
2. Try a different network
3. Check if your mobile carrier blocks the domain
4. Contact your network provider''';
        }
      });
    } catch (e) {
      setState(() {
        _isTesting = false;
        _testResult = '''❌ Unexpected Error!

Error: $e

This might be a temporary network issue.
Please try again in a few minutes.''';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Network Connectivity Test',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _testResult,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isTesting ? null : _testNetwork,
              child: Text(_isTesting ? 'Testing...' : 'Test Network Connection'),
            ),
            const SizedBox(height: 8),
            const Text(
              'This will test if your phone can reach the backend server.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}