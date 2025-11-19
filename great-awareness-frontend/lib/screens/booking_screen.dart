import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  String? _selectedTimeSlot;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // Mock data for available time slots
  final Map<String, List<String>> _availableTimeSlots = {
    '2024-01-15': ['09:00 AM', '10:30 AM', '02:00 PM', '03:30 PM'],
    '2024-01-16': ['09:30 AM', '11:00 AM', '01:30 PM', '04:00 PM'],
    '2024-01-17': ['10:00 AM', '11:30 AM', '02:30 PM', '04:30 PM'],
    '2024-01-18': ['08:30 AM', '10:00 AM', '01:00 PM', '03:00 PM'],
    '2024-01-19': ['09:00 AM', '10:30 AM', '02:00 PM', '03:30 PM'],
    '2024-01-22': ['09:30 AM', '11:00 AM', '01:30 PM', '04:00 PM'],
    '2024-01-23': ['10:00 AM', '11:30 AM', '02:30 PM', '04:30 PM'],
  };

  // Mock data for unavailable dates
  final List<String> _unavailableDates = [
    '2024-01-20',
    '2024-01-21',
    '2024-01-27',
    '2024-01-28',
  ];

  // Mock data for user's existing bookings
  final List<Booking> _userBookings = [
    Booking(
      id: '1',
      date: DateTime(2024, 1, 10),
      time: '10:00 AM',
      name: 'John Doe',
      email: 'john.doe@example.com',
      phone: '+1234567890',
    ),
    Booking(
      id: '2',
      date: DateTime(2024, 1, 12),
      time: '02:30 PM',
      name: 'John Doe',
      email: 'john.doe@example.com',
      phone: '+1234567890',
    ),
  ];

  bool _isDateUnavailable(DateTime date) {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    return _unavailableDates.contains(dateString);
  }

  List<String> _getTimeSlotsForDate(DateTime date) {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    return _availableTimeSlots[dateString] ?? [];
  }

  Future<void> _bookAppointment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a time slot',
            style: GoogleFonts.judson(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Mock booking logic
    final newBooking = Booking(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: _selectedDate,
      time: _selectedTimeSlot!,
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
    );

    setState(() {
      _userBookings.add(newBooking);
      // Remove the selected time slot from availability
      final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
      _availableTimeSlots[dateString]?.remove(_selectedTimeSlot);
    });

    // Clear form
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    setState(() {
      _selectedTimeSlot = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Appointment booked successfully!',
          style: GoogleFonts.judson(),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _cancelBooking(Booking booking) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Cancel Appointment',
            style: GoogleFonts.judson(
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          content: Text(
            'Are you sure you want to cancel your appointment on ${DateFormat('MMM dd, yyyy').format(booking.date)} at ${booking.time}?',
            style: GoogleFonts.judson(
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Keep Appointment',
                style: GoogleFonts.judson(
                  textStyle: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _userBookings.remove(booking);
                  // Add the time slot back to availability
                  final dateString = DateFormat('yyyy-MM-dd').format(booking.date);
                  if (!_availableTimeSlots.containsKey(dateString)) {
                    _availableTimeSlots[dateString] = [];
                  }
                  _availableTimeSlots[dateString]?.add(booking.time);
                  _availableTimeSlots[dateString]?.sort();
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Appointment cancelled successfully',
                      style: GoogleFonts.judson(),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.judson(
                  textStyle: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCalendarSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select a Date',
            style: GoogleFonts.judson(
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TableCalendar(
              focusedDay: _focusedDate,
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 30)),
              selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: const Color(0xFFD3E4DE),
                  borderRadius: BorderRadius.circular(8),
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledDecoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: GoogleFonts.judson(
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              enabledDayPredicate: (day) => !_isDateUnavailable(day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDate = selectedDay;
                  _focusedDate = focusedDay;
                  _selectedTimeSlot = null;
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFFD3E4DE),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Available',
                style: GoogleFonts.judson(
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Unavailable',
                style: GoogleFonts.judson(
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotsSection() {
    final timeSlots = _getTimeSlotsForDate(_selectedDate);
    
    if (timeSlots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'No available time slots for this date',
            style: GoogleFonts.judson(
              textStyle: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Time Slots',
            style: GoogleFonts.judson(
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: timeSlots.length,
            itemBuilder: (context, index) {
              final timeSlot = timeSlots[index];
              final isSelected = _selectedTimeSlot == timeSlot;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTimeSlot = timeSlot;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFD3E4DE) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFD3E4DE) : Colors.grey[300]!,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      timeSlot,
                      style: GoogleFonts.judson(
                        textStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.black : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBookingForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Details',
              style: GoogleFonts.judson(
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                labelStyle: GoogleFonts.judson(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
              style: GoogleFonts.judson(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                labelStyle: GoogleFonts.judson(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.email),
              ),
              style: GoogleFonts.judson(),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle: GoogleFonts.judson(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.phone),
              ),
              style: GoogleFonts.judson(),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                if (!RegExp(r'^\+?[0-9]{10,}$').hasMatch(value)) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _bookAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD3E4DE),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Book Appointment',
                  style: GoogleFonts.judson(
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingBookings() {
    if (_userBookings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'No existing bookings',
            style: GoogleFonts.judson(
              textStyle: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Bookings',
            style: GoogleFonts.judson(
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _userBookings.length,
            itemBuilder: (context, index) {
              final booking = _userBookings[index];
              final isPastBooking = booking.date.isBefore(DateTime.now());
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('MMM dd, yyyy').format(booking.date),
                            style: GoogleFonts.judson(
                              textStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            booking.time,
                            style: GoogleFonts.judson(
                              textStyle: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          if (isPastBooking) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Completed',
                              style: GoogleFonts.judson(
                                textStyle: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!isPastBooking)
                      ElevatedButton(
                        onPressed: () => _cancelBooking(booking),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.judson(
                            textStyle: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD3E4DE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Book Therapy',
          style: GoogleFonts.judson(
            textStyle: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCalendarSection(),
            const SizedBox(height: 16),
            _buildTimeSlotsSection(),
            const SizedBox(height: 16),
            _buildBookingForm(),
            const SizedBox(height: 16),
            _buildExistingBookings(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}

class Booking {
  final String id;
  final DateTime date;
  final String time;
  final String name;
  final String email;
  final String phone;

  Booking({
    required this.id,
    required this.date,
    required this.time,
    required this.name,
    required this.email,
    required this.phone,
  });
}