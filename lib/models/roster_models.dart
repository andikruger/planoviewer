// models/roster_models.dart

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

    return WorkRosterData(
      columns: columns,
      shiftInfos: shiftInfos,
    );
  }

  List<WorkDay> getDays() {
    final days = <WorkDay>[];

    // Get the first column for hours worked
    final hoursColumn = columns.values.firstWhere(
      (col) => col['itemType'] == 'MonthJournalDataAccount',
    );

    // Get all shift interval columns
    final allShiftColumns = columns.values
        .where(
          (col) => col['itemType'] == 'MonthJournalDataIntervals',
        )
        .toList();

    final hoursItems = hoursColumn['items'] as List;

    for (int i = 0; i < hoursItems.length; i++) {
      final hoursWorked = hoursItems[i]['value'] ?? '0:00';

      // Collect all shifts from all interval columns for this day
      final allShifts = <WorkShift>[];

      for (final shiftColumn in allShiftColumns) {
        final shiftItems = shiftColumn['items'] as List;
        if (i < shiftItems.length) {
          final shiftData = shiftItems[i] as Map<String, dynamic>;
          final intervals = shiftData['intervals'] as List? ?? [];

          for (final interval in intervals) {
            allShifts.add(WorkShift(
              name: interval['name'] ?? '',
              interval: interval['interval'] ?? '',
            ));
          }
        }
      }

      // Merge consecutive Arbeitszeit shifts
      final mergedShifts = _mergeConsecutiveShifts(allShifts);

      days.add(WorkDay(
        hoursWorked: hoursWorked,
        shifts: mergedShifts,
      ));
    }

    return days;
  }

  List<WorkShift> _mergeConsecutiveShifts(List<WorkShift> shifts) {
    if (shifts.isEmpty) return shifts;

    final merged = <WorkShift>[];
    final arbeitszeit = <WorkShift>[];

    for (final shift in shifts) {
      if (shift.name == 'Arbeitszeit') {
        arbeitszeit.add(shift);
      } else {
        // If we have accumulated Arbeitszeit shifts, merge them first
        if (arbeitszeit.isNotEmpty) {
          merged.add(_mergeArbeitszeitShifts(arbeitszeit));
          arbeitszeit.clear();
        }
        merged.add(shift);
      }
    }

    // Don't forget any remaining Arbeitszeit shifts
    if (arbeitszeit.isNotEmpty) {
      merged.add(_mergeArbeitszeitShifts(arbeitszeit));
    }

    return merged;
  }

  WorkShift _mergeArbeitszeitShifts(List<WorkShift> shifts) {
    if (shifts.length == 1) return shifts.first;

    // Sort shifts by start time to ensure proper merging
    shifts.sort((a, b) {
      final timeA = a.interval.split('-')[0];
      final timeB = b.interval.split('-')[0];
      return timeA.compareTo(timeB);
    });

    // Get start time from first shift and end time from last shift
    final firstInterval = shifts.first.interval.split('-');
    final lastInterval = shifts.last.interval.split('-');

    if (firstInterval.length >= 2 && lastInterval.length >= 2) {
      final startTime = firstInterval[0];
      final endTime = lastInterval[1];

      return WorkShift(
        name: 'Arbeitszeit',
        interval: '$startTime-$endTime',
      );
    }

    // Fallback: return first shift if parsing fails
    return shifts.first;
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

  WorkDay({required this.hoursWorked, required this.shifts});

  bool get hasWork =>
      hoursWorked != '0:00' && hoursWorked.isNotEmpty || shifts.isNotEmpty;
}

class WorkShift {
  final String name;
  final String interval;

  WorkShift({required this.name, required this.interval});
}
