import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'post_detail_screen.dart';
import 'admin_posting_screen.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../services/notification_service.dart';
import '../models/content.dart';
import '../models/notification.dart';

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
    
    // Listen for new notifications
    Provider.of<NotificationService>(context, listen: false).notificationStream.listen((notification) {
      // Optional: Show a snackbar for new notifications
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New ${notification.type == NotificationType.post ? 'post' : 'question'} in ${notification.category}'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  // Pull-to-refresh functionality
  Future<void> _refreshPosts() async {
    if (kDebugMode) {
      debugPrint('Refreshing posts...');
    }
    
    try {
      // Get current user and token
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = authService.currentUser?.token;
      
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Fetch fresh posts from backend (reset pagination)
      final freshPosts = await _apiService.fetchFeed(token, skip: 0);
      
      // Update cache with fresh data
      await CacheService.cachePosts(freshPosts);
      
      setState(() {
        _posts.clear();
        _filteredPosts.clear();
        _posts.addAll(freshPosts);
        _filteredPosts.addAll(freshPosts);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feed updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error refreshing posts: $e');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh feed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ignore: unused_element
  Future<void> _refreshPost(int postId) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = authService.currentUser?.token;
    
    if (token == null) return;
    
    try {
      final updatedPost = await _apiService.getContent(token, postId);
      if (updatedPost != null && mounted) {
        setState(() {
          // Update the post in both lists
          final postIndex = _posts.indexWhere((p) => p.id == postId);
          if (postIndex != -1) {
            _posts[postIndex] = updatedPost;
          }
          
          final filteredIndex = _filteredPosts.indexWhere((p) => p.id == postId);
          if (filteredIndex != -1) {
            _filteredPosts[filteredIndex] = updatedPost;
          }
        });
      }
    } catch (e) {
      debugPrint('Error refreshing post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh post: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadComments(int postId) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = authService.currentUser?.token;
    
    if (token == null) return;
    
    // Check if comments are already cached
    if (_postComments[postId] != null && _postComments[postId]!.isNotEmpty) {
      debugPrint('Comments already cached for post $postId, skipping reload');
      return;
    }
    
    setState(() {
      _loadingComments[postId] = true;
    });
    
    try {
      final comments = await _apiService.getComments(token, postId);
      debugPrint('Loaded comments for post $postId: ${comments?.length ?? 0} comments');
      if (mounted) {
        setState(() {
          _postComments[postId] = comments ?? [];
          _loadingComments[postId] = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading comments for post $postId: $e');
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
    final user = authService.currentUser;
    final token = user?.token;
    
    if (token == null || user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add comments'), backgroundColor: Colors.red),
      );
      return;
    }
    
    // Optimistic UI update - update comment count immediately
    setState(() {
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
          isLikedByUser: _posts[postIndex].isLikedByUser,
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
            isLikedByUser: _filteredPosts[filteredIndex].isLikedByUser,
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
    
    // Show brief posting feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Posting comment...'), duration: Duration(milliseconds: 300)),
    );
    
    try {
      debugPrint('Attempting to create comment for post $postId with text: $text');
      final newComment = await _apiService.createComment(token, postId, int.tryParse(user.id ?? '') ?? 0, text);
      debugPrint('API Response for createComment: $newComment');
      
      if (newComment != null && mounted) {
        // Successfully created comment - reload comments from server for accuracy
        debugPrint('Comment created successfully, reloading comments...');
        await _loadComments(postId);
        
        // Update post comment count
        setState(() {
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
              isLikedByUser: _posts[postIndex].isLikedByUser,
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
                isLikedByUser: _filteredPosts[filteredIndex].isLikedByUser,
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
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Comment added!'), backgroundColor: Colors.green, duration: Duration(milliseconds: 500)),
          );
        }
      } else {
        // API failed, rollback comment count
        if (mounted) {
          setState(() {
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
                commentsCount: _posts[postIndex].commentsCount - 1,
                isLikedByUser: _posts[postIndex].isLikedByUser,
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
                  commentsCount: _filteredPosts[filteredIndex].commentsCount - 1,
                  isLikedByUser: _filteredPosts[filteredIndex].isLikedByUser,
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
            const SnackBar(content: Text('Failed to add comment. Please try again.'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      debugPrint('Exception in _addComment: $e');
      // Error occurred, rollback comment count
      if (mounted) {
        setState(() {
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
              commentsCount: _posts[postIndex].commentsCount - 1,
              isLikedByUser: _posts[postIndex].isLikedByUser,
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
                commentsCount: _filteredPosts[filteredIndex].commentsCount - 1,
                isLikedByUser: _filteredPosts[filteredIndex].isLikedByUser,
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
          SnackBar(
            content: Text('Error adding comment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
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
      // First, try to load cached posts for immediate display
      final cachedPosts = await CacheService.getCachedPosts();
      
      if (cachedPosts != null && cachedPosts.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('=== CACHED POSTS LOADED ===');
          debugPrint('Loaded ${cachedPosts.length} posts from cache');
        }
        
        setState(() {
          _posts.clear();
          _filteredPosts.clear();
          _posts.addAll(cachedPosts);
          _filteredPosts.addAll(cachedPosts);
          _isLoading = false;
        });
        
        // Load fresh posts in background to update cache
        _loadFreshPostsInBackground();
        return;
      }
      
      // If no cache, fetch from backend
      await _loadFreshPostsFromBackend();
      
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
      
      debugPrint('Failed to load posts: $e');
    }
  }

  // Load fresh posts from backend and update cache
  Future<void> _loadFreshPostsFromBackend() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = authService.currentUser?.token;
    
    if (token == null) {
      throw Exception('No authentication token found');
    }

    // Fetch posts from backend
    final posts = await _apiService.fetchFeed(token);
    
    // Debug: Print post data to see what we're getting
    if (kDebugMode) {
      debugPrint('=== FRESH POSTS LOADED FROM BACKEND ===');
      for (final post in posts) {
        debugPrint('Post ID: ${post.id}, Title: ${post.title}, isTextOnly: ${post.isTextOnly}, imagePath: ${post.imagePath}, postType: ${post.postType}');
      }
      debugPrint('====================');
    }
    
    // Cache the fresh posts
    await CacheService.cachePosts(posts);
    
    setState(() {
      _posts.clear();
      _filteredPosts.clear();
      _posts.addAll(posts);
      _filteredPosts.addAll(posts);
      _isLoading = false;
    });
  }

  // Load fresh posts in background to update cache without showing loading indicator
  Future<void> _loadFreshPostsInBackground() async {
    try {
      if (kDebugMode) {
        debugPrint('Loading fresh posts in background...');
      }
      
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = authService.currentUser?.token;
      
      if (token == null) return;

      final freshPosts = await _apiService.fetchFeed(token);
      
      // Update cache with fresh data
      await CacheService.cachePosts(freshPosts);
      
      if (kDebugMode) {
        debugPrint('Background refresh completed. Found ${freshPosts.length} fresh posts');
      }
      
      // Update UI with fresh data if cache was stale
      final isCacheValid = await CacheService.isCacheValid();
      if (!isCacheValid && freshPosts.isNotEmpty) {
        setState(() {
          _posts.clear();
          _filteredPosts.clear();
          _posts.addAll(freshPosts);
          _filteredPosts.addAll(freshPosts);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Background refresh failed: $e');
      }
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
      debugPrint('Failed to load more posts: $e');
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
    final user = authService.currentUser;
    final token = user?.token;
    
    if (token == null || user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to like posts'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Optimistic UI update - update immediately for instant feedback
    setState(() {
      // Toggle like status and count locally first
      final optimisticPost = Content(
        id: post.id,
        title: post.title,
        body: post.body,
        topic: post.topic,
        postType: post.postType,
        imagePath: post.imagePath,
        isTextOnly: post.isTextOnly,
        authorName: post.authorName,
        authorAvatar: post.authorAvatar,
        likesCount: post.isLikedByUser ? post.likesCount - 1 : post.likesCount + 1,
        commentsCount: post.commentsCount,
        isLikedByUser: !post.isLikedByUser,
        status: post.status,
        isFeatured: post.isFeatured,
        createdAt: post.createdAt,
        updatedAt: post.updatedAt,
        publishedAt: post.publishedAt,
        createdBy: post.createdBy,
      );
      
      // Update both lists
      final postIndexInPosts = _posts.indexWhere((p) => p.id == post.id);
      if (postIndexInPosts != -1) {
        _posts[postIndexInPosts] = optimisticPost;
      }
      _filteredPosts[index] = optimisticPost;
    });

    try {
      // Use the toggle endpoint which returns Map<String, dynamic>
      final result = await _apiService.likeContent(token, post.id, int.tryParse(user.id ?? '') ?? 0);
      
      if (result != null && mounted) {
        // Update with server response for accuracy
        setState(() {
          final updatedPost = Content(
            id: post.id,
            title: post.title,
            body: post.body,
            topic: post.topic,
            postType: post.postType,
            imagePath: post.imagePath,
            isTextOnly: post.isTextOnly,
            authorName: post.authorName,
            authorAvatar: post.authorAvatar,
            likesCount: result['likes_count'],
            commentsCount: post.commentsCount,
            isLikedByUser: result['is_liked'],
            status: post.status,
            isFeatured: post.isFeatured,
            createdAt: post.createdAt,
            updatedAt: post.updatedAt,
            publishedAt: post.publishedAt,
            createdBy: post.createdBy,
          );

          final postIndexInPosts = _posts.indexWhere((p) => p.id == post.id);
          if (postIndexInPosts != -1) {
            _posts[postIndexInPosts] = updatedPost;
          }
          _filteredPosts[index] = updatedPost;
        });
        
        // Show brief success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['is_liked'] ? 'Post liked' : 'Post unliked'),
            backgroundColor: result['is_liked'] ? Colors.green : Colors.grey,
            duration: const Duration(milliseconds: 500),
          ),
        );
      } else {
        // API failed, rollback to original state
        if (mounted) {
          setState(() {
            // Revert to original state
            final postIndexInPosts = _posts.indexWhere((p) => p.id == post.id);
            if (postIndexInPosts != -1) {
              _posts[postIndexInPosts] = post;
            }
            _filteredPosts[index] = post;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update like. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Error occurred, rollback to original state
      if (mounted) {
        setState(() {
          final postIndexInPosts = _posts.indexWhere((p) => p.id == post.id);
          if (postIndexInPosts != -1) {
            _posts[postIndexInPosts] = post;
          }
          _filteredPosts[index] = post;
        });
        
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
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New post created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showComments(int index) {
    final post = _filteredPosts[index];
    final TextEditingController commentController = TextEditingController();
    bool isSubmitting = false;
    
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
                    icon: isSubmitting 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (commentController.text.trim().isNotEmpty) {
                              setModalState(() {
                                isSubmitting = true;
                              });
                              
                              try {
                                await _addComment(post.id, commentController.text.trim());
                                commentController.clear();
                                
                                // Update the modal state to reflect changes
                                if (mounted) {
                                  setModalState(() {
                                    isSubmitting = false;
                                  });
                                }
                              } catch (e) {
                                setModalState(() {
                                  isSubmitting = false;
                                });
                              }
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

  Widget _buildMinimalistPostCard(Content post, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24, left: 20, right: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openPostDetail(post, index),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image (Edge-to-Edge)
            if (post.imagePath != null && post.imagePath!.isNotEmpty)
              Container(
                height: 220,
                width: double.infinity,
                color: Colors.grey[100],
                child: Image.network(
                  post.imagePath!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.broken_image, color: Colors.grey[400]),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    post.title,
                    style: GoogleFonts.judson(
                      textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                    ),
                  ),
                  
                  // Excerpt
                  if (post.body.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      post.body,
                      style: GoogleFonts.judson(
                        textStyle: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: Colors.black54,
                        ),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Metadata (Combined Line)
                  Row(
                    children: [
                      Text(
                        '${post.authorName} • ${_formatTimestamp(post.createdAt)} • ${post.topic}',
                        style: GoogleFonts.judson(
                          textStyle: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Minimalist Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildIconAction(
                            icon: post.isLikedByUser ? Icons.favorite : Icons.favorite_border,
                            color: post.isLikedByUser ? Colors.red : Colors.grey[400]!,
                            onTap: () => _toggleLike(index),
                          ),
                          const SizedBox(width: 24),
                          _buildIconAction(
                            icon: Icons.chat_bubble_outline,
                            color: Colors.grey[400]!,
                            onTap: () => _showComments(index),
                          ),
                          const SizedBox(width: 24),
                          _buildIconAction(
                            icon: Icons.share_outlined,
                            color: Colors.grey[400]!,
                            onTap: () => _sharePost(index),
                          ),
                        ],
                      ),
                      _buildIconAction(
                        icon: Icons.bookmark_border,
                        color: Colors.grey[400]!,
                        onTap: () => _toggleSave(index),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconAction({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Icon(
          icon,
          color: color,
          size: 24,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      floatingActionButton: _authService.isAdmin
          ? FloatingActionButton(
              onPressed: () => _navigateToAdminPosting(),
              backgroundColor: const Color(0xFF4A90A4),
              child: const Icon(Icons.add),
            )
          : null,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search, color: Colors.black),
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
          const SizedBox(width: 8),
        ],
        bottom: _showSearch
            ? PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search psychology topics...',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                    ),
                    style: GoogleFonts.judson(),
                  ),
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          // Minimalist Category Chips
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: Colors.white,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _psychologyTopics.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final topic = _psychologyTopics[index];
                final isSelected = _searchController.text == topic;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _searchController.clear();
                        _filterPosts();
                      } else {
                        _searchController.text = topic;
                        _filterPosts();
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? const Color(0xFF4A90A4).withValues(alpha: 0.1) 
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        topic,
                        style: GoogleFonts.judson(
                          textStyle: TextStyle(
                            color: isSelected ? const Color(0xFF4A90A4) : Colors.grey[600],
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Posts List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshPosts,
              color: const Color(0xFF4A90A4),
              backgroundColor: Colors.white,
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
                      padding: const EdgeInsets.only(top: 12),
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
                      return _buildMinimalistPostCard(post, index);
                    },
                  ),
            ),
          ),
        ],
      ),
    );
  }

}