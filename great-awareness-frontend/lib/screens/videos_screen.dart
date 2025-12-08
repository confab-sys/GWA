import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/video.dart';
import '../services/video_service.dart';
import '../widgets/cloudflare_video_player.dart';
// TODO: Create video_upload_screen.dart or implement upload functionality
// import 'video_upload_screen.dart';

class VideosScreen extends StatefulWidget {
  const VideosScreen({super.key});

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen> {
  // ignore: prefer_final_fields
  List<Video> _videos = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;
  final int _perPage = 10;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadVideos();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreVideos();
    }
  }

  Future<void> _loadVideos({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _videos.clear();
      });
    }

    try {
      final response = await VideoService.listVideos(
        page: _currentPage,
        perPage: _perPage,
      );

      if (mounted) {
        setState(() {
          _videos.addAll(response.videos);
          _hasMore = response.videos.length == _perPage;
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = 'Failed to load videos: $e';
        });
      }
    }
  }

  Future<void> _loadMoreVideos() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    await _loadVideos();
  }

  Future<void> _refreshVideos() async {
    await _loadVideos(refresh: true);
  }

  void _navigateToUpload() async {
    // TODO: Implement video upload functionality or create VideoUploadScreen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Video upload not implemented yet')),
    );
    /*
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VideoUploadScreen(),
      ),
    );

    // Refresh videos if upload was successful
    if (result == true) {
      _refreshVideos();
    }
    */
  }

  void _playVideo(Video video) async {
    // Navigate directly to the CloudflareVideoPlayer widget
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CloudflareVideoPlayer(
          video: video,
          title: video.title,
          subtitle: video.description,
          onVideoCompleted: () {
            // Handle video completion if needed
          },
        ),
      ),
    );
  }

  String _formatDuration(DateTime dateTime) {
    final duration = DateTime.now().difference(dateTime);
    if (duration.inDays > 0) return '${duration.inDays}d ago';
    if (duration.inHours > 0) return '${duration.inHours}h ago';
    if (duration.inMinutes > 0) return '${duration.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Videos',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: GoogleFonts.inter(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshVideos,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshVideos,
        child: _buildContent(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToUpload,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _videos.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null && _videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load videos',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refreshVideos,
              icon: const Icon(Icons.refresh),
              label: Text(
                'Try Again',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No videos yet',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to upload a video!',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToUpload,
              icon: const Icon(Icons.add),
              label: Text(
                'Upload Video',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _videos.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _videos.length) {
          return _buildLoadingIndicator();
        }

        final video = _videos[index];
        return _buildVideoCard(video);
      },
    );
  }

  Widget _buildVideoCard(Video video) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _playVideo(video),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Video thumbnail placeholder
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          video.formattedFileSize,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Video title
              Text(
                video.displayName,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (video.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  video.description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              // Video metadata
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(video.createdAt),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.video_file,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    video.contentType.split('/').last.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.visibility,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    video.formattedViewCount,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.comment,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    video.formattedCommentCount,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 8),
            Text(
              'Loading more videos...',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}