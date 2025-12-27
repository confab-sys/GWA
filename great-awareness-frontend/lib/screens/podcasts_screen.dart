import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/podcast.dart';
import '../services/podcast_service.dart';
import '../services/auth_service.dart';
import 'upload_podcast_screen.dart';
import 'podcast_player_screen.dart';

class PodcastsScreen extends StatefulWidget {
  const PodcastsScreen({super.key});

  @override
  State<PodcastsScreen> createState() => _PodcastsScreenState();
}

class _PodcastsScreenState extends State<PodcastsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PodcastService _podcastService = PodcastService();
  List<Podcast> allPodcasts = [];
  List<Podcast> filteredPodcasts = [];
  TextEditingController searchController = TextEditingController();
  String selectedCategory = 'All';
  bool isLoading = true;
  String? errorMessage;

  // Audio Player State
  VideoPlayerController? _audioController;
  final ValueNotifier<VideoPlayerController?> _controllerNotifier = ValueNotifier(null);
  String? _currentPlayingPodcastId;
  bool _isPlaying = false;
  bool _isPlayerLoading = false;

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

  Future<String> _getLocalFilePath(String filename) async {
    if (kIsWeb) return ''; // Should not be called on web
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$filename';
  }

  Future<void> _playPodcast(Podcast podcast) async {
    // If clicking the same podcast that is currently playing
    if (_currentPlayingPodcastId == podcast.id) {
      if (_audioController != null) {
        if (_audioController!.value.isPlaying) {
          await _audioController!.pause();
          setState(() {
            _isPlaying = false;
          });
        } else {
          await _audioController!.play();
          setState(() {
            _isPlaying = true;
          });
        }
      }
      return;
    }

    // Stop and dispose current controller if exists
    if (_audioController != null) {
      await _audioController!.pause();
      // Don't await dispose to make UI snappier, let it happen in background
      final oldController = _audioController;
      _audioController = null;
      _controllerNotifier.value = null;
      oldController?.dispose();
    }

    setState(() {
      _isPlayerLoading = true;
      _currentPlayingPodcastId = podcast.id;
      _isPlaying = false;
    });

    try {
      final filename = '${podcast.id}.m4a';
      bool isDownloaded = false;
      String? localPath;

      if (!kIsWeb) {
        localPath = await _getLocalFilePath(filename);
        isDownloaded = await File(localPath).exists();
      }

      if (isDownloaded && localPath != null) {
        print('Playing from local file: $localPath');
        _audioController = VideoPlayerController.file(File(localPath));
      } else {
        String audioUrl = podcast.audioUrl;
        if (audioUrl.isEmpty) {
          throw Exception('No audio URL available');
        }
        print('Playing from network: $audioUrl');
        _audioController = VideoPlayerController.networkUrl(Uri.parse(audioUrl));
      }
      _controllerNotifier.value = _audioController;
      
      // Initialize properly
      await _audioController!.initialize();
      
      // Only play if we are still trying to play THIS podcast (avoid race conditions)
      if (_currentPlayingPodcastId == podcast.id) {
        await _audioController!.play();
        
        // Update state when playback status changes
        _audioController!.addListener(() {
          if (mounted && _currentPlayingPodcastId == podcast.id) {
            final isPlaying = _audioController!.value.isPlaying;
            if (isPlaying != _isPlaying) {
              setState(() {
                _isPlaying = isPlaying;
              });
            }
            // Handle completion
            if (_audioController!.value.position >= _audioController!.value.duration && _audioController!.value.duration > Duration.zero) {
              setState(() {
                _isPlaying = false;
                // Don't reset ID so mini player stays visible
              });
            }
          }
        });

        setState(() {
          _isPlaying = true;
          _isPlayerLoading = false;
        });
        
        // Show a mini player bottom sheet or snackbar
        if (mounted) {
          _showMiniPlayer(context, podcast);
        }
      } else {
         // User switched while loading
         _audioController?.dispose();
      }

    } catch (e) {
      print('Error playing podcast: $e');
      if (mounted && _currentPlayingPodcastId == podcast.id) {
        setState(() {
          _isPlayerLoading = false;
          _currentPlayingPodcastId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to play audio: $e')),
        );
      }
    }
  }

  void _openPlayerScreen(BuildContext context, Podcast podcast) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PodcastPlayerScreen(
          podcast: podcast,
          controllerNotifier: _controllerNotifier,
          onPlayPause: () => _playPodcast(podcast),
          onSeek: (pos) => _audioController?.seekTo(pos),
          onClose: () => Navigator.pop(context),
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _showMiniPlayer(BuildContext context, Podcast podcast) {
    _scaffoldKey.currentState?.showBottomSheet(
      enableDrag: false, // Handle drag manually via tap
      (context) {
        return GestureDetector(
          onTap: () => _openPlayerScreen(context, podcast),
          child: Container(
            height: 80,
            color: const Color(0xFF1A1A1A), // Dark background for contrast
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    podcast.thumbnailUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      width: 50, 
                      height: 50, 
                      color: Colors.grey, 
                      child: const Icon(Icons.music_note)
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        podcast.title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        podcast.subtitle,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
                  color: Colors.white,
                  iconSize: 40,
                  onPressed: () {
                     _playPodcast(podcast);
                     // Refresh bottom sheet state
                     (context as Element).markNeedsBuild();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  color: Colors.white,
                  onPressed: () {
                    _audioController?.pause();
                    _audioController?.dispose();
                    _audioController = null;
                    setState(() {
                      _currentPlayingPodcastId = null;
                      _isPlaying = false;
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    _audioController?.dispose();
    _controllerNotifier.dispose();
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
    final isAdmin = Provider.of<AuthService>(context, listen: false).isAdmin;

    return Scaffold(
      key: _scaffoldKey,
      floatingActionButton: isAdmin ? FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UploadPodcastScreen()),
          );
          if (result == true) {
            _loadPodcasts();
          }
        },
        label: const Text('Upload'),
        icon: const Icon(Icons.upload),
        backgroundColor: isDarkMode ? Colors.white : Colors.black,
        foregroundColor: isDarkMode ? Colors.black : Colors.white,
      ) : null,
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
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            'Podcasts',
            style: GoogleFonts.judson(
              textStyle: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
    return GestureDetector(
      onTap: () => _openPlayerScreen(context, podcast),
      child: Container(
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
                Hero(
                  tag: podcast.id,
                  child: Container(
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
                        // Play Button
                        if (_isPlayerLoading && _currentPlayingPodcastId == podcast.id)
                          const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          IconButton(
                            icon: Icon(
                              _currentPlayingPodcastId == podcast.id && _isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled,
                              color: Colors.green[700],
                              size: 28,
                            ),
                            onPressed: () {
                              _openPlayerScreen(context, podcast);
                              if (_currentPlayingPodcastId != podcast.id || !_isPlaying) {
                                _playPodcast(podcast);
                              }
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
      ),
    );
  }

}