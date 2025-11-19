import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mainfeed_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  // Static flag to track if popup should be shown
  static bool _shouldShowSubscriptionPopup = false;

  // Static method to set flag when navigating from login
  static void setShowSubscriptionPopup(bool show) {
    _shouldShowSubscriptionPopup = show;
  }

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  int _selectedIndex = 0;
  bool _isPanelExpanded = true;

  final List<Map<String, dynamic>> _menuItems = [
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
  void initState() {
    super.initState();
    // Show subscription popup only when navigating from login
    if (FeedScreen._shouldShowSubscriptionPopup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSubscriptionDialog();
        FeedScreen._shouldShowSubscriptionPopup = false; // Reset flag after showing
      });
    }
  }

  void _showSubscriptionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User must make a choice
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white24, width: 1),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  'Great Awareness',
                  style: GoogleFonts.judson(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Main text
                Text(
                  'Great Awareness platform is more than content, it\'s a living ecosystem that demands attention and effort to maintain it. Supporting its upkeep requires a monthly investment of 100ksh, giving you full access to every tool, content and resources. Keeping your path to mastery uninterrupted.',
                  style: GoogleFonts.judson(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ready to join?',
                  style: GoogleFonts.judson(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Not Ready button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showTemporaryAccessDialog();
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Not Ready?',
                          style: GoogleFonts.judson(
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Yes button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showWelcomeDialog();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD3E4DE),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Yes',
                          style: GoogleFonts.judson(
                            textStyle: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTemporaryAccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.white24, width: 1),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your access expires in 30 days',
                  style: GoogleFonts.judson(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD3E4DE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'OK',
                    style: GoogleFonts.judson(
                      textStyle: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showWelcomeDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.white24, width: 1),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome to the journey of self improvement',
                  style: GoogleFonts.judson(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD3E4DE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Get Started',
                    style: GoogleFonts.judson(
                      textStyle: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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