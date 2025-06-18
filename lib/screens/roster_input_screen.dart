// screens/roster_input_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:planoviewer/widgets/api_token_dialog.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
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
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _currentApiToken;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  // SharedPreferences keys
  static const String _rosterDataKey = 'saved_roster';
  static const String _apiTokenKey = 'api_token';

  @override
  void initState() {
    super.initState();
    _jsonController.addListener(_onTextChanged);

    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuart,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _initializeRosterData();
  }

  @override
  void dispose() {
    _jsonController.removeListener(_onTextChanged);
    _jsonController.dispose();
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _jsonController.text.trim().isNotEmpty;
      _errorMessage = null;
    });
  }

  // [Keep all the existing backend methods - they remain unchanged]
  Future<void> _initializeRosterData() async {
    setState(() {
      _isInitializing = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRosterData = prefs.getString(_rosterDataKey);
      final apiToken = prefs.getString(_apiTokenKey);
      final savedStartDate = prefs.getString('roster_start_date');
      final savedEndDate = prefs.getString('roster_end_date');

      _currentApiToken = apiToken;

      if (savedRosterData != null && savedRosterData.isNotEmpty) {
        print('Found saved roster data, navigating to display screen');

        final jsonData = json.decode(savedRosterData);
        final rosterData = WorkRosterData.fromJson(jsonData);

        DateTime startDate, endDate;
        if (savedStartDate != null && savedEndDate != null) {
          startDate = DateTime.parse(savedStartDate);
          endDate = DateTime.parse(savedEndDate);
        } else {
          final (startDateStr, endDateStr) = _getDateRange(DateTime.now());
          startDate = DateTime.parse(startDateStr);
          endDate = DateTime.parse(endDateStr);
        }

        await Future.delayed(Duration(milliseconds: 500));

        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  RosterDisplayScreen(
                rosterData: rosterData,
                startDate: startDate,
                endDate: endDate,
              ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        }
        return;
      }

      if (apiToken != null && apiToken.isNotEmpty) {
        print('No saved data found, attempting to fetch from API');
        await _fetchRosterDataFromAPI();
      } else {
        setState(() {
          _isInitializing = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      print('Error during initialization: $e');
      setState(() {
        _errorMessage = 'Fehler beim Laden der Daten: ${e.toString()}';
        _isInitializing = false;
      });
      _animationController.forward();
    }
  }

  Future<void> _fetchRosterDataFromAPI() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final apiToken = prefs.getString(_apiTokenKey);

      if (apiToken == null || apiToken.isEmpty) {
        print('No API token available in SharedPreferences');
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Kein API-Token verfügbar. Bitte Token eingeben.';
        });
        _animationController.forward();
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final now = DateTime.now();
      final (startDateStr, endDateStr) = _getDateRange(now);
      final startDate = DateTime.parse(startDateStr);
      final endDate = DateTime.parse(endDateStr);

      print('Fetching roster data for period: $startDateStr to $endDateStr');
      print('Using API token: ${apiToken.substring(0, 8)}...');

      final response = await http.get(
        Uri.parse(
            'https://austrian.plano-wfm.cloud/myplanoservice/api/monthjournal/data?start=$startDateStr&end=$endDateStr'),
        headers: {
          'Authorization': 'Bearer $apiToken',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 30));

      print('API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final rosterData = WorkRosterData.fromJson(jsonData);

        await _saveRosterData(response.body);
        await _saveDateRange(startDate, endDate);

        print('Successfully fetched and saved roster data');

        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  RosterDisplayScreen(
                rosterData: rosterData,
                startDate: startDate,
                endDate: endDate,
              ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
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
        }
      } else {
        throw Exception(
            'API returned status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error fetching roster data from API: $e');
      setState(() {
        _errorMessage = 'Fehler beim Laden der API-Daten: ${e.toString()}';
        _isLoading = false;
        _isInitializing = false;
      });
      _animationController.forward();
    }
  }

  (String, String) _getDateRange(DateTime now) {
    final String startDateStr;
    final String endDateStr;

    if (now.day < 20) {
      startDateStr = _formatDate(DateTime(now.year, now.month + 1, 1));
      endDateStr = _formatDate(DateTime(now.year, now.month + 2, 1));
      print(
          'Before 15th - fetching current month only: ${_getMonthName(now.month)}');
    } else {
      startDateStr = _formatDate(DateTime(now.year, now.month, 1));
      endDateStr = _formatDate(DateTime(now.year, now.month + 2, 1));
      final nextMonth = now.month == 12 ? 1 : now.month + 1;
      print(
          'After 15th - fetching current and next month: ${_getMonthName(now.month)} + ${_getMonthName(nextMonth)}');
    }

    return (startDateStr, endDateStr);
  }

  Future<void> _saveDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('roster_start_date', startDate.toIso8601String());
      await prefs.setString('roster_end_date', endDate.toIso8601String());
      print(
          'Date range saved: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');
    } catch (e) {
      print('Error saving date range: $e');
    }
  }

  void _parseAndNavigate() {
    try {
      final jsonText = _jsonController.text.trim();
      if (jsonText.isEmpty) {
        setState(() {
          _errorMessage = 'Bitte füge JSON-Daten ein';
        });
        return;
      }

      final jsonData = json.decode(jsonText);
      final rosterData = WorkRosterData.fromJson(jsonData);

      final now = DateTime.now();
      final (startDateStr, endDateStr) = _getDateRange(now);
      final startDate = DateTime.parse(startDateStr);
      final endDate = DateTime.parse(endDateStr);

      _saveRosterData(jsonText);
      _saveDateRange(startDate, endDate);

      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              RosterDisplayScreen(
            rosterData: rosterData,
            startDate: startDate,
            endDate: endDate,
          ),
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

  String _getMonthName(int month) {
    const monthNames = [
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
    return monthNames[month];
  }

  Future<void> _showTokenDialog({bool isEdit = false}) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return TokenInputDialog(
          initialToken: isEdit ? _currentApiToken : null,
          title: isEdit ? 'API-Token bearbeiten' : 'API-Token eingeben',
          subtitle: isEdit
              ? 'Gib einen neuen API-Token ein'
              : 'Gib deinen Ihren API-Token ein, um automatisch Dienstpläne zu laden',
          onTokenSubmitted: () {},
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      await _saveApiToken(result);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ API-Token erfolgreich gespeichert'),
          backgroundColor: Color(0xFF111827),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
        ),
      );

      if (!isEdit) {
        await _fetchRosterDataFromAPI();
      }
    }
  }

  Future<void> _saveApiToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_apiTokenKey, token);
      setState(() {
        _currentApiToken = token;
      });
      print('API token saved to SharedPreferences');
    } catch (e) {
      print('Error saving API token: $e');
      throw Exception('Fehler beim Speichern des Tokens');
    }
  }

  Future<void> _clearApiToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_apiTokenKey);
      setState(() {
        _currentApiToken = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('API-Token entfernt'),
          backgroundColor: Color(0xFF111827),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      print('Error clearing API token: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _saveRosterData(String jsonData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_rosterDataKey, jsonData);
      print('Roster data saved to SharedPreferences');
    } catch (e) {
      print('Error saving roster data: $e');
      throw Exception('Fehler beim Speichern der Daten');
    }
  }

  Future<void> _clearSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_rosterDataKey);

      setState(() {
        _jsonController.clear();
        _hasText = false;
        _errorMessage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Daten gelöscht'),
          backgroundColor: Color(0xFF111827),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      print('Error clearing data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Löschen: $e'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
    }
  }

  Future<void> _refreshFromAPI() async {
    setState(() {
      _errorMessage = null;
    });
    await _fetchRosterDataFromAPI();
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData != null &&
          clipboardData.text != null &&
          clipboardData.text!.isNotEmpty) {
        setState(() {
          _jsonController.text = clipboardData.text!;
          _hasText = true;
          _errorMessage = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Eingefügt'),
            backgroundColor: Color(0xFF111827),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: EdgeInsets.all(16),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Zwischenablage ist leer'),
            backgroundColor: Color(0xFF111827),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      print('Error pasting from clipboard: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Einfügen'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showRemoveTokenDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFFFAFAFA),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Token entfernen?',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Der API-Token wird dauerhaft entfernt und automatische Updates sind nicht mehr möglich.',
          style: TextStyle(
            color: Color(0xFF6B7280),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Abbrechen',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearApiToken();
            },
            child: Text(
              'Entfernen',
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

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: Color(0xFFFAFAFA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Color(0xFF111827),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.flight,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 32),
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
                'Lade Dienstplan...',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Minimalist Header
                    Container(
                      margin: EdgeInsets.only(bottom: 48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Color(0xFFE30613),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AUSTRIAN',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF111827),
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  Text(
                                    'Ground Roster',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF6B7280),
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // API Token Section
                    _buildApiTokenSection(),

                    SizedBox(height: 48),

                    // Manual Input Section
                    Text(
                      'Manuell eingeben',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'JSON-Daten direkt eingeben',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    SizedBox(height: 24),

                    // JSON Input
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              _hasText ? Color(0xFF111827) : Color(0xFFE5E7EB),
                          width: _hasText ? 2 : 1,
                        ),
                        boxShadow: [
                          if (_hasText)
                            BoxShadow(
                              color: Color(0xFF111827).withOpacity(0.1),
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Header
                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Color(0xFFFAFAFA),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(15),
                                topRight: Radius.circular(15),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'JSON',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                    letterSpacing: 1,
                                  ),
                                ),
                                Spacer(),
                                GestureDetector(
                                  onTap: _pasteFromClipboard,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF111827),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.content_paste,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Einfügen',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Text Input
                          Container(
                            height: 300,
                            padding: EdgeInsets.all(20),
                            child: TextField(
                              controller: _jsonController,
                              maxLines: null,
                              expands: true,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText:
                                    '{\n  "type": "MonthJournalData",\n  "data": {\n    ...\n  }\n}',
                                hintStyle: TextStyle(
                                  color: Color(0xFFD1D5DB),
                                  fontSize: 14,
                                  fontFamily: 'monospace',
                                  height: 1.5,
                                ),
                              ),
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'monospace',
                                height: 1.5,
                                color: Color(0xFF111827),
                              ),
                              textAlignVertical: TextAlignVertical.top,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_errorMessage != null) ...[
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Color(0xFFDC2626).withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Color(0xFFDC2626),
                              size: 18,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    SizedBox(height: 32),

                    // Action Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _hasText ? _parseAndNavigate : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _hasText ? Color(0xFF111827) : Color(0xFFE5E7EB),
                          foregroundColor: Colors.white,
                          elevation: _hasText ? 8 : 0,
                          shadowColor: _hasText
                              ? Color(0xFF111827).withOpacity(0.3)
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Dienstplan anzeigen',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _hasText ? Colors.white : Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    ),

                    if (_hasText) ...[
                      SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: _clearSavedData,
                          child: Text(
                            'Eingabe löschen',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],

                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApiTokenSection() {
    final hasToken = _currentApiToken != null && _currentApiToken!.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasToken ? Color(0xFF059669) : Color(0xFFE5E7EB),
          width: hasToken ? 2 : 1,
        ),
        boxShadow: [
          if (hasToken)
            BoxShadow(
              color: Color(0xFF059669).withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: hasToken ? Color(0xFF059669) : Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(width: 12),
              Text(
                hasToken ? 'API-Token aktiv' : 'API-Token',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              Spacer(),
              if (hasToken)
                Icon(
                  Icons.check_circle,
                  color: Color(0xFF059669),
                  size: 20,
                ),
            ],
          ),
          SizedBox(height: 16),
          if (hasToken) ...[
            // Active token display
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aktueller Token:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF059669),
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${_currentApiToken!.substring(0, 8)}${'•' * 12}${_currentApiToken!.substring(_currentApiToken!.length - 4)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'monospace',
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Token actions
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _refreshFromAPI,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF111827),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Daten laden',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Container(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => _showTokenDialog(isEdit: true),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Bearbeiten',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  height: 48,
                  width: 48,
                  child: IconButton(
                    onPressed: _showRemoveTokenDialog,
                    icon: Icon(
                      Icons.delete_outline,
                      color: Color(0xFFDC2626),
                      size: 20,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Color(0xFFFEF2F2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // No token state
            Text(
              'Automatische Dienstplan-Updates aktivieren',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),

            SizedBox(height: 20),

            Container(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => _showTokenDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF111827),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Token eingeben',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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
}
