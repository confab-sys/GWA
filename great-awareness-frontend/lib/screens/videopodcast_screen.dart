import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'podcasts_screen.dart';
import 'video_upload_screen.dart';
import '../models/video.dart';

import '../services/video_service.dart';
import '../services/cloudflare_storage_service.dart';
import '../services/video_sync_service.dart';
import '../services/auth_service.dart';
import '../widgets/cloudflare_video_player.dart';
import '../widgets/premium_video_card.dart';
import '../widgets/category_button.dart';
import '../widgets/view_more_card.dart';

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
  String? _errorMessage;

  final List<String> _categoryLabels = [
    'Addictions',
    'Relationships',
    'Trauma',
    'Emotional Intelligence',
    'Sexual Health',
    'Finances',
    'Family',
    'Consciousness Expansion',
    'Behavior Updating',
  ];

  final Map<String, Color> _categoryColors = {
    'Addictions': const Color(0xFFE57373), // Red 300
    'Relationships': const Color(0xFFF06292), // Pink 300
    'Trauma': const Color(0xFFBA68C8), // Purple 300
    'Emotional Intelligence': const Color(0xFF64B5F6), // Blue 300
    'Sexual Health': const Color(0xFFFF8A65), // Deep Orange 300
    'Finances': const Color(0xFF81C784), // Green 300
    'Family': const Color(0xFF4DB6AC), // Teal 300
    'Consciousness Expansion': const Color(0xFF9575CD), // Deep Purple 300
    'Behavior Updating': const Color(0xFFFFB74D), // Orange 300
  };

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
      setState(() {
        isLoading = true;
        _errorMessage = null;
      });

      print('Loading videos from Cloudflare database...');
      
      // Get videos from database using VideoService
      final response = await VideoService.listVideos(
        page: 1,
        perPage: 50,
      );
      
      List<Video> loadedVideos = [];
      
      if (response.videos.isNotEmpty) {
        loadedVideos = response.videos;
      } else {
        try {
          final cloudflareVideos = await CloudflareStorageService.fetchVideosFromBucket();
          loadedVideos = cloudflareVideos.map((cfVideo) => Video(
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
        if (allVideos.isEmpty) {
          _errorMessage = "No videos found.";
        }
      });
      
    } catch (e) {
      print('Error loading videos: $e');
      setState(() {
        isLoading = false;
        allVideos = [];
        filteredVideos = [];
        _errorMessage = "Failed to load videos: $e";
      });
    }
  }

  void _onSearchChanged() {
    final query = searchController.text.toLowerCase();
    setState(() {
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
    });
  }

  void _playVideo(Video video) async {
    // First check if the video has a valid signed URL
    if (!video.hasValidSignedUrl) {
      // Show loading dialog while we refresh the signed URL
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(color: Colors.black),
              SizedBox(width: 16),
              Text('Preparing video...'),
            ],
          ),
        ),
      );

      try {
        // Try to get a fresh signed URL
        final freshVideo = await VideoSyncService.getVideoWithFreshSignedUrl(video.id);
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          
          // Navigate to the video player with fresh signed URL
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CloudflareVideoPlayer(
                video: freshVideo,
                title: freshVideo.title,
                subtitle: freshVideo.description,
                onVideoCompleted: () {},
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to prepare video: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      return;
    }

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Lighter background for premium feel
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Videos & Podcasts',
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
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  style: GoogleFonts.judson(
                    textStyle: const TextStyle(color: Colors.black, fontSize: 14),
                  ),
                ),
              ),
              // Tab Bar
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.black,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: GoogleFonts.judson(fontWeight: FontWeight.bold),
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
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.black),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage ?? 'No videos available',
                textAlign: TextAlign.center,
                style: GoogleFonts.judson(
                  textStyle: TextStyle(
                    color: _errorMessage != null ? Colors.red : Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadVideosFromCloudflare,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          _buildLatestVideosSection(),
          const SizedBox(height: 32),
          _buildMasterClassesSection(),
          const SizedBox(height: 32),
          _buildCategoryLayout(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLatestVideosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Latest Videos',
            style: GoogleFonts.judson(
              textStyle: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: filteredVideos.length > 5 ? 6 : filteredVideos.length,
            itemBuilder: (context, index) {
              if (filteredVideos.length > 5 && index == 5) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: ViewMoreCard(
                    count: filteredVideos.length - 5,
                    isLarge: true,
                    onTap: () => _showVideoList('Latest Videos', filteredVideos),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: PremiumVideoCard(
                  video: filteredVideos[index],
                  isLarge: true,
                  onTap: () => _playVideo(filteredVideos[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMasterClassesSection() {
    final List<Map<String, dynamic>> masterClasses = [
      {'title': 'Healing Trauma', 'color': const Color(0xFFBA68C8)},
      {'title': 'Conscious Relationships', 'color': const Color(0xFFF06292)},
      {'title': 'Financial Freedom', 'color': const Color(0xFF81C784)},
      {'title': 'Self Mastery', 'color': const Color(0xFF64B5F6)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'Master Classes',
                style: GoogleFonts.judson(
                  textStyle: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'PREMIUM',
                  style: GoogleFonts.judson(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: masterClasses.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  width: 240,
                  decoration: BoxDecoration(
                    color: masterClasses[index]['color'],
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (masterClasses[index]['color'] as Color).withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        bottom: -20,
                        child: Icon(
                          Icons.school,
                          size: 100,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'SERIES',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              masterClasses[index]['title'],
                              style: GoogleFonts.judson(
                                textStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Watch Collection',
                              style: GoogleFonts.judson(
                                textStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryLayout() {
    // Filter categories that have at least one video
    final activeCategories = _categoryLabels.where((category) {
      return filteredVideos.any((v) => v.category?.toLowerCase() == category.toLowerCase());
    }).toList();

    if (activeCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0), // Remove horizontal padding for the whole section to allow full-width scrolling
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Browse Categories',
              style: GoogleFonts.judson(
                textStyle: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: activeCategories.length,
            separatorBuilder: (context, index) => const SizedBox(height: 32),
            itemBuilder: (context, index) {
              final category = activeCategories[index];
              final color = _categoryColors[category] ?? Colors.grey;
              
              // Get all videos for this category
              final categoryVideos = filteredVideos.where(
                (v) => v.category?.toLowerCase() == category.toLowerCase()
              ).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 200, // Fixed width for the button/header
                      child: CategoryButton(
                        label: category,
                        color: color,
                        onTap: () {
                           // Navigate to full list or just keep as header
                           _showVideoList(category, categoryVideos);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Horizontal Video List
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: categoryVideos.length > 5 ? 6 : categoryVideos.length,
                      itemBuilder: (context, videoIndex) {
                        if (categoryVideos.length > 5 && videoIndex == 5) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: ViewMoreCard(
                              count: categoryVideos.length - 5,
                              isLarge: true,
                              onTap: () => _showVideoList(category, categoryVideos),
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: PremiumVideoCard(
                            video: categoryVideos[videoIndex],
                            isLarge: true,
                            onTap: () => _playVideo(categoryVideos[videoIndex]),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32), // Bottom padding
        ],
      ),
    );
  }

  void _showVideoList(String title, List<Video> videos) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    title,
                    style: GoogleFonts.judson(
                      textStyle: const TextStyle(
                        fontSize: 24,
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
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: videos.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return PremiumVideoCard(
                    video: videos[index],
                    isLarge: true,
                    onTap: () {
                      Navigator.pop(context);
                      _playVideo(videos[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
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
}
