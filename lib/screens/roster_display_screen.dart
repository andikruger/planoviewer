// screens/roster_display_screen.dart

import 'package:flutter/material.dart';
import '../models/roster_models.dart';
import '../widgets/day_card.dart';
import '../services/pdf_export_service.dart';
import 'calendar_screen.dart';

class RosterDisplayScreen extends StatefulWidget {
  final WorkRosterData rosterData;

  const RosterDisplayScreen({Key? key, required this.rosterData})
      : super(key: key);

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _exportRosterToPDF() async {
    final pdfService = PDFExportService();
    await pdfService.exportRosterToPDF(context, widget.rosterData);
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.rosterData.getDays();

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
                                'DIENSTPLAN JULI',
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
                              pageBuilder: (context, animation,
                                      secondaryAnimation) =>
                                  CalendarScreen(rosterData: widget.rosterData),
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
                              '${days.length}',
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
                              '${days.where((d) => d.hasWork).length}',
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
                              '${widget.rosterData.getTotalHours()}h',
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
                          itemCount: days.length,
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
                                        day: days[index], dayNumber: index + 1),
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
