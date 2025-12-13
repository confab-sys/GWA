import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'podcasts_screen.dart';
import 'video_upload_screen.dart';
import '../models/video.dart';

import '../services/video_service.dart';
import '../services/cloudflare_storage_service.dart';
import '../services/auth_service.dart';
import '../widgets/cloudflare_video_player.dart';

class Podcast {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String duration;
  final double listenProgress;
  final String thumbnailUrl;
  bool isFavorite;
  bool isSaved;

  Podcast({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.duration,
    this.listenProgress = 0.0,
    required this.thumbnailUrl,
    this.isFavorite = false,
    this.isSaved = false,
  });
}

class VideoPodcastScreen extends StatefulWidget {
  const VideoPodcastScreen({super.key});

  @override
  State<VideoPodcastScreen> createState() => _VideoPodcastScreenState();
}

class _VideoPodcastScreenState extends State<VideoPodcastScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Video> allVideos = [];
  List<Video> filteredVideos = [];
  List<Podcast> allPodcasts = [];
  List<Podcast> filteredPodcasts = [];
  TextEditingController searchController = TextEditingController();
  String selectedCategory = 'All';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadVideosFromCloudflare();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVideosFromCloudflare() async {
    try {
      // Show loading indicator
      setState(() {
        isLoading = true;
      });

      print('Loading videos from Cloudflare database...');
      print('Attempting to fetch videos from database using VideoService...');
      
      // Get videos from database using VideoService
      final response = await VideoService.listVideos(
        page: 1,
        perPage: 50, // Load more videos for better selection
      );
      
      List<Video> loadedVideos = [];
      
      if (response.videos.isNotEmpty) {
        print('✅ SUCCESS: Found ${response.videos.length} videos in Cloudflare database');
        
        // Log detailed information about the first few videos for debugging
        for (int i = 0; i < response.videos.length && i < 3; i++) {
          final video = response.videos[i];
          print('Video ${i + 1}: ${video.title}');
          print('  - ID: ${video.id}');
          print('  - Object Key: ${video.objectKey}');
          print('  - File Size: ${video.formattedFileSize}');
          print('  - Content Type: ${video.contentType}');
          print('  - Views: ${video.viewCount}');
          print('  - Comments: ${video.commentCount}');
          print('  - Has Signed URL: ${video.hasValidSignedUrl}');
          print('  - Original Name: ${video.originalName}');
        }
        
        // Use videos directly from database - they already have all fields
        loadedVideos = response.videos;
        
        print('📊 Database Summary:');
        print('  - Total videos: ${loadedVideos.length}');
        print('  - Average file size: ${loadedVideos.isNotEmpty ? (loadedVideos.map((v) => v.fileSize).reduce((a, b) => a + b) / loadedVideos.length / 1024 / 1024).toStringAsFixed(1) : 0} MB');
        print('  - Total views: ${loadedVideos.map((v) => v.viewCount).reduce((a, b) => a + b)}');
        print('  - Total comments: ${loadedVideos.map((v) => v.commentCount).reduce((a, b) => a + b)}');
        
      } else {
        print('⚠️  No videos found in database, checking Cloudflare storage...');
        
        // Fallback to Cloudflare storage service
        try {
          final cloudflareVideos = await CloudflareStorageService.fetchVideosFromBucket();
          print('Found ${cloudflareVideos.length} videos in Cloudflare storage');
          
          // Convert Cloudflare videos to Video model format
          loadedVideos = cloudflareVideos.map((cfVideo) => Video(
            id: cfVideo.key.hashCode.toString(), // Use hash of key as ID
            title: cfVideo.title,
            description: 'Video from Cloudflare storage',
            objectKey: cfVideo.key,
            createdAt: cfVideo.lastModified,
            fileSize: cfVideo.size,
            contentType: 'video/mp4',
            originalName: cfVideo.key,
            viewCount: 0,
            commentCount: 0,
          )).toList();
        } catch (cfError) {
          print('❌ Error loading from Cloudflare storage: $cfError');
          print('Using configured videos as final fallback');
          
          // Final fallback to configured videos
          final configuredVideos = CloudflareStorageService.getConfiguredVideos();
          loadedVideos = configuredVideos.map((cfVideo) => Video(
            id: cfVideo.key.hashCode.toString(),
            title: cfVideo.title,
            description: 'Video from Cloudflare storage',
            objectKey: cfVideo.key,
            createdAt: cfVideo.lastModified,
            fileSize: cfVideo.size,
            contentType: 'video/mp4',
            originalName: cfVideo.key,
            viewCount: 0,
            commentCount: 0,
          )).toList();
          
        } catch (cfError) {
          print('❌ Error loading from Cloudflare storage: $cfError');
          print('Using configured videos as final fallback');
          
          // Final fallback to configured videos
          final configuredVideos = CloudflareStorageService.getConfiguredVideos();
          loadedVideos = configuredVideos.map((cfVideo) => Video(
            id: cfVideo.key.hashCode.toString(),
            title: cfVideo.title,
            description: 'Video from Cloudflare storage',
            objectKey: cfVideo.key,
            createdAt: cfVideo.lastModified,
            fileSize: cfVideo.size,
            contentType: 'video/mp4',
            originalName: cfVideo.key,
            viewCount: 0,
            commentCount: 0,
          )).toList();
        }
      }

      setState(() {
        allVideos = loadedVideos;
        filteredVideos = List.from(allVideos);
        isLoading = false;
      });
      
      print('Successfully loaded ${loadedVideos.length} videos');
      
    } catch (e) {
      // Error loading videos, show empty state
      print('Error loading videos: $e');
      setState(() {
        isLoading = false;
        allVideos = [];
        filteredVideos = [];
      });
    }
  }



  void _onSearchChanged() {
    final query = searchController.text.toLowerCase();
    setState(() {
      // Filter videos
      if (query.isEmpty) {
        filteredVideos = List.from(allVideos);
        filteredPodcasts = List.from(allPodcasts);
      } else {
        filteredVideos = allVideos.where((video) {
          return video.title.toLowerCase().contains(query) ||
                 video.description.toLowerCase().contains(query);
        }).toList();
        
        filteredPodcasts = allPodcasts.where((podcast) {
          return podcast.title.toLowerCase().contains(query) ||
                 podcast.subtitle.toLowerCase().contains(query) ||
                 podcast.category.toLowerCase().contains(query);
        }).toList();
      }
      
      // Filter by category if not 'All' - removed since Video model doesn't have category field
      // For now, show all videos regardless of category selection
      if (selectedCategory != 'All') {
        // Category filtering disabled - real Video model doesn't have category field
        // filteredVideos = filteredVideos.where((video) => video.category == selectedCategory).toList();
        // filteredPodcasts = filteredPodcasts.where((podcast) => podcast.category == selectedCategory).toList();
      }
    });
  }

  List<String> get _categories {
    // Since real Video model doesn't have category field, return only 'All'
    // This can be enhanced later when categories are added to the database
    return ['All'];
  }

  Map<String, List<Video>> get _videosByCategory {
    // Since real Video model doesn't have category field, return all videos under 'All' category
    final Map<String, List<Video>> grouped = {};
    grouped.putIfAbsent('All', () => []).addAll(filteredVideos);
    return grouped;
  }

  void _showVideoDetails(Video video) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            video.title,
            style: GoogleFonts.judson(
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // File information
                _buildDetailRow('Original Name:', video.originalName),
                _buildDetailRow('Object Key:', video.objectKey),
                _buildDetailRow('Content Type:', video.contentType),
                _buildDetailRow('File Size:', video.formattedFileSize),
                const SizedBox(height: 8),
                
                // Upload information
                _buildDetailRow('Upload Date:', video.createdAt.toString()),
                _buildDetailRow('Time Ago:', video.formattedDuration),
                const SizedBox(height: 8),
                
                // Statistics
                _buildDetailRow('Views:', video.formattedViewCount),
                _buildDetailRow('Comments:', video.formattedCommentCount),
                const SizedBox(height: 8),
                
                // Description
                if (video.description.isNotEmpty) ...[
                  Text(
                    'Description:',
                    style: GoogleFonts.judson(
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    video.description,
                    style: GoogleFonts.judson(
                      textStyle: const TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Signed URL status
                _buildDetailRow('Signed URL:', video.hasValidSignedUrl ? 'Valid' : 'Expired/None'),
                if (video.signedUrlExpiry != null) ...[
                  _buildDetailRow('URL Expires:', video.signedUrlExpiry.toString()),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: GoogleFonts.judson(),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CloudflareVideoPlayer(
                      video: video,
                      title: video.title,
                      subtitle: video.description,
                      onVideoCompleted: () {},
                    ),
                  ),
                );
              },
              child: Text(
                'Play Video',
                style: GoogleFonts.judson(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.judson(
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.judson(
                textStyle: const TextStyle(
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
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
        title: Text(
          'Videos & Podcasts',
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
            icon: const Icon(Icons.upload, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VideoUploadScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              _loadVideosFromCloudflare();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search videos...',
                    hintStyle: GoogleFonts.judson(
                      textStyle: TextStyle(color: Colors.grey[600]),
                    ),
                    prefixIcon: const Icon(Icons.search, color: Colors.black),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: const BorderSide(color: Colors.black),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: GoogleFonts.judson(
                    textStyle: const TextStyle(color: Colors.black, fontSize: 14),
                  ),
                ),
              ),
              // Category Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: _categories.map((category) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          category,
                          style: GoogleFonts.judson(
                            textStyle: TextStyle(
                              color: selectedCategory == category ? Colors.white : Colors.black,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        selected: selectedCategory == category,
                        onSelected: (selected) {
                          setState(() {
                            selectedCategory = category;
                            _onSearchChanged();
                          });
                        },
                        backgroundColor: Colors.white,
                        selectedColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              // Tab Bar
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.black,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey[600],
                tabs: const [
                  Tab(text: 'Videos'),
                  Tab(text: 'Podcasts'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVideosTab(),
          _buildPodcastsTab(),
        ],
      ),
      floatingActionButton: Consumer<AuthService>(
        builder: (context, authService, child) {
          final currentUser = authService.currentUser;
          // Only show upload button for admin users
          if (currentUser == null || !currentUser.isAdmin) {
            return const SizedBox.shrink();
          }
          
          return FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VideoUploadScreen(),
                ),
              );
            },
            backgroundColor: Colors.black,
            child: const Icon(Icons.upload, color: Colors.white),
          );
        },
      ),
    );
  }

  Widget _buildVideosTab() {
    final videosByCategory = _videosByCategory;
    
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading videos...',
              style: GoogleFonts.judson(
                textStyle: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    if (filteredVideos.isEmpty) {
      return Center(
        child: Text(
          'No videos available',
          style: GoogleFonts.judson(
            textStyle: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: videosByCategory.keys.length,
      itemBuilder: (context, categoryIndex) {
        final category = videosByCategory.keys.elementAt(categoryIndex);
        final videos = videosByCategory[category]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Title
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                category,
                style: GoogleFonts.judson(
                  textStyle: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Videos Row
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: videos.length,
                itemBuilder: (context, videoIndex) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _buildEnhancedVideoCard(videos[videoIndex]),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildPodcastsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.podcasts,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'Explore Our Podcasts',
            style: GoogleFonts.judson(
              textStyle: const TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Discover healing and growth through our podcast collection',
            style: GoogleFonts.judson(
              textStyle: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PodcastsScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(
              'Go to Podcasts',
              style: GoogleFonts.judson(
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedVideoCard(Video video) {
    return GestureDetector(
      onTap: () {
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
      },
      child: Container(
        width: 180, // Increased width for more information
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video thumbnail with progress
          Stack(
            children: [
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Center(
                  child: Icon(
                    Icons.play_circle_outline,
                    size: 45,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              // File size badge
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    video.formattedFileSize,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Content type badge
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    video.contentType.split('/').last.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            ],
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    video.title,
                    style: GoogleFonts.judson(
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Original filename
                  Text(
                    'File: ${video.originalName}',
                    style: GoogleFonts.judson(
                      textStyle: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Description
                  if (video.description.isNotEmpty) ...[
                    Text(
                      video.description,
                      style: GoogleFonts.judson(
                        textStyle: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                        ),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                  ],
                  // Upload date and view count
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        video.formattedDuration,
                        style: GoogleFonts.judson(
                          textStyle: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.visibility, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        video.formattedViewCount,
                        style: GoogleFonts.judson(
                          textStyle: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Object key and comment count
                  Row(
                    children: [
                      Icon(Icons.key, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          video.objectKey,
                          style: GoogleFonts.judson(
                            textStyle: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[500],
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (video.commentCount > 0) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.comment, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          video.formattedCommentCount,
                          style: GoogleFonts.judson(
                            textStyle: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const Spacer(),
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Play button
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              'Play',
                              style: GoogleFonts.judson(
                                textStyle: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // More info
                      GestureDetector(
                        onTap: () => _showVideoDetails(video),
                        child: Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }



  Widget _buildPodcastCard(int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
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
          // Podcast thumbnail
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Center(
              child: Icon(
                Icons.podcasts,
                size: 32,
                color: Colors.grey[600],
              ),
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Podcast ${index + 1}',
                    style: GoogleFonts.judson(
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Discussion',
                    style: GoogleFonts.judson(
                      textStyle: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSmallActionButton(Icons.favorite_border, 'Like'),
                      _buildSmallActionButton(Icons.bookmark_border, 'Save'),
                      _buildSmallActionButton(Icons.download, 'Download'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallActionButton(IconData icon, String tooltip) {
    return IconButton(
      icon: Icon(icon, size: 16, color: Colors.grey[700]),
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: () {
        // Handle action
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$tooltip pressed'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }
}