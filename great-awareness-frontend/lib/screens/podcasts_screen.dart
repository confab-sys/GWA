import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/podcast.dart';
import '../services/podcast_service.dart';

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
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPodcasts();
    searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadPodcasts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final podcasts = await PodcastService.getPodcasts();
      setState(() {
        allPodcasts = podcasts;
        filteredPodcasts = podcasts;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load podcasts. Please try again later.';
      });
      print('Error loading podcasts: $e');
    }
  }


  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    filterPodcasts(selectedCategory);
  }

  void filterPodcasts(String category) {
    setState(() {
      selectedCategory = category;
      filteredPodcasts = allPodcasts.where((podcast) {
        final matchesCategory = category == 'All' || podcast.category == category;
        final matchesSearch = podcast.title.toLowerCase().contains(searchController.text.toLowerCase()) ||
            podcast.subtitle.toLowerCase().contains(searchController.text.toLowerCase());
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [const Color(0xFF1A1A1A), const Color(0xFF000000)]
                : [const Color(0xFFF5F5F5), const Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isDarkMode),
              _buildSearchBar(isDarkMode),
              _buildCategories(isDarkMode),
              Expanded(
                child: isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : errorMessage != null
                        ? Center(child: Text(errorMessage!, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)))
                        : filteredPodcasts.isEmpty
                            ? Center(child: Text('No podcasts found', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)))
                            : _buildPodcastsList(isDarkMode),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        'Podcasts',
        style: GoogleFonts.judson(
          textStyle: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Search podcasts...',
          hintStyle: GoogleFonts.judson(
            textStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
          ),
          prefixIcon: Icon(Icons.search, color: isDarkMode ? Colors.white : Colors.black),
          filled: true,
          fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: isDarkMode ? Colors.white : Colors.black),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: GoogleFonts.judson(
          textStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildCategories(bool isDarkMode) {
    final categories = ['All', ...allPodcasts.map((e) => e.category).toSet().toList()];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: categories.map((category) {
          final isSelected = selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                category,
                style: GoogleFonts.judson(
                  textStyle: TextStyle(
                    color: isSelected 
                        ? (isDarkMode ? Colors.black : Colors.white)
                        : (isDarkMode ? Colors.white : Colors.black),
                    fontSize: 12,
                  ),
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  filterPodcasts(category);
                }
              },
              backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
              selectedColor: isDarkMode ? Colors.white : Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPodcastsList(bool isDarkMode) {
    // Group podcasts by category if "All" is selected, otherwise just show list
    if (selectedCategory != 'All') {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: filteredPodcasts.length,
        itemBuilder: (context, index) {
          return _buildEnhancedPodcastCard(filteredPodcasts[index], isDarkMode);
        },
      );
    }

    final podcastsByCategory = <String, List<Podcast>>{};
    for (var podcast in filteredPodcasts) {
      if (!podcastsByCategory.containsKey(podcast.category)) {
        podcastsByCategory[podcast.category] = [];
      }
      podcastsByCategory[podcast.category]!.add(podcast);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: podcastsByCategory.keys.length,
      itemBuilder: (context, index) {
        final category = podcastsByCategory.keys.elementAt(index);
        final podcasts = podcastsByCategory[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                category,
                style: GoogleFonts.judson(
                  textStyle: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: podcasts.length,
                itemBuilder: (context, i) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _buildEnhancedPodcastCard(podcasts[i], isDarkMode),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildEnhancedPodcastCard(Podcast podcast, bool isDarkMode) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
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
          // Podcast thumbnail
          Stack(
            children: [
              Container(
                height: 90,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: podcast.thumbnailUrl.isNotEmpty
                      ? Image.network(
                          podcast.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.podcasts,
                              size: 40,
                              color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
                            );
                          },
                        )
                      : Icon(
                          Icons.podcasts,
                          size: 40,
                          color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
                        ),
                ),
              ),
              if (podcast.duration.isNotEmpty)
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
            ],
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    podcast.title,
                    style: GoogleFonts.judson(
                      textStyle: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    podcast.subtitle.isNotEmpty ? podcast.subtitle : podcast.description,
                    style: GoogleFonts.judson(
                      textStyle: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.play_circle_fill,
                          color: Colors.green[700],
                          size: 28,
                        ),
                        onPressed: () {
                          // TODO: Implement audio player
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Audio player coming soon')),
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              podcast.isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: podcast.isFavorite ? Colors.red : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
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