// screens/calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:planoviewer/screens/wish_screen.dart';
import '../models/roster_models.dart';

class CalendarScreen extends StatefulWidget {
  final WorkRosterData rosterData;
  final DateTime startDate;
  final DateTime endDate;

  const CalendarScreen({
    Key? key,
    required this.rosterData,
    required this.startDate,
    required this.endDate,
  }) : super(key: key);

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _selectionController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _selectionAnimation;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _selectionController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuart,
      ),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _selectionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _selectionController,
        curve: Curves.elasticOut,
      ),
    );

    _animationController.forward();

    print('=== CALENDAR DEBUG INFO ===');
    print('Start date: ${widget.startDate}');
    print('End date: ${widget.endDate}');
    print(
        'Date range: ${widget.endDate.difference(widget.startDate).inDays} days');
  }

  @override
  void dispose() {
    _animationController.dispose();
    _selectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allDays = widget.rosterData.getDays();
    final visibleDays = _getVisibleDays(allDays);
    final headerText = _getHeaderText();

    print('All days: ${allDays.length}, Visible days: ${visibleDays.length}');

    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Modern Header
              _buildHeader(headerText),

              // Stats Overview
              _buildStatsOverview(visibleDays),

              // Calendar
              _buildCalendarSection(visibleDays),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String headerText) {
    return Container(
      padding: EdgeInsets.all(24),
      child: Row(
        children: [
          // Back button
          Container(
            width: 44,
            height: 44,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF111827),
                size: 20,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Title section
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Color(0xFFE30613),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    headerText,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Wish calendar button
          Container(
            width: 44,
            height: 44,
            child: IconButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ShiftCalendarScreen(),
                ),
              ),
              icon: Icon(
                Icons.edit_calendar,
                color: Color(0xFF111827),
                size: 20,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(List<WorkDay> visibleDays) {
    final workingDays = visibleDays.where((d) => d.hasWork).length;
    final totalHours = _calculateTotalHours(visibleDays);

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 24),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '$workingDays',
                    'Arbeitstage',
                    Color(0xFF059669),
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: Color(0xFFE5E7EB),
                ),
                Expanded(
                  child: _buildStatItem(
                    '${visibleDays.length - workingDays}',
                    'Freie Tage',
                    Color(0xFF6366F1),
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: Color(0xFFE5E7EB),
                ),
                Expanded(
                  child: _buildStatItem(
                    '${totalHours}h',
                    'Stunden',
                    Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarSection(List<WorkDay> visibleDays) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.only(top: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Calendar header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  Text(
                    'KALENDER',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                      letterSpacing: 1.5,
                    ),
                  ),
                  Spacer(),
                  Text(
                    '${visibleDays.length} Tage',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Weekday headers
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So']
                    .map((day) => Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              day,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: (day == 'Sa' || day == 'So')
                                    ? Color(0xFFF59E0B)
                                    : Color(0xFF6B7280),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),

            // Calendar grid
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: _buildDynamicCalendarGrid(visibleDays),
              ),
            ),

            // Selected day details
            if (selectedDate != null) _buildSelectedDayDetails(visibleDays),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicCalendarGrid(List<WorkDay> days) {
    final startDate = widget.startDate;
    final endDate =
        widget.endDate.subtract(Duration(days: 1)); // Make inclusive

    // Calculate the calendar start (Monday of the week containing start date)
    final firstWeekday = startDate.weekday; // 1 = Monday, 7 = Sunday
    final calendarStart = startDate.subtract(Duration(days: firstWeekday - 1));

    // Calculate how many weeks we need to show all days
    final totalDays = endDate.difference(startDate).inDays + 1;
    final weeksNeeded = ((firstWeekday - 1 + totalDays) / 7).ceil();

    print('Calendar grid: ${weeksNeeded} weeks');
    print('Start: $startDate, End: $endDate');
    print('Calendar start: $calendarStart');

    return _buildCalendarWithDividers(
        calendarStart, startDate, endDate, days, weeksNeeded);
  }

  Widget _buildCalendarWithDividers(DateTime calendarStart, DateTime startDate,
      DateTime endDate, List<WorkDay> days, int weeksNeeded) {
    List<Widget> calendarRows = [];
    final monthNames = [
      '',
      'Januar',
      'Februar',
      'März',
      'April',
      'Mai',
      'Juni',
      'Juli',
      'August',
      'September',
      'Oktober',
      'November',
      'Dezember'
    ];

    int? lastMonth;

    for (int week = 0; week < weeksNeeded; week++) {
      List<Widget> weekCells = [];

      // Check if this week starts a new month
      bool shouldShowDivider = false;

      // Look for the first day of this week that's in our date range
      for (int day = 0; day < 7; day++) {
        final cellDate = calendarStart.add(Duration(days: week * 7 + day));
        final isInRange =
            cellDate.isAfter(startDate.subtract(Duration(days: 1))) &&
                cellDate.isBefore(endDate.add(Duration(days: 1)));

        if (isInRange) {
          if (lastMonth != null && cellDate.month != lastMonth) {
            shouldShowDivider = true;
          }
          if (lastMonth == null) {
            lastMonth = cellDate.month;
          }
          break;
        }
      }

      // Add month divider if needed
      if (shouldShowDivider) {
        for (int day = 0; day < 7; day++) {
          final cellDate = calendarStart.add(Duration(days: week * 7 + day));
          final isInRange =
              cellDate.isAfter(startDate.subtract(Duration(days: 1))) &&
                  cellDate.isBefore(endDate.add(Duration(days: 1)));

          if (isInRange && cellDate.month != lastMonth) {
            calendarRows.add(_buildMonthDivider(monthNames[cellDate.month]));
            lastMonth = cellDate.month;
            break;
          }
        }
      }

      // Build the week row
      for (int day = 0; day < 7; day++) {
        final cellDate = calendarStart.add(Duration(days: week * 7 + day));
        final isInRange =
            cellDate.isAfter(startDate.subtract(Duration(days: 1))) &&
                cellDate.isBefore(endDate.add(Duration(days: 1)));

        if (!isInRange) {
          // Empty cell for dates outside our range
          weekCells.add(Container(
            height: 56,
            child: Center(
              child: Text(
                '${cellDate.day}',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFFE5E7EB),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ));
          continue;
        }

        // Find the corresponding day data
        final dayIndex = cellDate.difference(startDate).inDays;
        final dayData = dayIndex < days.length ? days[dayIndex] : null;

        if (dayData == null) {
          weekCells.add(Container(height: 56)); // No data for this day
          continue;
        }

        final isWeekend = cellDate.weekday >= 6; // 6 = Saturday, 7 = Sunday
        final isSelected = selectedDate != null &&
            selectedDate!.year == cellDate.year &&
            selectedDate!.month == cellDate.month &&
            selectedDate!.day == cellDate.day;

        weekCells
            .add(_buildCalendarDay(cellDate, dayData, isWeekend, isSelected));
      }

      // Add the week row
      calendarRows.add(Container(
        margin: EdgeInsets.only(bottom: 8),
        child: Row(
          children: weekCells
              .map((cell) => Expanded(
                      child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: cell,
                  )))
              .toList(),
        ),
      ));
    }

    return SingleChildScrollView(
      child: Column(
        children: calendarRows,
      ),
    );
  }

  Widget _buildCalendarDay(
      DateTime cellDate, WorkDay dayData, bool isWeekend, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedDate = null;
            _selectionController.reverse();
          } else {
            selectedDate = cellDate;
            _selectionController.forward();
          }
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          color: _getDayBackgroundColor(dayData, isWeekend, isSelected),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getDayBorderColor(dayData, isWeekend, isSelected),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${cellDate.day}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _getDayTextColor(dayData, isWeekend, isSelected),
              ),
            ),
            SizedBox(height: 2),
            if (dayData.hasWork && dayData.shifts.isNotEmpty) ...[
              Container(
                width: 16,
                height: 2,
                decoration: BoxDecoration(
                  color: Color(0xFFE30613),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ] else if (dayData.hasWork && dayData.hoursWorked != '0:00') ...[
              Container(
                width: 12,
                height: 2,
                decoration: BoxDecoration(
                  color: Color(0xFF059669),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ] else if (isWeekend) ...[
              Container(
                width: 8,
                height: 2,
                decoration: BoxDecoration(
                  color: Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ] else ...[
              Container(
                width: 6,
                height: 1,
                decoration: BoxDecoration(
                  color: Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMonthDivider(String monthName) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: Color(0xFFE5E7EB),
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Color(0xFF111827),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              monthName.toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: Color(0xFFE5E7EB),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayDetails(List<WorkDay> visibleDays) {
    if (selectedDate == null) return Container();

    // Find the day data for selected date
    final dayIndex = selectedDate!.difference(widget.startDate).inDays;

    if (dayIndex < 0 || dayIndex >= visibleDays.length) return Container();

    final day = visibleDays[dayIndex];
    final dayName = _getDayName(selectedDate!.weekday);
    final isWeekend = selectedDate!.weekday >= 6;
    final monthNames = [
      '',
      'Januar',
      'Februar',
      'März',
      'April',
      'Mai',
      'Juni',
      'Juli',
      'August',
      'September',
      'Oktober',
      'November',
      'Dezember'
    ];

    return AnimatedBuilder(
      animation: _selectionAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _selectionAnimation.value,
          child: Opacity(
            opacity: _selectionAnimation.value,
            child: Container(
              margin: EdgeInsets.all(20),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(0xFF111827),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '${selectedDate!.day}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$dayName',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                            ),
                            Text(
                              '${selectedDate!.day}. ${monthNames[selectedDate!.month]} ${selectedDate!.year}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        child: IconButton(
                          onPressed: () {
                            setState(() => selectedDate = null);
                            _selectionController.reverse();
                          },
                          icon: Icon(
                            Icons.close,
                            color: Color(0xFF6B7280),
                            size: 16,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Content
                  if (day.shifts.isNotEmpty) ...[
                    SizedBox(height: 16),
                    ...day.shifts
                        .map((shift) => Container(
                              margin: EdgeInsets.only(bottom: 8),
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _getShiftAccentColor(shift.name),
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: _getShiftAccentColor(shift.name),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _getShiftDisplayName(shift.name),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF6B7280),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          _formatShiftInterval(shift.interval),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ] else if (!day.hasWork) ...[
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isWeekend
                                  ? Color(0xFFF59E0B).withOpacity(0.1)
                                  : Color(0xFFE5E7EB),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              isWeekend ? Icons.weekend : Icons.free_breakfast,
                              size: 16,
                              color: isWeekend
                                  ? Color(0xFFF59E0B)
                                  : Color(0xFF6B7280),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            isWeekend ? 'Wochenende' : 'Freier Tag',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF111827),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Hours worked
                  if (day.hoursWorked != '0:00' &&
                      day.hoursWorked.isNotEmpty) ...[
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF059669).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 12,
                            color: Color(0xFF059669),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Arbeitszeit: ${day.hoursWorked}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF059669),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Filter days based on roster release schedule
  List<WorkDay> _getVisibleDays(List<WorkDay> allDays) {
    final now = DateTime.now();

    if (now.day < 15) {
      // Before 15th: Show only current month
      final currentMonthDays = <WorkDay>[];

      for (int i = 0; i < allDays.length; i++) {
        final dayDate = widget.startDate.add(Duration(days: i));
        if (dayDate.month == now.month && dayDate.year == now.year) {
          currentMonthDays.add(allDays[i]);
        }
      }

      print('Filtering to current month only: ${currentMonthDays.length} days');
      return currentMonthDays;
    } else {
      // 15th and after: Show all days (current + next month)
      print('Showing all days: ${allDays.length} days');
      return allDays;
    }
  }

  /// Get header text based on visible date range
  String _getHeaderText() {
    final now = DateTime.now();
    final monthNames = [
      '',
      'JANUAR',
      'FEBRUAR',
      'MÄRZ',
      'APRIL',
      'MAI',
      'JUNI',
      'JULI',
      'AUGUST',
      'SEPTEMBER',
      'OKTOBER',
      'NOVEMBER',
      'DEZEMBER'
    ];

    if (now.day < 15) {
      // Before 15th: Show only current month
      return 'KALENDER ${monthNames[now.month]}';
    } else {
      // 15th and after: Show current + next month range
      final startMonth = monthNames[widget.startDate.month];
      final endMonth =
          monthNames[widget.endDate.subtract(Duration(days: 1)).month];

      if (startMonth == endMonth) {
        return 'KALENDER $startMonth';
      } else {
        return 'KALENDER $startMonth-$endMonth';
      }
    }
  }

  /// Calculate total hours for visible days
  int _calculateTotalHours(List<WorkDay> days) {
    return days.fold(0, (sum, day) {
      if (day.hoursWorked.isEmpty || day.hoursWorked == '0:00') return sum;
      final hours = day.hoursWorked.split(':')[0];
      return sum + (int.tryParse(hours) ?? 0);
    });
  }

  /// Format shift interval to 24-hour format (same as day_card.dart)
  String _formatShiftInterval(String interval) {
    if (interval.isEmpty) return interval;

    try {
      // Handle intervals like "6:30 AM - 2:30 PM" or "06:00-14:30"
      String separator = '-';
      if (interval.contains(' - ')) {
        separator = ' - ';
      }

      final parts = interval.split(separator);
      if (parts.length == 2) {
        final startTime = _convertTo24Hour(parts[0].trim());
        final endTime = _convertTo24Hour(parts[1].trim());
        return '$startTime$separator$endTime';
      }

      return _convertTo24Hour(interval);
    } catch (e) {
      print('Error formatting shift interval "$interval": $e');
      return interval;
    }
  }

  /// Simple 24-hour time converter
  String _convertTo24Hour(String timeString) {
    if (timeString.isEmpty) return timeString;

    // If no AM/PM, assume already 24-hour
    if (!timeString.toLowerCase().contains('am') &&
        !timeString.toLowerCase().contains('pm')) {
      return timeString;
    }

    final amPmRegex =
        RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)', caseSensitive: false);
    final match = amPmRegex.firstMatch(timeString);

    if (match != null) {
      int hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      final period = match.group(3)!.toUpperCase();

      if (period == 'PM' && hour != 12) {
        hour += 12;
      } else if (period == 'AM' && hour == 12) {
        hour = 0;
      }

      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }

    return timeString;
  }

  String _getDayName(int weekday) {
    final days = [
      'Montag',
      'Dienstag',
      'Mittwoch',
      'Donnerstag',
      'Freitag',
      'Samstag',
      'Sonntag'
    ];
    return days[weekday - 1]; // weekday is 1-based
  }

  Color _getDayBackgroundColor(WorkDay day, bool isWeekend, bool isSelected) {
    if (isSelected) return Color(0xFF111827).withOpacity(0.1);
    if (day.hasWork) return Colors.white;
    if (isWeekend) return Color(0xFFF59E0B).withOpacity(0.05);
    return Color(0xFFFAFAFA);
  }

  Color _getDayBorderColor(WorkDay day, bool isWeekend, bool isSelected) {
    if (isSelected) return Color(0xFF111827);
    if (day.hasWork) return Color(0xFFE30613).withOpacity(0.3);
    if (isWeekend) return Color(0xFFF59E0B).withOpacity(0.3);
    return Color(0xFFE5E7EB);
  }

  Color _getDayTextColor(WorkDay day, bool isWeekend, bool isSelected) {
    if (isSelected) return Color(0xFF111827);
    if (day.hasWork) return Color(0xFF111827);
    if (isWeekend) return Color(0xFFF59E0B);
    return Color(0xFF6B7280);
  }

  Color _getShiftAccentColor(String shiftName) {
    switch (shiftName) {
      case 'Arbeitszeit':
        return Color(0xFFE30613);
      case 'RT':
        return Color(0xFFF59E0B);
      case 'TX':
        return Color(0xFF6366F1);
      default:
        return Color(0xFF6B7280);
    }
  }

  String _getShiftDisplayName(String shiftName) {
    switch (shiftName) {
      case 'Arbeitszeit':
        return 'DIENST';
      case 'RT':
        return 'RUHEZEIT';
      case 'TX':
        return 'BLOCKIERT';
      default:
        return shiftName.toUpperCase();
    }
  }
}
