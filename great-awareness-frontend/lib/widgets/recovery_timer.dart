import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

class RecoveryTimer extends StatefulWidget {
  final DateTime startTime;
  final VoidCallback? onMilestoneReached;
  final Color? textColor;

  const RecoveryTimer({
    super.key,
    required this.startTime,
    this.onMilestoneReached,
    this.textColor,
  });

  @override
  State<RecoveryTimer> createState() => _RecoveryTimerState();
}

class _RecoveryTimerState extends State<RecoveryTimer>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  late DateTime _currentTime;
  
  // Cache the components to avoid creating objects every frame if possible,
  // but for clean logic we'll recompute. The calculation is cheap.
  late RecoveryDuration _duration;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _duration = RecoveryDuration.from(widget.startTime.toLocal(), _currentTime);
    
    _ticker = createTicker((_) {
      final now = DateTime.now();
      if (now.difference(_currentTime).inMilliseconds > 0) {
        setState(() {
          _currentTime = now;
          _duration = RecoveryDuration.from(widget.startTime.toLocal(), _currentTime);
        });
      }
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The Atomic Clock / Concentric Rings
        SizedBox(
          height: 320,
          width: 320,
          child: CustomPaint(
            painter: _TimerRingsPainter(
              duration: _duration,
              theme: theme,
              isDark: isDark,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDigitalReadout(theme, isDark),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDigitalReadout(ThemeData theme, bool isDark) {
    // A clean vertical layout for the digital time inside the rings
    // Or a compact grid.
    
    TextStyle valueStyle = GoogleFonts.chivoMono(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: widget.textColor ?? theme.primaryColor,
    );
    
    TextStyle labelStyle = GoogleFonts.inter(
      fontSize: 10,
      color: isDark ? Colors.white60 : Colors.black54,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _timeUnit(_duration.years, "Yrs", valueStyle, labelStyle),
            const SizedBox(width: 10),
            _timeUnit(_duration.months, "Mos", valueStyle, labelStyle),
            const SizedBox(width: 10),
            _timeUnit(_duration.days, "Days", valueStyle, labelStyle),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _timeUnit(_duration.hours, "Hr", valueStyle, labelStyle),
            Text(":", style: valueStyle.copyWith(fontSize: 20)),
            _timeUnit(_duration.minutes, "Min", valueStyle, labelStyle),
            Text(":", style: valueStyle.copyWith(fontSize: 20)),
            _timeUnit(_duration.seconds, "Sec", valueStyle, labelStyle),
          ],
        ),
      ],
    );
  }

  Widget _timeUnit(int value, String label, TextStyle vStyle, TextStyle lStyle) {
    return Column(
      children: [
        Text(value.toString().padLeft(2, '0'), style: vStyle),
        Text(label.toUpperCase(), style: lStyle),
      ],
    );
  }
}

class RecoveryDuration {
  final int years;
  final int months;
  final int days;
  final int hours;
  final int minutes;
  final int seconds;
  final int microseconds;
  final int totalDaysInMonth; // For progress calculation

  RecoveryDuration({
    required this.years,
    required this.months,
    required this.days,
    required this.hours,
    required this.minutes,
    required this.seconds,
    required this.microseconds,
    required this.totalDaysInMonth,
  });

  factory RecoveryDuration.from(DateTime start, DateTime end) {
    // Precise calculation of Y/M/D is tricky due to leap years/months.
    // We'll use a standard approach:
    
    int years = end.year - start.year;
    int months = end.month - start.month;
    int days = end.day - start.day;
    
    if (days < 0) {
      months--;
      // Days in the previous month of 'end' date
      final prevMonth = DateTime(end.year, end.month - 1);
      final daysInPrevMonth = DateUtils.getDaysInMonth(prevMonth.year, prevMonth.month);
      days += daysInPrevMonth;
    }
    
    if (months < 0) {
      years--;
      months += 12;
    }

    Duration diff = end.difference(start);
    
    // We can't just take diff.inHours because that includes the years/months/days.
    // We need the residual time.
    // Reconstruct the date up to the Day
    DateTime tempDate = DateTime(
      start.year + years, 
      start.month + months, 
      start.day + days
    );
    
    // If tempDate is ahead of end (due to day overflow logic issues), adjust.
    // But the above logic is standard.
    // Actually, accurate YMD + HMS requires getting the HMS from the difference
    // of the timestamps excluding the YMD part.
    // Or simpler: Just take the HMS from the difference of the *time of day* if we align dates.
    
    // Let's use the difference between 'end' and the 'YMD milestone'
    // But 'YMD milestone' might be tricky if start day > end day.
    
    // Alternative:
    // Calculate YMD as above.
    // Calculate HMS from the remaining duration.
    // But wait, the 'days' calculation above is 'calendar days'.
    // The HMS should be the time elapsed since that calendar moment.
    
    // Let's construct the "current anniversary"
    DateTime anniversary = DateTime(
      start.year + years,
      start.month + months,
      start.day + days,
      start.hour,
      start.minute,
      start.second,
      start.millisecond,
      start.microsecond
    );

    // If anniversary is in the future (due to variable month lengths?), backtrack?
    // The standard library 'intl' doesn't do Duration -> YMD.
    // The logic above (days < 0) handles the month length.
    
    // Let's refine the 'anniversary' to be safe.
    // Actually, we just need the time part difference if we assume YMD handles the date part.
    // But 'start' might be 10:00 PM and 'end' is 9:00 AM.
    // Then days would need to be decremented?
    
    // Let's stick to Duration for HMS.
    // Hours = totalHours % 24
    // Minutes = totalMinutes % 60
    // Seconds = totalSeconds % 60
    // Microseconds = totalMicros % 1000000
    
    // But we need to sync this with YMD.
    // If we just use total duration for HMS, it matches "Total Time Elapsed".
    // But "Days" in YMD is calendar days.
    // If I have been recovering for 1.5 days.
    // Y=0, M=0, D=1. H=12.
    // My logic above: 
    // Start: Jan 1, 10:00. End: Jan 2, 22:00.
    // days = 2 - 1 = 1.
    // H/M/S from diff?
    // Diff = 36 hours.
    // 36 % 24 = 12 hours. Correct.
    
    // Start: Jan 1, 22:00. End: Jan 2, 10:00.
    // days = 2 - 1 = 1.
    // Diff = 12 hours.
    // 12 % 24 = 12 hours.
    // Wait, if I say 1 Day 12 Hours, that's 36 hours. But actual diff is 12 hours.
    // So days calculation must account for time.
    
    Duration totalDiff = end.difference(start);
    
    // Correct logic:
    // 1. Calculate Calendar YMD candidate.
    // 2. Construct candidate date.
    // 3. If candidate > end, subtract 1 day (or month/year).
    
    // Simpler approach for visual continuity:
    // Just use Duration for HMS.
    // Use Calendar logic for YMD, but adjust if time is negative.
    
    int h = totalDiff.inHours % 24;
    int m = totalDiff.inMinutes % 60;
    int s = totalDiff.inSeconds % 60;
    int us = totalDiff.inMicroseconds % 1000000;
    
    // Adjust YMD if needed
    // If (end time) < (start time), we borrowed a day?
    // No, `totalDiff` is absolute.
    // We need `days` to be `totalDays`.
    // But we want Y/M/D breakdown.
    
    // Let's rely on the JodaTime-like logic:
    DateTime temp = start;
    int y = 0;
    while (temp.add(const Duration(days: 366)).isBefore(end)) {
        temp = temp.add(const Duration(days: 366)); // Leap year check approx?
        // Better:
        // DateTime nextYear = DateTime(temp.year + 1, temp.month, temp.day, temp.hour, temp.minute, temp.second);
        // if (nextYear.isBefore(end)) { temp = nextYear; y++; } else break;
    }
    // This iterative approach is safe but maybe slow? No, max 100 iterations.
    
    // Let's stick to the subtraction method with time adjustment.
    
    DateTime d1 = start;
    DateTime d2 = end;
    
    int yearsDiff = d2.year - d1.year;
    int monthsDiff = d2.month - d1.month;
    int daysDiff = d2.day - d1.day;
    int hoursDiff = d2.hour - d1.hour;
    int minutesDiff = d2.minute - d1.minute;
    int secondsDiff = d2.second - d1.second;
    int microDiff = d2.microsecond - d1.microsecond;
    
    // Normalize negative values
    if (microDiff < 0) {
      secondsDiff--;
      microDiff += 1000000;
    }
    if (secondsDiff < 0) {
      minutesDiff--;
      secondsDiff += 60;
    }
    if (minutesDiff < 0) {
      hoursDiff--;
      minutesDiff += 60;
    }
    if (hoursDiff < 0) {
      daysDiff--;
      hoursDiff += 24;
    }
    if (daysDiff < 0) {
      monthsDiff--;
      // Days in previous month relative to d2
      DateTime prevMonth = DateTime(d2.year, d2.month - 1);
      daysDiff += DateUtils.getDaysInMonth(prevMonth.year, prevMonth.month);
    }
    if (monthsDiff < 0) {
      yearsDiff--;
      monthsDiff += 12;
    }
    
    return RecoveryDuration(
      years: yearsDiff,
      months: monthsDiff,
      days: daysDiff,
      hours: hoursDiff,
      minutes: minutesDiff,
      seconds: secondsDiff,
      microseconds: microDiff,
      totalDaysInMonth: DateUtils.getDaysInMonth(d2.year, d2.month),
    );
  }
}

class _TimerRingsPainter extends CustomPainter {
  final RecoveryDuration duration;
  final ThemeData theme;
  final bool isDark;

  _TimerRingsPainter({
    required this.duration,
    required this.theme,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2;
    
    // Configuration for rings
    // Order: Outermost -> Innermost
    // 1. Seconds (Continuous)
    // 2. Minutes (Discrete/Continuous)
    // 3. Hours
    // 4. Days
    // 5. Months
    // 6. Years (Static or slow)
    // 7. Microseconds (Innermost, fast pulse)
    
    final strokeWidth = 8.0;
    final spacing = 6.0;
    
    // Colors
    final bgRingColor = isDark ? Colors.white10 : Colors.black12;
    
    // Helper to draw ring
    void drawRing(int index, double progress, Color color) {
      final radius = maxRadius - (index * (strokeWidth + spacing));
      final rect = Rect.fromCircle(center: center, radius: radius);
      
      final paintBg = Paint()
        ..color = bgRingColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
        
      final paintProgress = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawCircle(center, radius, paintBg);
      
      // Start from top (-pi/2)
      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, paintProgress);
    }

    // 1. Seconds (Continuous)
    // progress = (seconds + micros/1M) / 60
    double secondsProgress = (duration.seconds + duration.microseconds / 1000000) / 60.0;
    drawRing(0, secondsProgress, const Color(0xFFE57373)); // Soft Red

    // 2. Minutes (Continuous for smoothness)
    // progress = (minutes + seconds/60) / 60
    double minutesProgress = (duration.minutes + secondsProgress) / 60.0;
    drawRing(1, minutesProgress, const Color(0xFF81C784)); // Soft Green

    // 3. Hours
    // progress = (hours + minutes/60) / 24
    double hoursProgress = (duration.hours + duration.minutes / 60.0) / 24.0;
    drawRing(2, hoursProgress, const Color(0xFF64B5F6)); // Soft Blue

    // 4. Days
    // progress = days / totalDaysInMonth
    double daysProgress = duration.days / duration.totalDaysInMonth;
    drawRing(3, daysProgress, const Color(0xFFFFB74D)); // Soft Orange

    // 5. Months
    // progress = months / 12
    double monthsProgress = duration.months / 12.0;
    drawRing(4, monthsProgress, const Color(0xFFBA68C8)); // Soft Purple
    
    // 6. Years
    // Arbitrary 10 years for full circle?
    double yearsProgress = (duration.years % 10) / 10.0;
    drawRing(5, yearsProgress, const Color(0xFF90A4AE)); // Blue Grey
    
    // 7. Microseconds (Innermost)
    // Pulse effect or fast spin?
    // Let's do 0-1 sec fill
    double microsProgress = duration.microseconds / 1000000.0;
    drawRing(6, microsProgress, theme.primaryColor.withOpacity(0.5));
  }

  @override
  bool shouldRepaint(covariant _TimerRingsPainter oldDelegate) {
    return true; // Repaint every frame
  }
}
