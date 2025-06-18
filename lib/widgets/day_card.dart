// widgets/day_card.dart

import 'package:flutter/material.dart';
import '../models/roster_models.dart';
import '../services/transport_service.dart';

// Time converter utility class
class TimeConverter {
  /// Converts time from various formats to 24-hour format
  static String to24Hour(String timeString) {
    if (timeString.isEmpty) return timeString;

    try {
      final cleanTime = timeString.trim();

      // Check if already in 24-hour format (no AM/PM)
      if (!cleanTime.toLowerCase().contains('am') &&
          !cleanTime.toLowerCase().contains('pm') &&
          !cleanTime.toLowerCase().contains('a.m') &&
          !cleanTime.toLowerCase().contains('p.m')) {
        // Validate it's a proper time format
        final timeRegex = RegExp(r'^(\d{1,2}):(\d{2})$');
        final match = timeRegex.firstMatch(cleanTime);
        if (match != null) {
          final hour = int.parse(match.group(1)!);
          final minute = int.parse(match.group(2)!);
          if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
            return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
          }
        }
        return timeString; // Return as is if not valid 24-hour format
      }

      // Handle 12-hour format with AM/PM
      final amPmRegex = RegExp(
          r'(\d{1,2}):(\d{2})\s*(AM|PM|am|pm|a\.m\.|p\.m\.)',
          caseSensitive: false);
      final match = amPmRegex.firstMatch(cleanTime);

      if (match != null) {
        int hour = int.parse(match.group(1)!);
        final minute = int.parse(match.group(2)!);
        final period = match.group(3)!.toLowerCase();

        // Convert to 24-hour format
        if (period.startsWith('p') && hour != 12) {
          hour += 12;
        } else if (period.startsWith('a') && hour == 12) {
          hour = 0;
        }

        return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      }

      // If no pattern matches, return original
      print('Warning: Could not convert time format: "$timeString"');
      return timeString;
    } catch (e) {
      print('Error converting time "$timeString": $e');
      return timeString;
    }
  }
}

class DayCard extends StatelessWidget {
  final WorkDay day;
  final int dayNumber;
  final DateTime? actualDate;

  const DayCard({
    Key? key,
    required this.day,
    required this.dayNumber,
    this.actualDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isWeekend = _isWeekend(dayNumber);
    final dayName = _getDayName(dayNumber);
    final dateText = _getDateText();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: day.hasWork
              ? Color(0xFF111827).withOpacity(0.1)
              : Color(0xFFE5E7EB),
          width: day.hasWork ? 2 : 1,
        ),
        boxShadow: day.hasWork
            ? [
                BoxShadow(
                  color: Color(0xFF111827).withOpacity(0.08),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Column(
        children: [
          // Header section
          Container(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                // Day number circle
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: day.hasWork ? Color(0xFF111827) : Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '$dayNumber',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: day.hasWork ? Colors.white : Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 16),

                // Date info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            dayName,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Color(0xFF111827),
                            ),
                          ),
                          if (isWeekend) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Color(0xFFF59E0B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'WE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFF59E0B),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        dateText,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Hours badge
                if (day.hoursWorked.isNotEmpty && day.hoursWorked != '0:00')
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFF059669),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          day.hoursWorked,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Transport button
                if (day.hasWork && day.shifts.isNotEmpty) ...[
                  SizedBox(width: 8),
                  _buildTransportButton(context),
                ],
              ],
            ),
          ),

