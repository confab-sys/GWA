import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum EventType {
  community,
  seminar,
  groupCall,
}

enum AvailabilityStatus {
  available,
  notAvailable,
  notResponded,
}

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String time;
  final EventType type;
  final String location;
  final int maxParticipants;
  final String? imageUrl;
  AvailabilityStatus availability;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.type,
    required this.location,
    required this.maxParticipants,
    this.imageUrl,
    this.availability = AvailabilityStatus.notResponded,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'time': time,
      'type': type.toString().split('.').last,
      'location': location,
      'maxParticipants': maxParticipants,
      'imageUrl': imageUrl,
      'availability': availability.toString().split('.').last,
    };
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      time: json['time'],
      type: EventType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      location: json['location'],
      maxParticipants: json['maxParticipants'],
      imageUrl: json['imageUrl'],
      availability: AvailabilityStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['availability'],
        orElse: () => AvailabilityStatus.notResponded,
      ),
    );
  }
}

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  List<Event> events = [];
  bool isLoading = true;
  String selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    // Mock events data
    final mockEvents = [
      Event(
        id: '1',
        title: 'Community Mental Health Gathering',
        description: 'Join us for an open discussion about mental health awareness and community support. Share experiences and learn coping strategies.',
        date: DateTime.now().add(const Duration(days: 3)),
        time: '6:00 PM - 8:00 PM',
        type: EventType.community,
        location: 'Community Center, Main Hall',
        maxParticipants: 50,
        imageUrl: 'assets/images/mental_health_community.jpg',
      ),
      Event(
        id: '2',
        title: 'Stress Management Seminar',
        description: 'Professional seminar on effective stress management techniques. Learn practical tools for daily stress reduction.',
        date: DateTime.now().add(const Duration(days: 7)),
        time: '2:00 PM - 4:00 PM',
        type: EventType.seminar,
        location: 'Online via Zoom',
        maxParticipants: 100,
        imageUrl: 'assets/images/stress_seminar.jpg',
      ),
      Event(
        id: '3',
        title: 'Group Video Call: Anxiety Support',
        description: 'Weekly group video call for anxiety support. Share experiences and receive peer support in a safe environment.',
        date: DateTime.now().add(const Duration(days: 2)),
        time: '7:00 PM - 8:30 PM',
        type: EventType.groupCall,
        location: 'Google Meet',
        maxParticipants: 15,
        imageUrl: 'assets/images/anxiety_support.jpg',
      ),
      Event(
        id: '4',
        title: 'Mindfulness Workshop',
        description: 'Interactive workshop on mindfulness practices. Learn meditation techniques and mindful living strategies.',
        date: DateTime.now().add(const Duration(days: 5)),
        time: '10:00 AM - 12:00 PM',
        type: EventType.seminar,
        location: 'Wellness Center',
        maxParticipants: 30,
        imageUrl: 'assets/images/mindfulness_workshop.jpg',
      ),
      Event(
        id: '5',
        title: 'Depression Support Group',
        description: 'Monthly support group for individuals dealing with depression. Professional facilitation and peer support.',
        date: DateTime.now().add(const Duration(days: 10)),
        time: '6:30 PM - 8:00 PM',
        type: EventType.community,
        location: 'Mental Health Center',
        maxParticipants: 20,
        imageUrl: 'assets/images/depression_support.jpg',
      ),
      Event(
        id: '6',
        title: 'Teen Mental Health Forum',
        description: 'Special forum focused on teen mental health challenges. Parents and teens welcome to attend.',
        date: DateTime.now().add(const Duration(days: 8)),
        time: '4:00 PM - 6:00 PM',
        type: EventType.seminar,
        location: 'Youth Center Auditorium',
        maxParticipants: 80,
        imageUrl: 'assets/images/teen_mental_health.jpg',
      ),
    ];

    // Load saved availability data
    final prefs = await SharedPreferences.getInstance();
    final savedEventsData = prefs.getString('events_data');
    
    if (savedEventsData != null) {
      try {
        final List<dynamic> eventsJson = json.decode(savedEventsData);
        final savedEvents = eventsJson.map((json) => Event.fromJson(json)).toList();
        
        // Merge saved availability with mock data
        for (var i = 0; i < mockEvents.length; i++) {
          final savedEvent = savedEvents.firstWhere(
            (e) => e.id == mockEvents[i].id,
            orElse: () => mockEvents[i],
          );
          mockEvents[i].availability = savedEvent.availability;
        }
      } catch (e) {
        print('Error loading saved events: $e');
      }
    }

    setState(() {
      events = mockEvents;
      isLoading = false;
    });
  }

  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = events.map((event) => event.toJson()).toList();
    await prefs.setString('events_data', json.encode(eventsJson));
  }

  void _updateAvailability(Event event, AvailabilityStatus status) {
    setState(() {
      event.availability = status;
    });
    _saveEvents();
  }

  List<Event> get filteredEvents {
    if (selectedFilter == 'All') return events;
    return events.where((event) {
      switch (selectedFilter) {
        case 'Community':
          return event.type == EventType.community;
        case 'Seminars':
          return event.type == EventType.seminar;
        case 'Group Calls':
          return event.type == EventType.groupCall;
        case 'Available':
          return event.availability == AvailabilityStatus.available;
        case 'Not Available':
          return event.availability == AvailabilityStatus.notAvailable;
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
    // Using placeholder images from Unsplash for different event types
    switch (type) {
      case EventType.community:
        return 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=400&h=300&fit=crop&crop=faces';
      case EventType.seminar:
        return 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=400&h=300&fit=crop&crop=faces';
      case EventType.groupCall:
        return 'https://images.unsplash.com/photo-1591115765373-5207764f72e7?w=400&h=300&fit=crop&crop=faces';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
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
            onPressed: () {
              _showFilterDialog();
            },
          ),
        ],
      ),
      body: isLoading
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
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting your filter',
                        style: GoogleFonts.inter(
                          textStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 cards per row
                    childAspectRatio: 0.85, // Adjusted for larger photos
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    final event = filteredEvents[index];
                    return _buildEventGridCard(event);
                  },
                ),
    );
  }

  Widget _buildEventGridCard(Event event) {
    final daysUntilEvent = event.date.difference(DateTime.now()).inDays;
    final eventColor = _getEventColor(event.type);

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
          // Event Photo Placeholder (Larger)
          Container(
            height: 120, // Increased from 80 to 120
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              image: DecorationImage(
                image: NetworkImage(_getEventPlaceholderImage(event.type)),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                // Gradient overlay for better text readability
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
                        Colors.black.withOpacity(0.7), // Darker gradient for better text visibility
                      ],
                    ),
                  ),
                ),
                // Event type badge in top-left
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), // Slightly larger
                    decoration: BoxDecoration(
                      color: eventColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getEventIcon(event.type),
                          color: Colors.white,
                          size: 12, // Slightly larger
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _getEventTypeText(event.type),
                          style: GoogleFonts.inter(
                            textStyle: const TextStyle(
                              fontSize: 10, // Slightly larger
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Days until event in top-right
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
                        textStyle: TextStyle(
                          fontSize: 10, // Slightly larger
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                // Title and description at bottom of image
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
                            fontSize: 13, // Larger text for title
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
                            fontSize: 10, // Slightly larger description
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
          // Event Details (Location, Time, Participants)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(), // Add spacer to push details to bottom
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 10, color: Colors.grey[600]),
                      const SizedBox(width: 1),
                      Expanded(
                        child: Text(
                          event.location,
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
                        event.time,
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
                        '${event.maxParticipants}',
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
          // Availability Selection
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildGridAvailabilityButton(event, AvailabilityStatus.available, 'Yes', Colors.green),
                _buildGridAvailabilityButton(event, AvailabilityStatus.notAvailable, 'No', Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridAvailabilityButton(Event event, AvailabilityStatus status, String text, Color color) {
    final isSelected = event.availability == status;
    
    return GestureDetector(
      onTap: () => _updateAvailability(event, status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Icon(
                Icons.check_circle,
                size: 12,
                color: color,
              ),
            if (isSelected) const SizedBox(width: 2),
            Text(
              text,
              style: GoogleFonts.inter(
                textStyle: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? color : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityButton(Event event, AvailabilityStatus status, String text, Color color) {
    final isSelected = event.availability == status;
    
    return GestureDetector(
      onTap: () => _updateAvailability(event, status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Icon(
                Icons.check_circle,
                size: 14,
                color: color,
              ),
            if (isSelected) const SizedBox(width: 4),
            Text(
              text,
              style: GoogleFonts.inter(
                textStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? color : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Filter Events',
          style: GoogleFonts.inter(
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterOption('All'),
            _buildFilterOption('Community'),
            _buildFilterOption('Seminars'),
            _buildFilterOption('Group Calls'),
            const Divider(),
            _buildFilterOption('Available'),
            _buildFilterOption('Not Available'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.inter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(String filter) {
    return ListTile(
      title: Text(
        filter,
        style: GoogleFonts.inter(),
      ),
      leading: Radio<String>(
        value: filter,
        groupValue: selectedFilter,
        onChanged: (value) {
          setState(() {
            selectedFilter = value!;
          });
          Navigator.pop(context);
        },
      ),
      onTap: () {
        setState(() {
          selectedFilter = filter;
        });
        Navigator.pop(context);
      },
    );
  }
}