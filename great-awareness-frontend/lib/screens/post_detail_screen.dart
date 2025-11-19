import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;
  final int postIndex;
  final Function(int) onLikeToggle;
  final Function(int) onSaveToggle;

  const PostDetailScreen({
    Key? key,
    required this.post,
    required this.postIndex,
    required this.onLikeToggle,
    required this.onSaveToggle,
  }) : super(key: key);

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
            expandedHeight: 200,
            pinned: true,
            floating: false,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: post['image'] != null && !post['isTextOnly']
                  ? Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(post['image']),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: const Color(0xFFD3E4DE),
                      child: Center(
                        child: Icon(
                          Icons.psychology,
                          size: 80,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
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
                        backgroundImage: AssetImage(post['authorAvatar']),
                        radius: 24,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
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
                  ],
                ),
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
                    post['title'],
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
                  if (post['content'] != null && post['content'].isNotEmpty) ...[
                    Text(
                      post['content'],
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
                          'This post explores ${post['topic'].toLowerCase()} concepts and insights. Join the discussion to share your thoughts and learn from others in our psychology community.',
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
                        icon: post['isLiked'] ? Icons.favorite : Icons.favorite_border,
                        label: '${post['likes']} Likes',
                        color: post['isLiked'] ? Colors.red : Colors.grey,
                        onTap: () {
                          widget.onLikeToggle(widget.postIndex);
                          setState(() {});
                        },
                      ),
                      _buildInteractionButton(
                        icon: Icons.chat_bubble_outline,
                        label: '${post['comments']} Comments',
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
                        icon: post['isSaved'] ? Icons.bookmark : Icons.bookmark_border,
                        label: 'Save',
                        color: post['isSaved'] ? const Color(0xFFD3E4DE) : Colors.grey,
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
    final post = widget.post;
    final shareText = '${post['title']}\n\n${post['content']}\n\nShared from Great Awareness - Psychology Community';
    
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