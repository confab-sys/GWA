import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VideoPodcastScreen extends StatefulWidget {
  const VideoPodcastScreen({super.key});

  @override
  State<VideoPodcastScreen> createState() => _VideoPodcastScreenState();
}

class _VideoPodcastScreenState extends State<VideoPodcastScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.black,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey[600],
          tabs: const [
            Tab(text: 'Videos'),
            Tab(text: 'Podcasts'),
          ],
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
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        return _buildVideoCard(index);
      },
    );
  }

  Widget _buildPodcastsTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 10,
      itemBuilder: (context, index) {
        return _buildPodcastCard(index);
      },
    );
  }

  Widget _buildVideoCard(int index) {
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
          // Video thumbnail
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Center(
              child: Icon(
                Icons.play_circle_outline,
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
                    'Video ${index + 1}',
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
                    'Psychology',
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

  Widget _buildActionButton(IconData icon, String tooltip) {
    return IconButton(
      icon: Icon(icon, size: 20, color: Colors.grey[700]),
      tooltip: tooltip,
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