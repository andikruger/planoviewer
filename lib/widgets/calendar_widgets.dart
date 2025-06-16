// widgets/calendar_widgets.dart

import 'package:flutter/material.dart';
import '../models/calendar_model.dart';
import '../utils/calendar_utils.dart';

class QuickStatWidget extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const QuickStatWidget({
    Key? key,
    required this.label,
    required this.value,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
}

class DayOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const DayOptionTile({
    Key? key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withOpacity(0.1),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[300]!),
      ),
    );
  }
}

class CalendarDayWidget extends StatelessWidget {
  final int dayNumber;
  final DateTime date;
  final SelectedShift? selectedShift;
  final DayOff? dayOff;
  final bool isWeekend;
  final bool isPastDate;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const CalendarDayWidget({
    Key? key,
    required this.dayNumber,
    required this.date,
    this.selectedShift,
    this.dayOff,
    required this.isWeekend,
    required this.isPastDate,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dayType = CalendarUtils.getDayType(selectedShift, dayOff, isWeekend);

    return GestureDetector(
      onTap: isPastDate ? null : onTap,
      onLongPress:
          (selectedShift != null || dayOff != null) ? onLongPress : null,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: CalendarUtils.getDayBackgroundColor(dayType, isPastDate),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: CalendarUtils.getDayBorderColor(dayType, isPastDate),
            width: (selectedShift != null || dayOff != null) ? 2 : 1,
          ),
          boxShadow: (selectedShift != null || dayOff != null)
              ? [
                  BoxShadow(
                    color: CalendarUtils.getDayBorderColor(dayType, isPastDate)
                        .withOpacity(0.3),
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
                color: CalendarUtils.getDayTextColor(dayType, isPastDate),
              ),
            ),
            SizedBox(height: 4),
            _buildDayContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildDayContent() {
    if (selectedShift != null) {
      return Column(
        children: [
          Text(
            CalendarUtils.getStartTime(selectedShift!.timeRange),
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
            CalendarUtils.getEndTime(selectedShift!.timeRange),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFFE30613),
            ),
          ),
        ],
      );
    } else if (dayOff != null) {
      if (dayOff!.isFullDay) {
        return Column(
          children: [
            Icon(
              Icons.event_busy,
              size: 16,
              color: Color(0xFF2E7D32),
            ),
            Text(
              'FREI',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E7D32),
              ),
            ),
          ],
        );
      } else {
        return Column(
          children: [
            Text(
              CalendarUtils.getStartTime(dayOff!.timeRange!),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFF8F00),
              ),
            ),
            Container(
              width: 12,
              height: 1,
              color: Color(0xFFFF8F00),
              margin: EdgeInsets.symmetric(vertical: 1),
            ),
            Text(
              CalendarUtils.getEndTime(dayOff!.timeRange!),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFF8F00),
              ),
            ),
          ],
        );
      }
    } else if (isWeekend) {
      return Container(
        width: 16,
        height: 2,
        decoration: BoxDecoration(
          color: Color(0xFFFF8F00),
          borderRadius: BorderRadius.circular(1),
        ),
      );
    } else if (!isPastDate) {
      return Icon(
        Icons.add_circle_outline,
        size: 16,
        color: Colors.grey[400],
      );
    }
    return SizedBox.shrink();
  }
}
