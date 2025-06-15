// screens/roster_input_screen.dart

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/roster_models.dart';
import 'roster_display_screen.dart';

class RosterInputScreen extends StatefulWidget {
  @override
  _RosterInputScreenState createState() => _RosterInputScreenState();
}

class _RosterInputScreenState extends State<RosterInputScreen>
    with TickerProviderStateMixin {
  final TextEditingController _jsonController = TextEditingController();
  String? _errorMessage;
  bool _hasText = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _jsonController.addListener(_onTextChanged);
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _loadSavedRoster(); // Load saved data on startup
  }

  @override
  void dispose() {
    _jsonController.removeListener(_onTextChanged);
    _jsonController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _jsonController.text.trim().isNotEmpty;
      _errorMessage = null;
    });
  }

  // Load saved roster data from SharedPreferences
  void _loadSavedRoster() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString('saved_roster');
      if (savedJson != null && savedJson.isNotEmpty) {
        setState(() {
          _jsonController.text = savedJson;
          _hasText = true;
        });

        // Show a subtle indication that data was loaded
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.restore, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text('Gespeicherte Daten wiederhergestellt'),
                  ],
                ),
                backgroundColor: Color(0xFF1976D2),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.only(bottom: 100, left: 16, right: 16),
              ),
            );
          }
        });
      }
    } catch (e) {
      print('Error loading saved roster: $e');
    }
  }

  // Save roster data to SharedPreferences
  void _saveRosterData(String jsonData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_roster', jsonData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.save, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('Dienstplan automatisch gespeichert'),
            ],
          ),
          backgroundColor: Color(0xFF2E7D32),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('Error saving roster: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Speichern: $e'),
          backgroundColor: Color(0xFFE30613),
        ),
      );
    }
  }

  // Clear saved data
  void _clearSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_roster');

      setState(() {
        _jsonController.clear();
        _hasText = false;
        _errorMessage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.delete_sweep, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('Gespeicherte Daten gelöscht'),
            ],
          ),
          backgroundColor: Color(0xFFFF8F00),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('Error clearing data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Löschen: $e'),
          backgroundColor: Color(0xFFE30613),
        ),
      );
    }
  }

  void _parseAndNavigate() {
    try {
      final jsonText = _jsonController.text.trim();
      if (jsonText.isEmpty) {
        setState(() {
          _errorMessage = 'Bitte fügen Sie JSON-Daten ein';
        });
        return;
      }

      final jsonData = json.decode(jsonText);
      final rosterData = WorkRosterData.fromJson(jsonData);

      // Save the roster data
      _saveRosterData(jsonText);

      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              RosterDisplayScreen(rosterData: rosterData),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Ungültiges JSON-Format: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE30613), // Austrian Airlines Red
              Color(0xFFFFFFFF), // White
            ],
            stops: [0.0, 0.7],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 40),
                  // Austrian Airlines Logo Area
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.flight,
                              size: 32,
                              color: Color(0xFFE30613),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'AUSTRIAN',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE30613),
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Container(
                          height: 2,
                          width: 60,
                          decoration: BoxDecoration(
                            color: Color(0xFFE30613),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Crew Roster System',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),

                  Text(
                    'Dienstplan-Daten eingeben',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Fügen Sie Ihre JSON-Dienstplandaten ein',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),

                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Color(0xFFE30613).withOpacity(0.2),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(16),
                      child: TextField(
                        controller: _jsonController,
                        maxLines: null,
                        expands: true,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText:
                              '{\n  "type": "MonthJournalData",\n  "data": {\n    "columns": {\n      ...\n    }\n  }\n}',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                            fontFamily: 'Courier',
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'Courier',
                          height: 1.4,
                        ),
                        textAlignVertical: TextAlignVertical.top,
                      ),
                    ),
                  ),

                  if (_errorMessage != null) ...[
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFE30613).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Color(0xFFE30613).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Color(0xFFE30613)),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Color(0xFFE30613),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: 24),
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _hasText
                          ? [
                              BoxShadow(
                                color: Color(0xFFE30613).withOpacity(0.3),
                                blurRadius: 12,
                                offset: Offset(0, 6),
                              ),
                            ]
                          : [],
                    ),
                    child: ElevatedButton(
                      onPressed: _hasText ? _parseAndNavigate : null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.flight_takeoff, size: 20),
                          SizedBox(width: 12),
                          Text(
                            'Dienstplan anzeigen',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _hasText ? Color(0xFFE30613) : Colors.grey[300],
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  // Clear data button
                  if (_hasText) ...[
                    SizedBox(height: 12),
                    TextButton(
                      onPressed: _clearSavedData,
                      child: Text(
                        'Gespeicherte Daten löschen',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],

                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
