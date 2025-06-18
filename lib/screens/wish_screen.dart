// screens/shift_calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:planoviewer/models/calendar_model.dart';
import 'package:planoviewer/widgets/api_token_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../data/calendar_data.dart';
import '../utils/calendar_utils.dart';

import '../widgets/wish_calendar_widgets.dart';
import '../widgets/wish_calendar_dialog.dart';

class ShiftCalendarScreen extends StatefulWidget {
  const ShiftCalendarScreen({Key? key}) : super(key: key);

  @override
  _ShiftCalendarScreenState createState() => _ShiftCalendarScreenState();
}

class _ShiftCalendarScreenState extends State<ShiftCalendarScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _selectionController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

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
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _selectionController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuart,
      ),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
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
          _showSuccessSnackBar('Willkommen zurück! API-Token geladen.');
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
        _showInfoSnackBar('${parsedShifts.length} Schichten geladen');
      } else {
        print('No existing shifts found for this month');
      }
    } catch (e) {
      print('Error loading existing shifts: $e');

      // Show error message to user
      if (!mounted) return;
      _showWarningSnackBar(
          'Fehler beim Laden existierender Schichten: ${e.toString()}');
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
      _showWarningSnackBar('Warnung: Token konnte nicht gespeichert werden');
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
    _selectionController.dispose();
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
      _showSuccessSnackBar('API-Token erfolgreich gespeichert');
    } else {
      // User cancelled or no token provided
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || !_hasValidToken) {
      return Scaffold(
        backgroundColor: Color(0xFFFAFAFA),
        body: Center(
          child: Container(
            padding: EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.edit_calendar,
                    size: 40,
                    color: Color(0xFFE30613),
                  ),
                ),
                SizedBox(height: 24),
                if (_isLoading) ...[
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFE30613)),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Initialisierung...',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
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
      backgroundColor: Color(0xFFFAFAFA),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Modern Header
              ShiftCalendarHeader(
                targetMonth: targetMonth,
                onBackPressed: () => Navigator.pop(context),
                onMenuSelected: _handleMenuSelection,
              ),

              // Stats Overview
              ShiftCalendarStats(
                animation: _slideAnimation,
                selectedShifts: selectedShifts,
                daysOff: daysOff,
              ),

              // Calendar Section
              ShiftCalendarGrid(
                targetMonth: targetMonth,
                selectedShifts: selectedShifts,
                daysOff: daysOff,
                onDayTap: _showDayOptionsDialog,
                onDayLongPress: _quickRemoveDay,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMenuSelection(String value) {
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
  }

  // Dialog methods
  void _showDayOptionsDialog(DateTime selectedDate) {
    final dateKey = CalendarUtils.formatDateKey(selectedDate);
    final currentShift = selectedShifts[dateKey];
    final currentDayOff = daysOff[dateKey];

    ShiftCalendarDialogs.showDayOptionsDialog(
      context: context,
      selectedDate: selectedDate,
      currentShift: currentShift,
      currentDayOff: currentDayOff,
      onShiftSelected: () => _showShiftSelectionDialog(selectedDate),
      onFullDayOff: () => _setFullDayOff(selectedDate),
      onPartialDayOff: () => _showPartialDayOffDialog(selectedDate),
      onRemoveEntry: () =>
          _handleRemoveEntry(dateKey, currentShift, currentDayOff),
    );
  }

  void _showShiftSelectionDialog(DateTime selectedDate) {
    final dateKey = CalendarUtils.formatDateKey(selectedDate);
    final currentSelection = selectedShifts[dateKey];

    ShiftCalendarDialogs.showShiftSelectionDialog(
      context: context,
      selectedDate: selectedDate,
      availableShifts: availableShifts,
      currentSelection: currentSelection,
      onShiftSelected: (shift) => _saveShift(dateKey, selectedDate, shift),
      onClearShift: () => _clearShift(dateKey, currentSelection),
    );
  }

  void _showPartialDayOffDialog(DateTime selectedDate) {
    ShiftCalendarDialogs.showPartialDayOffDialog(
      context: context,
      selectedDate: selectedDate,
      onSave: (startTime, endTime) =>
          _savePartialDayOff(selectedDate, startTime, endTime),
    );
  }

  void _showSummaryDialog() {
    ShiftCalendarDialogs.showSummaryDialog(
      context: context,
      selectedShifts: selectedShifts,
      daysOff: daysOff,
      onRemoveItem: _removeSummaryItem,
    );
  }

  void _showTokenInfoDialog() {
    ShiftCalendarDialogs.showTokenInfoDialog(
      context: context,
      apiToken: _apiToken,
      onChangeToken: _changeApiToken,
    );
  }

  void _logoutAndClearToken() {
    ShiftCalendarDialogs.showLogoutDialog(
      context: context,
      onConfirm: _performLogout,
    );
  }

  void _changeApiToken() {
    ShiftCalendarDialogs.showChangeTokenDialog(
      context: context,
      onConfirm: _resetAndShowTokenDialog,
    );
  }

  // Action methods
  void _setFullDayOff(DateTime selectedDate) {
    final dateKey = CalendarUtils.formatDateKey(selectedDate);
    setState(() {
      selectedShifts.remove(dateKey);
      daysOff[dateKey] = DayOff(date: selectedDate, isFullDay: true);
    });
  }

  Future<void> _saveShift(
      String dateKey, DateTime selectedDate, AvailableShift shift) async {
    _showLoadingSnackBar('Schicht wird gespeichert...');

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
            instanceId: instanceId,
          );
        });

        _showSuccessSnackBar('Schicht erfolgreich gespeichert');
      } else {
        throw Exception('No instanceId returned from API');
      }
    } catch (e) {
      _showErrorSnackBar('Fehler beim Speichern: ${e.toString()}');
    }
  }

  Future<void> _clearShift(
      String dateKey, SelectedShift? currentSelection) async {
    if (currentSelection != null && currentSelection.instanceId != null) {
      _showLoadingSnackBar('Schicht wird entfernt...');

      try {
        final success =
            await ApiService.removeEntry(dateKey, currentSelection.instanceId!);
        if (success) {
          setState(() {
            selectedShifts.remove(dateKey);
          });
          _showSuccessSnackBar('Schicht erfolgreich entfernt');
        } else {
          throw Exception('API returned false');
        }
      } catch (e) {
        _showErrorSnackBar('Fehler beim Entfernen: ${e.toString()}');
      }
    } else {
      setState(() {
        selectedShifts.remove(dateKey);
      });
      _showInfoSnackBar('Schicht lokal entfernt');
    }
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
  }

  Future<void> _handleRemoveEntry(
      String dateKey, SelectedShift? shift, DayOff? dayOff) async {
    if (shift != null && shift.instanceId != null) {
      _showLoadingSnackBar('Schicht wird entfernt...');

      try {
        final success =
            await ApiService.removeEntry(dateKey, shift.instanceId!);
        if (success) {
          setState(() {
            selectedShifts.remove(dateKey);
            daysOff.remove(dateKey);
          });
          _showSuccessSnackBar('Planung erfolgreich entfernt');
        } else {
          throw Exception('API returned false');
        }
      } catch (e) {
        _showErrorSnackBar('Fehler beim Entfernen: ${e.toString()}');
      }
    } else {
      setState(() {
        selectedShifts.remove(dateKey);
        daysOff.remove(dateKey);
      });
      _showInfoSnackBar('Planung entfernt');
    }
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

    ShiftCalendarDialogs.showQuickRemoveDialog(
      context: context,
      date: date,
      itemType: itemType,
      itemDetails: itemDetails,
      isShift: shift != null,
      onConfirm: () => _confirmRemoval(dateKey, shift, dayOff, itemType),
    );
  }

  void _confirmRemoval(
      String dateKey, SelectedShift? shift, DayOff? dayOff, String itemType) {
    setState(() {
      selectedShifts.remove(dateKey);
      daysOff.remove(dateKey);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('$itemType entfernt'),
          ],
        ),
        backgroundColor: Color(0xFFE30613),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('$itemType entfernt'),
          ],
        ),
        backgroundColor: Color(0xFFE30613),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    _showSuccessSnackBar('Erfolgreich abgemeldet');

    // Show token dialog again after a short delay
    Future.delayed(Duration(milliseconds: 500), () {
      _showTokenDialog();
    });
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

  // SnackBar helper methods
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Color(0xFFE30613),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info, color: Colors.white),
            SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Color(0xFF6366F1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Color(0xFFF59E0B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _showLoadingSnackBar(String message) {
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
            Text(message),
          ],
        ),
        backgroundColor: Color(0xFFE30613),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 10),
      ),
    );
  }
}
