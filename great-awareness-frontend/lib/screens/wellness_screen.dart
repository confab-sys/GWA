import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'wellness_dashboard.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class WellnessScreen extends StatefulWidget {
  const WellnessScreen({super.key});

  @override
  State<WellnessScreen> createState() => _WellnessScreenState();
}

class WellnessIntroSlide {
  final String title;
  final String subtitle;
  final String lottieAsset;

  WellnessIntroSlide({
    required this.title,
    required this.subtitle,
    required this.lottieAsset,
  });
}

class _WellnessScreenState extends State<WellnessScreen> {
  DateTime? _habitStartTime;
  int _userDayStatus = 0;
  bool _isTrackingActive = false;
  bool _showIntro = true; // New state to toggle intro sequence
  String? _selectedAddictionType;
  String _customAddictionType = '';
  final TextEditingController _customAddictionController = TextEditingController();
  
  // Carousel controllers
  final PageController _pageController = PageController();
  int _currentSlide = 0;

  final List<String> _predefinedAddictions = [
    'Masturbation',
    'Alcoholism',
    'Smoking',
    'Gambling',
    'Social Media',
    'Other (Custom)'
  ];
  
  final List<Map<String, dynamic>> _wellnessUsers = [
    {
      'username': 'John_Doe',
      'dayStatus': 45,
      'habitStart': DateTime.now().subtract(const Duration(days: 45)),
      'avatar': 'assets/images/logo man.png',
    },
    {
      'username': 'Sarah_Smith',
      'dayStatus': 23,
      'habitStart': DateTime.now().subtract(const Duration(days: 23)),
      'avatar': 'assets/images/logo man 2.png',
    },
    {
      'username': 'Mike_Johnson',
      'dayStatus': 67,
      'habitStart': DateTime.now().subtract(const Duration(days: 67)),
      'avatar': 'assets/images/main logo man.png',
    },
  ];

  final List<WellnessIntroSlide> _slides = [
    WellnessIntroSlide(
      title: "Great Awareness Tracking App",
      subtitle: "Monitor your thoughts, moods, and habits effortlessly.",
      lottieAsset: "assets/animations/meditation.json",
    ),
    WellnessIntroSlide(
      title: "Track Your Recovery Journey",
      subtitle: "See your daily improvements and celebrate small wins.",
      lottieAsset: "assets/animations/recovery_path.json",
    ),
    WellnessIntroSlide(
      title: "Stay Motivated Every Day",
      subtitle: "Receive reminders, insights, and gentle nudges to keep moving forward.",
      lottieAsset: "assets/animations/celebration.json",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _customAddictionController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;
    
    if (currentUser != null) {
      // Simulate data loading
      setState(() {
        _userDayStatus = 15;
        _habitStartTime = DateTime.now().subtract(const Duration(days: 15));
        
        // For demonstration, we'll assume tracking is NOT active initially
        // so the user can see the intro sequence.
        // In a real app, check DB: if user has active habit -> _isTrackingActive = true;
        _isTrackingActive = false; // Changed to false to show intro by default
        
        // If tracking was active, we would skip intro
        if (_isTrackingActive) {
          _showIntro = false;
        } else {
          _showIntro = true;
        }

        _selectedAddictionType = 'Masturbation'; 
      });
    }
  }

  void _startHabitTracking() {
    if (_selectedAddictionType == null || _selectedAddictionType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select an addiction type first'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      _habitStartTime = DateTime.now();
      _isTrackingActive = true;
      _userDayStatus = 0;
      _showIntro = false; // Ensure intro is hidden
    });
  }

  void _finishIntro() {
    setState(() {
      _showIntro = false;
    });
  }

  void _updateDayStatus(int newDay) {
    setState(() {
      _userDayStatus = newDay;
    });
  }

  String _formatDuration(Duration duration) {
    int years = duration.inDays ~/ 365;
    int months = (duration.inDays % 365) ~/ 30;
    int days = (duration.inDays % 365) % 30;
    int hours = duration.inHours % 24;
    int minutes = duration.inMinutes % 60;
    int seconds = duration.inSeconds % 60;

    if (years > 0) {
      return '${years}y ${months}m ${days}d ${hours}h ${minutes}m ${seconds}s';
    } else if (months > 0) {
      return '${months}m ${days}d ${hours}h ${minutes}m ${seconds}s';
    } else if (days > 0) {
      return '${days}d ${hours}h ${minutes}m ${seconds}s';
    } else {
      return '${hours}h ${minutes}m ${seconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _showIntro ? null : AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Wellness Journey',
          style: TextStyle(
            color: theme.appBarTheme.foregroundColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: FaIcon(FontAwesomeIcons.arrowLeft, color: theme.appBarTheme.foregroundColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _showIntro 
          ? _buildIntroSequence(theme) 
          : _buildTrackingDashboard(theme),
    );
  }

  Widget _buildIntroSequence(ThemeData theme) {
    return SafeArea(
      child: Column(
        children: [
          // Header with Skip
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.close, color: theme.iconTheme.color),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton(
                  onPressed: _finishIntro,
                  child: Text(
                    'Skip',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Page View
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentSlide = index;
                });
              },
              itemCount: _slides.length,
              itemBuilder: (context, index) {
                return _buildIntroSlide(_slides[index], theme);
              },
            ),
          ),

          // Bottom Controls
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Indicators
                Row(
                  children: List.generate(
                    _slides.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 8),
                      height: 8,
                      width: _currentSlide == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentSlide == index
                            ? theme.primaryColor
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

                // Next/Get Started Button
                ElevatedButton(
                  onPressed: () {
                    if (_currentSlide < _slides.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _finishIntro();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: Text(
                    _currentSlide == _slides.length - 1 ? 'Get Started' : 'Next',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroSlide(WellnessIntroSlide slide, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Title on Top
          Padding(
            padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
            child: Text(
              slide.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.judson(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
                height: 1.2,
              ),
            ),
          ),

          // Illustration
          Expanded(
            child: Container(
              alignment: Alignment.center,
              child: Lottie.asset(
                slide.lottieAsset,
                fit: BoxFit.contain,
                frameRate: FrameRate.max,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('Lottie Load Error: $error');
                  return Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.broken_image,
                      size: 80,
                      color: theme.primaryColor.withValues(alpha: 0.5),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Subtitle
          Padding(
            padding: const EdgeInsets.only(top: 20.0, bottom: 40.0),
            child: Text(
              slide.subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingDashboard(ThemeData theme) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: WellnessDashboard(
        currentUser: currentUser,
        habitStartTime: _habitStartTime,
        addictionType: _selectedAddictionType ?? 'Habit',
        currentStreakDays: _userDayStatus,
      ),
    );
  }
}
