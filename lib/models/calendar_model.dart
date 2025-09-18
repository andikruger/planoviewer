// models/calendar_model.dart

class AvailableShift {
  final String id;
  final String timeRange;

  AvailableShift({required this.id, required this.timeRange});
}

class SelectedShift {
  final String id;
  final String timeRange;
  final DateTime date;
  final String?
      instanceId; // Add this field to store the instanceId from API response

  SelectedShift({
    required this.id,
    required this.timeRange,
    required this.date,
    this.instanceId,
  });

  // Add copyWith method to update instanceId after API response
  SelectedShift copyWith({
    String? id,
    String? timeRange,
    DateTime? date,
    String? instanceId,
  }) {
    return SelectedShift(
      id: id ?? this.id,
      timeRange: timeRange ?? this.timeRange,
      date: date ?? this.date,
      instanceId: instanceId ?? this.instanceId,
    );
  }

  // Add toJson and fromJson for persistence if needed
  Map<String, dynamic> toJson() => {
        'id': id,
        'timeRange': timeRange,
        'date': date.toIso8601String(),
        'instanceId': instanceId,
      };

  factory SelectedShift.fromJson(Map<String, dynamic> json) => SelectedShift(
        id: json['id'],
        timeRange: json['timeRange'],
        date: DateTime.parse(json['date']),
        instanceId: json['instanceId'],
      );
}

class DayOff {
  final DateTime date;
  final bool isFullDay;
  final String? timeRange; // null for full day, "HHMM-HHMM" for partial

  DayOff({required this.date, required this.isFullDay, this.timeRange});
}

enum ShiftType {
  early,
  day,
  late,
  night,
}

enum DayType {
  work,
  fullDayOff,
  partialDayOff,
  free,
}
