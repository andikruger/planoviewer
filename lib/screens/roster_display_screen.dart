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
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();

    // Debug: Print date range information
    _debugPrintDateInfo();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
  final pdfService = PDFExportService(
    startDate: widget.startDate,
    endDate: widget.endDate,
  );
  await pdfService.exportRosterToPDF(context, widget.rosterData);
}

  @override
  Widget build(BuildContext context) {
    final allDays = widget.rosterData.getDays();
    final visibleDays = _getVisibleDays(allDays);
    final headerText = _getHeaderText();

    print('All days: ${allDays.length}, Visible days: ${visibleDays.length}');

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE30613),
              Colors.white,
            ],
            stops: [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with Austrian Airlines branding
              Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.flight, color: Colors.white, size: 24),
                              SizedBox(width: 8),
                              Text(
                                headerText,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
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
                          icon: Icon(Icons.calendar_view_month,
                              color: Colors.white),
                          tooltip: 'Kalenderansicht',
                        ),
                        IconButton(
                          onPressed: _exportRosterToPDF,
                          icon: Icon(Icons.file_download, color: Colors.white),
                          tooltip: 'Export PDF',
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Container(
                      height: 2,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ],
                ),
              ),

              // Summary cards
              AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 20),
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Color(0xFFE30613).withOpacity(0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSummaryItem(
                              Icons.calendar_month,
                              'Tage Gesamt',
                              '${visibleDays.length}',
                              Color(0xFFE30613),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 50,
                            color: Colors.grey[200],
                          ),
                          Expanded(
                            child: _buildSummaryItem(
                              Icons.work,
                              'Arbeitstage',
                              '${visibleDays.where((d) => d.hasWork).length}',
                              Color(0xFF2E7D32),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 50,
                            color: Colors.grey[200],
                          ),
                          Expanded(
                            child: _buildSummaryItem(
                              Icons.schedule,
                              'Stunden Gesamt',
                              '${_calculateTotalHours(visibleDays)}h',
                              Color(0xFFFF8F00),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: 20),

              // Days list
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          itemCount: visibleDays.length,
                          itemBuilder: (context, index) {
                            return AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                final delay = index * 0.03;
                                final animationValue = Tween<double>(
                                  begin: 0.0,
                                  end: 1.0,
                                )
                                    .animate(
                                      CurvedAnimation(
                                        parent: _animationController,
                                        curve: Interval(delay, 1.0,
                                            curve: Curves.easeOutCubic),
                                      ),
                                    )
                                    .value;

                                return Transform.translate(
                                  offset: Offset(30 * (1 - animationValue), 0),
                                  child: Opacity(
                                    opacity: animationValue,
                                    child: DayCard(
                                        day: visibleDays[index],
                                        dayNumber: _getDayNumber(index)),
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
              ),
            ],
          ),
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

  Widget _buildSummaryItem(
      IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
