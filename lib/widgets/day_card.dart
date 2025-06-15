// widgets/day_card.dart

import 'package:flutter/material.dart';
import '../models/roster_models.dart';

class DayCard extends StatelessWidget {
  final WorkDay day;
  final int dayNumber;

  const DayCard({Key? key, required this.day, required this.dayNumber})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isWeekend = _isWeekend(dayNumber);
    final dayName = _getDayName(dayNumber);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: day.hasWork ? 3 : 1,
        borderRadius: BorderRadius.circular(12),
        shadowColor: day.hasWork
            ? Color(0xFFE30613).withOpacity(0.2)
            : Colors.grey.withOpacity(0.1),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: day.hasWork
                  ? Color(0xFFE30613).withOpacity(0.2)
                  : Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Header section
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: day.hasWork
                      ? Color(0xFFE30613).withOpacity(0.05)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color:
                            day.hasWork ? Color(0xFFE30613) : Colors.grey[400],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '$dayNumber',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                dayName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isWeekend
                                      ? Color(0xFFFF8F00)
                                      : Colors.grey[800],
                                ),
                              ),
                              if (isWeekend) ...[
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFF8F00).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'WE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFF8F00),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 2),
                          Text(
                            '${dayNumber}. Juli 2024',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (day.hoursWorked.isNotEmpty && day.hoursWorked != '0:00')
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(16),
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
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Content section
              if (day.shifts.isNotEmpty) ...[
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: day.shifts
                        .map((shift) => Container(
                              margin: EdgeInsets.only(bottom: 8),
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _getShiftColor(shift.name)
                                    .withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _getShiftColor(shift.name)
                                      .withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: _getShiftColor(shift.name),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      _getShiftIcon(shift.name),
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _getShiftDisplayName(shift.name),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        Text(
                                          shift.interval,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: _getShiftColor(shift.name),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ] else if (!day.hasWork) ...[
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.weekend, color: Colors.grey[500], size: 16),
                        SizedBox(width: 8),
                        Text(
                          isWeekend ? 'Wochenende' : 'Frei',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
    return dayOfWeek == 5 || dayOfWeek == 6; // Saturday or Sunday
  }

  Color _getShiftColor(String shiftName) {
    switch (shiftName) {
      case 'Arbeitszeit':
        return Color(0xFFE30613); // Austrian Airlines Red
      case 'RT':
        return Color(0xFFFF8F00); // Orange for rest time
      case 'TX':
        return Color(0xFF1976D2); // Blue for training
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
