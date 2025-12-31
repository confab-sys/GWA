import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user.dart';
import '../widgets/recovery_timer.dart';
import '../services/wellness_service.dart';
import '../services/auth_service.dart';
import 'events_screen.dart';
import 'wellness_chats_screen.dart';

// Helper to resolve dynamic icons to constants for tree-shaking
IconData _resolveIcon(int code) {
  const Map<int, IconData> iconMap = {
    0xf4d8: FontAwesomeIcons.seedling,      // seedling
    0xf784: FontAwesomeIcons.calendarWeek,  // calendarWeek
    0xf554: FontAwesomeIcons.personWalking, // personWalking
    0xf5a2: FontAwesomeIcons.medal,         // medal
    0xf005: FontAwesomeIcons.star,          // star
    0xf4c9: FontAwesomeIcons.shieldHeart,   // shieldHeart
    0xf091: FontAwesomeIcons.trophy,        // trophy
  };
  return iconMap[code] ?? FontAwesomeIcons.seedling;
}

class WellnessDashboard extends StatefulWidget {
  final User? currentUser;

  const WellnessDashboard({
    super.key,
    required this.currentUser,
  });

  @override
  State<WellnessDashboard> createState() => _WellnessDashboardState();
}

class _WellnessDashboardState extends State<WellnessDashboard> {
  int _selectedIndex = 0; // 0: Home (Videos), 1: Achievements, 2: Community, 3: Events
  WellnessStatus? _status;
  bool _isLoading = true;
  List<CommunityMember> _communityMembers = [];
  List<WellnessResource> _resources = [];
  List<Milestone> _milestones = [];
  
  late WellnessService _wellnessService;

  final List<String> _menuItems = ['Home', 'Achievements', 'Community', 'Events'];
  final List<IconData> _menuIcons = [
    FontAwesomeIcons.house,
    FontAwesomeIcons.trophy,
    FontAwesomeIcons.users,
    FontAwesomeIcons.calendarDay,
  ];

