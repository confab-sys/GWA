import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mainfeed_screen.dart';
import 'books_screen.dart';
import 'videopodcast_screen.dart';
import 'qa_screen.dart';
import 'settings_screen.dart';
import 'booking_screen.dart';

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

  final List<Map<String, dynamic>> _bottomNavItems = [
    {'title': 'Main Feed', 'icon': Icons.psychology},
    {'title': 'Video Courses', 'icon': Icons.video_library},
    {'title': 'Books', 'icon': Icons.book},
    {'title': 'Q&A', 'icon': Icons.question_answer},
  ];

  @override
  void initState() {
    super.initState();
    print('FeedScreen initState called, _shouldShowSubscriptionPopup: ${FeedScreen._shouldShowSubscriptionPopup}');
    // Show subscription popup only when navigating from login
    if (FeedScreen._shouldShowSubscriptionPopup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('Showing subscription dialog...');
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

  Widget _buildCentralPanelContent() {
    switch (_selectedIndex) {
      case 0:
        return const MainFeedScreen();
      case 1:
        return const VideoPodcastScreen();
      case 2:
        return const BooksScreen();
      case 3:
        return const QAScreen();
      default:
        return Center(
          key: ValueKey<int>(_selectedIndex),
          child: Text(
            _bottomNavItems[_selectedIndex]['title'],
            style: GoogleFonts.judson(
              textStyle: const TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
    }
  }

  void _showNavigationMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Text(
                'Navigation',
                style: GoogleFonts.judson(
                  textStyle: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Navigation options
              ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.black),
                title: Text(
                  'Calendar & Booking',
                  style: GoogleFonts.judson(
                    textStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BookingScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.spa, color: Colors.black),
                title: Text(
                  'Wellness',
                  style: GoogleFonts.judson(
                    textStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Add navigation to wellness screen when available
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.black),
                title: Text(
                  'Settings',
                  style: GoogleFonts.judson(
                    textStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD3E4DE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(
              'assets/images/main logo man.png',
              width: 32,
              height: 32,
            ),
            const SizedBox(width: 8),
            Text(
              'Great Awareness',
              style: GoogleFonts.judson(
                textStyle: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.black),
            tooltip: 'Notifications',
            onPressed: () {
              // Add navigation to notifications screen when available
            },
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            tooltip: 'Navigation Menu',
            onPressed: () {
              _showNavigationMenu();
            },
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeInOutCubic,
        switchOutCurve: Curves.easeInOutCubic.flipped,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        child: _buildCentralPanelContent(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey[600],
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: _bottomNavItems.map((item) {
          return BottomNavigationBarItem(
            icon: Icon(item['icon']),
            label: item['title'],
          );
        }).toList(),
      ),
    );
  }
}