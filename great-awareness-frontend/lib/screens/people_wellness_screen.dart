import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/wellness_service.dart';

class PeopleWellnessScreen extends StatefulWidget {
  final String? userId;
  final String? userName;

  const PeopleWellnessScreen({super.key, this.userId, this.userName});

  @override
  State<PeopleWellnessScreen> createState() => _PeopleWellnessScreenState();
}

class _PeopleWellnessScreenState extends State<PeopleWellnessScreen> {
  bool _isLoading = true;
  WellnessStatus? _status;
  List<Milestone> _milestones = [];
  User? _currentUser;
  String? _displayName;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final wellnessService = Provider.of<WellnessService>(context, listen: false);

    await authService.checkAuthentication();
    final currentUser = authService.currentUser;
    
    // Determine target user ID
    final targetUserId = widget.userId ?? currentUser?.id;
    
    if (targetUserId == null) {
      setState(() => _isLoading = false);
      return;
    }

    // Fetch status, milestones, and profile (if not current user) in parallel
    final futures = <Future<dynamic>>[
      wellnessService.getStatus(userId: targetUserId),
      wellnessService.getMilestones(userId: targetUserId),
    ];

    if (targetUserId != currentUser?.id) {
      futures.add(authService.getUserProfile(targetUserId));
    }

    final results = await Future.wait(futures);
    
    final status = results[0] as WellnessStatus?;
    final milestonesData = results[1] as Map<String, dynamic>;
    final fetchedUser = (results.length > 2) ? results[2] as User? : null;

    if (mounted) {
      setState(() {
        _currentUser = fetchedUser ?? currentUser;
        _displayName = fetchedUser?.name ?? widget.userName ?? currentUser?.name;
        _status = status;
        _milestones = milestonesData['milestones'] as List<Milestone>;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = Navigator.canPop(context);
    
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: theme.primaryColor));
    }

    return Scaffold(
      backgroundColor: widget.userId != null ? theme.scaffoldBackgroundColor : Colors.transparent,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Profile Header
              SliverToBoxAdapter(
                child: _buildProfileHeader(theme),
              ),
              
              // 2. Badges Section (Replaces Milestones list)
              if (_milestones.isNotEmpty) ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Badges",
                          style: GoogleFonts.judson(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Wrap(
                            spacing: 15,
                            runSpacing: 15,
                            children: _milestones.map((milestone) {
                              return _buildBadge(theme, milestone);
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 50)),
            ],
          ),

          // Back Button
          if (canPop)
            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor.withOpacity(0.8),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: theme.primaryColor,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          // Avatar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: theme.primaryColor.withOpacity(0.3), width: 2),
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              backgroundImage: _currentUser?.profileImage != null 
                  ? NetworkImage(_currentUser!.profileImage!) 
                  : null,
              // Use first letter if no image, or generic icon
              child: _currentUser?.profileImage == null
                  ? (_displayName != null && _displayName!.isNotEmpty
                      ? Text(
                          _displayName![0].toUpperCase(),
                          style: GoogleFonts.judson(
                            fontSize: 40,
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : FaIcon(FontAwesomeIcons.user, size: 40, color: theme.primaryColor))
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          // Name
          Text(
            _displayName ?? 'Guest User',
            style: GoogleFonts.judson(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          // Subtitle (Start Date or Recovery Time)
          if (_status?.startDate != null)
            Text(
              "Started Journey • ${DateFormat.yMMMd().format(_status!.startDate!)}",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
                letterSpacing: 0.5,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBadge(ThemeData theme, Milestone milestone) {
    // Calculate elapsed time (simple version, not real-time updated in this screen)
    final now = DateTime.now();
    final elapsed = _status?.startDate != null ? now.difference(_status!.startDate!) : Duration.zero;
    final duration = Duration(seconds: milestone.durationSeconds);
    final unlocked = milestone.isUnlocked;
    
    final color = _parseColor(milestone.colorHex);
    
    // Gradient
    final gradientColors = unlocked 
        ? [color.withOpacity(0.8), color]
        : [Colors.grey.shade300, Colors.grey.shade400];

    // Time remaining
    String timeRemaining = '';
    if (!unlocked) {
      final remaining = duration - elapsed;
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

    return Container(
      width: 110,
      height: 155,
      // No margin needed as Wrap handles it, but ensures internal layout matches
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
                color: (unlocked ? color : Colors.grey).withOpacity(0.05),
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
                      color: (unlocked ? color : Colors.grey).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: milestone.badgeImageUrl != null && milestone.badgeImageUrl!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            milestone.badgeImageUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return FaIcon(
                                _resolveIcon(milestone.iconCode),
                                size: 24,
                                color: Colors.white,
                              );
                            },
                          ),
                        )
                      : FaIcon(
                          _resolveIcon(milestone.iconCode),
                          size: 24,
                          color: Colors.white,
                        ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Label
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  milestone.label,
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
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "Active: ${_formatCompactDuration(elapsed - duration)}",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: color,
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

  IconData _resolveIcon(int code) {
    // Basic mapping, extend as needed based on common FontAwesome codes
    // or pass IconData directly if model supported it.
    // For now, using a simple map based on typical codes or fallback.
    const Map<int, IconData> iconMap = {
      61943: FontAwesomeIcons.award,      // Common milestone
      61769: FontAwesomeIcons.calendarCheck, // Weekly milestone
      0xf4d8: FontAwesomeIcons.seedling,
      0xf784: FontAwesomeIcons.calendarWeek,
      0xf554: FontAwesomeIcons.personWalking,
      0xf5a2: FontAwesomeIcons.medal,
      0xf005: FontAwesomeIcons.star,
      0xf4c9: FontAwesomeIcons.shieldHeart,
      0xf091: FontAwesomeIcons.trophy,
    };
    return iconMap[code] ?? FontAwesomeIcons.certificate;
  }
}
