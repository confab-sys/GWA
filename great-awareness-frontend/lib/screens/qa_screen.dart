import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class QAScreen extends StatefulWidget {
  const QAScreen({super.key});

  @override
  State<QAScreen> createState() => _QAScreenState();
}

class _QAScreenState extends State<QAScreen> {
  final List<Map<String, dynamic>> _posts = [
    {
      'id': 1,
      'category': 'Addiction',
      'question': 'How do I help a family member with alcohol addiction?',
      'author': 'Anonymous User',
      'time': '2 hours ago',
      'likes': 15,
      'comments': 8,
      'isLiked': false,
      'isSaved': false,
      'hasImage': false,
    },
    {
      'id': 2,
      'category': 'Trauma',
      'question': 'What are the best coping strategies for childhood trauma?',
      'author': 'Seeking Help',
      'time': '5 hours ago',
      'likes': 23,
      'comments': 12,
      'isLiked': true,
      'isSaved': false,
      'hasImage': true,
    },
    {
      'id': 3,
      'category': 'Relationships',
      'question': 'How to build trust after being cheated on?',
      'author': 'Heart Broken',
      'time': '1 day ago',
      'likes': 31,
      'comments': 19,
      'isLiked': false,
      'isSaved': true,
      'hasImage': false,
    },
    {
      'id': 4,
      'category': 'Addiction',
      'question': 'Is social media addiction real? I can\'t stop scrolling',
      'author': 'Worried Parent',
      'time': '2 days ago',
      'likes': 18,
      'comments': 6,
      'isLiked': false,
      'isSaved': false,
      'hasImage': false,
    },
  ];

  final List<String> _categories = ['All', 'Addiction', 'Trauma', 'Relationships', 'Anxiety', 'Depression'];
  String _selectedCategory = 'All';

  void _showNewQuestionDialog() {
    final TextEditingController questionController = TextEditingController();
    final TextEditingController categoryController = TextEditingController();
    XFile? selectedImage;

    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                          items: _categories.skip(1).map((String category) {
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
                      'Your Question',
                      style: GoogleFonts.judson(
                        textStyle: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: questionController,
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
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.judson(color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (questionController.text.trim().isNotEmpty) {
                      _addNewQuestion(
                        questionController.text.trim(),
                        categoryController.text.isEmpty ? 'General' : categoryController.text,
                        selectedImage != null,
                      );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD3E4DE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
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

  void _addNewQuestion(String question, String category, bool hasImage) {
    setState(() {
      _posts.insert(0, {
        'id': _posts.length + 1,
        'category': category,
        'question': question,
        'author': 'You',
        'time': 'Just now',
        'likes': 0,
        'comments': 0,
        'isLiked': false,
        'isSaved': false,
        'hasImage': hasImage,
      });
    });
  }

  List<Map<String, dynamic>> _getFilteredPosts() {
    if (_selectedCategory == 'All') {
      return _posts;
    }
    return _posts.where((post) => post['category'] == _selectedCategory).toList();
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
      body: Column(
        children: [
          // Category filter
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((category) {
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
                  post['question'],
                  style: GoogleFonts.judson(
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

  void _toggleLike(int postId) {
    setState(() {
      final post = _posts.firstWhere((p) => p['id'] == postId);
      post['isLiked'] = !post['isLiked'];
      post['likes'] = post['isLiked'] ? post['likes'] + 1 : post['likes'] - 1;
    });
  }

  void _toggleSave(int postId) {
    setState(() {
      final post = _posts.firstWhere((p) => p['id'] == postId);
      post['isSaved'] = !post['isSaved'];
    });
  }

  void _sharePost(Map<String, dynamic> post) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing: ${post["question"]}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showComments(Map<String, dynamic> post) {
    final TextEditingController commentController = TextEditingController();
    final List<Map<String, dynamic>> comments = [
      {
        'author': 'Dr. Sarah',
        'comment': 'This is a very common concern. I recommend seeking professional help and joining support groups.',
        'time': '1 hour ago',
      },
      {
        'author': 'Mike Johnson',
        'comment': 'I went through something similar. Feel free to DM me if you need someone to talk to.',
        'time': '3 hours ago',
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
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
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Comments list
                  Expanded(
                    child: ListView.builder(
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
                          icon: const Icon(Icons.send, color: Colors.black),
                          onPressed: () {
                            if (commentController.text.trim().isNotEmpty) {
                              setState(() {
                                comments.add({
                                  'author': 'You',
                                  'comment': commentController.text.trim(),
                                  'time': 'Just now',
                                });
                                commentController.clear();
                              });
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