import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MainFeedScreen extends StatefulWidget {
  const MainFeedScreen({super.key});

  @override
  State<MainFeedScreen> createState() => _MainFeedScreenState();
}

class _MainFeedScreenState extends State<MainFeedScreen> {
  final List<Map<String, dynamic>> _posts = [];
  final List<Map<String, dynamic>> _filteredPosts = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  bool _showSearch = false;

  final List<String> _psychologyTopics = [
    'Addictions',
    'Relationships', 
    'Trauma',
    'Emotional Intelligence'
  ];

  final List<String> _sampleContent = [
    'Understanding the psychology behind addiction and recovery processes.',
    'Building healthy relationships through effective communication.',
    'Healing from trauma: A journey towards mental wellness.',
    'Developing emotional intelligence for better life management.',
    'The science of addiction: How our brains respond to substances.',
    'Navigating relationship challenges with psychological insights.',
    'Trauma-informed care: Approaches to healing and growth.',
    'Emotional regulation techniques for everyday life.',
    'Breaking free from addictive patterns through mindfulness.',
    'The role of attachment in adult relationships.'
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialPosts();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && !_isLoading) {
      _loadMorePosts();
    }
  }

  void _onSearchChanged() {
    _filterPosts();
  }

  void _filterPosts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredPosts.clear();
        _filteredPosts.addAll(_posts);
      } else {
        _filteredPosts.clear();
        _filteredPosts.addAll(_posts.where((post) => 
          post['title'].toLowerCase().contains(query) ||
          post['content'].toLowerCase().contains(query) ||
          post['topic'].toLowerCase().contains(query)
        ));
      }
    });
  }

  void _loadInitialPosts() {
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(seconds: 1), () {
      final newPosts = _generatePosts(10);
      setState(() {
        _posts.addAll(newPosts);
        _filteredPosts.addAll(newPosts);
        _isLoading = false;
      });
    });
  }

  void _loadMorePosts() {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      final newPosts = _generatePosts(5);
      setState(() {
        _posts.addAll(newPosts);
        if (_searchController.text.isEmpty) {
          _filteredPosts.addAll(newPosts);
        }
        _isLoading = false;
      });
    });
  }

  List<Map<String, dynamic>> _generatePosts(int count) {
    final posts = <Map<String, dynamic>>[];
    final random = DateTime.now().millisecond;
    
    // Available psychology images for posts
    final postImages = [
      'assets/images/The power within, the secret behind emotions that you didnt know.png',
      'assets/images/Unlocking the primal brainThe hidden force shaping your thoughts and emotions.png',
      'assets/images/no more confusion, the real reason why you avent found your calling yet.png',
      null, // Some posts will be text-only
      'assets/images/main logo man.png',
      null,
    ];
    
    for (int i = 0; i < count; i++) {
      final topicIndex = (random + i) % _psychologyTopics.length;
      final contentIndex = (random + i) % _sampleContent.length;
      final hoursAgo = (random + i) % 24 + 1;
      final imageIndex = (random + i) % postImages.length;
      final isTextOnly = postImages[imageIndex] == null;
      
      posts.add({
        'id': 'post_${_posts.length + i}',
        'title': '${_psychologyTopics[topicIndex]}: ${_sampleContent[contentIndex].split(' ').take(3).join(' ')}',
        'content': _sampleContent[contentIndex],
        'topic': _psychologyTopics[topicIndex],
        'likes': (random + i) % 100 + 5,
        'comments': (random + i) % 50 + 2,
        'isLiked': false,
        'isSaved': false,
        'timestamp': DateTime.now().subtract(Duration(hours: hoursAgo)),
        'author': 'Dr. Sarah Johnson',
        'authorAvatar': 'assets/images/main logo man.png',
        'image': postImages[imageIndex],
        'isTextOnly': isTextOnly,
        'postType': isTextOnly ? 'text' : 'image'
      });
    }
    
    return posts;
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _toggleLike(int index) {
    setState(() {
      final post = _filteredPosts[index];
      post['isLiked'] = !post['isLiked'];
      post['likes'] += post['isLiked'] ? 1 : -1;
    });
  }

  void _toggleSave(int index) {
    setState(() {
      _filteredPosts[index]['isSaved'] = !_filteredPosts[index]['isSaved'];
    });
  }

  void _sharePost(int index) {
    final post = _filteredPosts[index];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sharing: ${post["title"]}')),
    );
  }

  void _showComments(int index) {
    final post = _filteredPosts[index];
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comments on ${post["title"]}',
              style: GoogleFonts.judson(
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: 3,
                itemBuilder: (context, commentIndex) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User ${commentIndex + 1}',
                          style: GoogleFonts.judson(
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'This is a great insight about ${post["topic"].toLowerCase()}. Very helpful!',
                          style: GoogleFonts.judson(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: GoogleFonts.judson(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Comment added!')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD3E4DE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: _showSearch
            ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search psychology topics...',
                  border: InputBorder.none,
                  hintStyle: GoogleFonts.judson(
                    textStyle: const TextStyle(color: Colors.grey),
                  ),
                ),
                style: GoogleFonts.judson(),
              )
            : Text(
                'Psychology Feed',
                style: GoogleFonts.judson(
                  textStyle: const TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  _filterPosts();
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Topic Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _psychologyTopics.map((topic) => 
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        topic,
                        style: GoogleFonts.judson(),
                      ),
                      selected: false,
                      onSelected: (selected) {
                        _searchController.text = topic;
                        _filterPosts();
                      },
                      backgroundColor: const Color(0xFFD3E4DE).withValues(alpha: 0.3),
                    ),
                  )
                ).toList(),
              ),
            ),
          ),
          
          // Posts List
          Expanded(
            child: _filteredPosts.isEmpty && !_isLoading
                ? Center(
                    child: Text(
                      'No posts found',
                      style: GoogleFonts.judson(
                        textStyle: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _filteredPosts.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _filteredPosts.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      
                      final post = _filteredPosts[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Post Header with modern design
                            Container(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFD3E4DE),
                                        width: 2,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      backgroundImage: AssetImage(post['authorAvatar']),
                                      radius: 22,
                                      backgroundColor: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          post['author'],
                                          style: GoogleFonts.judson(
                                            textStyle: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              _formatTimestamp(post['timestamp']),
                                              style: GoogleFonts.judson(
                                                textStyle: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFD3E4DE).withValues(alpha: 0.3),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                post['topic'],
                                                style: GoogleFonts.judson(
                                                  textStyle: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.black87,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                                    onPressed: () {
                                      // Add more options menu
                                      showModalBottomSheet(
                                        context: context,
                                        builder: (context) => Container(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ListTile(
                                                leading: const Icon(Icons.report),
                                                title: Text('Report post', style: GoogleFonts.judson()),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Post reported')),
                                                  );
                                                },
                                              ),
                                              ListTile(
                                                leading: const Icon(Icons.block),
                                                title: Text('Block author', style: GoogleFonts.judson()),
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Author blocked')),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            
                            // Post Image (if available)
                            if (!post['isTextOnly'] && post['image'] != null) ...[
                              Container(
                                height: 200,
                                width: double.infinity,
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image: AssetImage(post['image']),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            
                            // Post Content
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Post Title
                                  Text(
                                    post['title'],
                                    style: GoogleFonts.judson(
                                      textStyle: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                  
                                  if (post['content'] != null && post['content'].isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      post['content'],
                                      style: GoogleFonts.judson(
                                        textStyle: const TextStyle(
                                          fontSize: 14,
                                          height: 1.6,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      maxLines: post['isTextOnly'] ? 4 : 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Modern Action Buttons
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  // Like Button
                                  InkWell(
                                    onTap: () => _toggleLike(index),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      child: Row(
                                        children: [
                                          Icon(
                                            post['isLiked'] ? Icons.favorite : Icons.favorite_border,
                                            color: post['isLiked'] ? Colors.red : Colors.grey,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${post["likes"]}',
                                            style: GoogleFonts.judson(
                                              textStyle: TextStyle(
                                                color: post['isLiked'] ? Colors.red : Colors.grey,
                                                fontWeight: post['isLiked'] ? FontWeight.w600 : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  
                                  // Comment Button
                                  InkWell(
                                    onTap: () => _showComments(index),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.chat_bubble_outline,
                                            color: Colors.grey,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${post["comments"]}',
                                            style: GoogleFonts.judson(
                                              textStyle: const TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  
                                  // Share Button
                                  InkWell(
                                    onTap: () => _sharePost(index),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.share_outlined,
                                            color: Colors.grey,
                                            size: 20,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'Share',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  
                                  // Save Button
                                  InkWell(
                                    onTap: () => _toggleSave(index),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      child: Icon(
                                        post['isSaved'] ? Icons.bookmark : Icons.bookmark_border,
                                        color: post['isSaved'] ? const Color(0xFFD3E4DE) : Colors.grey,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}