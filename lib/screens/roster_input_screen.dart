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
  final TextEditingController _addressController = TextEditingController();
  bool _hasAddress = false;
  bool _isGeocodingLoading = false;
  String? _geocodingError;
  Map<String, double>? _coordinates; // {lat: double, lon: double}
  static const String _tomtomApiKey = 'dwCWaJkaAJk8CBe8UoyMpWGuhWzn4t9q';
  static const String _tomtomBaseUrl =
      'https://api.tomtom.com/search/2/geocode';

  // SharedPreferences keys
  static const String _rosterDataKey = 'saved_roster';
  static const String _apiTokenKey = 'api_token';
  bool _preventAutoNavigation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = ModalRoute.of(context);
      if (route != null && route.settings.arguments == 'prevent_auto_nav') {
        _preventAutoNavigation = true;
      }
    });
    _jsonController.addListener(_onTextChanged);
    _addressController.addListener(_onAddressChanged);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuart),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initializeRosterData();
  }

  @override
  void dispose() {
    _jsonController.removeListener(_onTextChanged);
    _jsonController.dispose();
    _animationController.dispose();
    _pulseController.dispose();
    _addressController.removeListener(_onAddressChanged);
    _addressController.dispose();

    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _jsonController.text.trim().isNotEmpty;
      _errorMessage = null;
    });
  }

  void _onAddressChanged() {
    setState(() {
      _hasAddress = _addressController.text.trim().isNotEmpty;
      _geocodingError = null;
      if (!_hasAddress) {
        _coordinates = null;
      }
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

      // Only auto-navigate if not explicitly prevented
      if (savedRosterData != null &&
          savedRosterData.isNotEmpty &&
          !_preventAutoNavigation) {
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

        await Future.delayed(const Duration(milliseconds: 500));

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

      // If we have saved data but prevented auto-nav, show it in the text field
      if (savedRosterData != null &&
          savedRosterData.isNotEmpty &&
          _preventAutoNavigation) {
        setState(() {
          _jsonController.text = savedRosterData;
          _hasText = true;
        });
      }

      if (apiToken != null && apiToken.isNotEmpty && !_preventAutoNavigation) {
        await _fetchRosterDataFromAPI();
      } else {
        setState(() {
          _isInitializing = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Fehler beim Laden der Daten: ${e.toString()}';
        _isInitializing = false;
      });
      _animationController.forward();
    }
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
          'Alle gespeicherten Daten (Dienstplan, API-Token, Adressen) werden dauerhaft gelöscht.',
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
      await prefs.remove(_rosterDataKey);
      await prefs.remove(_apiTokenKey);
      await prefs.remove('roster_start_date');
      await prefs.remove('roster_end_date');
      await prefs.remove('roster_lat');
      await prefs.remove('roster_lon');
      await prefs.remove('roster_address');

      setState(() {
        _jsonController.clear();
        _addressController.clear(); // if you added address input
        _hasText = false;
        _hasAddress = false; // if you added address input
        _errorMessage = null;
        _geocodingError = null; // if you added address input
        _currentApiToken = null;
        _coordinates = null; // if you added address input
        _preventAutoNavigation = false; // reset the flag
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.refresh, color: Colors.white),
              SizedBox(width: 12),
              Text('Alle Daten wurden zurückgesetzt'),
            ],
          ),
          backgroundColor: const Color(0xFF111827),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Zurücksetzen: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  Future<void> _fetchRosterDataFromAPI() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final apiToken = prefs.getString(_apiTokenKey);

      if (apiToken == null || apiToken.isEmpty) {
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

      final response = await http
          .get(
            Uri.parse(
              'https://austrian.plano-wfm.cloud/myplanoservice/api/monthjournal/data?start=$startDateStr&end=$endDateStr',
            ),
            headers: {
              'Authorization': 'Bearer $apiToken',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final rosterData = WorkRosterData.fromJson(jsonData);

        await _saveRosterData(response.body);
        await _saveDateRange(startDate, endDate);

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
          );
        }
      } else {
        throw Exception(
          'API returned status ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Fehler beim Laden der API-Daten: ${e.toString()}';
        _isLoading = false;
        _isInitializing = false;
      });
      _animationController.forward();
    }
  }

  Future<void> _geocodeAddress() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;

    setState(() {
      _isGeocodingLoading = true;
      _geocodingError = null;
    });

    try {
      final encodedAddress = Uri.encodeComponent(address);
      final url = '$_tomtomBaseUrl/$encodedAddress.json?key=$_tomtomApiKey';

      final response = await http
          .get(Uri.parse(url), headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final results = jsonData['results'] as List;

        if (results.isNotEmpty) {
          final position = results[0]['position'];
          setState(() {
            _coordinates = {
              'lat': position['lat'].toDouble(),
              'lon': position['lon'].toDouble(),
            };
            _isGeocodingLoading = false;
          });

          // Save coordinates to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setDouble('latitude', _coordinates!['lat']!);
          await prefs.setDouble('longitude', _coordinates!['lon']!);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✓ Adresse gefunden: ${_coordinates!['lat']!.toStringAsFixed(4)}, ${_coordinates!['lon']!.toStringAsFixed(4)}',
              ),
              backgroundColor: const Color(0xFF059669),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        } else {
          setState(() {
            _geocodingError = 'Keine Ergebnisse für diese Adresse gefunden';
            _isGeocodingLoading = false;
          });
        }
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _geocodingError = 'Fehler bei der Adresssuche: ${e.toString()}';
        _isGeocodingLoading = false;
      });
    }
  }

  (String, String) _getDateRange(DateTime now) {
    final String startDateStr;
    final String endDateStr;

    if (now.day < 15) {
      // 1st to 14th: Get current month's roster
      startDateStr = _formatDate(DateTime(now.year, now.month, 1));
      endDateStr = _formatDate(DateTime(now.year, now.month + 1, 1));
    } else {
      // 15th onwards: Get next month's roster
      startDateStr = _formatDate(DateTime(now.year, now.month + 1, 1));
      endDateStr = _formatDate(DateTime(now.year, now.month + 2, 1));
    }

    return (startDateStr, endDateStr);
  }

  Future<void> _saveDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('roster_start_date', startDate.toIso8601String());
      await prefs.setString('roster_end_date', endDate.toIso8601String());
    } catch (e) {}
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
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Ungültiges JSON-Format: ${e.toString()}';
      });
    }
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
          content: const Text('✓ API-Token erfolgreich gespeichert'),
          backgroundColor: const Color(0xFF111827),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
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
    } catch (e) {
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
          content: const Text('API-Token entfernt'),
          backgroundColor: const Color(0xFF111827),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {}
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _saveRosterData(String jsonData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_rosterDataKey, jsonData);

      // Save coordinates if available
      if (_coordinates != null) {
        await prefs.setDouble('roster_lat', _coordinates!['lat']!);
        await prefs.setDouble('roster_lon', _coordinates!['lon']!);
        await prefs.setString('roster_address', _addressController.text.trim());
      }
    } catch (e) {
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
          content: const Text('Daten gelöscht'),
          backgroundColor: const Color(0xFF111827),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Löschen: $e'),
          backgroundColor: const Color(0xFFDC2626),
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
            content: const Text('✓ Eingefügt'),
            backgroundColor: const Color(0xFF111827),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Zwischenablage ist leer'),
            backgroundColor: const Color(0xFF111827),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Fehler beim Einfügen'),
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

  void _showRemoveTokenDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFAFAFA),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Token entfernen?',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'Der API-Token wird dauerhaft entfernt und automatische Updates sind nicht mehr möglich.',
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
              _clearApiToken();
            },
            child: const Text(
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
        backgroundColor: const Color(0xFFFAFAFA),
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
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.flight,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF111827)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
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
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Minimalist Header
                    Container(
                      margin: const EdgeInsets.only(bottom: 48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE30613),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Column(
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

                    const SizedBox(height: 48),
                    _buildAddressSection(),

                    const SizedBox(height: 48),

                    // Manual Input Section
                    const Text(
                      'Manuell eingeben',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'JSON-Daten direkt eingeben',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // JSON Input
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _hasText
                              ? const Color(0xFF111827)
                              : const Color(0xFFE5E7EB),
                          width: _hasText ? 2 : 1,
                        ),
                        boxShadow: [
                          if (_hasText)
                            BoxShadow(
                              color: const Color(0xFF111827).withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFAFAFA),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(15),
                                topRight: Radius.circular(15),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  'JSON',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                    letterSpacing: 1,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: _pasteFromClipboard,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF111827),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
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
                            padding: const EdgeInsets.all(20),
                            child: TextField(
                              controller: _jsonController,
                              maxLines: null,
                              expands: true,
                              decoration: const InputDecoration(
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
                              style: const TextStyle(
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
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFDC2626).withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Color(0xFFDC2626),
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
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

                    const SizedBox(height: 32),

                    // Action Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _hasText ? _parseAndNavigate : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _hasText
                              ? const Color(0xFF111827)
                              : const Color(0xFFE5E7EB),
                          foregroundColor: Colors.white,
                          elevation: _hasText ? 8 : 0,
                          shadowColor: _hasText
                              ? const Color(0xFF111827).withOpacity(0.3)
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
                            color: _hasText
                                ? Colors.white
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Reset button (only show if there's any saved data)
                    if (_currentApiToken != null || _hasText) ...[
                      Container(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _showResetDialog,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFDC2626)),
                            foregroundColor: const Color(0xFFDC2626),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.refresh, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Alle Daten zurücksetzen',
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

                    if (_hasText) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: _clearSavedData,
                          child: const Text(
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

                    const SizedBox(height: 40),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasToken ? const Color(0xFF059669) : const Color(0xFFE5E7EB),
          width: hasToken ? 2 : 1,
        ),
        boxShadow: [
          if (hasToken)
            BoxShadow(
              color: const Color(0xFF059669).withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
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
                  color: hasToken
                      ? const Color(0xFF059669)
                      : const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                hasToken ? 'API-Token aktiv' : 'API-Token',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const Spacer(),
              if (hasToken)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF059669),
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (hasToken) ...[
            // Active token display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aktueller Token:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF059669),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_currentApiToken!.substring(0, 8)}${'•' * 12}${_currentApiToken!.substring(_currentApiToken!.length - 4)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'monospace',
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Token actions
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _refreshFromAPI,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF111827),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Daten laden',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => _showTokenDialog(isEdit: true),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Bearbeiten',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 48,
                  width: 48,
                  child: IconButton(
                    onPressed: _showRemoveTokenDialog,
                    icon: const Icon(
                      Icons.delete_outline,
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
          ] else ...[
            // No token state
            const Text(
              'Automatische Dienstplan-Updates aktivieren',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => _showTokenDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF111827),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
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

  Widget _buildAddressSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _coordinates != null
              ? const Color(0xFF059669)
              : const Color(0xFFE5E7EB),
          width: _coordinates != null ? 2 : 1,
        ),
        boxShadow: [
          if (_coordinates != null)
            BoxShadow(
              color: const Color(0xFF059669).withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: Color(0xFF111827),
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text(
                'Standort (Optional)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const Spacer(),
              if (_coordinates != null)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF059669),
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Adresse eingeben für GPS-Koordinaten',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 20),

          // Address Input Field
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                hintText: 'z.B. Flughafen Wien, 1300 Schwechat',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
              onSubmitted: (_) => _geocodeAddress(),
            ),
          ),

          const SizedBox(height: 16),

          // Geocode Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _hasAddress && !_isGeocodingLoading
                  ? _geocodeAddress
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111827),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isGeocodingLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'GPS-Koordinaten ermitteln',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          // Display coordinates or error
          if (_coordinates != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GPS-Koordinaten:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF059669),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lat: ${_coordinates!['lat']!.toStringAsFixed(6)}\nLon: ${_coordinates!['lon']!.toStringAsFixed(6)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'monospace',
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (_geocodingError != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFDC2626).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFFDC2626),
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _geocodingError!,
                      style: const TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