          // Content section
          if (day.shifts.isNotEmpty) ...[
            Container(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: day.shifts
                    .map((shift) => Container(
                          margin: EdgeInsets.only(bottom: 8),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color(0xFFFAFAFA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getShiftAccentColor(shift.name),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Shift indicator
                              Container(
                                width: 4,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: _getShiftAccentColor(shift.name),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),

                              SizedBox(width: 16),

                              // Shift details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: _getShiftAccentColor(
                                                shift.name),
                                            borderRadius:
                                                BorderRadius.circular(3),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          _getShiftDisplayName(shift.name),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF6B7280),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      _formatShiftInterval(shift.interval),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Shift icon
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _getShiftAccentColor(shift.name)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getShiftIcon(shift.name),
                                  size: 16,
                                  color: _getShiftAccentColor(shift.name),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ] else if (!day.hasWork) ...[
            Container(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        isWeekend ? Icons.weekend : Icons.free_breakfast,
                        color: Color(0xFF6B7280),
                        size: 16,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      isWeekend ? 'Wochenende' : 'Frei',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getDateText() {
    if (actualDate != null) {
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
      return '${actualDate!.day}. ${monthNames[actualDate!.month]} ${actualDate!.year}';
    }

    final now = DateTime.now();
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

    int estimatedMonth = now.month;
    int estimatedYear = now.year;

    if (now.day >= 15) {
      if (dayNumber < 15 && now.day > 20) {
        estimatedMonth = now.month == 12 ? 1 : now.month + 1;
        if (now.month == 12) estimatedYear = now.year + 1;
      }
    }

    return '$dayNumber. ${monthNames[estimatedMonth]} $estimatedYear';
  }

  Widget _buildTransportButton(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      child: Material(
        color: Color(0xFF111827),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            print('Transport button tapped!');
            _showTransportInfo(context);
          },
          child: Icon(
            Icons.directions_transit,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }

  void _showTransportInfo(BuildContext context) async {
    print('Transport button pressed!');

    if (day.shifts.isEmpty) {
      print('No shifts found');
      _showErrorDialog(context, 'Keine Schichten gefunden');
      return;
    }

    final firstShift = day.shifts.first;
    print('First shift interval: ${firstShift.interval}');

    String startTimeStr;
    if (firstShift.interval.contains('-')) {
      startTimeStr = firstShift.interval.split('-').first.trim();
    } else if (firstShift.interval.contains(' - ')) {
      startTimeStr = firstShift.interval.split(' - ').first.trim();
    } else {
      startTimeStr = firstShift.interval.trim();
    }

    print('Raw start time string: $startTimeStr');

    // Convert to 24-hour format if it's in AM/PM format
    final startTime24Hour = TimeConverter.to24Hour(startTimeStr);
    print('Converted to 24-hour: $startTime24Hour');

    final timeParts = startTime24Hour.split(':');
    if (timeParts.length != 2) {
      print('Invalid time format after conversion: $startTime24Hour');
      _showErrorDialog(context, 'Ungültiges Zeitformat: $startTime24Hour');
      return;
    }

    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      print('Could not parse hour/minute or invalid time: $hour:$minute');
      _showErrorDialog(
          context, 'Zeit konnte nicht geparst werden: $startTime24Hour');
      return;
    }

    DateTime shiftDate;
    if (actualDate != null) {
      shiftDate = actualDate!;
    } else {
      final now = DateTime.now();
      if (now.day >= 15) {
        if (dayNumber < 15 && now.day > 20) {
          shiftDate = DateTime(now.year, now.month + 1, dayNumber);
        } else {
          shiftDate = DateTime(now.year, now.month, dayNumber);
        }
      } else {
        shiftDate = DateTime(now.year, now.month, dayNumber);
      }
    }

    final shiftStartTime =
        DateTime(shiftDate.year, shiftDate.month, shiftDate.day, hour, minute);
    final workStartTime = shiftStartTime.subtract(Duration(minutes: 10));
    print('Shift starts at: $shiftStartTime');
    print('Want to arrive at: $workStartTime (10 minutes early)');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF111827)),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Lade Verbindungen...',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final allRoutes = await TransportService.getAllRoutes(workStartTime);
      Navigator.of(context).pop();

      if (allRoutes != null && allRoutes.isNotEmpty) {
        _showTransportDialog(context, allRoutes, workStartTime);
      } else {
        _showErrorDialog(context, 'Keine Verbindung gefunden');
      }
    } catch (e, stackTrace) {
      print('Exception in _showTransportInfo: $e');
      print('Stack trace: $stackTrace');
      Navigator.of(context).pop();
      _showErrorDialog(context, 'Fehler beim Laden der Verbindung: $e');
    }
  }

  void _showTransportDialog(
      BuildContext context, List<TransportInfo> routes, DateTime workStart) {
    showDialog(
      context: context,
      builder: (context) => _TransportDialog(
        routes: routes,
        workStart: workStart,
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Color(0xFFDC2626),
                size: 32,
              ),
              SizedBox(height: 16),
              Text(
                'Fehler',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF111827),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('OK'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  bool _isWeekend(int dayNumber) {
    final dayOfWeek = (dayNumber - 1) % 7;
    return dayOfWeek == 5 || dayOfWeek == 6;
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

  IconData _getShiftIcon(String shiftName) {
    switch (shiftName) {
      case 'Arbeitszeit':
        return Icons.flight_takeoff;
      case 'RT':
        return Icons.hotel;
      case 'TX':
        return Icons.block;
      default:
        return Icons.schedule;
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

  /// Format shift interval to display in 24-hour format
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
        final startTime = TimeConverter.to24Hour(parts[0].trim());
        final endTime = TimeConverter.to24Hour(parts[1].trim());
        return '$startTime$separator$endTime';
      }

      // If it's just a single time, convert it
      return TimeConverter.to24Hour(interval);
    } catch (e) {
      print('Error formatting shift interval "$interval": $e');
      return interval; // Return original if conversion fails
    }
  }
}

class _TransportDialog extends StatefulWidget {
  final List<TransportInfo> routes;
  final DateTime workStart;

  const _TransportDialog({
    required this.routes,
    required this.workStart,
  });

  @override
  _TransportDialogState createState() => _TransportDialogState();
}

class _TransportDialogState extends State<_TransportDialog> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 400,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(0xFF111827),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.directions_transit,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Anfahrt',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                            ),
                            Text(
                              'Zum Flughafen Wien',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.routes.length > 1)
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(0xFFFAFAFA),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Color(0xFFE5E7EB)),
                          ),
                          child: Text(
                            '${_currentIndex + 1}/${widget.routes.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF111827),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Route tabs
                  if (widget.routes.length > 1) ...[
                    SizedBox(height: 20),
                    Container(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.routes.length,
                        itemBuilder: (context, index) {
                          final route = widget.routes[index];
                          final isSelected = index == _currentIndex;
                          return GestureDetector(
                            onTap: () {
                              _pageController.animateToPage(
                                index,
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Container(
                              width: 100,
                              margin: EdgeInsets.only(right: 8),
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Color(0xFF111827)
                                    : Color(0xFFFAFAFA),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? Color(0xFF111827)
                                      : Color(0xFFE5E7EB),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    route.formattedDepartureTime,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? Colors.white
                                          : Color(0xFF111827),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    route.formattedDuration,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isSelected
                                          ? Colors.white.withOpacity(0.8)
                                          : Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: widget.routes.length,
                itemBuilder: (context, index) {
                  return _buildRouteDetails(widget.routes[index]);
                },
              ),
            ),

            // Footer
            Container(
              padding: EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF111827),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Schließen',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteDetails(TransportInfo info) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time info
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Color(0xFF059669),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Abfahrt ${info.formattedDepartureTime}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                          Text(
                            'Ankunft ${info.formattedArrivalTime}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 12,
                        color: Color(0xFF6366F1),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Ziel: ${widget.workStart.hour.toString().padLeft(2, '0')}:${widget.workStart.minute.toString().padLeft(2, '0')} (10 Min früher)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6366F1),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Stats
          Row(
            children: [
              _buildInfoChip(Icons.schedule, info.formattedDuration),
              SizedBox(width: 8),
              _buildInfoChip(Icons.swap_horiz, '${info.transfers} Umst.'),
              SizedBox(width: 8),
              _buildInfoChip(Icons.eco, '${info.co2Grams}g CO₂'),
            ],
          ),

          SizedBox(height: 20),

          // Route details
          Text(
            'ROUTE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
              letterSpacing: 1,
            ),
          ),

          SizedBox(height: 12),

          ...info.legs.asMap().entries.map((entry) {
            final index = entry.key;
            final leg = entry.value;
            final isLast = index == info.legs.length - 1;

            return Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Row(
                children: [
                  // Transport icon
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(0xFFE5E7EB)),
                    ),
                    child: Icon(
                      _getTransportIcon(leg.type),
                      size: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),

                  SizedBox(width: 12),

                  // Leg details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          leg.displayName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        if (leg.durationMinutes != null)
                          Text(
                            '${leg.durationMinutes} Minuten',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),

          // Disruption warning
          if (info.disruption != null) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFFF59E0B).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_outlined,
                    color: Color(0xFFF59E0B),
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      info.disruption!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB45309),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Color(0xFF6B7280)),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF111827),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTransportIcon(String type) {
    switch (type) {
      case 'walk':
        return Icons.directions_walk;
      case 'transit':
        return Icons.train;
      case 'transfer':
        return Icons.transfer_within_a_station;
      default:
        return Icons.directions;
    }
  }
}
