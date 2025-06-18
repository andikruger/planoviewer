// screens/roster_display_screen.dart

import 'package:flutter/material.dart';
import '../models/roster_models.dart';
import '../widgets/day_card.dart';
import '../services/pdf_export_service.dart';
import 'calendar_screen.dart';

class RosterDisplayScreen extends StatefulWidget {
  final WorkRosterData rosterData;
  final DateTime startDate;
  final DateTime endDate;

  const RosterDisplayScreen({
    Key? key,
    required this.rosterData,
    required this.startDate,
    required this.endDate,
  }) : super(key: key);

  @override
  _RosterDisplayScreenState createState() => _RosterDisplayScreenState();
}

class _RosterDisplayScreenState extends State<RosterDisplayScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _headerController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _headerAnimation;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    _headerController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: Curves.easeOutQuart,
      ),
    );

    _animationController.forward();
    _headerController.forward();

    _debugPrintDateInfo();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  void _debugPrintDateInfo() {
    print('=== ROSTER DISPLAY DEBUG INFO ===');
    print('Start date: ${widget.startDate}');
    print('End date: ${widget.endDate}');
    print(
        'Date range spans ${widget.endDate.difference(widget.startDate).inDays} days');
    print('Current date: ${DateTime.now()}');
    print('Should show filtered view: ${DateTime.now().day < 15}');
  }

  void _exportRosterToPDF() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final pdfService = PDFExportService(
        startDate: widget.startDate,
        endDate: widget.endDate,
      );
      await pdfService.exportRosterToPDF(context, widget.rosterData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ PDF exportiert'),
          backgroundColor: Color(0xFF111827),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Export'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
        ),
      );
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final allDays = widget.rosterData.getDays();
    final visibleDays = _getVisibleDays(allDays);
    final headerText = _getHeaderText();

    print('All days: ${allDays.length}, Visible days: ${visibleDays.length}');

    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header
            _buildHeader(headerText),

            // Stats Overview
            _buildStatsOverview(visibleDays),

            // Days List
            _buildDaysList(visibleDays),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String headerText) {
    return FadeTransition(
      opacity: _headerAnimation,
      child: Container(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            // Navigation and actions
            Row(
              children: [
                // Back button
                Container(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
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
                    child: Column(
                      children: [
                        Row(
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
                              headerText,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Action buttons
                Row(
                  children: [
                    // Calendar view
                    Container(
                      width: 44,
                      height: 44,
                      child: IconButton(
                        onPressed: () => Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    CalendarScreen(
                              rosterData: widget.rosterData,
                              startDate: widget.startDate,
                              endDate: widget.endDate,
                            ),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              return SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(1.0, 0.0),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeInOutCubic,
                                )),
                                child: child,
                              );
                            },
                          ),
                        ),
                        icon: Icon(
                          Icons.calendar_view_month,
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

                    SizedBox(width: 8),

                    // Export PDF
                    Container(
                      width: 44,
                      height: 44,
                      child: IconButton(
                        onPressed: _isExporting ? null : _exportRosterToPDF,
                        icon: _isExporting
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF111827)),
                                ),
                              )
                            : Icon(
                                Icons.file_download_outlined,
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
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview(List<WorkDay> visibleDays) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 24),
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      '${visibleDays.length}',
                      'Tage',
                      Color(0xFF6366F1),
                      Icons.calendar_month,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Color(0xFFE5E7EB),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      '${visibleDays.where((d) => d.hasWork).length}',
                      'Arbeitstage',
                      Color(0xFF059669),
                      Icons.work_outline,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Color(0xFFE5E7EB),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      '${_calculateTotalHours(visibleDays)}h',
                      'Stunden',
                      Color(0xFFF59E0B),
                      Icons.schedule,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
      String value, String label, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),
        SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
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

  Widget _buildDaysList(List<WorkDay> visibleDays) {
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

            // Days header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'SCHICHTEN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                      letterSpacing: 1.5,
                    ),
                  ),
                  Spacer(),
                  Text(
                    '${visibleDays.length} Tage',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Days list
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 24),
                itemCount: visibleDays.length,
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      final delay = index * 0.05;
                      final animationValue = Tween<double>(
                        begin: 0.0,
                        end: 1.0,
                      )
                          .animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: Interval(
                                delay.clamp(0.0, 0.7),
                                (delay + 0.3).clamp(0.3, 1.0),
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                          )
                          .value;

                      return Transform.translate(
                        offset: Offset(30 * (1 - animationValue), 0),
                        child: Opacity(
                          opacity: animationValue,
                          child: Container(
                            margin: EdgeInsets.only(bottom: 12),
                            child: DayCard(
                              day: visibleDays[index],
                              dayNumber: _getDayNumber(index),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Filter days based on roster release schedule
  List<WorkDay> _getVisibleDays(List<WorkDay> allDays) {
    final now = DateTime.now();

    if (now.day < 15) {
      // Before 15th: Show only current month
      final currentMonthDays = <WorkDay>[];

      for (int i = 0; i < allDays.length; i++) {
        final dayDate = widget.startDate.add(Duration(days: i));
        if (dayDate.month == now.month && dayDate.year == now.year) {
          currentMonthDays.add(allDays[i]);
        }
      }

      print('Filtering to current month only: ${currentMonthDays.length} days');
      return currentMonthDays;
    } else {
      // 15th and after: Show all days (current + next month)
      print('Showing all days: ${allDays.length} days');
      return allDays;
    }
  }

  /// Get header text based on visible date range
  String _getHeaderText() {
    final now = DateTime.now();
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

    if (now.day < 15) {
      // Before 15th: Show only current month
      return 'DIENSTPLAN ${monthNames[now.month]}';
    } else {
      // 15th and after: Show current + next month range
      final startMonth = monthNames[widget.startDate.month];
      final endMonth = monthNames[widget.endDate
          .subtract(Duration(days: 1))
          .month]; // subtract 1 day since endDate is exclusive

      if (startMonth == endMonth) {
        return 'DIENSTPLAN $startMonth';
      } else {
        return 'DIENSTPLAN $startMonth-$endMonth';
      }
    }
  }

  /// Calculate total hours for visible days
  int _calculateTotalHours(List<WorkDay> days) {
    return days.fold(0, (sum, day) {
      if (day.hoursWorked.isEmpty || day.hoursWorked == '0:00') return sum;
      final hours = day.hoursWorked.split(':')[0];
      return sum + (int.tryParse(hours) ?? 0);
    });
  }

  /// Get day number for display - using the passed date range
  int _getDayNumber(int visibleIndex) {
    final allDays = widget.rosterData.getDays();
    final visibleDays = _getVisibleDays(allDays);

    // Find the actual index in the full day list
    final visibleDay = visibleDays[visibleIndex];
    final actualIndex = allDays.indexOf(visibleDay);

    // Calculate the actual day number based on start date + index
    final dayDate = widget.startDate.add(Duration(days: actualIndex));

    print(
        'Visible index $visibleIndex -> actual index $actualIndex -> day ${dayDate.day} of ${dayDate.month}/${dayDate.year}');

    return dayDate.day;
  }
}
