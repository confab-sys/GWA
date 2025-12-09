import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/content.dart';
import '../widgets/network_image_widget.dart';

class PostDetailScreen extends StatefulWidget {
  final Content post;
  final int postIndex;
  final Function(int) onLikeToggle;
  final Function(int) onSaveToggle;

  const PostDetailScreen({
    super.key,
    required this.post,
    required this.postIndex,
    required this.onLikeToggle,
    required this.onSaveToggle,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 80,
            pinned: true,
            floating: false,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Post Details',
              style: GoogleFonts.judson(
                textStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            centerTitle: true,
          ),
          // Author information section
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
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
                      radius: 24,
                      backgroundColor: Colors.white,
                      child: ClipOval(
                        child: post.authorAvatar != null && post.authorAvatar!.isNotEmpty
                            ? NetworkImageWidget(
                                imageUrl: post.authorAvatar,
                                height: 48,
                                width: 48,
                                fit: BoxFit.cover,
                              )
                            : Image.asset(
                                'assets/images/main logo man.png',
                                height: 48,
                                width: 48,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
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
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: GoogleFonts.judson(
                      textStyle: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Full image display below title
                  if (post.imagePath != null && !post.isTextOnly) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: NetworkImageWidget(
                          imageUrl: post.imagePath,
                          height: 300,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (post.body.isNotEmpty) ...[
                    Text(
                      post.body,
                      style: GoogleFonts.judson(
                        textStyle: const TextStyle(
                          fontSize: 16,
                          height: 1.8,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD3E4DE).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFD3E4DE).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About this post',
                          style: GoogleFonts.judson(
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This post explores ${post.topic.toLowerCase()} concepts and insights. Join the discussion to share your thoughts and learn from others in our psychology community.',
                          style: GoogleFonts.judson(
                            textStyle: const TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Interactions',
                    style: GoogleFonts.judson(
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildInteractionButton(
                        icon: post.isLikedByUser ? Icons.favorite : Icons.favorite_border,
                        label: '${post.likesCount} Likes',
                        color: post.isLikedByUser ? Colors.red : Colors.grey,
                        onTap: () {
                          widget.onLikeToggle(widget.postIndex);
                          setState(() {});
                        },
                      ),
                      _buildInteractionButton(
                        icon: Icons.chat_bubble_outline,
                        label: '${post.commentsCount} Comments',
                        color: Colors.grey,
                        onTap: () => _showComments(),
                      ),
                      _buildInteractionButton(
                        icon: Icons.share_outlined,
                        label: 'Share',
                        color: Colors.grey,
                        onTap: () => _sharePost(),
                      ),
                      _buildInteractionButton(
                        icon: Icons.bookmark_border, // TODO: Implement save state
                        label: 'Save',
                        color: Colors.grey, // TODO: Implement save state
                        onTap: () {
                          widget.onSaveToggle(widget.postIndex);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.judson(
                textStyle: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  void _showComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Comments',
                      style: GoogleFonts.judson(
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  'No comments yet. Be the first to comment!',
                  style: GoogleFonts.judson(
                    textStyle: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sharePost() {
    // final post = widget.post; // Not used for now
    // final shareText = '${post.title}\n\n${post.body}\n\nShared from Great Awareness - Psychology Community';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Share Post',
          style: GoogleFonts.judson(),
        ),
        content: Text(
          'Share this post with others',
          style: GoogleFonts.judson(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.judson(),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Post copied to clipboard')),
              );
            },
            child: Text(
              'Copy Link',
              style: GoogleFonts.judson(),
            ),
          ),
        ],
      ),
    );
  }
}