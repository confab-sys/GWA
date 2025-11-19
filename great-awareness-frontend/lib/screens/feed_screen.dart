import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mainfeed_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  int _selectedIndex = 0;
  bool _isPanelExpanded = true;

  final List<Map<String, dynamic>> _menuItems = [
    {'title': 'Home Feed', 'subtitle': 'Mental health & updates', 'icon': Icons.home},
    {'title': 'Main Feed', 'subtitle': 'Psychology topics & discussions', 'icon': Icons.psychology},
    {'title': 'Books', 'subtitle': 'Read books', 'icon': Icons.book},
    {'title': 'Podcast Space', 'subtitle': 'Listen to latest podcasts', 'icon': Icons.podcasts},
    {'title': 'Video Courses', 'subtitle': 'Watch latest video courses', 'icon': Icons.video_library},
    {'title': 'Q & A Blogs', 'subtitle': 'Get answers asked by community', 'icon': Icons.question_answer},
    {'title': 'Wellness Apps', 'subtitle': 'Discover apps to boost productivity', 'icon': Icons.health_and_safety},
    {'title': 'Therapy Booking', 'subtitle': 'Book therapy sessions', 'icon': Icons.calendar_today},
    {'title': 'Settings', 'subtitle': 'App preferences', 'icon': Icons.settings},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD3E4DE),
      body: Row(
        children: [
          // Left Panel
          Container(
            width: _isPanelExpanded ? 250 : 70,
            color: Colors.white,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.black12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: _isPanelExpanded 
                      ? MainAxisAlignment.spaceBetween 
                      : MainAxisAlignment.center,
                    children: [
                      if (_isPanelExpanded) ...[
                        Image.asset(
                          'assets/images/main logo man.png',
                          width: 40,
                          height: 40,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Great Awareness',
                            style: GoogleFonts.judson(
                              textStyle: const TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.menu_open,
                            color: Colors.black,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPanelExpanded = !_isPanelExpanded;
                            });
                          },
                        ),
                      ] else ...[
                        Image.asset(
                          'assets/images/main logo man.png',
                          width: 30,
                          height: 30,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.menu,
                            color: Colors.black,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPanelExpanded = !_isPanelExpanded;
                            });
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ],
                  ),
                ),
                // Menu Items
                Expanded(
                  child: ListView.builder(
                    itemCount: _menuItems.length,
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 12, 
                            horizontal: _isPanelExpanded ? 16 : 8
                          ),
                          color: _selectedIndex == index 
                            ? const Color(0xFFD3E4DE).withValues(alpha: 0.3)
                            : Colors.transparent,
                          child: Row(
                            children: [
                              Icon(
                                _menuItems[index]['icon'],
                                color: _selectedIndex == index ? Colors.black : Colors.grey[600],
                                size: 24,
                              ),
                              if (_isPanelExpanded) ...[
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _menuItems[index]['title'],
                                        style: GoogleFonts.judson(
                                          textStyle: TextStyle(
                                            color: _selectedIndex == index ? Colors.black : Colors.grey[600],
                                            fontSize: 16,
                                            fontWeight: _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _menuItems[index]['subtitle'],
                                        style: GoogleFonts.judson(
                                          textStyle: TextStyle(
                                            color: _selectedIndex == index ? Colors.grey[700] : Colors.grey[500],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Central Panel
          Expanded(
            child: Container(
              color: const Color(0xFFD3E4DE),
              child: _selectedIndex == 0 
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/main logo man.png',
                          width: 80,
                          height: 80,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Great Awareness',
                          style: GoogleFonts.judson(
                            textStyle: const TextStyle(
                              color: Colors.black,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mental health & updates',
                          style: GoogleFonts.judson(
                            textStyle: const TextStyle(
                              color: Colors.black54,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    )
                  : _selectedIndex == 1
                      ? const MainFeedScreen()
                      : Center(
                          child: Text(
                            _menuItems[_selectedIndex]['title'],
                            style: GoogleFonts.judson(
                              textStyle: const TextStyle(
                                color: Colors.black,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                          ),
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}