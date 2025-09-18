// utils/calendar_utils.dart

import 'package:flutter/material.dart';
import 'package:planoviewer/models/calendar_model.dart';

class CalendarUtils {
  static String formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static String formatDisplayDate(DateTime date) {
    const days = [
      'Montag',
      'Dienstag',
      'Mittwoch',
      'Donnerstag',
      'Freitag',
      'Samstag',
      'Sonntag'
    ];
    const months = [
      'Jan',
      'Feb',
      'Mär',
      'Apr',
      'Mai',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Okt',
      'Nov',
      'Dez'
    ];
    return '${days[date.weekday - 1]}, ${date.day}. ${months[date.month - 1]}';
  }

  static String getMonthName(int month) {
    const months = [
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
    return months[month];
  }

  static int getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  static String getStartTime(String timeRange) {
    return timeRange.split('-')[0];
  }

  static String getEndTime(String timeRange) {
    final parts = timeRange.split('-');
    return parts.length > 1 ? parts[1] : '';
  }

  static String calculateDuration(String timeRange) {
    final parts = timeRange.split('-');
    if (parts.length != 2) return '';

    final start = parseTime(parts[0]);
    final end = parseTime(parts[1]);

    if (start == null || end == null) return '';

    int duration = end - start;
    if (duration < 0) duration += 24 * 60; // Handle overnight shifts

    final hours = duration ~/ 60;
    final minutes = duration % 60;

    return minutes == 0 ? '${hours}h' : '${hours}h ${minutes}m';
  }

  static int? parseTime(String timeStr) {
    if (timeStr.length != 4) return null;

    final hours = int.tryParse(timeStr.substring(0, 2));
    final minutes = int.tryParse(timeStr.substring(2, 4));

    if (hours == null || minutes == null) return null;

    return hours * 60 + minutes;
  }

  static int calculateTotalHours(Map<String, SelectedShift> selectedShifts) {
    int totalMinutes = 0;
    for (final shift in selectedShifts.values) {
      final parts = shift.timeRange.split('-');
      if (parts.length == 2) {
        final start = parseTime(parts[0]);
        final end = parseTime(parts[1]);
        if (start != null && end != null) {
          int duration = end - start;
          if (duration < 0) duration += 24 * 60;
          totalMinutes += duration;
        }
      }
    }
    return totalMinutes ~/ 60;
  }

  static ShiftType getShiftType(String timeRange) {
    final start = parseTime(timeRange.split('-')[0]);
    if (start == null) return ShiftType.day;

    // 04:30 - 07:30 = Early (270 - 450 minutes)
    if (start >= 4 * 60 + 30 && start <= 7 * 60 + 30) return ShiftType.early;

    // 08:00 - 11:59 = Day (480 - 719 minutes)
    if (start >= 8 * 60 && start < 12 * 60) return ShiftType.day;

    // 12:00 - 18:29 = Late (720 - 1109 minutes) - Changed to < 18:30
    if (start >= 12 * 60 && start < 18 * 60 + 30) return ShiftType.late;

    // 18:30+ = Night (1110+ minutes)
    if (start >= 18 * 60 + 30) return ShiftType.night;

    // Default fallback for times outside defined ranges
    return ShiftType.day;
  }

  static Color getShiftTypeColor(ShiftType type) {
    switch (type) {
      case ShiftType.early:
        return Color(0xFF3F51B5);
      case ShiftType.day:
        return Color(0xFF2196F3);
      case ShiftType.late:
        return Color(0xFFE30613);
      case ShiftType.night:
        return Color(0xFFFF8F00);
    }
  }

  static IconData getShiftTypeIcon(ShiftType type) {
    switch (type) {
      case ShiftType.early:
        return Icons.wb_sunny;
      case ShiftType.day:
        return Icons.work;
      case ShiftType.late:
        return Icons.wb_twighlight;

      case ShiftType.night:
        return Icons.nights_stay;
    }
  }

  static String getShiftTypeName(ShiftType type) {
    switch (type) {
      case ShiftType.early:
        return 'Frühdienst';
      case ShiftType.day:
        return 'Tagdienst';
      case ShiftType.late:
        return 'Spätdienst';

      case ShiftType.night:
        return 'Nachtdienst';
    }
  }

  static DayType getDayType(
      SelectedShift? shift, DayOff? dayOff, bool isWeekend) {
    if (shift != null) return DayType.work;
    if (dayOff != null) {
      return dayOff.isFullDay ? DayType.fullDayOff : DayType.partialDayOff;
    }
    return DayType.free;
  }

  static Color getDayBackgroundColor(DayType dayType, bool isPastDate) {
    if (isPastDate) return Colors.grey[200]!;

    switch (dayType) {
      case DayType.work:
        return Colors.white;
      case DayType.fullDayOff:
        return Color(0xFF2E7D32).withOpacity(0.1);
      case DayType.partialDayOff:
        return Color(0xFFFF8F00).withOpacity(0.1);
      case DayType.free:
        return Colors.grey[100]!;
    }
  }

  static Color getDayBorderColor(DayType dayType, bool isPastDate) {
    if (isPastDate) return Colors.grey[300]!;

    switch (dayType) {
      case DayType.work:
        return Color(0xFFE30613);
      case DayType.fullDayOff:
        return Color(0xFF2E7D32);
      case DayType.partialDayOff:
        return Color(0xFFFF8F00);
      case DayType.free:
        return Colors.grey[300]!;
    }
  }

  static Color getDayTextColor(DayType dayType, bool isPastDate) {
    if (isPastDate) return Colors.grey[400]!;

    switch (dayType) {
      case DayType.work:
        return Colors.grey[800]!;
      case DayType.fullDayOff:
        return Color(0xFF2E7D32);
      case DayType.partialDayOff:
        return Color(0xFFFF8F00);
      case DayType.free:
        return Colors.grey[600]!;
    }
  }
}