  @override
  void initState() {
    super.initState();
    _wellnessService = WellnessService(context.read<AuthService>());
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final status = await _wellnessService.getStatus();
      final resources = await _wellnessService.getResources();
      final milestonesData = await _wellnessService.getMilestones();
      
      setState(() {
        _status = status;
        _resources = resources;
        _milestones = milestonesData['milestones'] as List<Milestone>;
      });
      
      if (_selectedIndex == 2) { // Load community if tab selected
        _loadCommunity();
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCommunity() async {
    final members = await _wellnessService.getCommunity();
    setState(() => _communityMembers = members);
  }

  Future<void> _handleJoin(String addictionType) async {
    try {
      await _wellnessService.joinProgram(addictionType);
      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _handleReset() async {
    try {
      await _wellnessService.resetTimer();
      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }


  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final theme = Theme.of(context);

    // Wrap the entire dashboard in the WellnessService provider
    // so that child widgets (like EventsScreen) can access it.
    return ChangeNotifierProvider.value(
      value: _wellnessService,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        drawer: !isDesktop ? _buildNavigationDrawer(theme) : null,
        appBar: !isDesktop
            ? AppBar(
                backgroundColor: theme.scaffoldBackgroundColor,
                elevation: 0,
                iconTheme: IconThemeData(color: theme.primaryColor),
                title: Text(
                  _menuItems[_selectedIndex],
                  style: GoogleFonts.judson(
                    color: theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
              )
            : null,
        body: Row(
          children: [
            // Left Navigation Panel (Desktop only)
            if (isDesktop) _buildSidePanel(theme),

            // Main Content Area
            Expanded(
              child: Column(
                children: [
                  // Top Bar (Profile & Timer)
                  _buildTopBar(theme),

                  // Dynamic Content
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _buildContent(theme),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidePanel(ThemeData theme) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // App Logo/Title
          Text(
            'Wellness',
            style: GoogleFonts.judson(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 40),
          
          // Profile Placeholder
          CircleAvatar(
            radius: 35,
            backgroundColor: theme.primaryColor.withOpacity(0.1),
            child: FaIcon(FontAwesomeIcons.user, color: theme.primaryColor, size: 30),
          ),
          const SizedBox(height: 10),
          Text(
            widget.currentUser?.name ?? 'Guest User',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          Text(
            '${_status?.streakDays ?? 0} Day Streak',
            style: GoogleFonts.inter(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          
          const SizedBox(height: 40),
          
          // Menu Items
          Expanded(
            child: ListView.separated(
              itemCount: _menuItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final isSelected = _selectedIndex == index;
                return _buildMenuItem(theme, index, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationDrawer(ThemeData theme) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: theme.primaryColor),
            accountName: Text(widget.currentUser?.name ?? 'Guest User'),
            accountEmail: Text('${_status?.streakDays ?? 0} Day Streak'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: FaIcon(FontAwesomeIcons.user, color: theme.primaryColor),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: FaIcon(
                    _menuIcons[index],
                    color: _selectedIndex == index ? theme.primaryColor : Colors.grey,
                  ),
                  title: Text(
                    _menuItems[index],
                    style: GoogleFonts.inter(
                      fontWeight: _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
                      color: _selectedIndex == index ? theme.primaryColor : theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  selected: _selectedIndex == index,
                  onTap: () {
                    setState(() => _selectedIndex = index);
                    Navigator.pop(context); // Close drawer
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(ThemeData theme, int index, bool isSelected) {
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            FaIcon(
              _menuIcons[index],
              size: 20,
              color: isSelected ? theme.primaryColor : Colors.grey[400],
            ),
            const SizedBox(width: 15),
            Text(
              _menuItems[index],
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? theme.primaryColor : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Timer (Left aligned on Top Bar)
          GestureDetector(
            onTap: () {
              if (_status?.startDate != null) {
                showDialog(
                  context: context,
                  builder: (ctx) => _ShareableTimerDialog(
                    habitStartTime: _status!.startDate!,
                    theme: theme,
                    milestones: _milestones,
                  ),
                );
              }
            },
            child: _RealTimeTimer(habitStartTime: _status?.startDate, theme: theme),
          ),
          
          // Notifications / Profile (Mobile only usually, but here for consistency)
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.share),
                tooltip: 'Share Progress',
                onPressed: () {
                  if (_status?.startDate != null) {
                    showDialog(
                      context: context,
                      builder: (ctx) => _ShareableTimerDialog(
                        habitStartTime: _status!.startDate!,
                        theme: theme,
                        milestones: _milestones,
                      ),
                    );
                  } else {
                     ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Start your journey to share your progress!')),
                    );
                  }
                },
                color: Colors.grey[600],
              ),
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {},
                color: Colors.grey[600],
              ),
              const SizedBox(width: 10),
              // On mobile, profile is in drawer. On desktop, in side panel.
              // Maybe add a logout or settings here?
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {},
                color: Colors.grey[600],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeContent(theme);
      case 1:
        return _buildAchievementsContent(theme);
      case 2:
        return _buildCommunityContent(theme);
      case 3:
        return _buildEventsContent(theme);
      default:
        return _buildHomeContent(theme);
    }
  }

  Widget _buildHomeContent(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_status == null || !_status!.isActive) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration or Icon
            Icon(FontAwesomeIcons.heartPulse, size: 80, color: theme.primaryColor.withOpacity(0.5)),
            const SizedBox(height: 30),
            Text(
              "Ready to start your journey?",
              style: GoogleFonts.judson(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Begin tracking your recovery today.",
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => _showJoinDialog(theme),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 5,
              ),
              child: Text(
                "Start Recovery",
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // The Timer
          if (_status?.startDate != null) ...[
             RecoveryTimer(startTime: _status!.startDate!),
             const SizedBox(height: 30),
             // Badges Preview
             _RealTimeAchievements(
               startTime: _status?.startDate,
               theme: theme,
               milestones: _milestones,
               isPreview: true,
             ),
          ],
          
          const SizedBox(height: 10),
          Text(
            "Recovering from: ${_status?.addictionType}",
            style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]),
          ),
          
          const SizedBox(height: 40),
          
          // Motivation / Quote Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(FontAwesomeIcons.quoteLeft, color: theme.primaryColor.withOpacity(0.3), size: 30),
                const SizedBox(height: 15),
                Text(
                  "\"The only way to make sense out of change is to plunge into it, move with it, and join the dance.\"",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.judson(
                    fontSize: 20,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  "- Alan Watts",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Reset Option
          TextButton.icon(
            onPressed: () {
              showDialog(
                context: context, 
                builder: (ctx) => AlertDialog(
                  title: Text("Reset Recovery?", style: GoogleFonts.judson(fontWeight: FontWeight.bold)),
                  content: const Text("This will reset your progress to zero. This action cannot be undone."),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _handleReset();
                      },
                      child: Text("Reset", style: TextStyle(color: theme.colorScheme.error)),
                    ),
                  ],
                ),
              );
            },
            icon: Icon(Icons.refresh, size: 16, color: Colors.grey[500]),
            label: Text(
              "Reset Progress",
              style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Content Suggestions
          _buildContentSuggestions(theme),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showJoinDialog(ThemeData theme) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Start Your Journey", style: GoogleFonts.judson(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("What are you recovering from?"),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "e.g., Alcohol, Smoking, Gaming",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(ctx);
                _handleJoin(controller.text);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor),
            child: const Text("Start", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSuggestions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Text(
            'Resources for Your Journey',
            style: GoogleFonts.judson(
              fontSize: 22, 
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
        ),
        const SizedBox(height: 20),
        
        // Videos Section
        _buildSectionHeader("Videos", FontAwesomeIcons.youtube, Colors.red),
        const SizedBox(height: 10),
        SizedBox(
          height: 160,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _buildResourceList(
              theme, 
              'video', 
              FontAwesomeIcons.play, 
              Colors.redAccent,
              [
                {'title': "Understanding Addiction", 'subtitle': "Dr. Gabor Maté explains the roots of addiction.", 'url': 'https://www.youtube.com/watch?v=66cYcSak6nE'},
                {'title': "Breaking the Cycle", 'subtitle': "Practical tips for overcoming urges.", 'url': 'https://www.youtube.com/watch?v=VideoID2'},
              ]
            ),
          ),
        ),
        
        const SizedBox(height: 30),
        
        // Podcasts Section
        _buildSectionHeader("Podcasts", FontAwesomeIcons.podcast, Colors.purple),
        const SizedBox(height: 10),
        SizedBox(
          height: 160,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _buildResourceList(
              theme, 
              'podcast', 
              FontAwesomeIcons.headphones, 
              Colors.purpleAccent,
              [
                {'title': "Recovery Elevator", 'subtitle': "Stories of hope and recovery.", 'url': 'https://www.recoveryelevator.com/'},
                {'title': "The Sober Guy", 'subtitle': "Men's mental health and addiction.", 'url': 'https://www.thesoberguy.com/'},
              ]
            ),
          ),
        ),
        
        const SizedBox(height: 30),
        
        // Books Section
        _buildSectionHeader("Books", FontAwesomeIcons.bookOpen, Colors.blue),
        const SizedBox(height: 10),
        SizedBox(
          height: 160,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _buildResourceList(
              theme, 
              'book', 
              FontAwesomeIcons.book, 
              Colors.blueAccent,
              [
                {'title': "Atomic Habits", 'subtitle': "James Clear on building good habits.", 'url': 'https://jamesclear.com/atomic-habits'},
                {'title': "In the Realm of Hungry Ghosts", 'subtitle': "Close encounters with addiction.", 'url': 'https://drgabormate.com/book/in-the-realm-of-hungry-ghosts/'},
              ]
            ),
          ),
        ),
        
        const SizedBox(height: 30),
        
        // Posts/Articles Section
        _buildSectionHeader("Articles", FontAwesomeIcons.newspaper, Colors.green),
        const SizedBox(height: 10),
        SizedBox(
          height: 160,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _buildResourceList(
              theme, 
              'article', 
              FontAwesomeIcons.fileLines, 
              Colors.green,
              [
                {'title': "5 Steps to Recovery", 'subtitle': "A guide to starting your journey.", 'url': 'https://example.com/recovery-steps'},
                {'title': "Dealing with Relapse", 'subtitle': "How to get back on track.", 'url': 'https://example.com/relapse-help'},
              ]
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        FaIcon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildResourceCard(ThemeData theme, String title, String subtitle, IconData icon, Color accentColor, {String? url}) {
    return InkWell(
      onTap: () async {
        if (url != null && url.isNotEmpty) {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        }
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
              child: FaIcon(icon, size: 20, color: Colors.white),
            ),
            const Spacer(),
            Text(
              title,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: theme.textTheme.bodyLarge?.color,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildResourceList(ThemeData theme, String type, IconData icon, Color color, List<Map<String, String>> defaults) {
    final fetched = _resources.where((r) => r.type == type).toList();
    
    if (fetched.isNotEmpty) {
      return fetched.map((r) => Padding(
        padding: const EdgeInsets.only(right: 15),
        child: _buildResourceCard(theme, r.title, r.subtitle ?? '', icon, color, url: r.url),
      )).toList();
    }

    return defaults.map((d) => Padding(
      padding: const EdgeInsets.only(right: 15),
      child: _buildResourceCard(theme, d['title']!, d['subtitle']!, icon, color, url: d['url']),
    )).toList();
  }

  Widget _buildAchievementsContent(ThemeData theme) {
    return _RealTimeAchievements(
      startTime: _status?.startDate,
      theme: theme,
      milestones: _milestones,
    );
  }

  Widget _buildCommunityContent(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Wellness Chat Entry
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WellnessChatsScreen()),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF6B9080), const Color(0xFFA4C3B2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B9080).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const FaIcon(FontAwesomeIcons.comments, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Wellness Chat",
                        style: GoogleFonts.judson(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "A safe space for support & connection.",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 30),

        Text('Active Members', style: GoogleFonts.judson(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),

        if (_communityMembers.isEmpty)
          Center(child: Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Text("No active members yet. Be the first!", style: GoogleFonts.inter(color: Colors.grey)),
          ))
        else
          ..._communityMembers.map((member) {
          final streak = DateTime.now().difference(member.startDate).inDays;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.primaryColor.withOpacity(0.1),
                child: Text(
                  member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                  style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(member.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$streak Day Streak', style: GoogleFonts.inter(fontSize: 12)),
                  Text('Recovering from: ${member.addictionType}', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
                ],
              ),
              trailing: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.green, // Assuming active if in list
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEventsContent(ThemeData theme) {
    return const EventsScreen(isEmbedded: true);
  }
}

class _ShareableTimerDialog extends StatefulWidget {
  final DateTime habitStartTime;
  final ThemeData theme;
  final List<Milestone> milestones;

  const _ShareableTimerDialog({
    required this.habitStartTime,
    required this.theme,
    this.milestones = const [],
  });

  @override
  State<_ShareableTimerDialog> createState() => _ShareableTimerDialogState();
}

class _ShareableTimerDialogState extends State<_ShareableTimerDialog> {
  final GlobalKey _globalKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareImage() async {
    setState(() => _isSharing = true);
    
    try {
      // 1. Capture the image
      // Small delay to ensure the timer widget has rendered its first frame
      await Future.delayed(const Duration(milliseconds: 100));
      
      RenderRepaintBoundary boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) throw Exception("Could not generate image data");
      
      Uint8List pngBytes = byteData.buffer.asUint8List();

      // 2. Share using cross-platform method
      XFile fileToShare;
      
      if (kIsWeb) {
        // Web sharing
        fileToShare = XFile.fromData(
          pngBytes,
          mimeType: 'image/png',
          name: 'my_recovery_timer.png',
        );
      } else {
        // Mobile/Desktop sharing
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/my_recovery_timer.png';
        
        // Save using XFile to avoid dart:io dependency
        final tempFile = XFile.fromData(pngBytes);
        await tempFile.saveTo(path);
        
        fileToShare = XFile(path);
      }

      if (!mounted) return;

      final days = DateTime.now().difference(widget.habitStartTime).inDays;
      final shareText = 'This is my milestone, thanks to Great awareness. I have been clean for $days days! https://great-awareness-frontend.vercel.app/';
      
      // Calculate share origin for iPad/tablets
      final box = context.findRenderObject() as RenderBox?;
      final shareOrigin = box != null ? box.localToGlobal(Offset.zero) & box.size : null;

      await Share.shareXFiles(
        [fileToShare], 
        text: shareText,
        sharePositionOrigin: shareOrigin,
      );
      
    } catch (e) {
      debugPrint('Error sharing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not share image: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Prepare data (normalize to _BadgeData)
    List<_BadgeData> allBadges;
    if (widget.milestones.isNotEmpty) {
      allBadges = widget.milestones.map((m) => _BadgeData(
        m.label,
        Duration(seconds: m.durationSeconds),
        _resolveIcon(m.iconCode),
        _parseColor(m.colorHex),
        m.description,
        imageUrl: m.badgeImageUrl,
      )).toList();
    } else {
       // Fallback defaults if API returns empty
       allBadges = [
        _BadgeData('24 Hours', const Duration(hours: 24), FontAwesomeIcons.seedling, Colors.blue, "The first 24 hours."),
        _BadgeData('7 Days', const Duration(days: 7), FontAwesomeIcons.calendarWeek, Colors.cyan, "One week of clarity."),
        _BadgeData('21 Days', const Duration(days: 21), FontAwesomeIcons.personWalking, Colors.teal, "21 days to form a habit."),
        _BadgeData('30 Days', const Duration(days: 30), FontAwesomeIcons.medal, Colors.green, "One month strong."),
        _BadgeData('60 Days', const Duration(days: 60), FontAwesomeIcons.star, Colors.lime, "Two months of dedication."),
        _BadgeData('180 Days', const Duration(days: 180), FontAwesomeIcons.shieldHeart, Colors.orange, "Six months."),
        _BadgeData('1 Year', const Duration(days: 365), FontAwesomeIcons.trophy, Colors.amber, "One year."),
      ];
    }

    // 2. Filter unlocked based on actual elapsed time
    final elapsed = DateTime.now().difference(widget.habitStartTime);
    final unlockedBadges = allBadges.where((b) => elapsed >= b.duration).toList();

    // 3. Sort by duration
    unlockedBadges.sort((a, b) => a.duration.compareTo(b.duration));

    // 4. Limit to most recent 4
    final displayBadges = unlockedBadges.length > 4 
        ? unlockedBadges.sublist(unlockedBadges.length - 4) 
        : unlockedBadges;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(15),
      child: SingleChildScrollView( // Added scroll view in case content is tall
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              key: _globalKey,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: widget.theme.cardColor,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "RECOVERY STREAK",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: widget.theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // The Circular Timer
                    RecoveryTimer(
                      startTime: widget.habitStartTime,
                      textColor: Colors.black,
                    ),
                    
                    if (displayBadges.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        "UNLOCKED ACHIEVEMENTS",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: widget.theme.textTheme.bodyLarge?.color?.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: displayBadges.map((badge) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: badge.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                badge.imageUrl != null && badge.imageUrl!.isNotEmpty
                                    ? ClipOval(
                                        child: Image.network(
                                          badge.imageUrl!,
                                          width: 28,
                                          height: 28,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return badge.icon is IconData
                                                ? FaIcon(
                                                    badge.icon as IconData,
                                                    size: 24,
                                                    color: badge.color,
                                                  )
                                                : Text(
                                                    String.fromCharCode(badge.icon as int),
                                                    style: TextStyle(
                                                      fontFamily: 'FontAwesomeSolid',
                                                      package: 'font_awesome_flutter',
                                                      fontSize: 24,
                                                      color: badge.color,
                                                      height: 1,
                                                    ),
                                                  );
                                          },
                                        ),
                                      )
                                    : (badge.icon is IconData
                                        ? FaIcon(
                                            badge.icon as IconData,
                                            size: 24,
                                            color: badge.color,
                                          )
                                        : Text(
                                            String.fromCharCode(badge.icon as int),
                                            style: TextStyle(
                                              fontFamily: 'FontAwesomeSolid',
                                              package: 'font_awesome_flutter',
                                              fontSize: 24,
                                              color: badge.color,
                                              height: 1,
                                            ),
                                          )),
                                const SizedBox(width: 8),
                                Text(
                                  badge.label,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: badge.color,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 20),
                    Text(
                      "Great Awareness",
                      style: GoogleFonts.judson(
                        fontSize: 18,
                        color: widget.theme.primaryColor,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton.extended(
                  onPressed: _isSharing ? null : _shareImage,
                  backgroundColor: widget.theme.primaryColor,
                  foregroundColor: Colors.white,
                  icon: _isSharing 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.share),
                  label: Text(_isSharing ? "Preparing..." : "Share Streak"),
                ),
                const SizedBox(width: 15),
                FloatingActionButton(
                  onPressed: () => Navigator.pop(context),
                  backgroundColor: Colors.grey[800],
                  child: const Icon(Icons.close, color: Colors.white),
                  mini: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }
}

class _ShareableBadgeDialog extends StatefulWidget {
  final _BadgeData badge;
  final ThemeData theme;
  final bool unlocked;
  final DateTime? habitStartTime;

  const _ShareableBadgeDialog({
    super.key,
    required this.badge,
    required this.theme,
    required this.unlocked,
    this.habitStartTime,
  });

  @override
  State<_ShareableBadgeDialog> createState() => _ShareableBadgeDialogState();
}

class _ShareableBadgeDialogState extends State<_ShareableBadgeDialog> {
  final GlobalKey _globalKey = GlobalKey();
  bool _isSharing = false;
  late Timer _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    if (widget.habitStartTime != null) {
      setState(() {
        _elapsed = DateTime.now().difference(widget.habitStartTime!);
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _captureAndShare() async {
    if (_isSharing) return;
    
    setState(() => _isSharing = true);
    
    try {
      // Small delay to ensure UI updates and boundary is ready
      await Future.delayed(const Duration(milliseconds: 100));

      final boundary = _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception("Could not render badge image. Please try again.");
      }

      // Capture with pixel ratio 3.0 (good balance of quality and performance)
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        throw Exception("Failed to process image data.");
      }

      final pngBytes = byteData.buffer.asUint8List();
      
      // Clean filename
      final safeLabel = widget.badge.label.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
      final fileName = 'milestone_${safeLabel}_${DateTime.now().millisecondsSinceEpoch}.png';
      
      XFile fileToShare;

      if (kIsWeb) {
        fileToShare = XFile.fromData(
          pngBytes, 
          mimeType: 'image/png', 
          name: fileName
        );
      } else {
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/$fileName';
        
        // Save using XFile to avoid dart:io dependency
        final tempFile = XFile.fromData(pngBytes);
        await tempFile.saveTo(path);
        
        fileToShare = XFile(path);
      }

      if (!mounted) return;

      final shareText = widget.unlocked 
          ? '🏆 I just unlocked the ${widget.badge.label} milestone on Great Awareness! #Recovery #Wellness'
          : '🎯 I am working towards the ${widget.badge.label} milestone on Great Awareness! #Goals';
      
      // Calculate share origin for iPad/tablets
      final box = context.findRenderObject() as RenderBox?;
      final shareOrigin = box != null ? box.localToGlobal(Offset.zero) & box.size : null;

      await Share.shareXFiles(
        [fileToShare], 
        text: shareText,
        sharePositionOrigin: shareOrigin,
      );
      
    } catch (e) {
      debugPrint('Error sharing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not share image: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return "SOON";
    
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (days > 0) {
      return "${days}d ${hours}h ${minutes}m ${seconds}s";
    } else if (hours > 0) {
      return "${hours}h ${minutes}m ${seconds}s";
    } else {
      return "${minutes}m ${seconds}s";
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine gradient based on unlock status and badge color
    final gradientColors = widget.unlocked 
        ? [widget.badge.color.withOpacity(0.8), widget.badge.color]
        : [Colors.grey.shade400, Colors.grey.shade600];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RepaintBoundary(
            key: _globalKey,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.theme.cardTheme.color ?? Colors.white,
                    widget.theme.cardTheme.color?.withOpacity(0.9) ?? Colors.grey.shade50,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.unlocked 
                        ? Colors.green.withOpacity(0.5) 
                        : widget.badge.color.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
                border: Border.all(
                  color: widget.unlocked ? Colors.black : Colors.grey.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  // Decorative background elements
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.badge.color.withOpacity(0.05),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -30,
                    left: -30,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.badge.color.withOpacity(0.05),
                      ),
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(35),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // App Branding
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(FontAwesomeIcons.heartPulse, color: widget.theme.primaryColor, size: 14),
                            const SizedBox(width: 8),
                            Text(
                              "GREAT AWARENESS",
                              style: GoogleFonts.judson(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 3,
                                color: widget.theme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 35),
                        
                        // Badge Icon with Glow
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: gradientColors,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (widget.unlocked ? Colors.green : Colors.grey).withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 5,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: -5,
                                offset: const Offset(-5, -5),
                              ),
                            ],
                          ),
                          child: Center(
                            child: widget.badge.imageUrl != null && widget.badge.imageUrl!.isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      widget.badge.imageUrl!,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return widget.badge.icon is IconData
                                            ? FaIcon(
                                                widget.badge.icon as IconData,
                                                size: 50,
                                                color: Colors.white,
                                              )
                                            : Text(
                                                String.fromCharCode(widget.badge.icon as int),
                                                style: const TextStyle(
                                                  fontFamily: 'FontAwesomeSolid',
                                                  package: 'font_awesome_flutter',
                                                  fontSize: 50,
                                                  color: Colors.white,
                                                  height: 1,
                                                ),
                                              );
                                      },
                                    ),
                                  )
                                : (widget.badge.icon is IconData
                                    ? FaIcon(
                                        widget.badge.icon as IconData,
                                        size: 50,
                                        color: Colors.white,
                                      )
                                    : Text(
                                        String.fromCharCode(widget.badge.icon as int),
                                        style: const TextStyle(
                                          fontFamily: 'FontAwesomeSolid',
                                          package: 'font_awesome_flutter',
                                          fontSize: 50,
                                          color: Colors.white,
                                          height: 1,
                                        ),
                                      )),
                          ),
                        ),
                        const SizedBox(height: 30),
                        
                        // Status Label
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: (widget.unlocked ? widget.badge.color : Colors.grey).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: (widget.unlocked ? widget.badge.color : Colors.grey).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.timer, size: 12, color: widget.unlocked ? widget.badge.color : Colors.grey),
                              const SizedBox(width: 6),
                              Builder(
                                builder: (context) {
                                  if (widget.unlocked) {
                                    // Show time since unlocked
                                    final timeSinceUnlock = _elapsed - widget.badge.duration;
                                    final label = timeSinceUnlock.isNegative 
                                        ? "JUST UNLOCKED" 
                                        : "Active: ${_formatDuration(timeSinceUnlock)}";
                                    return Text(
                                      label,
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                        color: widget.badge.color,
                                      ),
                                    );
                                  } else {
                                    // Show time remaining
                                    final remaining = widget.badge.duration - _elapsed;
                                    return Text(
                                      remaining.isNegative 
                                          ? "SOON" 
                                          : "UNLOCKS IN ${_formatDuration(remaining)}",
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                        color: Colors.grey,
                                      ),
                                    );
                                  }
                                }
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        
                        // Badge Title
                        Text(
                          widget.badge.label,
                          style: GoogleFonts.judson(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: widget.theme.textTheme.bodyLarge?.color,
                            shadows: widget.unlocked ? [
                              Shadow(
                                color: widget.badge.color.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              )
                            ] : null,
                          ),
                        ),
                        const SizedBox(height: 15),
                        
                        // Description
                        Text(
                          widget.badge.description,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            height: 1.6,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 40),
                        
                        // Footer / Branding Link
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.link, size: 14, color: Colors.grey[500]),
                              const SizedBox(width: 5),
                              Text(
                                "greatawareness.app",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),
          
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                ),
                child: Text(
                  "Close", 
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  )
                ),
              ),
              const SizedBox(width: 15),
              ElevatedButton.icon(
                onPressed: _isSharing ? null : _captureAndShare,
                icon: _isSharing 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.share_rounded, size: 20),
                label: Text(
                  _isSharing ? "Generating..." : "Share Achievement",
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.unlocked ? widget.theme.primaryColor : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  elevation: 8,
                  shadowColor: widget.theme.primaryColor.withOpacity(0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BadgeData {
  final String label;
  final Duration duration;
  final Object icon; // Can be IconData or int (code point)
  final Color color;
  final String description;
  final String? imageUrl;

  _BadgeData(this.label, this.duration, this.icon, this.color, this.description, {this.imageUrl});
}

class _RealTimeAchievements extends StatefulWidget {
  final DateTime? startTime;
  final ThemeData theme;
  final List<Milestone> milestones;
  final bool isPreview;

  const _RealTimeAchievements({
    required this.startTime,
    required this.theme,
    required this.milestones,
    this.isPreview = false,
  });

  @override
  State<_RealTimeAchievements> createState() => _RealTimeAchievementsState();
}

class _RealTimeAchievementsState extends State<_RealTimeAchievements> {
  late Timer _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  @override
  void didUpdateWidget(_RealTimeAchievements oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startTime != oldWidget.startTime) {
      _updateTime();
    }
  }

  void _updateTime() {
    if (widget.startTime != null) {
      final now = DateTime.now();
      setState(() {
        _elapsed = now.difference(widget.startTime!);
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Define badges
    List<_BadgeData> badges;
    
    if (widget.milestones.isNotEmpty) {
      badges = widget.milestones.map((m) {
        return _BadgeData(
          m.label,
          Duration(seconds: m.durationSeconds),
          _resolveIcon(m.iconCode),
          _parseColor(m.colorHex),
          m.description,
          imageUrl: m.badgeImageUrl,
        );
      }).toList();
    } else {
      badges = [
        _BadgeData('24 Hours', const Duration(hours: 24), FontAwesomeIcons.seedling, Colors.blue, "The first 24 hours are the hardest. You've taken the first step!"),
        _BadgeData('7 Days', const Duration(days: 7), FontAwesomeIcons.calendarWeek, Colors.cyan, "One week of clarity. Keep building your streak!"),
        _BadgeData('21 Days', const Duration(days: 21), FontAwesomeIcons.personWalking, Colors.teal, "21 days to form a habit. You are changing your life."),
        _BadgeData('30 Days', const Duration(days: 30), FontAwesomeIcons.medal, Colors.green, "One month strong. Celebrate this milestone!"),
        _BadgeData('60 Days', const Duration(days: 60), FontAwesomeIcons.star, Colors.lime, "Two months of dedication. You're unstoppable."),
        _BadgeData('180 Days', const Duration(days: 180), FontAwesomeIcons.shieldHeart, Colors.orange, "Six months. Half a year of transformation."),
        _BadgeData('1 Year', const Duration(days: 365), FontAwesomeIcons.trophy, Colors.amber, "One year. A monumental achievement!"),
      ];
    }

    if (widget.isPreview) {
      final unlockedBadges = badges.where((b) => _elapsed >= b.duration).toList();
      
      if (unlockedBadges.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              "Recent Achievements",
              style: GoogleFonts.judson(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                color: widget.theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: unlockedBadges.length,
              separatorBuilder: (ctx, i) => const SizedBox(width: 15),
              itemBuilder: (ctx, i) {
                final badge = unlockedBadges[i];
                return _buildBadge(widget.theme, badge, true);
              },
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Your Milestones', style: GoogleFonts.judson(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        
        if (widget.startTime == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              "Start your recovery journey to unlock badges!",
              style: GoogleFonts.inter(color: Colors.grey),
            ),
          )
        else
          Wrap(
            spacing: 15,
            runSpacing: 15,
            children: badges.map((badge) {
              // Check if unlocked via API (if available in milestone) or via local timer
              // Since we mapped to _BadgeData, we lose the 'isUnlocked' property from Milestone
              // We can rely on _elapsed for real-time feedback, which matches backend logic
              final isUnlocked = _elapsed >= badge.duration;
              return _buildBadge(widget.theme, badge, isUnlocked);
            }).toList(),
          ),
      ],
    );
  }

  Color _parseColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  String _formatCompactDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    }
  }

  Widget _buildBadge(ThemeData theme, _BadgeData badge, bool unlocked) {
    // Determine gradient based on unlock status
    final gradientColors = unlocked 
        ? [badge.color.withOpacity(0.8), badge.color]
        : [Colors.grey.shade300, Colors.grey.shade400];

    // Calculate time remaining if locked
    String timeRemaining = '';
    if (!unlocked) {
      final remaining = badge.duration - _elapsed;
      if (remaining.isNegative) {
        timeRemaining = 'Soon';
      } else if (remaining.inDays > 0) {
        timeRemaining = '${remaining.inDays}d left';
      } else if (remaining.inHours > 0) {
        timeRemaining = '${remaining.inHours}h left';
      } else {
        timeRemaining = '${remaining.inMinutes}m left';
      }
    }

    return GestureDetector(
      onTap: () => _showShareDialog(context, badge, unlocked),
      child: Container(
        width: 110,
        height: 155, // Increased height for timer
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: unlocked ? Border.all(color: Colors.black, width: 2) : null,
          boxShadow: unlocked
              ? [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.6),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 0),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background Decoration
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (unlocked ? badge.color : Colors.grey).withOpacity(0.05),
                ),
              ),
            ),

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon Circle
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (unlocked ? badge.color : Colors.grey).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: badge.imageUrl != null && badge.imageUrl!.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              badge.imageUrl!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return badge.icon is IconData
                                    ? FaIcon(
                                        badge.icon as IconData,
                                        size: 24,
                                        color: Colors.white,
                                      )
                                    : Text(
                                        String.fromCharCode(badge.icon as int),
                                        style: const TextStyle(
                                          fontFamily: 'FontAwesomeSolid',
                                          package: 'font_awesome_flutter',
                                          fontSize: 24,
                                          color: Colors.white,
                                          height: 1,
                                        ),
                                      );
                              },
                            ),
                          )
                        : (badge.icon is IconData
                            ? FaIcon(
                                badge.icon as IconData,
                                size: 24,
                                color: Colors.white,
                              )
                            : Text(
                                String.fromCharCode(badge.icon as int),
                                style: const TextStyle(
                                  fontFamily: 'FontAwesomeSolid',
                                  package: 'font_awesome_flutter',
                                  fontSize: 24,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              )),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Label
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    badge.label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.judson(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: unlocked ? theme.textTheme.bodyLarge?.color : Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // Status Indicator or Timer
                if (unlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: badge.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "Active: ${_formatCompactDuration(_elapsed - badge.duration)}",
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: badge.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer, size: 10, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          timeRemaining,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showShareDialog(BuildContext context, _BadgeData badge, bool unlocked) {
    showDialog(
      context: context,
      builder: (ctx) => _ShareableBadgeDialog(
        badge: badge, 
        theme: widget.theme, 
        unlocked: unlocked,
        habitStartTime: widget.startTime,
      ),
    );
  }
}

class _RealTimeTimer extends StatefulWidget {
  final DateTime? habitStartTime;
  final ThemeData theme;

  const _RealTimeTimer({required this.habitStartTime, required this.theme});

  @override
  State<_RealTimeTimer> createState() => _RealTimeTimerState();
}

class _RealTimeTimerState extends State<_RealTimeTimer> {
  late Timer _timer;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  @override
  void didUpdateWidget(_RealTimeTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.habitStartTime != oldWidget.habitStartTime) {
      _updateTime();
    }
  }

  void _updateTime() {
    if (widget.habitStartTime != null) {
      setState(() {
        _duration = DateTime.now().difference(widget.habitStartTime!.toLocal());
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = _duration.inDays;
    final hours = _duration.inHours % 24;
    final minutes = _duration.inMinutes % 60;
    final seconds = _duration.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: widget.theme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: widget.theme.primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(FontAwesomeIcons.stopwatch, size: 18, color: widget.theme.primaryColor),
          const SizedBox(width: 10),
          Text(
            '${days}d ${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s',
            style: GoogleFonts.robotoMono(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: widget.theme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
