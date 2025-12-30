import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/wellness_service.dart';
import 'event_upload_screen.dart';

enum EventType {
  community,
  seminar,
  groupCall,
}

// Helper to map DB event to UI event type (simple logic for now)
EventType _guessEventType(String title) {
  final t = title.toLowerCase();
  if (t.contains('seminar') || t.contains('workshop')) return EventType.seminar;
  if (t.contains('call') || t.contains('zoom') || t.contains('online')) return EventType.groupCall;
  return EventType.community;
}

class EventsScreen extends StatefulWidget {
  final bool isEmbedded;
  const EventsScreen({super.key, this.isEmbedded = false});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  List<WellnessEvent> events = [];
  bool isLoading = true;
  String selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => isLoading = true);
    try {
      final fetchedEvents = await Provider.of<WellnessService>(context, listen: false).getEvents();
      setState(() {
        events = fetchedEvents;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading events: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _handleJoinLeave(WellnessEvent event) async {
    try {
      if (event.isJoined) {
        await Provider.of<WellnessService>(context, listen: false).leaveEvent(event.id);
      } else {
        await Provider.of<WellnessService>(context, listen: false).joinEvent(event.id);
      }
      _loadEvents(); // Refresh to get updated participant counts
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  List<WellnessEvent> get filteredEvents {
    if (selectedFilter == 'All') return events;
    return events.where((event) {
      final type = _guessEventType(event.title);
      switch (selectedFilter) {
        case 'Community':
          return type == EventType.community;
        case 'Seminars':
          return type == EventType.seminar;
        case 'Group Calls':
          return type == EventType.groupCall;
        case 'Available': 
          return event.isJoined;
        case 'Not Available':
          return !event.isJoined;
        default:
          return true;
      }
    }).toList();
  }

  IconData _getEventIcon(EventType type) {
    switch (type) {
      case EventType.community:
        return Icons.groups_rounded;
      case EventType.seminar:
        return Icons.psychology_alt_rounded;
      case EventType.groupCall:
        return Icons.video_chat_rounded;
    }
  }

  Color _getEventColor(EventType type) {
    switch (type) {
      case EventType.community:
        return Colors.green;
      case EventType.seminar:
        return Colors.blue;
      case EventType.groupCall:
        return Colors.purple;
    }
  }

  String _getEventTypeText(EventType type) {
    switch (type) {
      case EventType.community:
        return 'Community';
      case EventType.seminar:
        return 'Seminar';
      case EventType.groupCall:
        return 'Group Call';
    }
  }

  String _getEventPlaceholderImage(EventType type) {
    switch (type) {
      case EventType.community:
        return 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=400&h=300&fit=crop&crop=faces';
      case EventType.seminar:
        return 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=400&h=300&fit=crop&crop=faces';
      case EventType.groupCall:
        return 'https://images.unsplash.com/photo-1591115765373-5207764f72e7?w=400&h=300&fit=crop&crop=faces';
    }
  }

  ImageProvider _getImageProvider(String url) {
    if (url.startsWith('data:image')) {
      try {
        final base64String = url.split(',').last;
        return MemoryImage(base64Decode(base64String));
      } catch (e) {
        debugPrint('Error decoding base64 image: $e');
        return const NetworkImage('https://via.placeholder.com/400x300?text=Error');
      }
    }
    return NetworkImage(url);
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Events'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'All',
            'Community',
            'Seminars',
            'Group Calls',
            'Available',
            'Not Available'
          ].map((filter) => ListTile(
            title: Text(filter),
            leading: Radio<String>(
              value: filter,
              groupValue: selectedFilter,
              onChanged: (value) {
                setState(() => selectedFilter = value!);
                Navigator.pop(context);
              },
            ),
          )).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isEmbedded ? Colors.transparent : const Color(0xFFF5F7FA),
      appBar: widget.isEmbedded ? null : AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Upcoming Events',
          style: GoogleFonts.inter(
            textStyle: const TextStyle(
              color: Colors.black,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined, color: Colors.black),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Pass the existing WellnessService to the new route
          final wellnessService = Provider.of<WellnessService>(context, listen: false);
          
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChangeNotifierProvider.value(
                value: wellnessService,
                child: const EventUploadScreen(),
              ),
            ),
          );
          if (result == true) {
            _loadEvents();
          }
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          if (widget.isEmbedded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upcoming Events',
                    style: GoogleFonts.judson(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.filter_alt_outlined),
                    onPressed: _showFilterDialog,
                  ),
                ],
              ),
            ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.blue))
                : filteredEvents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_available_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No events found',
                              style: GoogleFonts.inter(
                                textStyle: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: filteredEvents.length,
                        itemBuilder: (context, index) {
                          final event = filteredEvents[index];
                          return _buildEventGridCard(event);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventGridCard(WellnessEvent event) {
    final daysUntilEvent = event.eventDate.difference(DateTime.now()).inDays;
    final type = _guessEventType(event.title);
    final eventColor = _getEventColor(type);
    
    final imageUrl = (event.imageUrl != null && event.imageUrl!.isNotEmpty) 
        ? event.imageUrl! 
        : _getEventPlaceholderImage(type);
    
    final imageProvider = _getImageProvider(imageUrl);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Photo
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
                onError: (e, s) {}, // Handle error silently
              ),
            ),
            child: Stack(
              children: [
                // Gradient
                Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
                // Type Badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: eventColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getEventIcon(type),
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _getEventTypeText(type),
                          style: GoogleFonts.inter(
                            textStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Days Badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: daysUntilEvent <= 3 ? Colors.red.withOpacity(0.9) : Colors.green.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      daysUntilEvent == 0 ? 'Today' : daysUntilEvent == 1 ? 'Tomorrow' : '$daysUntilEvent days',
                      style: GoogleFonts.inter(
                        textStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                // Title/Desc
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        event.title,
                        style: GoogleFonts.inter(
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        event.description,
                        style: GoogleFonts.inter(
                          textStyle: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.2,
                          ),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 10, color: Colors.grey[600]),
                      const SizedBox(width: 1),
                      Expanded(
                        child: Text(
                          event.location ?? 'No location',
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(
                              fontSize: 8,
                              color: Colors.grey[600],
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.schedule_outlined, size: 10, color: Colors.grey[600]),
                      const SizedBox(width: 1),
                      Text(
                        DateFormat('h:mm a').format(event.eventDate),
                        style: GoogleFonts.inter(
                          textStyle: TextStyle(
                            fontSize: 8,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.people_outline, size: 10, color: Colors.grey[600]),
                      const SizedBox(width: 1),
                      Text(
                        '${event.participantCount}',
                        style: GoogleFonts.inter(
                          textStyle: TextStyle(
                            fontSize: 8,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Actions
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 24,
                  child: ElevatedButton(
                    onPressed: () => _handleJoinLeave(event),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: event.isJoined ? Colors.grey[200] : eventColor,
                      foregroundColor: event.isJoined ? Colors.black87 : Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      elevation: 0,
                      textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    child: Text(event.isJoined ? 'Leave' : 'Join'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
