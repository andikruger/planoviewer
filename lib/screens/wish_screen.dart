// screens/shift_calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:planoviewer/models/calendar_model.dart';
import 'package:planoviewer/widgets/api_token_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../data/calendar_data.dart';
import '../utils/calendar_utils.dart';
import '../widgets/calendar_widgets.dart';

class ShiftCalendarScreen extends StatefulWidget {
  const ShiftCalendarScreen({Key? key}) : super(key: key);

  @override
  _ShiftCalendarScreenState createState() => _ShiftCalendarScreenState();
}

class _ShiftCalendarScreenState extends State<ShiftCalendarScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Store selected shifts and days off
  Map<String, SelectedShift> selectedShifts = {};
  Map<String, DayOff> daysOff = {};

  // Current date and target month (2 months ahead)
  late DateTime currentDate;
  late DateTime targetMonth;

  // Available shifts data
  late List<AvailableShift> availableShifts;

  // API token state
  String? _apiToken;
  bool _isLoading = true;
  bool _hasValidToken = false;

  // SharedPreferences key
  static const String _tokenKey = 'api_token';

  @override
  void initState() {
    super.initState();
    currentDate = DateTime.now();
    targetMonth = DateTime(currentDate.year, currentDate.month + 2, 1);
    availableShifts = CalendarData.getAvailableShifts();

    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Check for saved token on startup
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(_tokenKey);

      if (savedToken != null && savedToken.isNotEmpty) {
        // Set the token in ApiService
        ApiService.setToken(savedToken);

        setState(() {
          _apiToken = savedToken;
          _hasValidToken = true;
          _isLoading = false;
        });
        _animationController.forward();

        // Load existing shifts from API
        _loadExistingShifts();

        // Show welcome back message
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Willkommen zurück! API-Token geladen.'),
                ],
              ),
              backgroundColor: Color(0xFF2E7D32),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              duration: Duration(seconds: 2),
            ),
          );
        });
      } else {
        // No saved token, show token dialog
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showTokenDialog();
        });
      }
    } catch (e) {
      // Error loading preferences, show token dialog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTokenDialog();
      });
    }
  }

  Future<void> _loadExistingShifts() async {
    if (!ApiService.hasToken) {
      print('No API token available, skipping shift loading');
      return;
    }

    try {
      print(
          'Loading existing shifts for ${targetMonth.year}-${targetMonth.month}');

      // Get shifts from API
      final apiResponse = await ApiService.getShiftsForMonth(targetMonth);

      // Parse the year calendar response
      final parsedShifts =
          ApiService.parseYearCalendarShiftsResponse(apiResponse, targetMonth);

      if (parsedShifts.isNotEmpty) {
        // Update local state
        setState(() {
          selectedShifts.addAll(parsedShifts);
        });

        print('Loaded ${parsedShifts.length} existing shifts from API');

        // Show success message
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.cloud_download, color: Colors.white),
                SizedBox(width: 12),
                Text('${parsedShifts.length} Schichten geladen'),
              ],
            ),
            backgroundColor: Colors.blue[600],
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        print('No existing shifts found for this month');
      }
    } catch (e) {
      print('Error loading existing shifts: $e');

      // Show error message to user
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                    'Fehler beim Laden existierender Schichten: ${e.toString()}'),
              ),
            ],
          ),
          backgroundColor: Colors.orange[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _saveTokenToPreferences(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);

      // Set token in API service
      ApiService.setToken(token);
    } catch (e) {
      // Handle error - show message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 12),
              Text('Warnung: Token konnte nicht gespeichert werden'),
            ],
          ),
          backgroundColor: Colors.orange[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _clearTokenFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);

      // Clear token from API service
      ApiService.clearToken();
    } catch (e) {
      // Handle error silently for clearing
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _showTokenDialog() async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return TokenInputDialog(
          onTokenSubmitted: () {
            // This callback is called when validation starts
          },
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      // Token was provided
      setState(() {
        _apiToken = result;
        _hasValidToken = true;
        _isLoading = false;
      });

      // Save token to shared preferences
      await _saveTokenToPreferences(result);

      _animationController.forward();

      // Load existing shifts from API after token is set
      _loadExistingShifts();

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
    } else {
      // User cancelled or no token provided
      Navigator.of(context).pop();
    }
  }

  void _showTokenInfoDialog() {
    String maskedToken = _apiToken != null
        ? '${_apiToken!.substring(0, 8)}${'*' * (_apiToken!.length - 12)}${_apiToken!.substring(_apiToken!.length - 4)}'
        : 'Kein Token';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info, color: Color(0xFFE30613)),
            SizedBox(width: 8),
            Text('API-Token Information'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aktueller Token:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                maskedToken,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Token ist gültig und gespeichert',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Schließen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _changeApiToken();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE30613),
              foregroundColor: Colors.white,
            ),
            child: Text('Token ändern'),
          ),
        ],
      ),
    );
  }

  void _logoutAndClearToken() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red[600]),
            SizedBox(width: 8),
            Text('Abmelden'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Möchstest du dich wirklich abmelden?'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning, color: Colors.orange[600], size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dies wird:',
                          style: TextStyle(
                            color: Colors.orange[800],
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '• Den gespeicherten API-Token löschen\n• Alle geplanten Schichten entfernen\n• Dich zur Token-Eingabe zurückführen',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: Text('Abmelden'),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
    // Clear all data
    setState(() {
      selectedShifts.clear();
      daysOff.clear();
      _hasValidToken = false;
      _isLoading = true;
      _apiToken = null;
    });

    // Clear token from shared preferences
    await _clearTokenFromPreferences();

    // Show logout success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Erfolgreich abgemeldet'),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: Duration(seconds: 2),
      ),
    );

    // Show token dialog again after a short delay
    Future.delayed(Duration(milliseconds: 500), () {
      _showTokenDialog();
    });
  }

  void _changeApiToken() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[600]),
            SizedBox(width: 8),
            Text('API-Token ändern'),
          ],
        ),
        content: Text(
          'Möchtest du wirklich einen neuen API-Token eingeben? Dies wird alle aktuellen Daten zurücksetzen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetAndShowTokenDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE30613),
              foregroundColor: Colors.white,
            ),
            child: Text('Token ändern'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetAndShowTokenDialog() async {
    // Clear current data
    setState(() {
      selectedShifts.clear();
      daysOff.clear();
      _hasValidToken = false;
      _isLoading = true;
      _apiToken = null;
    });

    // Clear token from shared preferences
    await _clearTokenFromPreferences();

    // Show token dialog again
    await _showTokenDialog();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || !_hasValidToken) {
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
                    Icons.calendar_month,
                    size: 40,
                    color: Color(0xFFE30613),
                  ),
                ),
                SizedBox(height: 24),
                if (_isLoading) ...[
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Initialisierung...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
              Color(0xFFE30613),
              Colors.white,
            ],
            stops: [0.0, 0.25],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildHeader(),
                _buildQuickStats(),
                SizedBox(height: 20),
                _buildCalendarContainer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
                    Icon(Icons.calendar_month, color: Colors.white, size: 24),
                    SizedBox(width: 8),
                    Text(
                      '${CalendarUtils.getMonthName(targetMonth.month).toUpperCase()} ${targetMonth.year}',
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
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  switch (value) {
                    case 'summary':
                      _showSummaryDialog();
                      break;
                    case 'view_token':
                      _showTokenInfoDialog();
                      break;
                    case 'change_token':
                      _changeApiToken();
                      break;
                    case 'logout':
                      _logoutAndClearToken();
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'summary',
                    child: Row(
                      children: [
                        Icon(Icons.list_alt, color: Colors.grey[700]),
                        SizedBox(width: 12),
                        Text('Übersicht'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'view_token',
                    child: Row(
                      children: [
                        Icon(Icons.visibility, color: Colors.grey[700]),
                        SizedBox(width: 12),
                        Text('Token anzeigen'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'change_token',
                    child: Row(
                      children: [
                        Icon(Icons.key, color: Colors.grey[700]),
                        SizedBox(width: 12),
                        Text('Token ändern'),
                      ],
                    ),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red[600]),
                        SizedBox(width: 12),
                        Text(
                          'Abmelden',
                          style: TextStyle(color: Colors.red[600]),
                        ),
                      ],
                    ),
                  ),
                ],
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
    );
  }

  Widget _buildQuickStats() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          QuickStatWidget(
            label: 'Gesamt Stunden',
            value: '${CalendarUtils.calculateTotalHours(selectedShifts)}h',
            color: Color(0xFFFF8F00),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarContainer() {
    return Expanded(
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
            _buildCalendarHeader(),
            SizedBox(height: 16),
            _buildCalendarGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So']
            .map((day) => Container(
                  width: 40,
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: (day == 'Sa' || day == 'So')
                          ? Color(0xFFFF8F00)
                          : Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: _buildCalendarDays(),
      ),
    );
  }

  Widget _buildCalendarDays() {
    final firstDayOfMonth = DateTime(targetMonth.year, targetMonth.month, 1);
    final lastDayOfMonth = DateTime(targetMonth.year, targetMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday =
        firstDayOfMonth.weekday - 1; // Convert to 0-6 (Mon-Sun)

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.8,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: 42, // 6 weeks max
      itemBuilder: (context, index) {
        if (index < firstWeekday || index >= firstWeekday + daysInMonth) {
          return Container(); // Empty cell
        }

        final dayNumber = index - firstWeekday + 1;
        final date = DateTime(targetMonth.year, targetMonth.month, dayNumber);
        final dateKey = CalendarUtils.formatDateKey(date);
        final selectedShift = selectedShifts[dateKey];
        final dayOff = daysOff[dateKey];
        final isWeekend = date.weekday >= 6;
        final isPastDate =
            date.isBefore(DateTime.now().subtract(Duration(days: 1)));

        return CalendarDayWidget(
          dayNumber: dayNumber,
          date: date,
          selectedShift: selectedShift,
          dayOff: dayOff,
          isWeekend: isWeekend,
          isPastDate: isPastDate,
          onTap: () => _showDayOptionsDialog(date),
          onLongPress: () => _quickRemoveDay(date),
        );
      },
    );
  }

  // Dialog methods
  void _showDayOptionsDialog(DateTime selectedDate) {
    final dateKey = CalendarUtils.formatDateKey(selectedDate);
    final currentShift = selectedShifts[dateKey];
    final currentDayOff = daysOff[dateKey];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogHeader('Tag planen', selectedDate, Icons.event),
                _buildDayOptionsContent(
                    selectedDate, currentShift, currentDayOff),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogHeader(String title, DateTime date, IconData icon) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFE30613),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  CalendarUtils.formatDisplayDate(date),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildDayOptionsContent(DateTime selectedDate,
      SelectedShift? currentShift, DayOff? currentDayOff) {
    final dateKey = CalendarUtils.formatDateKey(selectedDate);

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Current status
          if (currentShift != null || currentDayOff != null)
            _buildCurrentStatusWidget(currentShift, currentDayOff),

          // Options
          DayOptionTile(
            icon: Icons.work,
            iconColor: Color(0xFFE30613),
            title: 'Schicht planen',
            subtitle: 'Arbeitszeit für diesen Tag festlegen',
            onTap: () {
              Navigator.of(context).pop();
              _showShiftSelectionDialog(selectedDate);
            },
          ),
          SizedBox(height: 8),
          DayOptionTile(
            icon: Icons.event_busy,
            iconColor: Color(0xFF2E7D32),
            title: 'Ganzer Tag frei',
            subtitle: 'Tag als komplett frei markieren',
            onTap: () {
              setState(() {
                selectedShifts.remove(dateKey);
                daysOff[dateKey] = DayOff(date: selectedDate, isFullDay: true);
              });
              Navigator.of(context).pop();
            },
          ),
          SizedBox(height: 8),
          DayOptionTile(
            icon: Icons.schedule,
            iconColor: Color(0xFFFF8F00),
            title: 'Teilweise frei',
            subtitle: 'Bestimmte Stunden als frei markieren',
            onTap: () {
              Navigator.of(context).pop();
              _showPartialDayOffDialog(selectedDate);
            },
          ),

          // Clear option - NOW WITH PROPER API REMOVAL
          if (currentShift != null || currentDayOff != null) ...[
            SizedBox(height: 8),
            Divider(),
            SizedBox(height: 8),
            DayOptionTile(
              icon: Icons.clear,
              iconColor: Colors.grey[600]!,
              title: 'Planung entfernen',
              subtitle: 'Alle Einstellungen für diesen Tag löschen',
              onTap: () =>
                  _handleRemoveEntry(dateKey, currentShift, currentDayOff),
            ),
          ],
        ],
      ),
    );
  }

