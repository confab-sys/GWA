import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/user.dart';

class WellnessDashboard extends StatefulWidget {
  final User? currentUser;
  final DateTime? habitStartTime;
  final String addictionType;
  final int currentStreakDays;

  const WellnessDashboard({
    super.key,
    required this.currentUser,
    required this.habitStartTime,
    required this.addictionType,
    required this.currentStreakDays,
  });

  @override
  State<WellnessDashboard> createState() => _WellnessDashboardState();
}

class _WellnessDashboardState extends State<WellnessDashboard> {
  int _selectedIndex = 0; // 0: Home (Videos), 1: Achievements, 2: Community, 3: Events
  
  final List<String> _menuItems = ['Home', 'Achievements', 'Community', 'Events'];
  final List<IconData> _menuIcons = [
    FontAwesomeIcons.house,
    FontAwesomeIcons.trophy,
    FontAwesomeIcons.users,
    FontAwesomeIcons.calendarDay,
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final theme = Theme.of(context);

    return Scaffold(
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
            '${widget.currentStreakDays} Day Streak',
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
            accountEmail: Text('${widget.currentStreakDays} Day Streak'),
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
          _RealTimeTimer(habitStartTime: widget.habitStartTime, theme: theme),
          
          // Notifications / Profile (Mobile only usually, but here for consistency)
          Row(
            children: [
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
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Recommended for You',
          style: GoogleFonts.judson(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        _buildVideoCard(
          theme,
          'Understanding Triggers',
          'Learn how to identify and manage your emotional triggers.',
          'assets/images/video_thumb_1.jpg', // Placeholder
        ),
        const SizedBox(height: 15),
        _buildVideoCard(
          theme,
          'Morning Meditation',
          'Start your day with clarity and focus.',
          'assets/images/video_thumb_2.jpg', // Placeholder
        ),
        const SizedBox(height: 15),
        _buildVideoCard(
          theme,
          'The Power of Habit',
          'Building small habits for long-term success.',
          'assets/images/video_thumb_3.jpg', // Placeholder
        ),
      ],
    );
  }

  Widget _buildVideoCard(ThemeData theme, String title, String subtitle, String imagePath) {
    return Container(
      height: 100,
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
      ),
      child: Row(
        children: [
          Container(
            width: 100,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                bottomLeft: Radius.circular(15),
              ),
              // image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover),
            ),
            child: const Center(child: Icon(Icons.play_circle_outline, size: 40, color: Colors.white)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsContent(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Your Milestones', style: GoogleFonts.judson(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Wrap(
          spacing: 15,
          runSpacing: 15,
          children: [
            _buildBadge(theme, '24 Hours', FontAwesomeIcons.check, Colors.blue, true),
            _buildBadge(theme, '3 Days', FontAwesomeIcons.star, Colors.orange, true),
            _buildBadge(theme, '1 Week', FontAwesomeIcons.trophy, Colors.purple, widget.currentStreakDays >= 7),
            _buildBadge(theme, '1 Month', FontAwesomeIcons.crown, Colors.amber, widget.currentStreakDays >= 30),
          ],
        ),
      ],
    );
  }

  Widget _buildBadge(ThemeData theme, String label, IconData icon, Color color, bool unlocked) {
    return Container(
      width: 100,
      height: 120,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: unlocked ? color.withOpacity(0.5) : Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: (unlocked ? color : Colors.grey).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(icon, size: 30, color: unlocked ? color : Colors.grey[300]),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: unlocked ? theme.textTheme.bodyLarge?.color : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityContent(ThemeData theme) {
    // Mock Data
    final users = [
      {'name': 'Alex', 'status': 'Online', 'streak': 45},
      {'name': 'Sarah', 'status': 'Offline', 'streak': 12},
      {'name': 'Mike', 'status': 'Online', 'streak': 89},
      {'name': 'Emma', 'status': 'Online', 'streak': 5},
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Active Members', style: GoogleFonts.judson(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        ...users.map((user) => Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              child: Text(
                (user['name'] as String)[0],
                style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(user['name'] as String, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            subtitle: Text('${user['streak']} Day Streak', style: GoogleFonts.inter(fontSize: 12)),
            trailing: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: user['status'] == 'Online' ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildEventsContent(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Upcoming Events', style: GoogleFonts.judson(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        _buildEventCard(theme, 'Live Q&A with Dr. Smith', 'Tomorrow, 5:00 PM', 'Join the waitlist'),
        const SizedBox(height: 15),
        _buildEventCard(theme, 'Group Meditation', 'Sunday, 8:00 AM', 'Join the waitlist'),
      ],
    );
  }

  Widget _buildEventCard(ThemeData theme, String title, String time, String action) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: FaIcon(FontAwesomeIcons.calendar, color: theme.primaryColor),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 5),
                Text(time, style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(action, style: GoogleFonts.inter(fontSize: 12)),
          ),
        ],
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

  void _updateTime() {
    if (widget.habitStartTime != null) {
      setState(() {
        _duration = DateTime.now().difference(widget.habitStartTime!);
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
