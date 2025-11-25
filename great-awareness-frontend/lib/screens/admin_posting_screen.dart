import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AdminPostingScreen extends StatefulWidget {
  const AdminPostingScreen({super.key});

  @override
  State<AdminPostingScreen> createState() => _AdminPostingScreenState();
}

class _AdminPostingScreenState extends State<AdminPostingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _authorController = TextEditingController();
  String _selectedTopic = 'Addictions';
  String _selectedPostType = 'text';
  String? _selectedImagePath;
  bool _isLoading = false;

  final List<String> _psychologyTopics = [
    'Addictions',
    'Relationships', 
    'Trauma',
    'Emotional Intelligence'
  ];

  final List<Map<String, String>> _postTypes = [
    {'value': 'text', 'label': 'Text Only'},
    {'value': 'image', 'label': 'With Image'},
  ];

  final List<String> _availableImages = [
    'assets/images/The power within, the secret behind emotions that you didnt know.png',
    'assets/images/Unlocking the primal brainThe hidden force shaping your thoughts and emotions.png',
    'assets/images/no more confusion, the real reason why you avent found your calling yet.png',
    'assets/images/main logo man.png',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _submitPost() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Get current user and token
        final authService = Provider.of<AuthService>(context, listen: false);
        final token = authService.currentUser?.token;
        
        if (token == null) {
          throw Exception('No authentication token found');
        }

        // Create content using API service
        final apiService = ApiService();
        final newContent = await apiService.createContent(
          token,
          title: _titleController.text,
          body: _contentController.text,
          topic: _selectedTopic,
          postType: _selectedPostType,
          imagePath: _selectedPostType == 'image' ? _selectedImagePath : null,
          isTextOnly: _selectedPostType == 'text',
          status: 'published',
        );

        setState(() {
          _isLoading = false;
        });

        if (newContent != null) {
          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Post created successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }

          // Clear form
          _formKey.currentState!.reset();
          _titleController.clear();
          _contentController.clear();
          _authorController.clear();
          setState(() {
            _selectedImagePath = null;
            _selectedPostType = 'text';
            _selectedTopic = 'Addictions';
          });

          // Return to previous screen with the created content
          Navigator.pop(context, newContent);
        } else {
          throw Exception('Failed to create content');
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        // Show error message
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error creating post: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
      }
    }
  }

  void _selectImage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Select Image',
            style: GoogleFonts.judson(
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          content: Container(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: _availableImages.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImagePath = _availableImages[index];
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedImagePath == _availableImages[index]
                            ? Colors.blue
                            : Colors.grey,
                        width: _selectedImagePath == _availableImages[index] ? 3 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        _availableImages[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, size: 40),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD3E4DE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Create New Post',
          style: GoogleFonts.judson(
            textStyle: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Topic Selection
              Text(
                'Topic Category',
                style: GoogleFonts.judson(
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                ),
                items: _psychologyTopics.map((topic) {
                  return DropdownMenuItem(
                    value: topic,
                    child: Text(
                      topic,
                      style: GoogleFonts.judson(),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTopic = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a topic';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Post Type Selection
              Text(
                'Post Type',
                style: GoogleFonts.judson(
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                ),
                items: _postTypes.map((type) {
                  return DropdownMenuItem(
                    value: type['value'],
                    child: Text(
                      type['label']!,
                      style: GoogleFonts.judson(),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPostType = value!;
                    if (value == 'text') {
                      _selectedImagePath = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // Image Selection (only if post type is image)
              if (_selectedPostType == 'image') ...[
                Text(
                  'Select Image',
                  style: GoogleFonts.judson(
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _selectImage,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: _selectedImagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.asset(
                              _selectedImagePath!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.broken_image, size: 40),
                                );
                              },
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 40,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to select image',
                                  style: GoogleFonts.judson(
                                    textStyle: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Title Input
              Text(
                'Post Title',
                style: GoogleFonts.judson(
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Enter post title...',
                  hintStyle: GoogleFonts.judson(
                    textStyle: TextStyle(color: Colors.grey[600]),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: GoogleFonts.judson(),
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

              // Content Input
              Text(
                'Post Content',
                style: GoogleFonts.judson(
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contentController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Write your post content...',
                  hintStyle: GoogleFonts.judson(
                    textStyle: TextStyle(color: Colors.grey[600]),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: GoogleFonts.judson(),
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
              const SizedBox(height: 16),

              // Author Input (Optional)
              Text(
                'Author Name (Optional)',
                style: GoogleFonts.judson(
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _authorController,
                decoration: InputDecoration(
                  hintText: 'Enter author name (defaults to Admin)',
                  hintStyle: GoogleFonts.judson(
                    textStyle: TextStyle(color: Colors.grey[600]),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: GoogleFonts.judson(),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Create Post',
                          style: GoogleFonts.judson(
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}