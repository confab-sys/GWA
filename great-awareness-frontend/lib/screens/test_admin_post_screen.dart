import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class TestAdminPostScreen extends StatefulWidget {
  const TestAdminPostScreen({super.key});

  @override
  State<TestAdminPostScreen> createState() => _TestAdminPostScreenState();
}

class _TestAdminPostScreenState extends State<TestAdminPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController(text: 'Test Post');
  final _contentController = TextEditingController(text: 'This is a test post content that is long enough to pass validation.');
  bool _isLoading = false;
  String _result = '';

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _testCreatePost() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _result = 'Form validation failed';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _result = 'Testing...';
    });

    try {
      // Get current user and token
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = authService.currentUser?.token;
      
      debugPrint('Token: $token');
      
      if (token == null) {
        setState(() {
          _result = 'No authentication token found';
        });
        return;
      }

      // Create content using API service
      final apiService = ApiService();
      debugPrint('Creating content with API...');
      
      final newContent = await apiService.createContent(
        token,
        title: _titleController.text,
        body: _contentController.text,
        topic: 'Addictions',
        postType: 'text',
        isTextOnly: true,
        status: 'published',
      );

      setState(() {
        _isLoading = false;
      });

      if (newContent != null) {
        setState(() {
          _result = '✅ SUCCESS: Post created! ID: ${newContent.id}';
        });
      } else {
        setState(() {
          _result = '❌ FAILED: API returned null';
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() {
        _isLoading = false;
        _result = '❌ ERROR: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Admin Post'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  if (value.length < 5) {
                    return 'Title must be at least 5 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter content';
                  }
                  if (value.length < 10) {
                    return 'Content must be at least 10 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _testCreatePost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Test Create Post',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _result,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}