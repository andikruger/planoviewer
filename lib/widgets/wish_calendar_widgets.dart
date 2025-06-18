// screens/shift_calendar/shift_calendar_widgets.dart

import 'package:flutter/material.dart';
import 'package:planoviewer/models/calendar_model.dart';
import '../../utils/calendar_utils.dart';

class ShiftCalendarHeader extends StatelessWidget {
  final DateTime targetMonth;
  final VoidCallback onBackPressed;
  final Function(String) onMenuSelected;

  const ShiftCalendarHeader({
    Key? key,
    required this.targetMonth,
    required this.onBackPressed,
    required this.onMenuSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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

    return Container(
      padding: EdgeInsets.all(24),
      child: Row(
        children: [
          // Back button
          Container(
            width: 44,
            height: 44,
            child: IconButton(
              onPressed: onBackPressed,
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
                    'WUNSCHKALENDER ${monthNames[targetMonth.month]}',
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

          // Menu button
          Container(
            width: 44,
            height: 44,
            child: PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: Color(0xFF111827),
                size: 20,
              ),
              onSelected: onMenuSelected,
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'summary',
                  child: Row(
                    children: [
                      Icon(Icons.list_alt, color: Color(0xFF6B7280)),
                      SizedBox(width: 12),
                      Text('Übersicht'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'view_token',
                  child: Row(
                    children: [
                      Icon(Icons.visibility, color: Color(0xFF6B7280)),
                      SizedBox(width: 12),
                      Text('Token anzeigen'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'change_token',
                  child: Row(
                    children: [
                      Icon(Icons.key, color: Color(0xFF6B7280)),
                      SizedBox(width: 12),
                      Text('Token ändern'),
                    ],
                  ),
                ),
                PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Color(0xFFE30613)),
                      SizedBox(width: 12),
                      Text(
                        'Abmelden',
                        style: TextStyle(color: Color(0xFFE30613)),
                      ),
                    ],
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

class ShiftCalendarStats extends StatelessWidget {
  final Animation<double> animation;
  final Map<String, SelectedShift> selectedShifts;
  final Map<String, DayOff> daysOff;

  const ShiftCalendarStats({
    Key? key,
    required this.animation,
    required this.selectedShifts,
    required this.daysOff,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final totalHours = CalendarUtils.calculateTotalHours(selectedShifts);
    final totalShifts = selectedShifts.length;
    final totalDaysOff = daysOff.length;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, animation.value),
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
                    '$totalShifts',
                    'Schichten',
                    Color(0xFFE30613),
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: Color(0xFFE5E7EB),
                ),
                Expanded(
                  child: _buildStatItem(
                    '$totalDaysOff',
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
}

class ShiftCalendarGrid extends StatelessWidget {
  final DateTime targetMonth;
  final Map<String, SelectedShift> selectedShifts;
  final Map<String, DayOff> daysOff;
  final Function(DateTime) onDayTap;
  final Function(DateTime) onDayLongPress;

  const ShiftCalendarGrid({
    Key? key,
    required this.targetMonth,
    required this.selectedShifts,
    required this.daysOff,
    required this.onDayTap,
    required this.onDayLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                    'WUNSCHKALENDER',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                      letterSpacing: 1.5,
                    ),
                  ),
                  Spacer(),
                  Text(
                    '${CalendarUtils.getMonthName(targetMonth.month)} ${targetMonth.year}',
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
                child: _buildCalendarGrid(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(targetMonth.year, targetMonth.month, 1);
    final lastDayOfMonth = DateTime(targetMonth.year, targetMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday =
        firstDayOfMonth.weekday - 1; // Convert to 0-6 (Mon-Sun)

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.8,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: 42, // 6 weeks max
      itemBuilder: (context, index) {
        if (index < firstWeekday || index >= firstWeekday + daysInMonth) {
          return Container(); // Empty cell
        }

        final dayNumber = index - firstWeekday + 1;
        final date = DateTime(targetMonth.year, targetMonth.month, dayNumber);
        final dateKey = CalendarUtils.formatDateKey(date);
        final selectedShift = selectedShifts[dateKey];
        final dayOff = daysOff[dateKey];
        final isWeekend = date.weekday >= 6;
        final isPastDate =
            date.isBefore(DateTime.now().subtract(Duration(days: 1)));

        return ShiftCalendarDay(
          dayNumber: dayNumber,
          date: date,
          selectedShift: selectedShift,
          dayOff: dayOff,
          isWeekend: isWeekend,
          isPastDate: isPastDate,
          onTap: () => onDayTap(date),
          onLongPress: () => onDayLongPress(date),
        );
      },
    );
  }
}

class ShiftCalendarDay extends StatelessWidget {
  final int dayNumber;
  final DateTime date;
  final SelectedShift? selectedShift;
  final DayOff? dayOff;
  final bool isWeekend;
  final bool isPastDate;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const ShiftCalendarDay({
    Key? key,
    required this.dayNumber,
    required this.date,
    required this.selectedShift,
    required this.dayOff,
    required this.isWeekend,
    required this.isPastDate,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          color: _getDayBackgroundColor(),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getDayBorderColor(),
            width: (selectedShift != null || dayOff != null) ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$dayNumber',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _getDayTextColor(),
              ),
            ),
            SizedBox(height: 2),
            _buildDayIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildDayIndicator() {
    if (selectedShift != null) {
      final shiftType = CalendarUtils.getShiftType(selectedShift!.timeRange);
      return Container(
        width: 16,
        height: 2,
        decoration: BoxDecoration(
          color: CalendarUtils.getShiftTypeColor(shiftType),
          borderRadius: BorderRadius.circular(1),
        ),
      );
    } else if (dayOff != null) {
      return Container(
        width: dayOff!.isFullDay ? 14 : 12,
        height: 2,
        decoration: BoxDecoration(
          color: dayOff!.isFullDay ? Color(0xFF059669) : Color(0xFF6366F1),
          borderRadius: BorderRadius.circular(1),
        ),
      );
    } else if (isWeekend) {
      return Container(
        width: 8,
        height: 2,
        decoration: BoxDecoration(
          color: Color(0xFFF59E0B),
          borderRadius: BorderRadius.circular(1),
        ),
      );
    } else {
      return Container(
        width: 6,
        height: 1,
        decoration: BoxDecoration(
          color: Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(1),
        ),
      );
    }
  }

  Color _getDayBackgroundColor() {
    if (isPastDate) return Color(0xFFF9FAFB);
    if (selectedShift != null) return Colors.white;
    if (dayOff != null) {
      return dayOff!.isFullDay
          ? Color(0xFF059669).withOpacity(0.05)
          : Color(0xFF6366F1).withOpacity(0.05);
    }
    if (isWeekend) return Color(0xFFF59E0B).withOpacity(0.05);
    return Color(0xFFFAFAFA);
  }

  Color _getDayBorderColor() {
    if (isPastDate) return Color(0xFFE5E7EB);
    if (selectedShift != null) {
      final shiftType = CalendarUtils.getShiftType(selectedShift!.timeRange);
      return CalendarUtils.getShiftTypeColor(shiftType).withOpacity(0.3);
    }
    if (dayOff != null) {
      return dayOff!.isFullDay
          ? Color(0xFF059669).withOpacity(0.3)
          : Color(0xFF6366F1).withOpacity(0.3);
    }
    if (isWeekend) return Color(0xFFF59E0B).withOpacity(0.3);
    return Color(0xFFE5E7EB);
  }

  Color _getDayTextColor() {
    if (isPastDate) return Color(0xFFE5E7EB);
    if (selectedShift != null || dayOff != null) return Color(0xFF111827);
    if (isWeekend) return Color(0xFFF59E0B);
    return Color(0xFF6B7280);
  }
}
