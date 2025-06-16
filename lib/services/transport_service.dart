// services/transport_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class TransportService {
  /// Calculates when to leave home to arrive at work on time
  /// [workStartTime] should be in Vienna local time
  static Future<TransportInfo?> calculateDepartureTime(
      DateTime workStartTime) async {
    try {
      print('Calculating departure time for: $workStartTime'); // Debug

      // Convert Vienna local time to UTC for the API
      final utcArrivalTime = _convertViennaToUtc(workStartTime);

      final formattedArrivalTime =
          '${utcArrivalTime.year}-${utcArrivalTime.month.toString().padLeft(2, '0')}-${utcArrivalTime.day.toString().padLeft(2, '0')}T${utcArrivalTime.hour.toString().padLeft(2, '0')}%3A${utcArrivalTime.minute.toString().padLeft(2, '0')}%3A${utcArrivalTime.second.toString().padLeft(2, '0')}.${utcArrivalTime.millisecond.toString().padLeft(3, '0')}Z';

      final urlString =
          'https://www.wienmobil.at//api/routes?origin=48.181867%2C16.344933&destination=vao%3A430470800&arrivalTime=$formattedArrivalTime&walkSpeed=normal&wheelchairAccessible=false&lineType=all&embed=trafficInformation&limit=3&types=&routeKey=public-transport';

      final uri = Uri.parse(urlString);
      final response = await http.get(uri);

      print('Response status: ${response.statusCode}'); // Debug
      print('Response body: ${response.body}'); // Debug

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          print('Found ${data['routes'].length} routes'); // Debug
          return TransportInfo.fromJson(data['routes'][0]);
        } else {
          print('No routes found in response'); // Debug
        }
      } else {
        print('HTTP error: ${response.statusCode} - ${response.body}'); // Debug
      }
      return null;
    } catch (e, stackTrace) {
      print('Error fetching transport data: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Converts Vienna local time to UTC, accounting for daylight saving time
  static DateTime _convertViennaToUtc(DateTime viennaTime) {
    // Vienna is UTC+1 in winter (CET) and UTC+2 in summer (CEST)
    // Daylight saving time in Europe typically runs from last Sunday in March
    // to last Sunday in October

    final year = viennaTime.year;
    final month = viennaTime.month;
    final day = viennaTime.day;

    // Simple DST check for Vienna
    bool isDst = false;
    if (month > 3 && month < 10) {
      isDst = true; // Definitely summer time
    } else if (month == 3) {
      // Check if it's after the last Sunday of March
      final lastSundayMarch = _getLastSundayOfMonth(year, 3);
      isDst = day >= lastSundayMarch;
    } else if (month == 10) {
      // Check if it's before the last Sunday of October
      final lastSundayOctober = _getLastSundayOfMonth(year, 10);
      isDst = day < lastSundayOctober;
    }

    // Vienna offset: UTC+1 (CET) or UTC+2 (CEST)
    final offsetHours = isDst ? 2 : 1;
    return viennaTime.subtract(Duration(hours: offsetHours));
  }

  static int _getLastSundayOfMonth(int year, int month) {
    // Find the last day of the month
    final lastDay = DateTime(year, month + 1, 0).day;

    // Find the last Sunday
    for (int day = lastDay; day >= 1; day--) {
      final date = DateTime(year, month, day);
      if (date.weekday == DateTime.sunday) {
        return day;
      }
    }
    return lastDay;
  }

  /// Gets all available routes for the specified arrival time
  static Future<List<TransportInfo>?> getAllRoutes(
      DateTime workStartTime) async {
    try {
      print('Calculating all routes for: $workStartTime'); // Debug

      // Convert Vienna local time to UTC for the API
      final utcArrivalTime = _convertViennaToUtc(workStartTime);

      // Format the UTC time without colons (API requirement)

      final formattedArrivalTime =
          '${utcArrivalTime.year}-${utcArrivalTime.month.toString().padLeft(2, '0')}-${utcArrivalTime.day.toString().padLeft(2, '0')}T${utcArrivalTime.hour.toString().padLeft(2, '0')}%3A${utcArrivalTime.minute.toString().padLeft(2, '0')}%3A${utcArrivalTime.second.toString().padLeft(2, '0')}.${utcArrivalTime.millisecond.toString().padLeft(3, '0')}Z';

      final urlString =
          'https://www.wienmobil.at//api/routes?origin=48.181867%2C16.344933&destination=vao%3A430470800&arrivalTime=$formattedArrivalTime&walkSpeed=normal&wheelchairAccessible=false&lineType=all&embed=trafficInformation&limit=3&types=&routeKey=public-transport';

      final uri = Uri.parse(urlString);
      print('API URL: $uri'); // Debug

      final response = await http.get(uri);

      print('Response status: ${response.statusCode}'); // Debug
      print('Response body: ${response.body}'); // Debug

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          print('Found ${data['routes'].length} routes'); // Debug

          // Convert all routes to TransportInfo objects
          List<TransportInfo> routes = [];
          for (var routeData in data['routes']) {
            try {
              routes.add(TransportInfo.fromJson(routeData));
            } catch (e) {
              print('Error parsing route: $e');
              // Continue with other routes even if one fails
            }
          }

          return routes.isNotEmpty ? routes : null;
        } else {
          print('No routes found in response'); // Debug
        }
      } else {
        print('HTTP error: ${response.statusCode} - ${response.body}'); // Debug
      }
      return null;
    } catch (e, stackTrace) {
      print('Error fetching transport data: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }
}

class TransportInfo {
  final DateTime departureTime;
  final DateTime arrivalTime;
  final int durationMinutes;
  final int transfers;
  final List<TransportLeg> legs;
  final int co2Grams;
  final String? disruption;

  TransportInfo({
    required this.departureTime,
    required this.arrivalTime,
    required this.durationMinutes,
    required this.transfers,
    required this.legs,
    required this.co2Grams,
    this.disruption,
  });

  factory TransportInfo.fromJson(Map<String, dynamic> json) {
    print('=== PARSING TRANSPORT INFO ===');
    print('Raw departureTime: ${json['departureTime']}');
    print('Raw arrivalTime: ${json['arrivalTime']}');

    final legs = (json['legs'] as List?)
            ?.map((leg) => TransportLeg.fromJson(leg))
            .toList() ??
        [];

    // Check for disruptions in traffic information
    String? disruption;
    for (final leg in json['legs'] ?? []) {
      final trafficInfo = leg['trafficInformation'] as List?;
      if (trafficInfo != null && trafficInfo.isNotEmpty) {
        final info = trafficInfo.first;
        if (info['headline'] != null) {
          disruption = info['headline'];
          break;
        }
      }
    }

    final transportInfo = TransportInfo(
      departureTime: DateTime.parse(json['departureTime']),
      arrivalTime: DateTime.parse(json['arrivalTime']),
      durationMinutes: (json['duration']['inSeconds'] as int) ~/ 60,
      transfers: json['transfers'] ?? 0,
      legs: legs,
      co2Grams: json['co2Emission']?['inGrams'] ?? 0,
      disruption: disruption,
    );

    print('Parsed departureTime: ${transportInfo.departureTime}');
    print('Parsed arrivalTime: ${transportInfo.arrivalTime}');
    print('Formatted departure: ${transportInfo.formattedDepartureTime}');
    print('Formatted arrival: ${transportInfo.formattedArrivalTime}');

    return transportInfo;
  }

  String get formattedDepartureTime {
    // Convert UTC back to Vienna time for display
    final viennaTime = departureTime.add(Duration(hours: _getViennaOffset()));
    final formatted =
        '${viennaTime.hour.toString().padLeft(2, '0')}:${viennaTime.minute.toString().padLeft(2, '0')}';
    print(
        'Departure: UTC ${departureTime} → Vienna ${viennaTime} → Formatted: $formatted');
    return formatted;
  }

  String get formattedArrivalTime {
    // Convert UTC back to Vienna time for display
    final viennaTime = arrivalTime.add(Duration(hours: _getViennaOffset()));
    final formatted =
        '${viennaTime.hour.toString().padLeft(2, '0')}:${viennaTime.minute.toString().padLeft(2, '0')}';
    print(
        'Arrival: UTC ${arrivalTime} → Vienna ${viennaTime} → Formatted: $formatted');
    return formatted;
  }

  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }

  int _getViennaOffset() {
    // Get current time to determine if we're in DST
    final now = DateTime.now();
    final month = now.month;
    final day = now.day;

    // Simple DST check for Vienna (this matches the logic in _convertViennaToUtc)
    bool isDst = false;
    if (month > 3 && month < 10) {
      isDst = true; // Definitely summer time
    } else if (month == 3) {
      // Check if it's after the last Sunday of March
      final lastSundayMarch = _getLastSundayOfMonth(now.year, 3);
      isDst = day >= lastSundayMarch;
    } else if (month == 10) {
      // Check if it's before the last Sunday of October
      final lastSundayOctober = _getLastSundayOfMonth(now.year, 10);
      isDst = day < lastSundayOctober;
    }

    final offset = isDst ? 2 : 1;
    print(
        'Vienna offset calculation: month=$month, day=$day, isDst=$isDst, offset=$offset');
    return offset;
  }

  static int _getLastSundayOfMonth(int year, int month) {
    // Find the last day of the month
    final lastDay = DateTime(year, month + 1, 0).day;

    // Find the last Sunday
    for (int day = lastDay; day >= 1; day--) {
      final date = DateTime(year, month, day);
      if (date.weekday == DateTime.sunday) {
        return day;
      }
    }
    return lastDay;
  }
}

class TransportLeg {
  final String type;
  final String? lineName;
  final String? direction;
  final DateTime? departureTime;
  final DateTime? arrivalTime;
  final int? durationMinutes;

  TransportLeg({
    required this.type,
    this.lineName,
    this.direction,
    this.departureTime,
    this.arrivalTime,
    this.durationMinutes,
  });

  factory TransportLeg.fromJson(Map<String, dynamic> json) {
    return TransportLeg(
      type: json['type'] ?? '',
      lineName: json['line']?['name'],
      direction: json['headsign'] ?? json['destination'],
      departureTime: json['departureTime'] != null
          ? DateTime.parse(json['departureTime'])
          : null,
      arrivalTime: json['arrivalTime'] != null
          ? DateTime.parse(json['arrivalTime'])
          : null,
      durationMinutes: json['duration'] != null
          ? (json['duration']['inSeconds'] as int) ~/ 60
          : null,
    );
  }

  String get displayName {
    if (type == 'walk') return 'Zu Fuß';
    if (type == 'transfer') return 'Umsteigen';
    if (lineName != null) return lineName!;
    return type;
  }
}