// Add this new method to handle proper removal with API calls
  void _handleRemoveEntry(
      String dateKey, SelectedShift? shift, DayOff? dayOff) async {
    print('=== HANDLE REMOVE ENTRY ===');
    print('DateKey: $dateKey');
    print('Shift: ${shift?.toString()}');
    print('DayOff: ${dayOff?.toString()}');

    // Close the current dialog first
    Navigator.of(context).pop();

    // If there's a shift with instanceId, we need to call the API
    if (shift != null && shift.instanceId != null) {
      print('Shift has instanceId, calling API removal...');

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Schicht wird entfernt...'),
            ],
          ),
          backgroundColor: Colors.red[600],
          duration: Duration(seconds: 10),
        ),
      );

      try {
        // Remove from API
        final success =
            await ApiService.removeEntry(dateKey, shift.instanceId!);

        if (success) {
          // Remove from local state
          setState(() {
            selectedShifts.remove(dateKey);
            daysOff.remove(dateKey);
          });

          // Show success message
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Planung erfolgreich entfernt'),
                ],
              ),
              backgroundColor: Color(0xFF2E7D32),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          );
        } else {
          throw Exception('API returned false');
        }
      } catch (e) {
        print('Error during removal: $e');

        // Hide loading snackbar and show error
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Fehler beim Entfernen: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } else {
      // No API call needed, just remove locally
      print('No instanceId, removing locally only');

      setState(() {
        selectedShifts.remove(dateKey);
        daysOff.remove(dateKey);
      });

      // Show info message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info, color: Colors.white),
              SizedBox(width: 12),
              Text('Planung entfernt'),
            ],
          ),
          backgroundColor: Colors.blue[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Widget _buildCurrentStatusWidget(
      SelectedShift? currentShift, DayOff? currentDayOff) {
    String statusText = currentShift != null
        ? 'Aktuell: Schicht ${currentShift.timeRange}'
        : currentDayOff!.isFullDay
            ? 'Aktuell: Ganzer Tag frei'
            : 'Aktuell: Teilweise frei ${currentDayOff.timeRange}';

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: Colors.blue[600]),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                color: Colors.blue[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showShiftSelectionDialog(DateTime selectedDate) {
    final dateKey = CalendarUtils.formatDateKey(selectedDate);
    final currentSelection = selectedShifts[dateKey];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogHeader(
                    'Schicht auswählen', selectedDate, Icons.schedule),
                _buildShiftSelectionContent(selectedDate, currentSelection),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShiftSelectionContent(
      DateTime selectedDate, SelectedShift? currentSelection) {
    final dateKey = CalendarUtils.formatDateKey(selectedDate);

    return Flexible(
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Clear selection option
            _buildClearShiftOption(dateKey, currentSelection),

            // Divider if there's a current selection
            if (currentSelection != null) ...[
              Divider(color: Colors.grey[300]),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Verfügbare Schichten',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],

            // Available shifts
            Expanded(
              child: ListView.builder(
                itemCount: availableShifts.length,
                itemBuilder: (context, index) {
                  final shift = availableShifts[index];
                  final isSelected = currentSelection?.id == shift.id;
                  final shiftType = CalendarUtils.getShiftType(shift.timeRange);

                  return _buildShiftListItem(
                      shift, isSelected, shiftType, selectedDate, dateKey);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClearShiftOption(
      String dateKey, SelectedShift? currentSelection) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              currentSelection != null ? Colors.red[100] : Colors.grey[200],
          child: Icon(Icons.clear,
              color: currentSelection != null
                  ? Colors.red[700]
                  : Colors.grey[500]),
        ),
        title: Text(
          'Keine Schicht',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: currentSelection != null ? Colors.black87 : Colors.grey[500],
          ),
        ),
        subtitle: Text(
          currentSelection != null
              ? 'Aktuelle Auswahl entfernen'
              : 'Kein Dienst an diesem Tag',
          style: TextStyle(
            color:
                currentSelection != null ? Colors.red[600] : Colors.grey[400],
          ),
        ),
        trailing: currentSelection != null
            ? Icon(Icons.remove_circle, color: Colors.red[600])
            : null,
        onTap: () async {
          if (currentSelection != null) {
            // Check if we have an instanceId (shift was saved to API)
            if (currentSelection.instanceId != null) {
              // Show loading indicator for API removal
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Schicht wird entfernt...'),
                    ],
                  ),
                  backgroundColor: Colors.red[600],
                  duration: Duration(seconds: 10),
                ),
              );

              try {
                print(
                    'Removing shift with instance ID: ${currentSelection.instanceId}');
                // Remove from API
                final success = await ApiService.removeEntry(
                    dateKey, currentSelection.instanceId!);

                if (success) {
                  // Remove from local state
                  setState(() {
                    selectedShifts.remove(dateKey);
                  });

                  Navigator.of(context).pop();

                  // Show success message
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Text('Schicht erfolgreich entfernt'),
                        ],
                      ),
                      backgroundColor: Color(0xFF2E7D32),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                } else {
                  throw Exception('API returned false');
                }
              } catch (e) {
                // Hide loading snackbar and show error
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.error, color: Colors.white),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text('Fehler beim Entfernen: ${e.toString()}'),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.red[600],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    duration: Duration(seconds: 4),
                  ),
                );
              }
            } else {
              // No instanceId - this is a local-only shift, just remove it locally
              print('Removing local shift (no instanceId)');
              setState(() {
                selectedShifts.remove(dateKey);
              });
              Navigator.of(context).pop();

              // Show info message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.info, color: Colors.white),
                      SizedBox(width: 12),
                      Text('Schicht lokal entfernt'),
                    ],
                  ),
                  backgroundColor: Colors.blue[600],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              );
            }
          } else {
            // No selection, just close dialog
            Navigator.of(context).pop();
          }
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color:
                currentSelection != null ? Colors.red[300]! : Colors.grey[300]!,
            width: currentSelection != null ? 2 : 1,
          ),
        ),
        tileColor: currentSelection != null ? Colors.red[50] : null,
      ),
    );
  }

  Widget _buildShiftListItem(AvailableShift shift, bool isSelected,
      ShiftType shiftType, DateTime selectedDate, String dateKey) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSelected
              ? Color(0xFFE30613)
              : CalendarUtils.getShiftTypeColor(shiftType).withOpacity(0.2),
          child: Icon(
            CalendarUtils.getShiftTypeIcon(shiftType),
            color: isSelected
                ? Colors.white
                : CalendarUtils.getShiftTypeColor(shiftType),
          ),
        ),
        title: Text(
          shift.timeRange,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Color(0xFFE30613) : Colors.black87,
          ),
        ),
        subtitle: Text(
          '${CalendarUtils.getShiftTypeName(shiftType)} • ${CalendarUtils.calculateDuration(shift.timeRange)}',
          style: TextStyle(
            color: isSelected
                ? Color(0xFFE30613).withOpacity(0.7)
                : Colors.grey[600],
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: Color(0xFFE30613))
            : null,
        onTap: () async {
          // Show loading indicator
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Schicht wird gespeichert...'),
                ],
              ),
              backgroundColor: Color(0xFFE30613),
              duration: Duration(seconds: 2),
            ),
          );

          try {
            // Save to API and get instanceId
            final instanceId = await ApiService.saveShift(dateKey, shift.id);

            if (instanceId != null) {
              // Update local state with instanceId
              setState(() {
                selectedShifts[dateKey] = SelectedShift(
                  id: shift.id,
                  timeRange: shift.timeRange,
                  date: selectedDate,
                  instanceId: instanceId, // Store the instanceId
                );
              });

              Navigator.of(context).pop();

              // Show success message
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 12),
                      Text('Schicht erfolgreich gespeichert'),
                    ],
                  ),
                  backgroundColor: Color(0xFF2E7D32),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              );
            } else {
              throw Exception('No instanceId returned from API');
            }
          } catch (e) {
            // Hide loading snackbar and show error
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.error, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('Fehler beim Speichern: ${e.toString()}'),
                    ),
                  ],
                ),
                backgroundColor: Colors.red[600],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                duration: Duration(seconds: 4),
              ),
            );
          }
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected ? Color(0xFFE30613) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        tileColor: isSelected ? Color(0xFFE30613).withOpacity(0.05) : null,
      ),
    );
  }

  void _showPartialDayOffDialog(DateTime selectedDate) {
    TimeOfDay startTime = TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = TimeOfDay(hour: 17, minute: 0);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPartialDayOffHeader(selectedDate),
                    _buildPartialDayOffContent(
                        selectedDate, startTime, endTime, setDialogState),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPartialDayOffHeader(DateTime selectedDate) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFFF8F00),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: Colors.white),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Teilweise frei',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  CalendarUtils.formatDisplayDate(selectedDate),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildPartialDayOffContent(DateTime selectedDate, TimeOfDay startTime,
      TimeOfDay endTime, StateSetter setDialogState) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Wähle die Zeit in der du frei haben willst:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),

          // Time selection widgets
          _buildTimeSelector('Von', startTime, Icons.play_arrow, () async {
            final time = await showTimePicker(
              context: context,
              initialTime: startTime,
            );
            if (time != null) {
              setDialogState(() {
                startTime = time;
              });
            }
          }),

          SizedBox(height: 12),

          _buildTimeSelector('Bis', endTime, Icons.stop, () async {
            final time = await showTimePicker(
              context: context,
              initialTime: endTime,
            );
            if (time != null) {
              setDialogState(() {
                endTime = time;
              });
            }
          }),

          SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Abbrechen'),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      _savePartialDayOff(selectedDate, startTime, endTime),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF8F00),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Speichern'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector(
      String label, TimeOfDay time, IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: Color(0xFFFF8F00)),
        title: Text(label),
        trailing: Text(
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF8F00),
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  void _savePartialDayOff(
      DateTime selectedDate, TimeOfDay startTime, TimeOfDay endTime) {
    final dateKey = CalendarUtils.formatDateKey(selectedDate);
    final timeRange =
        '${startTime.hour.toString().padLeft(2, '0')}${startTime.minute.toString().padLeft(2, '0')}-${endTime.hour.toString().padLeft(2, '0')}${endTime.minute.toString().padLeft(2, '0')}';

    setState(() {
      selectedShifts.remove(dateKey);
      daysOff[dateKey] = DayOff(
        date: selectedDate,
        isFullDay: false,
        timeRange: timeRange,
      );
    });
    Navigator.of(context).pop();
  }

  void _quickRemoveDay(DateTime date) {
    final dateKey = CalendarUtils.formatDateKey(date);
    final shift = selectedShifts[dateKey];
    final dayOff = daysOff[dateKey];

    if (shift == null && dayOff == null) return;

    String itemType = shift != null ? 'Schicht' : 'Freizeiteintrag';
    String itemDetails = shift != null
        ? shift.timeRange
        : dayOff!.isFullDay
            ? 'Ganzer Tag frei'
            : 'Teilweise frei ${dayOff.timeRange}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red[600]),
            SizedBox(width: 8),
            Text('$itemType entfernen'),
          ],
        ),
        content: _buildRemovalContent(date, itemDetails, shift != null),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => _confirmRemoval(dateKey, shift, dayOff, itemType),
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

  Widget _buildRemovalContent(DateTime date, String itemDetails, bool isShift) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            'Willst du  ${isShift ? ' die Schicht' : 'den Freizeiteintrag'} wirklich entfernen?'),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(isShift ? Icons.work : Icons.event_busy,
                  size: 20,
                  color: isShift ? Color(0xFFE30613) : Color(0xFF2E7D32)),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CalendarUtils.formatDisplayDate(date),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      itemDetails,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmRemoval(
      String dateKey, SelectedShift? shift, DayOff? dayOff, String itemType) {
    setState(() {
      selectedShifts.remove(dateKey);
      daysOff.remove(dateKey);
    });
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$itemType entfernt'),
        backgroundColor: Colors.red[600],
        action: SnackBarAction(
          label: 'Rückgängig',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              if (shift != null) {
                selectedShifts[dateKey] = shift;
              }
              if (dayOff != null) {
                daysOff[dateKey] = dayOff;
              }
            });
          },
        ),
      ),
    );
  }

  void _showSummaryDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSummaryHeader(),
              _buildSummaryContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFE30613),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.list_alt, color: Colors.white),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Übersicht',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryContent() {
    return Flexible(
      child: (selectedShifts.isEmpty && daysOff.isEmpty)
          ? _buildEmptySummary()
          : _buildSummaryList(),
    );
  }

  Widget _buildEmptySummary() {
    return Container(
      padding: EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule_outlined, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'Keine Planungen vorhanden',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: selectedShifts.length + daysOff.length,
      itemBuilder: (context, index) {
        if (index < selectedShifts.length) {
          return _buildShiftSummaryItem(index);
        } else {
          return _buildDayOffSummaryItem(index - selectedShifts.length);
        }
      },
    );
  }

  Widget _buildShiftSummaryItem(int index) {
    final entry = selectedShifts.entries.elementAt(index);
    final shift = entry.value;
    final dateKey = entry.key;
    final shiftType = CalendarUtils.getShiftType(shift.timeRange);

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              CalendarUtils.getShiftTypeColor(shiftType).withOpacity(0.2),
          child: Icon(
            CalendarUtils.getShiftTypeIcon(shiftType),
            color: CalendarUtils.getShiftTypeColor(shiftType),
          ),
        ),
        title: Text(
          CalendarUtils.formatDisplayDate(shift.date),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${shift.timeRange} • ${CalendarUtils.getShiftTypeName(shiftType)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              CalendarUtils.calculateDuration(shift.timeRange),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFE30613),
              ),
            ),
            SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red[600]),
              onPressed: () => _removeSummaryItem(dateKey, shift: shift),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey[300]!),
        ),
      ),
    );
  }

  Widget _buildDayOffSummaryItem(int dayOffIndex) {
    final entry = daysOff.entries.elementAt(dayOffIndex);
    final dayOff = entry.value;
    final dateKey = entry.key;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: dayOff.isFullDay
              ? Color(0xFF2E7D32).withOpacity(0.2)
              : Color(0xFFFF8F00).withOpacity(0.2),
          child: Icon(
            dayOff.isFullDay ? Icons.event_busy : Icons.schedule,
            color: dayOff.isFullDay ? Color(0xFF2E7D32) : Color(0xFFFF8F00),
          ),
        ),
        title: Text(
          CalendarUtils.formatDisplayDate(dayOff.date),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          dayOff.isFullDay
              ? 'Ganzer Tag frei'
              : 'Teilweise frei ${dayOff.timeRange}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!dayOff.isFullDay)
              Text(
                CalendarUtils.calculateDuration(dayOff.timeRange!),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF8F00),
                ),
              ),
            SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red[600]),
              onPressed: () => _removeSummaryItem(dateKey, dayOff: dayOff),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey[300]!),
        ),
      ),
    );
  }

  void _removeSummaryItem(String dateKey,
      {SelectedShift? shift, DayOff? dayOff}) {
    final itemType = shift != null ? 'Schicht' : 'Freizeiteintrag';

    setState(() {
      if (shift != null) {
        selectedShifts.remove(dateKey);
      }
      if (dayOff != null) {
        daysOff.remove(dateKey);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$itemType entfernt'),
        backgroundColor: Colors.red[600],
        action: SnackBarAction(
          label: 'Rückgängig',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              if (shift != null) {
                selectedShifts[dateKey] = shift;
              }
              if (dayOff != null) {
                daysOff[dateKey] = dayOff;
              }
            });
          },
        ),
      ),
    );
  }
}
