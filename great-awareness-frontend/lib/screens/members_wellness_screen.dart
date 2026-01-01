import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../services/wellness_service.dart';
import 'people_wellness_screen.dart';

// Helper to resolve dynamic icons
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

class MembersWellnessScreen extends StatefulWidget {
  const MembersWellnessScreen({super.key});

  @override
  State<MembersWellnessScreen> createState() => _MembersWellnessScreenState();
}

class _MembersWellnessScreenState extends State<MembersWellnessScreen> {
  bool _isLoading = true;
  List<CommunityMember> _communityMembers = [];

  @override
  void initState() {
    super.initState();
    _loadCommunity();
  }

  Future<void> _loadCommunity() async {
    try {
      final members = await context.read<WellnessService>().getCommunity();
      if (mounted) {
        setState(() {
          _communityMembers = members;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading members: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.primaryColor),
        title: Text(
          "Community Members",
          style: GoogleFonts.judson(
            color: theme.textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _communityMembers.isEmpty
              ? Center(
                  child: Text(
                    "No active members yet.",
                    style: GoogleFonts.inter(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _communityMembers.length,
                  itemBuilder: (context, index) {
                    final member = _communityMembers[index];
                    final streak = DateTime.now().difference(member.startDate).inDays;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PeopleWellnessScreen(
                                userId: member.userId,
                                userName: member.name,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(15),
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
                          trailing: member.latestMilestone != null
                              ? _buildMilestoneBadge(member.latestMilestone!, theme)
                              : Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildMilestoneBadge(CommunityMilestone milestone, ThemeData theme) {
    if (milestone.badgeImageUrl != null && milestone.badgeImageUrl!.isNotEmpty) {
      return Tooltip(
        message: milestone.label,
        child: ClipOval(
          child: Image.network(
            milestone.badgeImageUrl!,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
               return _buildMilestoneIcon(milestone, theme);
            },
          ),
        ),
      );
    }
    return Tooltip(message: milestone.label, child: _buildMilestoneIcon(milestone, theme));
  }

  Widget _buildMilestoneIcon(CommunityMilestone milestone, ThemeData theme) {
    Color badgeColor = theme.primaryColor;
    try {
      String hex = milestone.colorHex.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      badgeColor = Color(int.parse(hex, radix: 16));
    } catch (e) {
      // ignore
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: badgeColor, width: 2),
      ),
      alignment: Alignment.center,
      child: FaIcon(
        _resolveIcon(milestone.iconCode),
        size: 20,
        color: badgeColor,
      ),
    );
  }
}
