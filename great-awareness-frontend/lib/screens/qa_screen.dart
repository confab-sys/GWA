import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';


class QAScreen extends StatefulWidget {
  const QAScreen({super.key});

  @override
  State<QAScreen> createState() => _QAScreenState();
}

class _QAScreenState extends State<QAScreen> {
  final ApiService _apiService = ApiService();
  late List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';

  final List<String> _categoryList = ['All', 'Addiction', 'Trauma', 'Relationships', 'Anxiety', 'Depression'];

  void _showNewQuestionDialog() {
    final screenContext = context; // Capture screen context
    final TextEditingController titleController = TextEditingController();
    final TextEditingController contentController = TextEditingController();
    final TextEditingController categoryController = TextEditingController();
    XFile? selectedImage;
    bool isAnonymous = false;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Ask a Question',
                style: GoogleFonts.judson(
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category',
                      style: GoogleFonts.judson(
                        textStyle: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: categoryController.text.isEmpty ? 'Addiction' : categoryController.text,
                          isExpanded: true,
                          items: _categoryList.skip(1).map((String category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              categoryController.text = newValue!;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Question Title',
                      style: GoogleFonts.judson(
                        textStyle: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: titleController,
                      maxLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Enter a brief title...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: isAnonymous,
                          onChanged: (bool? value) {
                            setState(() {
                              isAnonymous = value ?? false;
                            });
                          },
                        ),
                        Text(
                          'Post anonymously',
                          style: GoogleFonts.judson(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your Question',
                      style: GoogleFonts.judson(
                        textStyle: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: contentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Type your question here...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Add Image (Optional)',
                      style: GoogleFonts.judson(
                        textStyle: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          setState(() {
                            selectedImage = image;
                          });
                        }
                      },
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[50],
                        ),
                        child: selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  selectedImage!.path,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.broken_image, size: 40);
                                  },
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, size: 32, color: Colors.grey[600]),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to add image',
                                    style: GoogleFonts.judson(
                                      textStyle: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600] ?? Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.judson(color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (titleController.text.trim().isNotEmpty && contentController.text.trim().isNotEmpty) {
                            // Check minimum length for title
                            if (titleController.text.trim().length < 10) {
                              ScaffoldMessenger.of(screenContext).showSnackBar(
                                const SnackBar(
                                  content: Text('Title must be at least 10 characters long'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }
                            
                            setState(() {
                              isSubmitting = true;
                            });
                            
                            try {
                              final authService = Provider.of<AuthService>(screenContext, listen: false);
                              final user = authService.currentUser;
                              final token = user?.token;
                              
                              if (token != null) {
                                final titleText = titleController.text;
                                final contentText = contentController.text;
                                final categoryText = categoryController.text;
                                
                                debugPrint('Posting question with:');
                                debugPrint('Title: ${titleText.trim()}');
                                debugPrint('Content: ${contentText.trim()}');
                                debugPrint('Category: ${categoryText.isEmpty ? 'General' : categoryText}');
                                debugPrint('Is Anonymous: $isAnonymous');
                                
                                await _apiService.createQuestion(
                                  token,
                                  title: titleText.trim(),
                                  body: contentText.trim(),
                                  category: categoryText.isEmpty ? 'General' : categoryText,
                                  isAnonymous: isAnonymous,
                                  userId: int.tryParse(user?.id ?? ''),
                                  authorName: user?.name ?? 'Anonymous',
                                );
                                
                                // Close the dialog first
                                if (dialogContext.mounted) {
                                  Navigator.of(dialogContext, rootNavigator: true).pop();
                                }
                                
                                // Then reload questions and show success message
                              await _loadQuestions();
                              
                              if (screenContext.mounted) {
                                ScaffoldMessenger.of(screenContext).showSnackBar(
                                  const SnackBar(content: Text('Question posted successfully')),
                                );
                              }
                            } else {
                              if (screenContext.mounted) {
                                ScaffoldMessenger.of(screenContext).showSnackBar(
                                  const SnackBar(content: Text('Please log in to post questions')),
                                );
                              }
                              }
                            } catch (e) {
                              debugPrint('Error posting question: $e');
                              if (screenContext.mounted) {
                                ScaffoldMessenger.of(screenContext).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to post question: $e'),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 5),
                                  ),
                                );
                              }
                            } finally {
                              if (dialogContext.mounted) {
                                setState(() {
                                  isSubmitting = false;
                                });
                              }
                            }
                          } else {
                            ScaffoldMessenger.of(screenContext).showSnackBar(
                              const SnackBar(content: Text('Please enter both title and question content')),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD3E4DE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Post Question',
                          style: GoogleFonts.judson(
                            textStyle: const TextStyle(color: Colors.black),
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      final token = user?.token;

      if (token != null) {
        final questions = await _apiService.getQuestions(token);
        if (mounted) {
          setState(() {
            _questions = questions ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading questions: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredPosts() {
    if (_selectedCategory == 'All') {
      return _questions;
    }
    return _questions.where((post) => post['category'] == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD3E4DE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Q&A Community',
          style: GoogleFonts.judson(
            textStyle: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: _showNewQuestionDialog,
            tooltip: 'Ask Question',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Category filter
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categoryList.map((category) {
                        final isSelected = category == _selectedCategory;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              category,
                              style: GoogleFonts.judson(
                                textStyle: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: Colors.black,
                            backgroundColor: Colors.grey[200],
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                // Posts list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _getFilteredPosts().length,
                    itemBuilder: (context, index) {
                      final post = _getFilteredPosts()[index];
                      return _buildQuestionCard(post);
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewQuestionDialog,
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD3E4DE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    post['category'],
                    style: GoogleFonts.judson(
                      textStyle: const TextStyle(
                        fontSize: 10,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  post['time'],
                  style: GoogleFonts.judson(
                    textStyle: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600] ?? Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post['title'],
                  style: GoogleFonts.judson(
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  post['question'],
                  style: GoogleFonts.judson(
                    textStyle: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'by ${post['author']}',
                  style: GoogleFonts.judson(
                    textStyle: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                if (post['hasImage']) ...[
                  const SizedBox(height: 12),
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(Icons.image, size: 48, color: Colors.grey),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Action buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildActionButton(
                      icon: post['isLiked'] ? Icons.favorite : Icons.favorite_border,
                      color: post['isLiked'] ? Colors.red : (Colors.grey[600] ?? Colors.grey),
                      text: '${post['likes']}',
                      onTap: () => _toggleLike(post['id']),
                    ),
                    const SizedBox(width: 16),
                    _buildActionButton(
                      icon: Icons.comment_outlined,
                      color: Colors.grey[600] ?? Colors.grey,
                      text: '${post['comments']}',
                      onTap: () => _showComments(post),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        post['isSaved'] ? Icons.bookmark : Icons.bookmark_border,
                        color: post['isSaved'] ? Colors.black : Colors.grey[600],
                      ),
                      onPressed: () => _toggleSave(post['id']),
                    ),
                    IconButton(
                      icon: Icon(Icons.share_outlined, color: Colors.grey[600]),
                      onPressed: () => _sharePost(post),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.judson(
              textStyle: TextStyle(
                fontSize: 12,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleLike(int postId) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = authService.currentUser?.token;
    
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to like questions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Find the post and current state
    final postIndex = _questions.indexWhere((p) => p['id'] == postId);
    if (postIndex == -1) return;
    
    final post = _questions[postIndex];
    final isLiked = post['isLiked'] == true;

    // Optimistic update
    setState(() {
      post['isLiked'] = !isLiked;
      post['likes'] = isLiked ? (post['likes'] - 1) : (post['likes'] + 1);
    });

    try {
      Map<String, dynamic>? result;
      if (isLiked) {
        result = await _apiService.unlikeQuestion(token, postId);
      } else {
        result = await _apiService.likeQuestion(token, postId);
      }
      
      if (result != null && mounted) {
        setState(() {
          // Update with server values to ensure sync
          post['isLiked'] = result?['is_liked'] ?? !isLiked;
          post['likes'] = result?['likes_count'] ?? post['likes'];
        });
      } else {
        // Revert optimistic update on failure (null result)
        _revertLikeUpdate(post, isLiked);
      }
    } catch (e) {
      // Revert optimistic update on error
      _revertLikeUpdate(post, isLiked);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error liking question: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _revertLikeUpdate(Map<String, dynamic> post, bool originalLikeState) {
    if (mounted) {
      setState(() {
        post['isLiked'] = originalLikeState;
        post['likes'] = originalLikeState ? (post['likes'] + 1) : (post['likes'] - 1);
      });
    }
  }

  void _toggleSave(int postId) {
    setState(() {
      final post = _questions.firstWhere((p) => p['id'] == postId);
      post['isSaved'] = !post['isSaved'];
    });
  }

  void _sharePost(Map<String, dynamic> post) {
    final shareLink = 'https://greatawareness.app/question/${post["id"]}';
    final shareText = '${post["title"]}\n\n${post["question"]}\n\nRead more: $shareLink\n\nShared from Great Awareness - Psychology Community';
    Share.share(shareText, subject: post["title"]);
  }

  void _showComments(Map<String, dynamic> post) async {
    final screenContext = context; // Capture screen context
    final TextEditingController commentController = TextEditingController();
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = authService.currentUser?.token;
    List<Map<String, dynamic>> comments = [];
    bool isLoading = true;
    bool isSubmitting = false;

    // Load comments from API
    if (token != null) {
      try {
        final loadedComments = await _apiService.getQuestionComments(token, post['id']);
        if (loadedComments != null) {
          comments = loadedComments;
        }
      } catch (e) {
        debugPrint('Error loading comments: $e');
      }
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (sheetContext, setState) {
            return Container(
              height: MediaQuery.of(modalContext).size.height * 0.8,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header
                  Row(
                    children: [
                      Text(
                        'Comments (${comments.length})',
                        style: GoogleFonts.judson(
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(modalContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Comments list
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : comments.isEmpty
                            ? Center(
                                child: Text(
                                  'No comments yet. Be the first to comment!',
                                  style: GoogleFonts.judson(
                                    textStyle: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: comments.length,
                                itemBuilder: (context, index) {
                                  final comment = comments[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              comment['author'],
                                              style: GoogleFonts.judson(
                                                textStyle: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              comment['time'],
                                              style: GoogleFonts.judson(
                                                textStyle: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          comment['comment'],
                                          style: GoogleFonts.judson(
                                            textStyle: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                  ),
                  // Comment input
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            decoration: InputDecoration(
                              hintText: 'Add a comment...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: isSubmitting 
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send, color: Colors.black),
                          onPressed: isSubmitting ? null : () async {
                            final commentText = commentController.text.trim();
                            if (commentText.isNotEmpty && token != null) {
                              setState(() {
                                isSubmitting = true;
                              });
                              
                              try {
                                final result = await _apiService.createQuestionComment(
                                  token, 
                                  post['id'], 
                                  commentText,
                                );
                                
                                if (result != null) {
                                  // Reload comments from API to get the newly created comment
                                  final updatedComments = await _apiService.getQuestionComments(token, post['id']);
                                  if (updatedComments != null) {
                                    setState(() {
                                      comments = updatedComments;
                                      commentController.clear();
                                    });
                                  }
                                }
                              } catch (e) {
                                if (screenContext.mounted) {
                                  ScaffoldMessenger.of(screenContext).showSnackBar(
                                    SnackBar(
                                      content: Text('Error posting comment: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } finally {
                                if (sheetContext.mounted) {
                                  setState(() {
                                    isSubmitting = false;
                                  });
                                }
                              }
                            } else if (token == null) {
                              if (mounted) {
                                ScaffoldMessenger.of(screenContext).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please login to comment'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}