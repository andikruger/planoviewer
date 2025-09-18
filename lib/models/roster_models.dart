// models/roster_models.dart

import '../services/api_service.dart';

class WorkRosterData {
  final Map<String, dynamic> columns;
  final Map<String, ShiftInfo> shiftInfos;

  WorkRosterData({required this.columns, required this.shiftInfos});

  factory WorkRosterData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final columns = data['columns'] as Map<String, dynamic>;
    final shiftInfosJson = data['shiftInfos'] as Map<String, dynamic>;

    final shiftInfos = <String, ShiftInfo>{};
    shiftInfosJson.forEach((key, value) {
      shiftInfos[key] = ShiftInfo.fromJson(value);
    });

    return WorkRosterData(columns: columns, shiftInfos: shiftInfos);
  }

  List<WorkDay> getDays() {
    final days = <WorkDay>[];

    // Get the first column for hours worked
    final hoursColumn = columns.values.firstWhere(
      (col) => col['itemType'] == 'MonthJournalDataAccount',
    );

    // Get all shift interval columns
    final allShiftColumns = columns.values
        .where((col) => col['itemType'] == 'MonthJournalDataIntervals')
        .toList();

    final hoursItems = hoursColumn['items'] as List;

    for (int i = 0; i < hoursItems.length; i++) {
      final hoursWorked = hoursItems[i]['value'] ?? '0:00';

      // Collect all intervals from all columns for this day
      final allIntervals = <Map<String, dynamic>>[];

      for (final shiftColumn in allShiftColumns) {
        final shiftItems = shiftColumn['items'] as List;
        if (i < shiftItems.length) {
          final shiftData = shiftItems[i] as Map<String, dynamic>;
          final intervals = shiftData['intervals'] as List? ?? [];

          // Convert to the format expected by ApiService
          for (final interval in intervals) {
            allIntervals.add({
              'name': interval['name'] ?? '',
              'interval': interval['interval'] ?? '',
            });
          }
        }
      }

      // Use ApiService to process the intervals
      final result = ApiService.processRosterDay(allIntervals);
      final timeRange = result['timeRange'] as String;
      final hasWork = result['hasWork'] as bool;

      // Convert back to WorkShift format for compatibility
      final shifts = <WorkShift>[];
      if (hasWork && timeRange.isNotEmpty) {
        shifts.add(WorkShift(name: 'Arbeitszeit', interval: timeRange));
      } else if (!hasWork && allIntervals.isNotEmpty) {
        // Add RT or other non-work shifts for display
        for (final interval in allIntervals) {
          final name = interval['name'] as String;
          final intervalStr = interval['interval'] as String;
          if (name == 'RT' || intervalStr.contains('12:00 PM-12:01 PM')) {
            shifts.add(WorkShift(name: name, interval: intervalStr));
            break; // Only need one to show it's a day off
          }
        }
      }

      days.add(
        WorkDay(
          hoursWorked: hoursWorked,
          shifts: shifts,
          timeRange: timeRange, // Add this property
          hasWork: hasWork, // Add this property
        ),
      );
    }

    return days;
  }

  String getTotalHours() {
    final days = getDays();
    double totalMinutes = 0;

    for (final day in days) {
      if (day.hoursWorked != '0:00' && day.hoursWorked.isNotEmpty) {
        final parts = day.hoursWorked.split(':');
        if (parts.length == 2) {
          final hours = int.tryParse(parts[0]) ?? 0;
          final minutes = int.tryParse(parts[1]) ?? 0;
          totalMinutes += (hours * 60) + minutes;
        }
      }
    }

    final totalHours = totalMinutes / 60;
    return totalHours.toStringAsFixed(1);
  }
}

class ShiftInfo {
  final String name;
  final String background;
  final String foreground;

  ShiftInfo({
    required this.name,
    required this.background,
    required this.foreground,
  });

  factory ShiftInfo.fromJson(Map<String, dynamic> json) {
    return ShiftInfo(
      name: json['name'] ?? '',
      background: json['background'] ?? '',
      foreground: json['foreground'] ?? '',
    );
  }
}

class WorkDay {
  final String hoursWorked;
  final List<WorkShift> shifts;
  final String timeRange; // Add this property
  final bool hasWork; // Add this property

  WorkDay({
    required this.hoursWorked,
    required this.shifts,
    this.timeRange = '', // Default empty
    bool? hasWork, // Make nullable to calculate if not provided
  }) : hasWork =
           hasWork ??
           (hoursWorked != '0:00' && hoursWorked.isNotEmpty) ||
               shifts.isNotEmpty;
}

class WorkShift {
  final String name;
  final String interval;

  WorkShift({required this.name, required this.interval});
}
