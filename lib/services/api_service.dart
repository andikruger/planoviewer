// services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:planoviewer/models/calendar_model.dart';
import 'package:uuid/uuid.dart';

class ApiService {
  static String? _apiToken;
  static const String _baseUrl =
      'https://austrian.plano-wfm.cloud/myplanoservice/api';
  static const String _configId =
      'ddc117e8-1971-4b9e-862b-ae3a46fd5327'; // Replace with actual config ID

  // UUID generator
  static const Uuid _uuid = Uuid();

  static String? get apiToken => _apiToken;
  static bool get hasToken => _apiToken != null && _apiToken!.isNotEmpty;

  static void setToken(String token) {
    _apiToken = token;
  }

  static void clearToken() {
    _apiToken = null;
  }

  /// Validates the API token by making a test request
  static Future<bool> validateToken(String token) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/validate'), // Replace with actual validation endpoint
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('Token validation error: $e');
      return false;
    }
  }

  /// Helper method to format date as YYYY-MM-DD
  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Saves a shift selection to the API and returns the instanceId
  static Future<String?> saveShift(String date, String shiftId) async {
    if (!hasToken) {
      throw Exception('No API token available');
    }

    try {
      // Parse the date string to DateTime
      DateTime startDate;
      if (date.contains('-') && date.length >= 8) {
        // Date is already in YYYY-MM-DD format
        startDate = DateTime.parse(date);
      } else {
        // Assume it's in some other format, try to parse
        startDate = DateTime.parse(date);
      }

      final endDate = startDate.add(Duration(days: 1));

      // Format dates as YYYY-MM-DD
      final formattedStartDate = _formatDate(startDate);
      final formattedEndDate = _formatDate(endDate);

      // Generate new UUID for this request
      final instanceId = _uuid.v4();

      // Build request body
      final requestBody = {
        "type": "UniformCollection",
        "items": [
          {
            "checkOnly": false,
            "configId": _configId,
            "ignoreWarnings": false,
            "instanceId": instanceId,
            "isUpdate": false,
            "periods": [
              {
                "start": formattedStartDate,
                "end": formattedEndDate,
                "ItemId": _uuid.v4(), // Generate UUID for ItemId
              }
            ],
            "workflowType": "ScheduleWorkflowInstance",
            "shifts": [
              {"shiftTypeId": shiftId, "intervals": []}
            ]
          }
        ],
        "itemType": "ScheduleRequest"
      };

      print('Sending shift request: ${json.encode(requestBody)}');

      final response = await http
          .post(
            Uri.parse(
                '$_baseUrl/workflow/schedule'), // Replace with actual endpoint
            headers: {
              'Authorization': 'Bearer $_apiToken',
              'Content-Type': 'application/json',
            },
            body: json.encode(requestBody),
          )
          .timeout(Duration(seconds: 30));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      // 204 indicates success (No Content)
      if (response.statusCode == 204) {
        // Return the instanceId that we generated for this request
        return instanceId;
      } else {
        return null;
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on HttpException {
      throw Exception('HTTP error occurred');
    } catch (e) {
      print('Error saving shift: $e');
      throw Exception('Failed to save shift: $e');
    }
  }

  /// Saves a day off to the API
  static Future<bool> saveDayOff(
      String date, bool isFullDay, String? timeRange) async {
    if (!hasToken) {
      throw Exception('No API token available');
    }

    // TODO: Implement day off API call
    print(
        'Day off request - Date: $date, Full Day: $isFullDay, Time Range: $timeRange');

    // Placeholder return for now
    return true;
  }

  /// Removes an entry (shift or day off) from the API
  static Future<bool> removeEntry(String date, String instanceId) async {
    if (!hasToken) {
      throw Exception('No API token available');
    }

    print('=== REMOVE ENTRY DEBUG INFO ===');
    print('Date: $date');
    print('InstanceId: $instanceId');
    print('Token available: ${hasToken}');
    print('Base URL: $_baseUrl');

    try {
      // Build request body for withdrawal
      final requestBody = {
        "meta": {},
        "links": {},
        "type": "WorkflowActions",
        "data": {
          "actions": [
            {"actionType": "Withdraw", "instanceId": instanceId}
          ],
          "checkOnly": false,
          "ignoreWarnings": false
        }
      };

      print('Request body: ${json.encode(requestBody)}');
      print('Full URL: $_baseUrl/workflow/actions');

      final response = await http
          .post(
            Uri.parse('$_baseUrl/workflow/actions'),
            headers: {
              'Authorization': 'Bearer $_apiToken',
              'Content-Type': 'application/json',
            },
            body: json.encode(requestBody),
          )
          .timeout(Duration(seconds: 30));

      print('Withdrawal response status: ${response.statusCode}');
      print('Withdrawal response headers: ${response.headers}');
      print('Withdrawal response body: ${response.body}');

      // 204 indicates success (No Content)
      final success = response.statusCode == 204;
      print('Withdrawal success: $success');

      return success;
    } on SocketException catch (e) {
      print('Socket exception during removal: $e');
      throw Exception('No internet connection');
    } on HttpException catch (e) {
      print('HTTP exception during removal: $e');
      throw Exception('HTTP error occurred');
    } catch (e) {
      print('General error removing entry: $e');
      print('Error type: ${e.runtimeType}');
      throw Exception('Failed to remove entry: $e');
    }
  }

  /// Gets shifts for a specific month from the API
  static Future<Map<String, dynamic>> getShiftsForMonth(DateTime month) async {
    if (!hasToken) {
      throw Exception('No API token available');
    }

    try {
      // Calculate start and end dates for the month
      final startDate = DateTime(month.year, month.month, 1);
      final endDate = DateTime(month.year, month.month + 1, 1);

      // Format dates as YYYY-MM-DD
      final formattedStartDate = _formatDate(startDate);
      final formattedEndDate = _formatDate(endDate);

      print(
          'Fetching shifts for period: $formattedStartDate to $formattedEndDate');

      final response = await http.get(
        Uri.parse(
            '$_baseUrl/yearcalendar/shifts?start=$formattedStartDate&end=$formattedEndDate'),
        headers: {
          'Authorization': 'Bearer $_apiToken',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 30));

      print('Get shifts response status: ${response.statusCode}');
      print('Get shifts response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to load shifts: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on HttpException {
      throw Exception('HTTP error occurred');
    } catch (e) {
      print('Error getting shifts for month: $e');
      throw Exception('Failed to get shifts: $e');
    }
  }

  /// Parses API shift data into SelectedShift objects
  static Map<String, SelectedShift> parseYearCalendarShiftsResponse(
      Map<String, dynamic> apiResponse, DateTime targetMonth) {
    Map<String, SelectedShift> selectedShifts = {};

    try {
      // Extract the data section
      final data = apiResponse['data'];
      if (data == null) {
        print('No data section found in API response');
        return selectedShifts;
      }

      // Get shift information for lookup
      final shiftInfos = data['shiftInfos'] as Map<String, dynamic>? ?? {};

      // Get preference arrays (these contain the user's shift wishes)
      final preferences = data['preference'] as List<dynamic>? ?? [];

      // Get workflow arrays (these contain workflow info with instanceId)
      final workflows = data['workflow'] as List<dynamic>? ?? [];

      print(
          'Found ${preferences.length} preference days, ${workflows.length} workflow days');
      print('ShiftInfos available: ${shiftInfos.keys.toList()}');

      // Process each day of the month
      for (int dayIndex = 0; dayIndex < preferences.length; dayIndex++) {
        final dayNumber = dayIndex + 1; // Convert 0-based index to 1-based day
        final date = DateTime(targetMonth.year, targetMonth.month, dayNumber);
        final dateKey = _formatDate(date);

        // Check if this day exceeds the actual month length
        final daysInMonth =
            DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
        if (dayNumber > daysInMonth) {
          break; // Stop processing if we exceed the month
        }

        // Check preferences for this day
        final dayPreferences = preferences[dayIndex] as List<dynamic>? ?? [];
        final dayWorkflows = dayIndex < workflows.length
            ? workflows[dayIndex] as List<dynamic>? ?? []
            : <dynamic>[];

        if (dayPreferences.isNotEmpty) {
          // Process the first preference for this day
          final preference = dayPreferences[0] as Map<String, dynamic>;
          final shiftId = preference['shiftId'] as String?;

          if (shiftId != null) {
            // Look up shift information
            final shiftInfo = shiftInfos[shiftId] as Map<String, dynamic>?;
            final timeRange = shiftInfo?['name'] as String? ?? 'Unknown';

            // Look for corresponding workflow info to get instanceId
            String? instanceId;
            String? workflowState;

            for (var workflow in dayWorkflows) {
              final workflowData = workflow as Map<String, dynamic>;
              if (workflowData['shiftId'] == shiftId) {
                // Try different possible ID fields for withdrawal
                instanceId = workflowData['workflowId'] as String? ??
                    workflowData['instanceId'] as String? ??
                    workflowData['id'] as String?;
                workflowState = workflowData['state'] as String?;

                // Debug: Print all available fields
                print(
                    'Workflow data for $dateKey: ${workflowData.keys.toList()}');
                print('Available values: $workflowData');
                break;
              }
            }

            // Create SelectedShift
            selectedShifts[dateKey] = SelectedShift(
              id: shiftId,
              timeRange: timeRange,
              date: date,
              instanceId: instanceId,
            );

            print(
                'Parsed shift for $dateKey: $timeRange (instanceId: $instanceId, state: $workflowState)');
          }
        }
      }

      print(
          'Successfully parsed ${selectedShifts.length} shifts from API response');
    } catch (e) {
      print('Error parsing year calendar shifts response: $e');
    }

    return selectedShifts;
  }
}
