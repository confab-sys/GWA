import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'post_detail_screen.dart';
import 'admin_posting_screen.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/content.dart';

class MainFeedScreen extends StatefulWidget {
  const MainFeedScreen({super.key});

  @override
  State<MainFeedScreen> createState() => _MainFeedScreenState();
}

class _MainFeedScreenState extends State<MainFeedScreen> {
  final List<Content> _posts = [];
  final List<Content> _filteredPosts = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  bool _showSearch = false;
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  final List<String> _psychologyTopics = [
    'Addictions',
    'Relationships', 
    'Trauma',
    'Emotional Intelligence'
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialPosts();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    
    // Mock admin login for testing - remove this in production
    _authService.mockAdminLogin();
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
          post.title.toLowerCase().contains(query) ||
          post.body.toLowerCase().contains(query) ||
          post.topic.toLowerCase().contains(query)
        ));
      }
    });
  }

  Future<void> _loadInitialPosts() async {
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

      // Fetch posts from backend
      final posts = await _apiService.fetchFeed(token);
      
      setState(() {
        _posts.clear();
        _filteredPosts.clear();
        _posts.addAll(posts);
        _filteredPosts.addAll(posts);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading posts: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      // Don't fallback to mock data - just show error
      print('Failed to load posts: $e');
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = authService.currentUser?.token;
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Fetch more posts from backend with pagination
      final morePosts = await _apiService.fetchFeed(token, skip: _posts.length);
      
      setState(() {
        _posts.addAll(morePosts);
        if (_searchController.text.isEmpty) {
          _filteredPosts.addAll(morePosts);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Failed to load more posts: $e');
    }
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
      // For now, just update the local state
      // In a real implementation, you would call an API to update the like status
      // final post = _filteredPosts[index]; // Commented out for now
      // This would need to be implemented with proper like tracking
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Like functionality will be implemented soon!')),
        );
      }
    });
  }

  void _toggleSave(int index) {
    setState(() {
      // For now, just show a snackbar
      // In a real implementation, you would call an API to save/unsave the post
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Save functionality will be implemented soon!')),
        );
      }
    });
  }

  void _sharePost(int index) {
    final post = _filteredPosts[index];
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sharing: ${post.title}')),
      );
    }
  }

  void _navigateToAdminPosting() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminPostingScreen(),
      ),
    );
    
    // If a new post was created, add it to the feed
    if (result != null && result is Content) {
      setState(() {
        _posts.insert(0, result);
        _filterPosts();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('New post created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
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
              'Comments on ${post.title}',
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
                itemCount: post.commentsCount,
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
                          'This is a great insight about ${post.topic.toLowerCase()}. Very helpful!',
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

  void _openPostDetail(Content post, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(
          post: post,
          postIndex: index,
          onLikeToggle: _toggleLike,
          onSaveToggle: _toggleSave,
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
          // Admin posting button (visible only to admins)
          if (_authService.isAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.black),
              onPressed: () => _navigateToAdminPosting(),
              tooltip: 'Create New Post',
            ),
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
                      return InkWell(
                        onTap: () => _openPostDetail(post, index),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
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
                                      backgroundImage: AssetImage(post.authorAvatar ?? 'assets/images/main logo man.png'),
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
                                          post.authorName,
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
                                              _formatTimestamp(post.createdAt),
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
                                                post.topic,
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
                            if (!post.isTextOnly && post.imagePath != null) ...[
                              Container(
                                height: 200,
                                width: double.infinity,
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image: AssetImage(post.imagePath!),
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
                                    post.title,
                                    style: GoogleFonts.judson(
                                      textStyle: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                  
                                  if (post.body.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      post.body,
                                      style: GoogleFonts.judson(
                                        textStyle: const TextStyle(
                                          fontSize: 14,
                                          height: 1.6,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      maxLines: post.isTextOnly ? 4 : 3,
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
                                            Icons.favorite_border,
                                            color: Colors.grey,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${post.likesCount}',
                                            style: GoogleFonts.judson(
                                              textStyle: const TextStyle(
                                                color: Colors.grey,
                                                fontWeight: FontWeight.normal,
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
                                            '${post.commentsCount}',
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
                                        Icons.bookmark_border,
                                        color: Colors.grey,
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