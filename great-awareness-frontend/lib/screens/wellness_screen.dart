import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/theme_provider.dart';
import '../models/user.dart';

class WellnessScreen extends StatefulWidget {
  const WellnessScreen({super.key});

  @override
  State<WellnessScreen> createState() => _WellnessScreenState();
}

class _WellnessScreenState extends State<WellnessScreen> {
  DateTime? _habitStartTime;
  int _userDayStatus = 0;
  bool _isTrackingActive = false;
  String? _selectedAddictionType;
  String _customAddictionType = '';
  final TextEditingController _customAddictionController = TextEditingController();
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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _customAddictionController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;
    
    if (currentUser != null) {
      // In a real app, this would come from your backend API
      // For now, we'll simulate some data
      setState(() {
        _userDayStatus = 15; // This would come from your database
        _habitStartTime = DateTime.now().subtract(const Duration(days: 15));
        _isTrackingActive = true;
        _selectedAddictionType = 'Masturbation'; // This would come from your database
      });
    }
  }

  void _startHabitTracking() {
    if (_selectedAddictionType == null || _selectedAddictionType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select an addiction type first'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      _habitStartTime = DateTime.now();
      _isTrackingActive = true;
      _userDayStatus = 0;
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
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // User Profile Section
              _buildUserProfileCard(currentUser, theme),
              const SizedBox(height: 30),
              
              // Addiction Type Selection
              _buildAddictionTypeSection(theme),
              const SizedBox(height: 30),
              
              // Habit Timer Section
              _buildHabitTimerSection(theme),
              const SizedBox(height: 30),
              
              // Milestone Badges Section
              _buildMilestoneBadgesSection(theme),
              const SizedBox(height: 30),
              
              // Day Status Update Section
              _buildDayStatusSection(theme),
              const SizedBox(height: 30),
              
              // Community Section
              _buildCommunitySection(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddictionTypeSection(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(FontAwesomeIcons.bullseye, color: theme.primaryColor, size: 30),
              const SizedBox(width: 15),
              Text(
                'Choose Your Challenge',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isTrackingActive && _selectedAddictionType != null) ...[
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  FaIcon(FontAwesomeIcons.circleCheck, color: theme.primaryColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Currently overcoming: ${_selectedAddictionType == "Other (Custom)" ? _customAddictionType : _selectedAddictionType}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            DropdownButtonFormField<String>(
              value: _selectedAddictionType,
              decoration: InputDecoration(
                labelText: 'Select Addiction Type',
                labelStyle: theme.textTheme.bodyMedium,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: theme.primaryColor.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: theme.primaryColor.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: theme.primaryColor, width: 2),
                ),
              ),
              items: _predefinedAddictions.map((String addiction) {
                return DropdownMenuItem<String>(
                  value: addiction,
                  child: Text(addiction),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedAddictionType = newValue;
                  if (newValue == "Other (Custom)") {
                    _customAddictionType = '';
                  }
                });
              },
              hint: Text('Choose your challenge', style: theme.textTheme.bodyMedium),
            ),
            if (_selectedAddictionType == "Other (Custom)") ...[
              const SizedBox(height: 15),
              TextField(
                controller: _customAddictionController,
                decoration: InputDecoration(
                  labelText: 'Enter your custom challenge',
                  labelStyle: theme.textTheme.bodyMedium,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: theme.primaryColor.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: theme.primaryColor.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: theme.primaryColor, width: 2),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _customAddictionType = value;
                  });
                },
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildMilestoneBadgesSection(ThemeData theme) {
    final List<Map<String, dynamic>> milestones = [
      {'days': 21, 'name': '21 Days', 'icon': FontAwesomeIcons.star, 'color': const Color(0xFFCD7F32)}, // Bronze
      {'days': 30, 'name': '1 Month', 'icon': FontAwesomeIcons.medal, 'color': const Color(0xFFC0C0C0)}, // Silver
      {'days': 60, 'name': '2 Months', 'icon': FontAwesomeIcons.award, 'color': const Color(0xFFFFD700)}, // Gold
      {'days': 90, 'name': '3 Months', 'icon': FontAwesomeIcons.trophy, 'color': const Color(0xFF800080)}, // Purple
      {'days': 180, 'name': '6 Months', 'icon': FontAwesomeIcons.crown, 'color': const Color(0xFF0000FF)}, // Blue
      {'days': 365, 'name': '1 Year', 'icon': FontAwesomeIcons.gem, 'color': const Color(0xFF008000)}, // Green
      {'days': 730, 'name': '2 Years', 'icon': FontAwesomeIcons.rocket, 'color': const Color(0xFFFF0000)}, // Red
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(FontAwesomeIcons.certificate, color: theme.primaryColor, size: 30),
              const SizedBox(width: 15),
              Text(
                'Milestone Badges',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Unlock badges as you progress!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 15,
            runSpacing: 15,
            alignment: WrapAlignment.center,
            children: milestones.map((milestone) {
              final isUnlocked = _userDayStatus >= milestone['days'];
              return Container(
                width: 80,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUnlocked 
                      ? milestone['color'].withValues(alpha: 0.1)
                      : theme.cardTheme.color?.withValues(alpha: 0.5) ?? theme.cardColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isUnlocked 
                        ? milestone['color']
                        : theme.primaryColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(
                      milestone['icon'],
                      size: 30,
                      color: isUnlocked ? milestone['color'] : Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      milestone['name'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? milestone['color'] : Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (isUnlocked) ...[
                      const SizedBox(height: 4),
                      FaIcon(
                        FontAwesomeIcons.check,
                        size: 12,
                        color: Colors.green,
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileCard(User? currentUser, ThemeData theme) {
    final String addictionDisplayName = _selectedAddictionType == "Other (Custom)" 
        ? (_customAddictionType.isNotEmpty ? _customAddictionType : "Custom Challenge")
        : (_selectedAddictionType ?? "Not Started");

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: theme.primaryColor.withValues(alpha: 0.3),
            child: FaIcon(
              FontAwesomeIcons.user,
              size: 30,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            currentUser?.name ?? currentUser?.email ?? 'Guest User',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _isTrackingActive ? 'Day $_userDayStatus of $addictionDisplayName' : 'Challenge: $addictionDisplayName',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_isTrackingActive) ...[
            const SizedBox(height: 5),
            Text(
              'Status: Day $_userDayStatus',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHabitTimerSection(ThemeData theme) {
    final String addictionDisplayName = _selectedAddictionType == "Other (Custom)" 
        ? (_customAddictionType.isNotEmpty ? _customAddictionType : "Custom Challenge")
        : (_selectedAddictionType ?? "Your Challenge");

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          FaIcon(
            FontAwesomeIcons.clock,
            size: 40,
            color: theme.primaryColor,
          ),
          const SizedBox(height: 15),
          if (_isTrackingActive) ...[
            Text(
              'Overcoming: $addictionDisplayName',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 20),
          if (_isTrackingActive && _habitStartTime != null) ...[
            StreamBuilder<Duration>(
              stream: Stream.periodic(const Duration(seconds: 1), (_) {
                return DateTime.now().difference(_habitStartTime!);
              }),
              builder: (context, snapshot) {
                final duration = snapshot.data ?? Duration.zero;
                return Column(
                  children: [
                    Text(
                      _formatDuration(duration),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Time Since You Started',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                );
              },
            ),
          ] else ...[
            Text(
              'Ready to Start Your Journey?',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_selectedAddictionType != null) ...[
              const SizedBox(height: 10),
              Text(
                'Challenge: $addictionDisplayName',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: _startHabitTracking,
              icon: const FaIcon(FontAwesomeIcons.play, size: 18),
              label: const Text('Start Tracking'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDayStatusSection(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(FontAwesomeIcons.trophy, color: theme.primaryColor, size: 30),
              const SizedBox(width: 15),
              Text(
                'Update Your Progress',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Wrap(
            spacing: 15,
            runSpacing: 15,
            alignment: WrapAlignment.center,
            children: [
              _buildDayButton(10, 'Day 10', theme),
              _buildDayButton(20, 'Day 20', theme),
              _buildDayButton(30, 'Day 30', theme),
              _buildDayButton(45, 'Day 45', theme),
              _buildDayButton(60, 'Day 60', theme),
              _buildDayButton(90, 'Day 90', theme),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Text(
              'Current: Day $_userDayStatus',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayButton(int day, String label, ThemeData theme) {
    final isSelected = _userDayStatus == day;
    return GestureDetector(
      onTap: () => _updateDayStatus(day),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.primaryColor
              : theme.cardTheme.color?.withValues(alpha: 0.5) ?? theme.cardColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected 
                ? Colors.transparent
                : theme.primaryColor.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCommunitySection(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(FontAwesomeIcons.users, color: theme.primaryColor, size: 30),
              const SizedBox(width: 15),
              Text(
                'Wellness Community',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _wellnessUsers.length,
            itemBuilder: (context, index) {
              final user = _wellnessUsers[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color?.withOpacity(0.7) ?? theme.cardColor.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: theme.primaryColor.withOpacity(0.2),
                      child: FaIcon(
                        FontAwesomeIcons.user,
                        size: 20,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['username'],
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Day ${user['dayStatus']} - Going Strong!',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FaIcon(
                            FontAwesomeIcons.fire,
                            size: 12,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${user['dayStatus']}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}