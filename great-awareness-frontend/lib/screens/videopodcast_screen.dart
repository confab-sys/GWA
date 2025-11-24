import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Video {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String duration;
  final double watchProgress;
  final String thumbnailUrl;
  bool isFavorite;
  bool isSaved;

  Video({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.duration,
    this.watchProgress = 0.0,
    required this.thumbnailUrl,
    this.isFavorite = false,
    this.isSaved = false,
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeVideos();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _initializeVideos() {
    // Sample video data organized by categories
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
      ),
      Video(
        id: '2',
        title: 'Breaking Free from Pornography',
        subtitle: 'Practical steps to overcome porn addiction',
        category: 'Overcoming Addictions',
        duration: '22:15',
        watchProgress: 80.0,
        thumbnailUrl: 'assets/images/breaking_free.jpg',
      ),
      Video(
        id: '3',
        title: 'Building Healthy Habits',
        subtitle: 'Replace bad habits with positive ones',
        category: 'Overcoming Addictions',
        duration: '18:45',
        watchProgress: 0.0,
        thumbnailUrl: 'assets/images/healthy_habits.jpg',
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
      ),
      Video(
        id: '5',
        title: 'EMDR Therapy Explained',
        subtitle: 'Effective trauma processing technique',
        category: 'Healing Trauma',
        duration: '30:10',
        watchProgress: 65.0,
        thumbnailUrl: 'assets/images/emdr_therapy.jpg',
      ),
      Video(
        id: '6',
        title: 'Self-Compassion Practices',
        subtitle: 'Healing through kindness to yourself',
        category: 'Healing Trauma',
        duration: '12:30',
        watchProgress: 100.0,
        thumbnailUrl: 'assets/images/self_compassion.jpg',
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
      ),
      Video(
        id: '8',
        title: 'Setting Boundaries',
        subtitle: 'Protect your emotional well-being',
        category: 'Relationships',
        duration: '16:40',
        watchProgress: 0.0,
        thumbnailUrl: 'assets/images/boundaries.jpg',
      ),
      Video(
        id: '9',
        title: 'Healing from Heartbreak',
        subtitle: 'Moving forward after relationship loss',
        category: 'Relationships',
        duration: '28:50',
        watchProgress: 90.0,
        thumbnailUrl: 'assets/images/heartbreak.jpg',
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

  Map<String, List<Podcast>> get _podcastsByCategory {
    final Map<String, List<Podcast>> grouped = {};
    for (final podcast in filteredPodcasts) {
      grouped.putIfAbsent(podcast.category, () => []).add(podcast);
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
    
    if (filteredVideos.isEmpty) {
      return Center(
        child: Text(
          'No videos found',
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
    final podcastsByCategory = _podcastsByCategory;
    
    if (filteredPodcasts.isEmpty) {
      return Center(
        child: Text(
          'No podcasts found',
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
      itemCount: podcastsByCategory.keys.length,
      itemBuilder: (context, categoryIndex) {
        final category = podcastsByCategory.keys.elementAt(categoryIndex);
        final podcasts = podcastsByCategory[category]!;
        
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
            // Podcasts Row
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: podcasts.length,
                itemBuilder: (context, podcastIndex) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _buildEnhancedPodcastCard(podcasts[podcastIndex]),
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

  Widget _buildEnhancedVideoCard(Video video) {
    return Container(
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
    );
  }

  Widget _buildEnhancedPodcastCard(Podcast podcast) {
    return Container(
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
          // Podcast thumbnail with progress
          Stack(
            children: [
              Container(
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  image: DecorationImage(
                    image: AssetImage(podcast.thumbnailUrl),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {
                      // Fallback to icon if image fails to load
                    },
                  ),
                ),
                child: podcast.thumbnailUrl.contains('assets/images/')
                    ? Center(
                        child: Icon(
                          Icons.podcasts,
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
                    podcast.duration,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Listen progress indicator
              if (podcast.listenProgress > 0)
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
                          flex: podcast.listenProgress.round(),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: (100 - podcast.listenProgress).round(),
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
                    podcast.title,
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
                    podcast.subtitle,
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
                          podcast.isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: podcast.isFavorite ? Colors.red : Colors.grey[600],
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            podcast.isFavorite = !podcast.isFavorite;
                          });
                        },
                      ),
                      // Save button
                      IconButton(
                        icon: Icon(
                          podcast.isSaved ? Icons.bookmark : Icons.bookmark_border,
                          size: 16,
                          color: podcast.isSaved ? Colors.blue : Colors.grey[600],
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            podcast.isSaved = !podcast.isSaved;
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