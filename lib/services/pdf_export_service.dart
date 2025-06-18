// services/pdf_export_service.dart

// ignore_for_file: unused_local_variable

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/roster_models.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

// Web-specific import
import 'dart:html' as html show AnchorElement, Blob, Url;

class PDFExportService {
  final DateTime startDate;
  final DateTime endDate;

  PDFExportService({
    required this.startDate,
    required this.endDate,
  });

  Future<void> exportRosterToPDF(
      BuildContext context, WorkRosterData rosterData) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.transparent,
          content: Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 40,
                  offset: Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Color(0xFFE30613),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.picture_as_pdf,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'PDF wird erstellt...',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Dienstplan wird formatiert und optimiert',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );

      final days = rosterData.getDays();

      if (kIsWeb) {
        await _generateAndDownloadPDFWeb(context, days, rosterData);
      } else {
        await _generateAndSavePDFMobile(context, days, rosterData);
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim PDF-Export: $e'),
          backgroundColor: Color(0xFFE30613),
        ),
      );
    }
  }

  // Web PDF download
  Future<void> _generateAndDownloadPDFWeb(BuildContext context,
      List<WorkDay> days, WorkRosterData rosterData) async {
    try {
      final pdf = await _generatePDF(days, rosterData);
      final pdfBytes = await pdf.save();

      // Create blob and trigger download
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Create filename with timestamp and actual date range
      final timestamp =
          DateTime.now().toString().replaceAll(':', '-').substring(0, 19);
      final filename = _generateFilename(timestamp);

      // Create download link and trigger download
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();

      // Clean up
      html.Url.revokeObjectUrl(url);

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.download_done, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('PDF heruntergeladen: $filename')),
            ],
          ),
          backgroundColor: Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Web-Download: $e'),
          backgroundColor: Color(0xFFE30613),
        ),
      );
    }
  }

  // Mobile PDF save
  Future<void> _generateAndSavePDFMobile(BuildContext context,
      List<WorkDay> days, WorkRosterData rosterData) async {
    try {
      // Request storage permission for Android
      if (Platform.isAndroid) {
        var status = await Permission.storage.request();
        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
          if (!status.isGranted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Speicherberechtigung erforderlich'),
                backgroundColor: Color(0xFFE30613),
              ),
            );
            return;
          }
        }
      }

      final pdf = await _generatePDF(days, rosterData);

      // Get the appropriate directory
      Directory? directory;
      String directoryName = '';

      if (Platform.isAndroid) {
        try {
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
          directoryName = 'Downloads';
        } catch (e) {
          directory = await getApplicationDocumentsDirectory();
          directoryName = 'App Documents';
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
        directoryName = 'Documents';
      }

      if (directory == null) {
        throw Exception('Konnte Speicherort nicht finden');
      }

      // Create filename with timestamp and actual date range
      final timestamp =
          DateTime.now().toString().replaceAll(':', '-').substring(0, 19);
      final filename = _generateFilename(timestamp);
      final file = File('${directory.path}/$filename');

      // Save the PDF
      await file.writeAsBytes(await pdf.save());

      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('PDF gespeichert: $filename')),
            ],
          ),
          backgroundColor: Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Speichern: $e'),
          backgroundColor: Color(0xFFE30613),
        ),
      );
    }
  }

  // Generate filename based on actual date range
  String _generateFilename(String timestamp) {
    final monthNames = [
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

    final startMonth = monthNames[startDate.month];
    final endMonth = monthNames[endDate.month];

    if (startDate.month == endDate.month) {
      // Same month
      return 'Austrian_Airlines_Dienstplan_${startMonth}_${startDate.year}_$timestamp.pdf';
    } else {
      // Cross-month
      return 'Austrian_Airlines_Dienstplan_${startMonth}_${endMonth}_${startDate.year}_$timestamp.pdf';
    }
  }

  // Generate PDF header text based on actual date range
  String _getPDFHeaderText() {
    final monthNames = [
      '',
      'JANUAR',
      'FEBRUAR',
      'MÄRZ',
      'APRIL',
      'MAI',
      'JUNI',
      'JULI',
      'AUGUST',
      'SEPTEMBER',
      'OKTOBER',
      'NOVEMBER',
      'DEZEMBER'
    ];

    final startMonth = monthNames[startDate.month];
    final endMonth = monthNames[endDate.month];

    if (startDate.month == endDate.month) {
      // Same month
      return '$startMonth ${startDate.year}';
    } else {
      // Cross-month
      return '$startMonth-$endMonth ${startDate.year}';
    }
  }

  // Generate PDF document with clean, app-matching design
  Future<pw.Document> _generatePDF(
      List<WorkDay> days, WorkRosterData rosterData) async {
    final pdf = pw.Document();
    final workingDays = days.where((d) => d.hasWork).length;
    final totalHours = rosterData.getTotalHours();
    final totalDays = days.length;

    // Define color scheme matching your app
    final primaryRed = PdfColor.fromHex('#E30613');
    final lightGray = PdfColor.fromHex('#FAFAFA');
    final mediumGray = PdfColor.fromHex('#6B7280');
    final darkGray = PdfColor.fromHex('#111827');
    final lightBorder = PdfColor.fromHex('#E5E7EB');
    final workColor = PdfColor.fromHex('#059669');
    final freeColor = PdfColor.fromHex('#6366F1');
    final weekendColor = PdfColor.fromHex('#F59E0B');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            // Clean Header matching your app style
            pw.Container(
              padding: pw.EdgeInsets.all(32),
              decoration: pw.BoxDecoration(
                color: lightGray,
                borderRadius: pw.BorderRadius.circular(16),
              ),
              child: pw.Row(
                children: [
                  // Left side with accent
                  pw.Container(
                    width: 4,
                    height: 40,
                    decoration: pw.BoxDecoration(
                      color: primaryRed,
                      borderRadius: pw.BorderRadius.circular(2),
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'AUSTRIAN AIRLINES',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: darkGray,
                            letterSpacing: 0.5,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Dienstplan ${_getPDFHeaderText()}',
                          style: pw.TextStyle(
                            fontSize: 14,
                            color: mediumGray,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Date info
                  pw.Text(
                    '${_formatDateForPDF(DateTime.now())}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: mediumGray,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 24),

            // Clean Statistics matching your app
            pw.Container(
              margin: pw.EdgeInsets.symmetric(horizontal: 0),
              padding: pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(16),
                border: pw.Border.all(color: lightBorder),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: _buildStatColumn(
                        '$workingDays', 'Arbeitstage', workColor),
                  ),
                  pw.Container(width: 1, height: 32, color: lightBorder),
                  pw.Expanded(
                    child: _buildStatColumn(
                        '${totalDays - workingDays}', 'Freie Tage', freeColor),
                  ),
                  pw.Container(width: 1, height: 32, color: lightBorder),
                  pw.Expanded(
                    child: _buildStatColumn(
                        '${totalHours}h', 'Stunden', weekendColor),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 32),

            // Section header
            pw.Container(
              padding: pw.EdgeInsets.symmetric(horizontal: 0, vertical: 12),
              child: pw.Row(
                children: [
                  pw.Text(
                    'KALENDER',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: darkGray,
                      letterSpacing: 1.5,
                    ),
                  ),
                  pw.Spacer(),
                  pw.Text(
                    '${days.length} Tage',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: mediumGray,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),

            // Clean calendar-like layout
            pw.Container(
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(16),
                border: pw.Border.all(color: lightBorder),
              ),
              child: pw.Column(
                children: [
                  // Header
                  pw.Container(
                    padding: pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      color: lightGray,
                      borderRadius: pw.BorderRadius.only(
                        topLeft: pw.Radius.circular(16),
                        topRight: pw.Radius.circular(16),
                      ),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(flex: 2, child: _buildTableHeader('DATUM')),
                        pw.Expanded(flex: 2, child: _buildTableHeader('TAG')),
                        pw.Expanded(
                            flex: 3, child: _buildTableHeader('ZEITEN')),
                        pw.Expanded(flex: 1, child: _buildTableHeader('STD')),
                      ],
                    ),
                  ),

                  // Days
                  ...List.generate(days.length, (index) {
                    final day = days[index];
                    final actualDate = startDate.add(Duration(days: index));
                    final dayName = _getDayNameShort(actualDate.weekday);
                    final isWeekend = actualDate.weekday >= 6;

                    return pw.Container(
                      padding: pw.EdgeInsets.all(16),
                      decoration: pw.BoxDecoration(
                        color: index % 2 == 0 ? PdfColors.white : lightGray,
                        border: pw.Border(
                          bottom: index == days.length - 1
                              ? pw.BorderSide.none
                              : pw.BorderSide(color: lightBorder),
                        ),
                      ),
                      child: pw.Row(
                        children: [
                          // Date
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              '${actualDate.day}.${actualDate.month}.${actualDate.year}',
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                                color: darkGray,
                              ),
                            ),
                          ),

                          // Day
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                              dayName,
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.normal,
                                color: isWeekend ? weekendColor : mediumGray,
                              ),
                            ),
                          ),

                          // Shifts
                          pw.Expanded(
                            flex: 3,
                            child: pw.Text(
                              day.shifts.isNotEmpty
                                  ? day.shifts
                                      .map((s) =>
                                          _formatShiftInterval(s.interval))
                                      .join(', ')
                                  : (isWeekend ? 'Wochenende' : 'Frei'),
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.normal,
                                color: day.shifts.isNotEmpty
                                    ? darkGray
                                    : mediumGray,
                              ),
                            ),
                          ),

                          // Hours
                          pw.Expanded(
                            flex: 1,
                            child: pw.Text(
                              day.hoursWorked != '0:00' ? day.hoursWorked : '—',
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                                color: day.hoursWorked != '0:00'
                                    ? darkGray
                                    : mediumGray,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            pw.SizedBox(height: 32),

            // Clean footer
            pw.Container(
              padding: pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: lightGray,
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Zeitraum: ${_formatDateForPDF(startDate)} — ${_formatDateForPDF(endDate.subtract(Duration(days: 1)))}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: mediumGray,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Erstellt am ${_formatDateForPDF(DateTime.now())} • Austrian Airlines Planoviewer',
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: mediumGray,
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  // Helper method to build clean stat columns
  pw.Widget _buildStatColumn(String value, String label, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 12,
            color: PdfColor.fromHex('#6B7280'),
            fontWeight: pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTableHeader(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 11,
        fontWeight: pw.FontWeight.bold,
        color: PdfColor.fromHex('#6B7280'),
        letterSpacing: 0.5,
      ),
    );
  }

  /// Format date for PDF display (DD. Month YYYY)
  String _formatDateForPDF(DateTime date) {
    final monthNames = [
      '',
      'Jan',
      'Feb',
      'Mär',
      'Apr',
      'Mai',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Okt',
      'Nov',
      'Dez'
    ];
    return '${date.day}. ${monthNames[date.month]} ${date.year}';
  }

  String _getDayNameShort(int weekday) {
    final days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    return days[weekday - 1];
  }

  /// Format shift interval to 24-hour format for PDF
  String _formatShiftInterval(String interval) {
    if (interval.isEmpty) return interval;

    try {
      // Handle intervals like "6:30 AM - 2:30 PM" or "06:00-14:30"
      String separator = '-';
      if (interval.contains(' - ')) {
        separator = ' - ';
      }

      final parts = interval.split(separator);
      if (parts.length == 2) {
        final startTime = _convertTo24Hour(parts[0].trim());
        final endTime = _convertTo24Hour(parts[1].trim());
        return '$startTime$separator$endTime';
      }

      return _convertTo24Hour(interval);
    } catch (e) {
      return interval; // Return original if conversion fails
    }
  }

  /// Convert time to 24-hour format
  String _convertTo24Hour(String timeString) {
    if (timeString.isEmpty) return timeString;

    // If no AM/PM, assume already 24-hour
    if (!timeString.toLowerCase().contains('am') &&
        !timeString.toLowerCase().contains('pm')) {
      return timeString;
    }

    final amPmRegex =
        RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)', caseSensitive: false);
    final match = amPmRegex.firstMatch(timeString);

    if (match != null) {
      int hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      final period = match.group(3)!.toUpperCase();

      if (period == 'PM' && hour != 12) {
        hour += 12;
      } else if (period == 'AM' && hour == 12) {
        hour = 0;
      }

      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }

    return timeString;
  }

  String _getDayNameGerman(int weekday) {
    final days = [
      'Montag',
      'Dienstag',
      'Mittwoch',
      'Donnerstag',
      'Freitag',
      'Samstag',
      'Sonntag'
    ];
    return days[weekday - 1]; // weekday is 1-based (1 = Monday)
  }
}
