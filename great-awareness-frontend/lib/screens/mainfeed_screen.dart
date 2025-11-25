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
  final Set<int> _likedPosts = {}; // Track locally liked posts
  final Map<int, List<dynamic>> _postComments = {}; // Cache comments for each post
  final Map<int, bool> _loadingComments = {}; // Track loading state for each post

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

  Future<void> _loadComments(int postId) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = authService.currentUser?.token;
    
    if (token == null) return;
    
    setState(() {
      _loadingComments[postId] = true;
    });
    
    try {
      final comments = await _apiService.getComments(token, postId);
      if (mounted) {
        setState(() {
          _postComments[postId] = comments ?? [];
          _loadingComments[postId] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingComments[postId] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading comments: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _addComment(int postId, String text) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = authService.currentUser?.token;
    
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add comments'), backgroundColor: Colors.red),
      );
      return;
    }
    
    try {
      final newComment = await _apiService.createComment(token, postId, text);
      if (newComment != null && mounted) {
        // Add the new comment to the cache
        setState(() {
          if (_postComments[postId] == null) {
            _postComments[postId] = [];
          }
          _postComments[postId]!.add(newComment);
          
          // Update the comment count in the post
          final postIndex = _posts.indexWhere((p) => p.id == postId);
          if (postIndex != -1) {
            _posts[postIndex] = Content(
              id: _posts[postIndex].id,
              title: _posts[postIndex].title,
              body: _posts[postIndex].body,
              topic: _posts[postIndex].topic,
              postType: _posts[postIndex].postType,
              imagePath: _posts[postIndex].imagePath,
              isTextOnly: _posts[postIndex].isTextOnly,
              authorName: _posts[postIndex].authorName,
              authorAvatar: _posts[postIndex].authorAvatar,
              likesCount: _posts[postIndex].likesCount,
              commentsCount: _posts[postIndex].commentsCount + 1,
              status: _posts[postIndex].status,
              isFeatured: _posts[postIndex].isFeatured,
              createdAt: _posts[postIndex].createdAt,
              updatedAt: _posts[postIndex].updatedAt,
              publishedAt: _posts[postIndex].publishedAt,
              createdBy: _posts[postIndex].createdBy,
            );
            
            final filteredIndex = _filteredPosts.indexWhere((p) => p.id == postId);
            if (filteredIndex != -1) {
              _filteredPosts[filteredIndex] = Content(
                id: _filteredPosts[filteredIndex].id,
                title: _filteredPosts[filteredIndex].title,
                body: _filteredPosts[filteredIndex].body,
                topic: _filteredPosts[filteredIndex].topic,
                postType: _filteredPosts[filteredIndex].postType,
                imagePath: _filteredPosts[filteredIndex].imagePath,
                isTextOnly: _filteredPosts[filteredIndex].isTextOnly,
                authorName: _filteredPosts[filteredIndex].authorName,
                authorAvatar: _filteredPosts[filteredIndex].authorAvatar,
                likesCount: _filteredPosts[filteredIndex].likesCount,
                commentsCount: _filteredPosts[filteredIndex].commentsCount + 1,
                status: _filteredPosts[filteredIndex].status,
                isFeatured: _filteredPosts[filteredIndex].isFeatured,
                createdAt: _filteredPosts[filteredIndex].createdAt,
                updatedAt: _filteredPosts[filteredIndex].updatedAt,
                publishedAt: _filteredPosts[filteredIndex].publishedAt,
                createdBy: _filteredPosts[filteredIndex].createdBy,
              );
            }
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment added successfully!'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding comment: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatCommentTime(String? createdAt) {
    if (createdAt == null) return '';
    
    try {
      final dateTime = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
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

  void _toggleLike(int index) async {
    final post = _filteredPosts[index];
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = authService.currentUser?.token;
    
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to like posts'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      Content? updatedPost;
      
      if (_likedPosts.contains(post.id)) {
        // Unlike the post
        updatedPost = await _apiService.unlikeContent(token, post.id);
        if (updatedPost != null && mounted) {
          setState(() {
            _likedPosts.remove(post.id);
            _posts[_posts.indexWhere((p) => p.id == post.id)] = updatedPost!;
            _filteredPosts[index] = updatedPost!;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Post unliked!'),
              backgroundColor: Colors.grey,
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        // Like the post
        updatedPost = await _apiService.likeContent(token, post.id);
        if (updatedPost != null && mounted) {
          setState(() {
            _likedPosts.add(post.id);
            _posts[_posts.indexWhere((p) => p.id == post.id)] = updatedPost!;
            _filteredPosts[index] = updatedPost!;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Post liked!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
    final TextEditingController commentController = TextEditingController();
    
    // Load comments when the modal opens
    _loadComments(post.id);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.8,
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
                child: _loadingComments[post.id] == true
                    ? const Center(child: CircularProgressIndicator())
                    : _postComments[post.id]?.isEmpty ?? true
                        ? Center(
                            child: Text(
                              'No comments yet. Be the first to comment!',
                              style: GoogleFonts.judson(
                                textStyle: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _postComments[post.id]?.length ?? 0,
                            itemBuilder: (context, commentIndex) {
                              final comment = _postComments[post.id]![commentIndex];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        comment['user']?['username'] ?? 'Anonymous',
                                        style: GoogleFonts.judson(
                                          textStyle: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        comment['text'] ?? '',
                                        style: GoogleFonts.judson(),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatCommentTime(comment['created_at']),
                                        style: GoogleFonts.judson(
                                          textStyle: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
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
                    onPressed: () async {
                      if (commentController.text.trim().isNotEmpty) {
                        await _addComment(post.id, commentController.text.trim());
                        commentController.clear();
                        // Reload comments and update modal state
                        await _loadComments(post.id);
                        setModalState(() {});
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
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
                                            _likedPosts.contains(post.id) ? Icons.favorite : Icons.favorite_border,
                                            color: _likedPosts.contains(post.id) ? Colors.red : Colors.grey,
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