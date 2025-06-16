// screens/calendar_screen.dart

// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:planoviewer/screens/wish_screen.dart';
import '../models/roster_models.dart';

class CalendarScreen extends StatefulWidget {
  final WorkRosterData rosterData;

  const CalendarScreen({Key? key, required this.rosterData}) : super(key: key);

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int? selectedDay;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.rosterData.getDays();
    final workingDays = days.where((d) => d.hasWork).length;
    final totalHours = widget.rosterData.getTotalHours();

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
                                  'KALENDER JULI',
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
                      _buildQuickStat('Freie Tage', '${31 - workingDays}',
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

                        // Calendar Grid
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: _buildCalendarGrid(days),
                          ),
                        ),

                        // Selected Day Details
                        if (selectedDay != null && selectedDay! <= days.length)
                          _buildSelectedDayDetails(
                              days[selectedDay! - 1], selectedDay!),
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

  Widget _buildCalendarGrid(List<WorkDay> days) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.85,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: 35, // 5 weeks
      itemBuilder: (context, index) {
        // July 2024 starts on Monday (index 0)
        final dayNumber = index + 1;

        if (dayNumber > 31) {
          return Container(); // Empty cell for days beyond July 31
        }

        final day = days[dayNumber - 1];
        final isWeekend = index % 7 >= 5; // Saturday (5) and Sunday (6)
        final isSelected = selectedDay == dayNumber;

        return GestureDetector(
          onTap: () {
            setState(() {
              selectedDay = selectedDay == dayNumber ? null : dayNumber;
            });
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _getDayBackgroundColor(day, isWeekend, isSelected),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getDayBorderColor(day, isWeekend, isSelected),
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
                  '$dayNumber',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getDayTextColor(day, isWeekend, isSelected),
                  ),
                ),
                SizedBox(height: 4),
                if (day.hasWork && day.shifts.isNotEmpty) ...[
                  Text(
                    _getShiftStartTime(day.shifts.first.interval),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE30613),
                    ),
                  ),
                  Container(
                    width: 12,
                    height: 1,
                    color: Color(0xFFE30613),
                    margin: EdgeInsets.symmetric(vertical: 1),
                  ),
                  Text(
                    _getShiftEndTime(day.shifts.first.interval),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE30613),
                    ),
                  ),
                ] else if (day.hasWork && day.hoursWorked != '0:00') ...[
                  Text(
                    '${day.hoursWorked.split(':')[0]}h',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE30613),
                    ),
                  ),
                ] else if (isWeekend) ...[
                  Container(
                    width: 16,
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
        );
      },
    );
  }

  Widget _buildSelectedDayDetails(WorkDay day, int dayNumber) {
    final dayName = _getDayName(dayNumber);
    final isWeekend = _isWeekend((dayNumber - 1) % 7);

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
                    '$dayNumber',
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
                      '$dayName, $dayNumber. Juli',
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
                onPressed: () => setState(() => selectedDay = null),
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
                            '${_getShiftDisplayName(shift.name)}: ${shift.interval}',
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

  // Helper methods
  String _getShiftStartTime(String interval) {
    final parts = interval.split('-');
    return parts.isNotEmpty ? parts[0].trim() : '';
  }

  String _getShiftEndTime(String interval) {
    final parts = interval.split('-');
    if (parts.length >= 2) {
      return parts[1].replaceAll('+1', '').trim();
    }
    return '';
  }

  String _getDayName(int dayNumber) {
    final days = [
      'Montag',
      'Dienstag',
      'Mittwoch',
      'Donnerstag',
      'Freitag',
      'Samstag',
      'Sonntag'
    ];
    return days[(dayNumber - 1) % 7];
  }

  bool _isWeekend(int dayOfWeek) {
    return dayOfWeek == 5 || dayOfWeek == 6; // Saturday (5) or Sunday (6)
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
