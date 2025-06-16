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
  late Animation<double> _fadeAnimation;
  int? selectedDay;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allDays = widget.rosterData.getDays();
    final visibleDays = _getVisibleDays(allDays);
    final workingDays = visibleDays.where((d) => d.hasWork).length;
    final totalHours = _calculateTotalHours(visibleDays);
    final headerText = _getHeaderText();

    print('All days: ${allDays.length}, Visible days: ${visibleDays.length}');

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE30613),
              Colors.white,
            ],
            stops: [0.0, 0.25],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon:
                                Icon(Icons.arrow_back_ios, color: Colors.white),
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.calendar_month,
                                    color: Colors.white, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  headerText,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ShiftCalendarScreen(),
                              ),
                            ),
                            icon:
                                Icon(Icons.calendar_month, color: Colors.white),
                            tooltip: 'Wunsch eintragen',
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Container(
                        height: 2,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  ),
                ),

                // Quick Stats
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickStat(
                          'Arbeitstage', '$workingDays', Color(0xFFE30613)),
                      _buildQuickStat(
                          'Freie Tage',
                          '${visibleDays.length - workingDays}',
                          Color(0xFF2E7D32)),
                      _buildQuickStat(
                          'Stunden', '${totalHours}h', Color(0xFFFF8F00)),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Calendar Container
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        // Calendar Header
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So']
                                .map((day) => Container(
                                      width: 40,
                                      child: Text(
                                        day,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: (day == 'Sa' || day == 'So')
                                              ? Color(0xFFFF8F00)
                                              : Colors.grey[700],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),

                        SizedBox(height: 16),

                        // Calendar Grid - FIXED VERSION
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: _buildDynamicCalendarGrid(visibleDays),
                          ),
                        ),

                        // Selected Day Details
                        if (selectedDate != null) _buildSelectedDayDetails(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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

  /// Build dynamic calendar grid that works with actual date range
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

    // Build the calendar with month dividers
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
      DateTime weekStartDate = calendarStart.add(Duration(days: week * 7));

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
        // Find the new month name
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
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${cellDate.day}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[300],
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
          weekCells.add(Container(height: 60)); // No data for this day
          continue;
        }

        final isWeekend = cellDate.weekday >= 6; // 6 = Saturday, 7 = Sunday
        final isSelected = selectedDate != null &&
            selectedDate!.year == cellDate.year &&
            selectedDate!.month == cellDate.month &&
            selectedDate!.day == cellDate.day;

        weekCells.add(GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedDate = null;
              } else {
                selectedDate = cellDate;
              }
            });
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            height: 60,
            decoration: BoxDecoration(
              color: _getDayBackgroundColor(dayData, isWeekend, isSelected),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getDayBorderColor(dayData, isWeekend, isSelected),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Color(0xFFE30613).withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${cellDate.day}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getDayTextColor(dayData, isWeekend, isSelected),
                  ),
                ),
                SizedBox(height: 2),
                if (dayData.hasWork && dayData.shifts.isNotEmpty) ...[
                  Text(
                    _getShiftStartTime(dayData.shifts.first.interval),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE30613),
                    ),
                  ),
                  Container(
                    width: 10,
                    height: 1,
                    color: Color(0xFFE30613),
                    margin: EdgeInsets.symmetric(vertical: 1),
                  ),
                  Text(
                    _getShiftEndTime(dayData.shifts.first.interval),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE30613),
                    ),
                  ),
                ] else if (dayData.hasWork &&
                    dayData.hoursWorked != '0:00') ...[
                  Text(
                    '${dayData.hoursWorked.split(':')[0]}h',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE30613),
                    ),
                  ),
                ] else if (isWeekend) ...[
                  Container(
                    width: 12,
                    height: 2,
                    decoration: BoxDecoration(
                      color: Color(0xFFFF8F00),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ] else ...[
                  Text(
                    'FREI',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ));
      }

      // Add the week row
      calendarRows.add(Container(
        margin: EdgeInsets.only(bottom: 4),
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

  Widget _buildMonthDivider(String monthName) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Color(0xFFE30613).withOpacity(0.3),
                  ],
                ),
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xFFE30613),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFE30613).withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  monthName.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFE30613).withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayDetails() {
    if (selectedDate == null) return Container();

    // Find the day data for selected date
    final dayIndex = selectedDate!.difference(widget.startDate).inDays;
    final visibleDays = _getVisibleDays(widget.rosterData.getDays());

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

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE30613).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFE30613).withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(0xFFE30613),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${selectedDate!.day}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$dayName, ${selectedDate!.day}. ${monthNames[selectedDate!.month]}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isWeekend ? Color(0xFFFF8F00) : Colors.grey[800],
                      ),
                    ),
                    if (day.hoursWorked != '0:00' && day.hoursWorked.isNotEmpty)
                      Text(
                        'Arbeitszeit: ${day.hoursWorked}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() => selectedDate = null),
                icon: Icon(Icons.close, color: Colors.grey[500]),
              ),
            ],
          ),
          if (day.shifts.isNotEmpty) ...[
            SizedBox(height: 12),
            ...day.shifts
                .map((shift) => Container(
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getShiftColor(shift.name).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getShiftColor(shift.name).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getShiftIcon(shift.name),
                            size: 16,
                            color: _getShiftColor(shift.name),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '${_getShiftDisplayName(shift.name)}: ${_formatShiftInterval(shift.interval)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ] else if (!day.hasWork) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isWeekend ? Icons.weekend : Icons.free_breakfast,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                  SizedBox(width: 8),
                  Text(
                    isWeekend ? 'Wochenende' : 'Freier Tag',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
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

  Widget _buildQuickStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Helper methods
  String _getShiftStartTime(String interval) {
    final parts = interval.split('-');
    return parts.isNotEmpty ? _convertTo24Hour(parts[0].trim()) : '';
  }

  String _getShiftEndTime(String interval) {
    final parts = interval.split('-');
    if (parts.length >= 2) {
      return _convertTo24Hour(parts[1].replaceAll('+1', '').trim());
    }
    return '';
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
    if (isSelected) return Color(0xFFE30613).withOpacity(0.1);
    if (day.hasWork) return Colors.white;
    if (isWeekend) return Color(0xFFFF8F00).withOpacity(0.1);
    return Colors.grey[100]!;
  }

  Color _getDayBorderColor(WorkDay day, bool isWeekend, bool isSelected) {
    if (isSelected) return Color(0xFFE30613);
    if (day.hasWork) return Color(0xFFE30613).withOpacity(0.3);
    if (isWeekend) return Color(0xFFFF8F00).withOpacity(0.3);
    return Colors.grey[300]!;
  }

  Color _getDayTextColor(WorkDay day, bool isWeekend, bool isSelected) {
    if (isSelected) return Color(0xFFE30613);
    if (day.hasWork) return Colors.grey[800]!;
    if (isWeekend) return Color(0xFFFF8F00);
    return Colors.grey[500]!;
  }

  Color _getShiftColor(String shiftName) {
    switch (shiftName) {
      case 'Arbeitszeit':
        return Color(0xFFE30613);
      case 'RT':
        return Color(0xFFFF8F00);
      case 'TX':
        return Color(0xFF1976D2);
      default:
        return Colors.grey;
    }
  }

  IconData _getShiftIcon(String shiftName) {
    switch (shiftName) {
      case 'Arbeitszeit':
        return Icons.flight_takeoff;
      case 'RT':
        return Icons.hotel;
      case 'TX':
        return Icons.school;
      default:
        return Icons.schedule;
    }
  }

  String _getShiftDisplayName(String shiftName) {
    switch (shiftName) {
      case 'Arbeitszeit':
        return 'Dienst';
      case 'RT':
        return 'Ruhezeit';
      case 'TX':
        return 'Training';
      default:
        return shiftName;
    }
  }
}
