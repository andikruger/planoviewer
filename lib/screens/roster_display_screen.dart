// screens/roster_display_screen.dart

import 'package:flutter/material.dart';
import 'package:planoviewer/widgets/api_token_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/roster_models.dart';
import '../widgets/day_card.dart';
import 'roster_input_screen.dart';
import '../services/export_service.dart';
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

enum ExportFormat {
  pdf,
  listCsv,
  calendarCsv,
  icalendar,
  csv,
  pdfList,
  pdfCalendar,
}

class _RosterDisplayScreenState extends State<RosterDisplayScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _headerController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _headerAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutQuart),
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

  Future<void> _showResetDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFAFAFA),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Alle Daten zurücksetzen?',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'Alle gespeicherten Daten (Dienstplan, API-Token, Adressen) werden dauerhaft gelöscht und Sie kehren zum Startbildschirm zurück.',
          style: TextStyle(color: Color(0xFF6B7280), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Abbrechen',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetAllData();
            },
            child: const Text(
              'Zurücksetzen',
              style: TextStyle(
                color: Color(0xFFDC2626),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear all app data
      await prefs.remove('saved_roster');
      await prefs.remove('api_token');
      await prefs.remove('roster_start_date');
      await prefs.remove('roster_end_date');
      await prefs.remove('roster_lat');
      await prefs.remove('roster_lon');
      await prefs.remove('roster_address');

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.refresh, color: Colors.white),
              SizedBox(width: 12),
              Text('Alle Daten wurden zurückgesetzt'),
            ],
          ),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );

      // Navigate back to input screen with clean slate
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => RosterInputScreen()),
          (route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Fehler beim Zurücksetzen: ${e.toString()}'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _debugPrintDateInfo() {
    print('=== ROSTER DISPLAY DEBUG INFO ===');
    print('Start date: ${widget.startDate}');
    print('End date: ${widget.endDate}');
    print(
      'Date range spans ${widget.endDate.difference(widget.startDate).inDays} days',
    );
    print('Current date: ${DateTime.now()}');
    print('Should show filtered view: ${DateTime.now().day < 15}');
  }

  Future<void> _showTokenUpdateDialog() async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return TokenInputDialog(
          title: 'API-Token aktualisieren',
          subtitle: 'Gib einen neuen API-Token ein, um fortzufahren',
          onTokenSubmitted: () {
            // This callback is called when validation starts
          },
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      // Token was updated successfully
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('API-Token erfolgreich aktualisiert'),
            ],
          ),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allDays = widget.rosterData.getDays();
    final visibleDays = _getVisibleDays(allDays);
    final headerText = _getHeaderText();

    print('All days: ${allDays.length}, Visible days: ${visibleDays.length}');

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
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
        padding: const EdgeInsets.all(24),
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
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RosterInputScreen(),
                        settings: const RouteSettings(
                          arguments: 'prevent_auto_nav',
                        ),
                      ),
                    ),
                    icon: const Icon(
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
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE30613),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              headerText,
                              style: const TextStyle(
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
                    // Update API Token
                    Container(
                      width: 44,
                      height: 44,
                      child: IconButton(
                        onPressed: _showTokenUpdateDialog,
                        icon: const Icon(
                          Icons.key,
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

                    const SizedBox(width: 8),

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
                            transitionsBuilder:
                                (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                ) {
                                  return SlideTransition(
                                    position:
                                        Tween<Offset>(
                                          begin: const Offset(1.0, 0.0),
                                          end: Offset.zero,
                                        ).animate(
                                          CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeInOutCubic,
                                          ),
                                        ),
                                    child: child,
                                  );
                                },
                          ),
                        ),
                        icon: const Icon(
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

                    const SizedBox(width: 8),

                    // Export PDF
                    Container(
                      width: 44,
                      height: 44,
                      child: PopupMenuButton<ExportFormat>(
                        onSelected: (format) => ExportService(
                          startDate: widget.startDate,
                          endDate: widget.endDate,
                        ).exportRoster(context, widget.rosterData, format),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: ExportFormat.pdfList,
                            child: Row(
                              children: [
                                Icon(Icons.list_alt),
                                SizedBox(width: 8),
                                Text('PDF Liste'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: ExportFormat.pdfCalendar,
                            child: Row(
                              children: [
                                Icon(Icons.calendar_view_month),
                                SizedBox(width: 8),
                                Text('PDF Kalender'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: ExportFormat.csv,
                            child: Row(
                              children: [
                                Icon(Icons.table_chart),
                                SizedBox(width: 8),
                                Text('CSV'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: ExportFormat.icalendar,
                            child: Row(
                              children: [
                                Icon(Icons.event),
                                SizedBox(width: 8),
                                Text('iCalendar'),
                              ],
                            ),
                          ),
                        ],
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.file_download_outlined,
                            color: Color(0xFF111827),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Reset all data
                    Container(
                      width: 44,
                      height: 44,
                      child: IconButton(
                        onPressed: _showResetDialog,
                        icon: const Icon(
                          Icons.refresh,
                          color: Color(0xFFDC2626),
                          size: 20,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFFEF2F2),
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
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      '${visibleDays.length}',
                      'Tage',
                      const Color(0xFF6366F1),
                      Icons.calendar_month,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: const Color(0xFFE5E7EB),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      '${visibleDays.where((d) => d.hasWork).length}',
                      'Arbeitstage',
                      const Color(0xFF059669),
                      Icons.work_outline,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: const Color(0xFFE5E7EB),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      '${_calculateTotalHours(visibleDays)}h',
                      'Stunden',
                      const Color(0xFFF59E0B),
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
    String value,
    String label,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
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
        margin: const EdgeInsets.only(top: 24),
        decoration: const BoxDecoration(
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
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Days header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    'SCHICHTEN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${visibleDays.length} Tage',
                    style: const TextStyle(
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
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: visibleDays.length,
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      final delay = index * 0.05;
                      final animationValue = Tween<double>(begin: 0.0, end: 1.0)
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
                            margin: const EdgeInsets.only(bottom: 12),
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
  /// Filter days based on roster release schedule
  List<WorkDay> _getVisibleDays(List<WorkDay> allDays) {
    final now = DateTime.now();

    // Get the actual start and end months from the roster data
    final rosterStartMonth = widget.startDate.month;
    final rosterStartYear = widget.startDate.year;

    if (now.day < 15) {
      // Before 15th: Show only the first month of the roster period
      final firstMonthDays = <WorkDay>[];

      for (int i = 0; i < allDays.length; i++) {
        final dayDate = widget.startDate.add(Duration(days: i));
        if (dayDate.month == rosterStartMonth &&
            dayDate.year == rosterStartYear) {
          firstMonthDays.add(allDays[i]);
        }
      }

      print(
        'Filtering to first roster month (${rosterStartMonth}): ${firstMonthDays.length} days',
      );
      return firstMonthDays;
    } else {
      // 15th and after: Show all days in the roster period
      print('Showing all roster days: ${allDays.length} days');
      return allDays;
    }
  }

  String _getHeaderText() {
    final now = DateTime.now();
    final monthNames = [
      '',
      'JANUAR', // or 'JANUAR' for display, 'Januar' for calendar
      'FEBRUAR',
      'MAERZ',
      'APRIL',
      'MAI',
      'JUNI',
      'JULI',
      'AUGUST',
      'SEPTEMBER',
      'OKTOBER',
      'NOVEMBER',
      'DEZEMBER',
    ];

    final rosterStartMonth = widget.startDate.month;
    final rosterEndDate = widget.endDate.subtract(const Duration(days: 1));
    final rosterEndMonth = rosterEndDate.month;

    if (now.day < 15) {
      // Before 15th: Show only first month of roster
      return 'DIENSTPLAN ${monthNames[rosterStartMonth]}'; // or 'KALENDER' for calendar screen
    } else {
      // 15th and after: Show full range
      if (rosterStartMonth == rosterEndMonth) {
        return 'DIENSTPLAN ${monthNames[rosterStartMonth]}';
      } else {
        return 'DIENSTPLAN ${monthNames[rosterStartMonth]}-${monthNames[rosterEndMonth]}';
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
      'Visible index $visibleIndex -> actual index $actualIndex -> day ${dayDate.day} of ${dayDate.month}/${dayDate.year}',
    );

    return dayDate.day;
  }
}
