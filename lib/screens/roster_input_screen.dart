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
  late Animation<double> _fadeAnimation;

  // SharedPreferences keys
  static const String _rosterDataKey = 'saved_roster';
  static const String _apiTokenKey = 'api_token';

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

    // Check for existing data or fetch from API
    _initializeRosterData();
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

  /// Initialize roster data - check SharedPreferences first, then API

  /// Initialize roster data - check SharedPreferences first, then API
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

      // Store current API token for display
      _currentApiToken = apiToken;

      if (savedRosterData != null && savedRosterData.isNotEmpty) {
        // We have saved data, navigate directly to display screen
        print('Found saved roster data, navigating to display screen');

        final jsonData = json.decode(savedRosterData);
        final rosterData = WorkRosterData.fromJson(jsonData);

        // Parse saved dates or calculate them
        DateTime startDate, endDate;
        if (savedStartDate != null && savedEndDate != null) {
          startDate = DateTime.parse(savedStartDate);
          endDate = DateTime.parse(savedEndDate);
        } else {
          // Fallback to current date calculation
          final (startDateStr, endDateStr) = _getDateRange(DateTime.now());
          startDate = DateTime.parse(startDateStr);
          endDate = DateTime.parse(endDateStr);
        }

        // Wait a moment for the animation, then navigate
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

      // No saved data, try to fetch from API if token exists
      if (apiToken != null && apiToken.isNotEmpty) {
        print('No saved data found, attempting to fetch from API');
        await _fetchRosterDataFromAPI();
      } else {
        // No token, show manual input screen
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

  /// Fetch roster data from API
  Future<void> _fetchRosterDataFromAPI() async {
    try {
      // Get API token from SharedPreferences
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

      // Get date range based on current date
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

        // Validate that we can parse this data
        final rosterData = WorkRosterData.fromJson(jsonData);

        // Save roster data and date range
        await _saveRosterData(response.body);
        await _saveDateRange(startDate, endDate);

        print('Successfully fetched and saved roster data');

        // Navigate to display screen with date range
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

  /// Get date range based on roster release schedule
  (String, String) _getDateRange(DateTime now) {
    final String startDateStr;
    final String endDateStr;

    if (now.day < 20) {
      // Before 15th: Show only current month
      startDateStr = _formatDate(DateTime(now.year, now.month + 1, 1));
      endDateStr = _formatDate(DateTime(now.year, now.month + 2, 1));
      print(
          'Before 15th - fetching current month only: ${_getMonthName(now.month)}');
    } else {
      // 15th and after: Show current month + next month
      startDateStr = _formatDate(DateTime(now.year, now.month, 1));
      endDateStr = _formatDate(DateTime(now.year, now.month + 2, 1));
      final nextMonth = now.month == 12 ? 1 : now.month + 1;
      print(
          'After 15th - fetching current and next month: ${_getMonthName(now.month)} + ${_getMonthName(nextMonth)}');
    }

    return (startDateStr, endDateStr);
  }

  /// Save date range to SharedPreferences
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

  /// Parse manual JSON input and navigate
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

      // For manual input, calculate current date range
      final now = DateTime.now();
      final (startDateStr, endDateStr) = _getDateRange(now);
      final startDate = DateTime.parse(startDateStr);
      final endDate = DateTime.parse(endDateStr);

      // Save the roster data and date range
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

  /// Get month name for logging
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

  /// Show token input dialog
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
          onTokenSubmitted: () {
            // This callback is called when validation starts
          },
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      // Token was provided, save it
      await _saveApiToken(result);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('API-Token erfolgreich gespeichert'),
            ],
          ),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      // Try to fetch roster data with new token
      if (!isEdit) {
        await _fetchRosterDataFromAPI();
      }
    }
  }

  /// Save API token to SharedPreferences
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

  /// Clear API token
  Future<void> _clearApiToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_apiTokenKey);
      setState(() {
        _currentApiToken = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info, color: Colors.white),
              SizedBox(width: 12),
              Text('API-Token entfernt'),
            ],
          ),
          backgroundColor: Colors.blue[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      print('Error clearing API token: $e');
    }
  }

  /// Format date as YYYY-MM-DD
  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Save roster data to SharedPreferences
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

  /// Clear saved roster data
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

  /// Refresh data from API
  Future<void> _refreshFromAPI() async {
    setState(() {
      _errorMessage = null;
    });
    await _fetchRosterDataFromAPI();
  }

  /// Paste from clipboard (for manual input)
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
            content: Row(
              children: [
                Icon(Icons.content_paste, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Aus Zwischenablage eingefügt'),
              ],
            ),
            backgroundColor: Color(0xFF1976D2),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Zwischenablage ist leer'),
              ],
            ),
            backgroundColor: Color(0xFFFF8F00),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Error pasting from clipboard: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('Fehler beim Einfügen: $e'),
            ],
          ),
          backgroundColor: Color(0xFFE30613),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Parse manual JSON input and navigate

  /// Build API token section
  Widget _buildApiTokenSection() {
    final hasToken = _currentApiToken != null && _currentApiToken!.isNotEmpty;
    final maskedToken = hasToken
        ? '${_currentApiToken!.substring(0, 8)}${'*' * (_currentApiToken!.length - 12)}${_currentApiToken!.substring(_currentApiToken!.length - 4)}'
        : null;

    return Container(
      margin: EdgeInsets.only(bottom: 32),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasToken
              ? Color(0xFF2E7D32).withOpacity(0.3)
              : Color(0xFFFF8F00).withOpacity(0.3),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasToken ? Icons.verified_user : Icons.key,
                color: hasToken ? Color(0xFF2E7D32) : Color(0xFFFF8F00),
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasToken
                      ? 'API-Token konfiguriert'
                      : 'API-Token erforderlich',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: hasToken ? Color(0xFF2E7D32) : Color(0xFFFF8F00),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (hasToken) ...[
            // Show current token info
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF2E7D32).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFF2E7D32).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Token aktiv:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          maskedToken!,
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'monospace',
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),

            // Action buttons for existing token
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _refreshFromAPI,
                    icon: _isLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white)))
                        : Icon(Icons.refresh, size: 18),
                    label: Text(_isLoading ? 'Lädt...' : 'Daten laden'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showTokenDialog(isEdit: true),
                  icon: Icon(Icons.edit, size: 18),
                  label: Text('Bearbeiten'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF8F00),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showRemoveTokenDialog(),
                  icon: Icon(Icons.delete_outline, color: Colors.red[600]),
                  tooltip: 'Token entfernen',
                ),
              ],
            ),
          ] else ...[
            // Show token input prompt
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFFFF8F00).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFFFF8F00).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFFF8F00), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Gib deinen API-Token ein, um automatisch Dienstpläne zu laden',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFFF8F00),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),

            // Add token button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showTokenDialog(),
                icon: Icon(Icons.add, size: 20),
                label: Text(
                  'API-Token eingeben',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF8F00),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Show remove token confirmation dialog
  void _showRemoveTokenDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[600]),
            SizedBox(width: 8),
            Text('Token entfernen'),
          ],
        ),
        content: Text(
            'Möchstest du den API-Token wirklich entfernen? Du kannst danach keine automatischen Dienstplan-Updates mehr laden.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearApiToken();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: Text('Entfernen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen during initialization
    if (_isInitializing) {
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
              stops: [0.0, 0.4],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.flight,
                    size: 40,
                    color: Color(0xFFE30613),
                  ),
                ),
                SizedBox(height: 24),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                SizedBox(height: 16),
                Text(
                  'Dienstplan wird geladen...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
                  SizedBox(height: 20),
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
                          'Ground Roster System',
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

                  // API Token Section
                  _buildApiTokenSection(),

                  // Manual input section
                  Text(
                    'Manuell eingeben',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Alternativ kannst du die JSON-Daten direkt eingeben',
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
                      child: Column(
                        children: [
                          // Clipboard paste button
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(0xFFE30613).withOpacity(0.05),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(14),
                                topRight: Radius.circular(14),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.content_paste,
                                  size: 16,
                                  color: Color(0xFFE30613),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'JSON-Daten:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFE30613),
                                  ),
                                ),
                                Spacer(),
                                InkWell(
                                  onTap: _pasteFromClipboard,
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFE30613),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.content_paste,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Einfügen',
                                          style: TextStyle(
                                            fontSize: 11,
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
                          // Text input field
                          Expanded(
                            child: Padding(
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
                        ],
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
