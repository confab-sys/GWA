import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'podcasts_screen.dart';
import 'video_player_screen.dart';
import '../models/video_comment.dart';
import '../services/cloudflare_storage_service.dart';

class Video {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String duration;
  final double watchProgress;
  final String thumbnailUrl;
  final String cloudflareUrl;
  bool isFavorite;
  bool isSaved;
  int likes;
  bool isLiked;
  List<VideoComment> comments;

  Video({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.duration,
    this.watchProgress = 0.0,
    required this.thumbnailUrl,
    required this.cloudflareUrl,
    this.isFavorite = false,
    this.isSaved = false,
    this.likes = 0,
    this.isLiked = false,
    this.comments = const [],
  });
}

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

      print('Loading videos from Cloudflare...');
      // Get videos from Cloudflare - using configured videos directly since we know they work
      final cloudflareVideos = CloudflareStorageService.getConfiguredVideos();
      print('Found ${cloudflareVideos.length} configured videos');
      
      if (cloudflareVideos.isEmpty) {
        print('No videos found in configuration');
        setState(() {
          isLoading = false;
        });
        return;
      }
      
      // Log the first video details for debugging
      if (cloudflareVideos.isNotEmpty) {
        print('First video: ${cloudflareVideos.first.title} - ${cloudflareVideos.first.url}');
      }
      
      // Convert CloudflareVideo objects to Video objects
      final List<Video> loadedVideos = cloudflareVideos.map((cfVideo) => Video(
        id: cfVideo.key.hashCode.toString(),
        title: cfVideo.title,
        subtitle: 'Video from Cloudflare bucket',
        category: cfVideo.category,
        duration: cfVideo.duration,
        watchProgress: 0.0,
        thumbnailUrl: 'assets/images/video_placeholder.jpg', // Default thumbnail
        cloudflareUrl: cfVideo.url,
        likes: 0,
        isLiked: false,
        comments: [],
      )).toList();

      setState(() {
        allVideos = loadedVideos;
        filteredVideos = List.from(allVideos);
        isLoading = false;
      });
      
      print('Successfully loaded ${loadedVideos.length} accessible videos');
      
    } catch (e) {
      // Error loading videos, fallback to default
      print('Error loading videos from Cloudflare: $e');
      setState(() {
        isLoading = false;
      });
      
      // Fallback to default videos if loading fails
      _initializeDefaultVideos();
    }
  }

  void _initializeDefaultVideos() {
    // Sample video data organized by categories with Cloudflare streaming URLs
    allVideos = [
      // Overcoming Addictions
      Video(
        id: '1',
        title: 'Understanding Addiction Psychology',
        subtitle: 'Learn the science behind addictive behaviors',
        category: 'Overcoming Addictions',
        duration: '15:30',
        watchProgress: 45.0,
        thumbnailUrl: 'assets/images/addiction_psychology.jpg',
        cloudflareUrl: 'https://pub-1c8c879e41fe4ff48de96ceabce671a2.r2.dev/understanding-addiction-psychology.mp4',
        likes: 124,
        isLiked: false,
        comments: [
          VideoComment(
            id: 'c1',
            userId: 'user1',
            userName: 'Sarah M.',
            text: 'This video really helped me understand my patterns. Thank you!',
            timestamp: DateTime.now().subtract(const Duration(days: 1)),
          ),
          VideoComment(
            id: 'c2',
            userId: 'user2',
            userName: 'Mike R.',
            text: 'Great insights into the psychology behind addiction.',
            timestamp: DateTime.now().subtract(const Duration(hours: 12)),
          ),
        ],
      ),
      Video(
        id: '2',
        title: 'Breaking Free from Pornography',
        subtitle: 'Practical steps to overcome porn addiction',
        category: 'Overcoming Addictions',
        duration: '22:15',
        watchProgress: 80.0,
        thumbnailUrl: 'assets/images/breaking_free.jpg',
        cloudflareUrl: 'https://pub-1c8c879e41fe4ff48de96ceabce671a2.r2.dev/breaking-free-pornography.mp4',
        likes: 89,
        isLiked: true,
        comments: [
          VideoComment(
            id: 'c3',
            userId: 'user3',
            userName: 'David K.',
            text: 'These practical steps are life-changing.',
            timestamp: DateTime.now().subtract(const Duration(hours: 6)),
          ),
        ],
      ),
      Video(
        id: '3',
        title: 'Building Healthy Habits',
        subtitle: 'Replace bad habits with positive ones',
        category: 'Overcoming Addictions',
        duration: '18:45',
        watchProgress: 0.0,
        thumbnailUrl: 'assets/images/healthy_habits.jpg',
        cloudflareUrl: 'https://pub-1c8c879e41fe4ff48de96ceabce671a2.r2.dev/building-healthy-habits.mp4',
        likes: 156,
        isLiked: false,
        comments: [],
      ),
      
      // Healing Trauma
      Video(
        id: '4',
        title: 'Understanding Childhood Trauma',
        subtitle: 'How early experiences shape adult behavior',
        category: 'Healing Trauma',
        duration: '25:20',
        watchProgress: 30.0,
        thumbnailUrl: 'assets/images/childhood_trauma.jpg',
        cloudflareUrl: 'https://pub-1c8c879e41fe4ff48de96ceabce671a2.r2.dev/understanding-childhood-trauma.mp4',
        likes: 203,
        isLiked: false,
        comments: [
          VideoComment(
            id: 'c4',
            userId: 'user4',
            userName: 'Emma L.',
            text: 'This explained so much about my childhood experiences.',
            timestamp: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ],
      ),
      Video(
        id: '5',
        title: 'EMDR Therapy Explained',
        subtitle: 'Effective trauma processing technique',
        category: 'Healing Trauma',
        duration: '30:10',
        watchProgress: 65.0,
        thumbnailUrl: 'assets/images/emdr_therapy.jpg',
        cloudflareUrl: 'https://pub-1c8c879e41fe4ff48de96ceabce671a2.r2.dev/emdr-therapy-explained.mp4',
        likes: 167,
        isLiked: true,
        comments: [],
      ),
      Video(
        id: '6',
        title: 'Self-Compassion Practices',
        subtitle: 'Healing through kindness to yourself',
        category: 'Healing Trauma',
        duration: '12:30',
        watchProgress: 100.0,
        thumbnailUrl: 'assets/images/self_compassion.jpg',
        cloudflareUrl: 'https://pub-1c8c879e41fe4ff48de96ceabce671a2.r2.dev/self-compassion-practices.mp4',
        likes: 278,
        isLiked: false,
        comments: [
          VideoComment(
            id: 'c5',
            userId: 'user5',
            userName: 'Lisa K.',
            text: 'I practice these daily and they have transformed my life!',
            timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          ),
        ],
      ),
      
      // Relationships
      Video(
        id: '7',
        title: 'Healthy Communication Skills',
        subtitle: 'Build stronger connections with others',
        category: 'Relationships',
        duration: '20:15',
        watchProgress: 15.0,
        thumbnailUrl: 'assets/images/communication.jpg',
        cloudflareUrl: 'https://pub-1c8c879e41fe4ff48de96ceabce671a2.r2.dev/healthy-communication-skills.mp4',
        likes: 145,
        isLiked: false,
        comments: [],
      ),
      Video(
        id: '8',
        title: 'Setting Boundaries',
        subtitle: 'Protect your emotional well-being',
        category: 'Relationships',
        duration: '16:40',
        watchProgress: 0.0,
        thumbnailUrl: 'assets/images/boundaries.jpg',
        cloudflareUrl: 'https://pub-1c8c879e41fe4ff48de96ceabce671a2.r2.dev/setting-boundaries.mp4',
        likes: 98,
        isLiked: false,
        comments: [
          VideoComment(
            id: 'c6',
            userId: 'user6',
            userName: 'Anna P.',
            text: 'Setting boundaries has been crucial for my mental health.',
            timestamp: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ],
      ),
      Video(
        id: '9',
        title: 'Healing from Heartbreak',
        subtitle: 'Moving forward after relationship loss',
        category: 'Relationships',
        duration: '28:50',
        watchProgress: 90.0,
        thumbnailUrl: 'assets/images/heartbreak.jpg',
        cloudflareUrl: 'https://pub-1c8c879e41fe4ff48de96ceabce671a2.r2.dev/healing-from-heartbreak.mp4',
        likes: 234,
        isLiked: true,
        comments: [
          VideoComment(
            id: 'c7',
            userId: 'user7',
            userName: 'Tom W.',
            text: 'This helped me through a very difficult time. Thank you.',
            timestamp: DateTime.now().subtract(const Duration(hours: 8)),
          ),
          VideoComment(
            id: 'c8',
            userId: 'user8',
            userName: 'Rachel S.',
            text: 'The healing process takes time, but this video gives hope.',
            timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          ),
        ],
      ),
    ];
    
    // Sample podcast data organized by categories
    allPodcasts = [
      // Overcoming Addictions
      Podcast(
        id: 'p1',
        title: 'Addiction Recovery Stories',
        subtitle: 'Real stories from people who overcame addiction',
        category: 'Overcoming Addictions',
        duration: '45:20',
        listenProgress: 25.0,
        thumbnailUrl: 'assets/images/podcast_addiction.jpg',
      ),
      Podcast(
        id: 'p2',
        title: 'Breaking the Cycle',
        subtitle: 'Expert advice on addiction recovery',
        category: 'Overcoming Addictions',
        duration: '38:15',
        listenProgress: 0.0,
        thumbnailUrl: 'assets/images/podcast_cycle.jpg',
      ),
      
      // Healing Trauma
      Podcast(
        id: 'p3',
        title: 'Trauma-Informed Therapy',
        subtitle: 'Understanding trauma and healing approaches',
        category: 'Healing Trauma',
        duration: '52:10',
        listenProgress: 60.0,
        thumbnailUrl: 'assets/images/podcast_trauma.jpg',
      ),
      Podcast(
        id: 'p4',
        title: 'Inner Child Healing',
        subtitle: 'Reconnecting with your inner child for healing',
        category: 'Healing Trauma',
        duration: '41:30',
        listenProgress: 100.0,
        thumbnailUrl: 'assets/images/podcast_inner_child.jpg',
      ),
      
      // Relationships
      Podcast(
        id: 'p5',
        title: 'Healthy Relationship Dynamics',
        subtitle: 'Building strong and supportive relationships',
        category: 'Relationships',
        duration: '35:45',
        listenProgress: 15.0,
        thumbnailUrl: 'assets/images/podcast_relationships.jpg',
      ),
      Podcast(
        id: 'p6',
        title: 'Communication in Marriage',
        subtitle: 'Effective communication strategies for couples',
        category: 'Relationships',
        duration: '48:20',
        listenProgress: 0.0,
        thumbnailUrl: 'assets/images/podcast_marriage.jpg',
      ),
    ];
    
    filteredVideos = List.from(allVideos);
    filteredPodcasts = List.from(allPodcasts);
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
                 video.subtitle.toLowerCase().contains(query) ||
                 video.category.toLowerCase().contains(query);
        }).toList();
        
        filteredPodcasts = allPodcasts.where((podcast) {
          return podcast.title.toLowerCase().contains(query) ||
                 podcast.subtitle.toLowerCase().contains(query) ||
                 podcast.category.toLowerCase().contains(query);
        }).toList();
      }
      
      // Filter by category if not 'All'
      if (selectedCategory != 'All') {
        filteredVideos = filteredVideos.where((video) => video.category == selectedCategory).toList();
        filteredPodcasts = filteredPodcasts.where((podcast) => podcast.category == selectedCategory).toList();
      }
    });
  }

  List<String> get _categories {
    final videoCategories = allVideos.map((video) => video.category).toSet();
    final podcastCategories = allPodcasts.map((podcast) => podcast.category).toSet();
    final allCategories = videoCategories.union(podcastCategories).toList();
    allCategories.insert(0, 'All');
    return allCategories;
  }

  Map<String, List<Video>> get _videosByCategory {
    final Map<String, List<Video>> grouped = {};
    for (final video in filteredVideos) {
      grouped.putIfAbsent(video.category, () => []).add(video);
    }
    return grouped;
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
              'Loading videos from Cloudflare...',
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
          'No videos found in your Cloudflare bucket',
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
            builder: (context) => VideoPlayerScreen(
              videoUrl: video.cloudflareUrl,
              title: video.title,
              subtitle: video.subtitle,
              initialLikes: video.likes,
              initialIsLiked: video.isLiked,
              initialComments: video.comments,
              onLikeChanged: (likes, isLiked) {
                setState(() {
                  video.likes = likes;
                  video.isLiked = isLiked;
                });
              },
              onCommentAdded: (comment) {
                setState(() {
                  video.comments.add(comment);
                });
              },
            ),
          ),
        );
      },
      child: Container(
        width: 160,
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
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  image: DecorationImage(
                    image: AssetImage(video.thumbnailUrl),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {
                      // Fallback to icon if image fails to load
                    },
                  ),
                ),
                child: video.thumbnailUrl.contains('assets/images/')
                    ? Center(
                        child: Icon(
                          Icons.play_circle_outline,
                          size: 40,
                          color: Colors.grey[600],
                        ),
                      )
                    : null,
              ),
              // Duration badge
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
                    video.duration,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Watch progress indicator
              if (video.watchProgress > 0)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: video.watchProgress.round(),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: (100 - video.watchProgress).round(),
                          child: const SizedBox(),
                        ),
                      ],
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
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Subtitle
                  Text(
                    video.subtitle,
                    style: GoogleFonts.judson(
                      textStyle: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Favorite button
                      IconButton(
                        icon: Icon(
                          video.isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: video.isFavorite ? Colors.red : Colors.grey[600],
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            video.isFavorite = !video.isFavorite;
                          });
                        },
                      ),
                      // Save button
                      IconButton(
                        icon: Icon(
                          video.isSaved ? Icons.bookmark : Icons.bookmark_border,
                          size: 16,
                          color: video.isSaved ? Colors.blue : Colors.grey[600],
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            video.isSaved = !video.isSaved;
                          });
                        },
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