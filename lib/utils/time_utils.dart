// utils/time_format_utils.dart

class TimeFormatUtils {
  /// Converts various time formats to 24-hour format (HH:MM)
  static String to24Hour(String timeString) {
    if (timeString.isEmpty) return timeString;

    try {
      // Remove any extra whitespace
      final cleanTime = timeString.trim();

      // Pattern 1: Already in 24-hour format (HH:MM or H:MM)
      final format24Regex = RegExp(r'^(\d{1,2}):(\d{2})$');
      final match24 = format24Regex.firstMatch(cleanTime);
      if (match24 != null) {
        final hour = int.parse(match24.group(1)!);
        final minute = int.parse(match24.group(2)!);

        // Validate time
        if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
          return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        }
      }

      // Pattern 2: 12-hour format with AM/PM (various formats)
      final format12Regex = RegExp(
          r'(\d{1,2}):(\d{2})\s*(AM|PM|am|pm|a\.m\.|p\.m\.)',
          caseSensitive: false);
      final match12 = format12Regex.firstMatch(cleanTime);
      if (match12 != null) {
        int hour = int.parse(match12.group(1)!);
        final minute = int.parse(match12.group(2)!);
        final period = match12.group(3)!.toLowerCase();

        // Convert to 24-hour format
        if (period.startsWith('p') && hour != 12) {
          hour += 12;
        } else if (period.startsWith('a') && hour == 12) {
          hour = 0;
        }

        // Validate converted time
        if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
          return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        }
      }

      // Pattern 3: 12-hour format without space (2:30PM, 10:15AM)
      final format12NoSpaceRegex =
          RegExp(r'(\d{1,2}):(\d{2})(AM|PM|am|pm)', caseSensitive: false);
      final match12NoSpace = format12NoSpaceRegex.firstMatch(cleanTime);
      if (match12NoSpace != null) {
        int hour = int.parse(match12NoSpace.group(1)!);
        final minute = int.parse(match12NoSpace.group(2)!);
        final period = match12NoSpace.group(3)!.toLowerCase();

        // Convert to 24-hour format
        if (period.startsWith('p') && hour != 12) {
          hour += 12;
        } else if (period.startsWith('a') && hour == 12) {
          hour = 0;
        }

        // Validate converted time
        if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
          return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        }
      }

      // Pattern 4: Single digit hour formats (9:30, 9:30 AM, etc.)
      final singleHourRegex =
          RegExp(r'(\d):(\d{2})(?:\s*(AM|PM|am|pm))?', caseSensitive: false);
      final matchSingle = singleHourRegex.firstMatch(cleanTime);
      if (matchSingle != null) {
        int hour = int.parse(matchSingle.group(1)!);
        final minute = int.parse(matchSingle.group(2)!);
        final period = matchSingle.group(3)?.toLowerCase();

        // If period is specified, convert from 12-hour
        if (period != null) {
          if (period.startsWith('p') && hour != 12) {
            hour += 12;
          } else if (period.startsWith('a') && hour == 12) {
            hour = 0;
          }
        }

        // Validate time
        if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
          return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        }
      }

      // Pattern 5: Handle times with seconds (HH:MM:SS)
      final formatWithSecondsRegex = RegExp(
          r'(\d{1,2}):(\d{2}):(\d{2})(?:\s*(AM|PM|am|pm))?',
          caseSensitive: false);
      final matchSeconds = formatWithSecondsRegex.firstMatch(cleanTime);
      if (matchSeconds != null) {
        int hour = int.parse(matchSeconds.group(1)!);
        final minute = int.parse(matchSeconds.group(2)!);
        final period = matchSeconds.group(4)?.toLowerCase();

        // If period is specified, convert from 12-hour
        if (period != null) {
          if (period.startsWith('p') && hour != 12) {
            hour += 12;
          } else if (period.startsWith('a') && hour == 12) {
            hour = 0;
          }
        }

        // Validate time (ignore seconds)
        if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
          return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        }
      }

      // If no pattern matches, return original
      print('Warning: Could not parse time format: "$timeString"');
      return timeString;
    } catch (e) {
      print('Error parsing time "$timeString": $e');
      return timeString; // Return original on error
    }
  }

  /// Batch convert multiple time strings
  static List<String> convertMultiple(List<String> times) {
    return times.map((time) => to24Hour(time)).toList();
  }

  /// Test method to verify different formats work
  static void testFormats() {
    final testCases = [
      '6:30 AM',
      '2:30 PM',
      '12:00 PM',
      '12:00 AM',
      '06:30',
      '14:30',
      '9:15',
      '09:15',
      '6:30AM',
      '2:30PM',
      '6:30 a.m.',
      '2:30 p.m.',
      '10:45:30',
      '10:45:30 AM',
      'invalid time',
      '',
    ];

    print('=== TIME FORMAT TESTING ===');
    for (final testCase in testCases) {
      final result = to24Hour(testCase);
      print('$testCase → $result');
    }
  }
}

// Add this utility method to your day_card.dart or create a separate utils file

class TimeConverter {
  /// Converts time from various formats to 24-hour format
  static String to24Hour(String timeString) {
    if (timeString.isEmpty) return timeString;

    try {
      final cleanTime = timeString.trim();

      // Check if already in 24-hour format (no AM/PM)
      if (!cleanTime.toLowerCase().contains('am') &&
          !cleanTime.toLowerCase().contains('pm') &&
          !cleanTime.toLowerCase().contains('a.m') &&
          !cleanTime.toLowerCase().contains('p.m')) {
        // Validate it's a proper time format
        final timeRegex = RegExp(r'^(\d{1,2}):(\d{2})$');
        final match = timeRegex.firstMatch(cleanTime);
        if (match != null) {
          final hour = int.parse(match.group(1)!);
          final minute = int.parse(match.group(2)!);
          if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
            return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
          }
        }
        return timeString; // Return as is if not valid 24-hour format
      }

      // Handle 12-hour format with AM/PM
      final amPmRegex = RegExp(
          r'(\d{1,2}):(\d{2})\s*(AM|PM|am|pm|a\.m\.|p\.m\.)',
          caseSensitive: false);
      final match = amPmRegex.firstMatch(cleanTime);

      if (match != null) {
        int hour = int.parse(match.group(1)!);
        final minute = int.parse(match.group(2)!);
        final period = match.group(3)!.toLowerCase();

        // Convert to 24-hour format
        if (period.startsWith('p') && hour != 12) {
          hour += 12;
        } else if (period.startsWith('a') && hour == 12) {
          hour = 0;
        }

        return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      }

      // If no pattern matches, return original
      print('Warning: Could not convert time format: "$timeString"');
      return timeString;
    } catch (e) {
      print('Error converting time "$timeString": $e');
      return timeString;
    }
  }
}
