import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/video_comment.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String subtitle;
  final int initialLikes;
  final bool initialIsLiked;
  final List<VideoComment> initialComments;
  final Function(int likes, bool isLiked) onLikeChanged;
  final Function(VideoComment comment) onCommentAdded;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.title,
    required this.subtitle,
    required this.initialLikes,
    required this.initialIsLiked,
    required this.initialComments,
    required this.onLikeChanged,
    required this.onCommentAdded,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  late ChewieController _chewieController;
  bool _isPlaying = false;
  int _likes = 0;
  bool _isLiked = false;
  List<VideoComment> _comments = [];
  TextEditingController _commentController = TextEditingController();
  bool _showComments = false;

  @override
  void initState() {
    super.initState();
    _likes = widget.initialLikes;
    _isLiked = widget.initialIsLiked;
    _comments = List.from(widget.initialComments);
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      print('Initializing video player with URL: ${widget.videoUrl}');
      
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      await _videoPlayerController.initialize();
      
      print('Video player initialized successfully');

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Error loading video: $errorMessage',
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.blue,
          handleColor: Colors.blueAccent,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.lightBlue.withOpacity(0.5),
        ),
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
      );

      _videoPlayerController.addListener(() {
        setState(() {
          _isPlaying = _videoPlayerController.value.isPlaying;
        });
      });

      setState(() {});
    } catch (e) {
      print('Error initializing video player: $e');
      setState(() {
        // Show error state
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likes = _isLiked ? _likes + 1 : _likes - 1;
    });
    widget.onLikeChanged(_likes, _isLiked);
  }

  void _addComment() {
    if (_commentController.text.trim().isEmpty) return;

    final newComment = VideoComment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: 'current_user_id', // This should come from your auth system
      userName: 'Current User', // This should come from your auth system
      text: _commentController.text.trim(),
      timestamp: DateTime.now(),
    );

    setState(() {
      _comments.add(newComment);
      _commentController.clear();
    });

    widget.onCommentAdded(newComment);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: GoogleFonts.judson(
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              widget.subtitle,
              style: GoogleFonts.judson(
                textStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isLiked ? Icons.favorite : Icons.favorite_border,
              color: _isLiked ? Colors.red : Colors.white,
            ),
            onPressed: _toggleLike,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '$_likes',
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
        ],
      ),
      body: Column(
        children: [
          // Video Player
          AspectRatio(
            aspectRatio: _videoPlayerController.value.isInitialized
                ? _videoPlayerController.value.aspectRatio
                : 16 / 9,
            child: _videoPlayerController.value.isInitialized
                ? Chewie(controller: _chewieController)
                : Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
          ),
          
          // Controls and Comments
          Expanded(
            child: Container(
              color: const Color(0xFF1A1A1A),
              child: Column(
                children: [
                  // Action Buttons
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _toggleLike,
                            icon: Icon(
                              _isLiked ? Icons.favorite : Icons.favorite_border,
                              color: _isLiked ? Colors.red : Colors.white,
                            ),
                            label: Text(
                              '$_likes',
                              style: GoogleFonts.judson(
                                textStyle: const TextStyle(color: Colors.white),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[800],
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _showComments = !_showComments;
                              });
                            },
                            icon: const Icon(Icons.comment, color: Colors.white),
                            label: Text(
                              '${_comments.length}',
                              style: GoogleFonts.judson(
                                textStyle: const TextStyle(color: Colors.white),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[800],
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Comments Section
                  if (_showComments) ...[
                    // Comment Input
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              style: GoogleFonts.judson(
                                textStyle: const TextStyle(color: Colors.white),
                              ),
                              decoration: InputDecoration(
                                hintText: 'Add a comment...',
                                hintStyle: GoogleFonts.judson(
                                  textStyle: TextStyle(color: Colors.grey[400]),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide(color: Colors.grey[600]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide(color: Colors.grey[600]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: const BorderSide(color: Colors.blue),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _addComment,
                            icon: const Icon(Icons.send, color: Colors.blue),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey[800],
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Comments List
                    Expanded(
                      child: ListView.builder(
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[850],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      comment.userName,
                                      style: GoogleFonts.judson(
                                        textStyle: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatTimestamp(comment.timestamp),
                                      style: GoogleFonts.judson(
                                        textStyle: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  comment.text,
                                  style: GoogleFonts.judson(
                                    textStyle: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
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
}