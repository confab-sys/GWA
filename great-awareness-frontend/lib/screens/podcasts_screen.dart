import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

class PodcastsScreen extends StatefulWidget {
  const PodcastsScreen({super.key});

  @override
  State<PodcastsScreen> createState() => _PodcastsScreenState();
}

class _PodcastsScreenState extends State<PodcastsScreen> {
  List<Podcast> allPodcasts = [];
  List<Podcast> filteredPodcasts = [];
  TextEditingController searchController = TextEditingController();
  String selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _initializePodcasts();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _initializePodcasts() {
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
      Podcast(
        id: 'p3',
        title: 'Mindful Recovery',
        subtitle: 'Mindfulness practices for addiction healing',
        category: 'Overcoming Addictions',
        duration: '42:30',
        listenProgress: 75.0,
        thumbnailUrl: 'assets/images/podcast_mindful.jpg',
      ),
      
      // Healing Trauma
      Podcast(
        id: 'p4',
        title: 'Trauma-Informed Therapy',
        subtitle: 'Understanding trauma and healing approaches',
        category: 'Healing Trauma',
        duration: '52:10',
        listenProgress: 60.0,
        thumbnailUrl: 'assets/images/podcast_trauma.jpg',
      ),
      Podcast(
        id: 'p5',
        title: 'Inner Child Healing',
        subtitle: 'Reconnecting with your inner child for healing',
        category: 'Healing Trauma',
        duration: '41:30',
        listenProgress: 100.0,
        thumbnailUrl: 'assets/images/podcast_inner_child.jpg',
      ),
      Podcast(
        id: 'p6',
        title: 'EMDR Insights',
        subtitle: 'Deep dive into EMDR therapy techniques',
        category: 'Healing Trauma',
        duration: '48:45',
        listenProgress: 30.0,
        thumbnailUrl: 'assets/images/podcast_emdr.jpg',
      ),
      
      // Relationships
      Podcast(
        id: 'p7',
        title: 'Healthy Relationship Dynamics',
        subtitle: 'Building strong and supportive relationships',
        category: 'Relationships',
        duration: '35:45',
        listenProgress: 15.0,
        thumbnailUrl: 'assets/images/podcast_relationships.jpg',
      ),
      Podcast(
        id: 'p8',
        title: 'Communication in Marriage',
        subtitle: 'Effective communication strategies for couples',
        category: 'Relationships',
        duration: '48:20',
        listenProgress: 0.0,
        thumbnailUrl: 'assets/images/podcast_marriage.jpg',
      ),
      Podcast(
        id: 'p9',
        title: 'Setting Boundaries',
        subtitle: 'How to establish healthy boundaries in relationships',
        category: 'Relationships',
        duration: '36:15',
        listenProgress: 85.0,
        thumbnailUrl: 'assets/images/podcast_boundaries.jpg',
      ),
      
      // Self-Development
      Podcast(
        id: 'p10',
        title: 'Mindset Transformation',
        subtitle: 'Changing your mindset for personal growth',
        category: 'Self-Development',
        duration: '44:20',
        listenProgress: 45.0,
        thumbnailUrl: 'assets/images/podcast_mindset.jpg',
      ),
      Podcast(
        id: 'p11',
        title: 'Building Confidence',
        subtitle: 'Practical strategies to boost self-confidence',
        category: 'Self-Development',
        duration: '39:50',
        listenProgress: 20.0,
        thumbnailUrl: 'assets/images/podcast_confidence.jpg',
      ),
    ];
    
    filteredPodcasts = List.from(allPodcasts);
  }

  void _onSearchChanged() {
    final query = searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredPodcasts = List.from(allPodcasts);
      } else {
        filteredPodcasts = allPodcasts.where((podcast) {
          return podcast.title.toLowerCase().contains(query) ||
                 podcast.subtitle.toLowerCase().contains(query) ||
                 podcast.category.toLowerCase().contains(query);
        }).toList();
      }
      
      // Filter by category if not 'All'
      if (selectedCategory != 'All') {
        filteredPodcasts = filteredPodcasts.where((podcast) => podcast.category == selectedCategory).toList();
      }
    });
  }

  List<String> get _categories {
    final podcastCategories = allPodcasts.map((podcast) => podcast.category).toSet();
    final allCategories = podcastCategories.toList();
    allCategories.insert(0, 'All');
    return allCategories;
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
          'Podcasts',
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
                    hintText: 'Search podcasts...',
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
            ],
          ),
        ),
      ),
      body: _buildPodcastsContent(),
    );
  }

  Widget _buildPodcastsContent() {
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
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
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
                        color: Colors.grey[600],
                        fontSize: 11,
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
                      // Play/Pause button
                      IconButton(
                        icon: Icon(
                          Icons.play_circle_fill,
                          color: Colors.green[700],
                          size: 28,
                        ),
                        onPressed: () {
                          // Handle play/pause
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      // Action buttons
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              podcast.isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: podcast.isFavorite ? Colors.red : Colors.grey[600],
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                podcast.isFavorite = !podcast.isFavorite;
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              podcast.isSaved ? Icons.bookmark : Icons.bookmark_border,
                              color: podcast.isSaved ? Colors.blue : Colors.grey[600],
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                podcast.isSaved = !podcast.isSaved;
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
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
}