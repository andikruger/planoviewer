// services/pdf_export_service.dart

// ignore_for_file: unused_local_variable

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:planoviewer/screens/roster_display_screen.dart';
import '../models/roster_models.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

// Web-specific import
// ignore: deprecated_member_use
import 'dart:html' as html show AnchorElement, Blob, Url;

class ExportService {
  final DateTime startDate;
  final DateTime endDate;

  ExportService({required this.startDate, required this.endDate});

  Future<void> exportRoster(
    BuildContext context,
    WorkRosterData rosterData,
    ExportFormat format,
  ) async {
    switch (format) {
      case ExportFormat.pdfList:
        await _exportRosterToPDFList(context, rosterData);
        break;
      case ExportFormat.pdfCalendar:
        await _exportRosterToPDFCalendar(context, rosterData);
        break;
      case ExportFormat.csv:
        await _exportRosterToCSV(context, rosterData);
        break;
      case ExportFormat.icalendar:
        await _exportRosterToICS(context, rosterData);
        break;
      case ExportFormat.pdf:
        // TODO: Handle this case.
        throw UnimplementedError();
      case ExportFormat.listCsv:
        // TODO: Handle this case.
        throw UnimplementedError();
      case ExportFormat.calendarCsv:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  Future<void> _exportRosterToPDFList(
    BuildContext context,
    WorkRosterData rosterData,
  ) async {
    try {
      _showExportDialog(context, 'PDF Liste wird erstellt...', Icons.list_alt);

      final days = rosterData.getDays();

      if (kIsWeb) {
        await _generateAndDownloadPDFListWeb(context, days, rosterData);
      } else {
        await _generateAndSavePDFListMobile(context, days, rosterData);
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Fehler beim PDF-Liste-Export: $e');
    }
  }

  Future<void> _exportRosterToPDFCalendar(
    BuildContext context,
    WorkRosterData rosterData,
  ) async {
    try {
      _showExportDialog(
        context,
        'PDF Kalender wird erstellt...',
        Icons.calendar_view_month,
      );

      final days = rosterData.getDays();

      if (kIsWeb) {
        await _generateAndDownloadPDFCalendarWeb(context, days, rosterData);
      } else {
        await _generateAndSavePDFCalendarMobile(context, days, rosterData);
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Fehler beim PDF-Kalender-Export: $e');
    }
  }

  // Web download methods
  Future<void> _generateAndDownloadPDFListWeb(
    BuildContext context,
    List<WorkDay> days,
    WorkRosterData rosterData,
  ) async {
    try {
      final pdf = await _generateCompactPDF(days, rosterData);
      final pdfBytes = await pdf.save();

      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);

      final filename = _generateFilename(
        'pdf',
      ).replaceAll('.pdf', '_Liste.pdf');
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();

      html.Url.revokeObjectUrl(url);
      Navigator.pop(context);
      _showSuccessSnackBar(context, 'PDF Liste heruntergeladen: $filename');
    } catch (e) {
      _showErrorSnackBar(context, 'Fehler beim Web-Download: $e');
    }
  }

  Future<void> _generateAndDownloadPDFCalendarWeb(
    BuildContext context,
    List<WorkDay> days,
    WorkRosterData rosterData,
  ) async {
    try {
      final pdf = await _generateCalendarPDF(days, rosterData);
      final pdfBytes = await pdf.save();

      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);

      final filename = _generateFilename(
        'pdf',
      ).replaceAll('.pdf', '_Kalender.pdf');
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();

      html.Url.revokeObjectUrl(url);
      Navigator.pop(context);
      _showSuccessSnackBar(context, 'PDF Kalender heruntergeladen: $filename');
    } catch (e) {
      _showErrorSnackBar(context, 'Fehler beim Web-Download: $e');
    }
  }

  // Mobile save methods
  Future<void> _generateAndSavePDFListMobile(
    BuildContext context,
    List<WorkDay> days,
    WorkRosterData rosterData,
  ) async {
    try {
      if (Platform.isAndroid) {
        var status = await Permission.storage.request();
        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
          if (!status.isGranted) {
            Navigator.pop(context);
            _showErrorSnackBar(context, 'Speicherberechtigung erforderlich');
            return;
          }
        }
      }

      final pdf = await _generateCompactPDF(days, rosterData);

      Directory? directory;
      if (Platform.isAndroid) {
        try {
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
        } catch (e) {
          directory = await getApplicationDocumentsDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Konnte Speicherort nicht finden');
      }

      final filename = _generateFilename(
        'pdf',
      ).replaceAll('.pdf', '_Liste.pdf');
      final file = File('${directory.path}/$filename');
      await file.writeAsBytes(await pdf.save());

      Navigator.pop(context);
      _showSuccessSnackBar(context, 'PDF Liste gespeichert: $filename');
    } catch (e) {
      _showErrorSnackBar(context, 'Fehler beim Speichern: $e');
    }
  }

  Future<void> _generateAndSavePDFCalendarMobile(
    BuildContext context,
    List<WorkDay> days,
    WorkRosterData rosterData,
  ) async {
    try {
      if (Platform.isAndroid) {
        var status = await Permission.storage.request();
        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
          if (!status.isGranted) {
            Navigator.pop(context);
            _showErrorSnackBar(context, 'Speicherberechtigung erforderlich');
            return;
          }
        }
      }

      final pdf = await _generateCalendarPDF(days, rosterData);

      Directory? directory;
      if (Platform.isAndroid) {
        try {
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
        } catch (e) {
          directory = await getApplicationDocumentsDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Konnte Speicherort nicht finden');
      }

      final filename = _generateFilename(
        'pdf',
      ).replaceAll('.pdf', '_Kalender.pdf');
      final file = File('${directory.path}/$filename');
      await file.writeAsBytes(await pdf.save());

      Navigator.pop(context);
      _showSuccessSnackBar(context, 'PDF Kalender gespeichert: $filename');
    } catch (e) {
      _showErrorSnackBar(context, 'Fehler beim Speichern: $e');
    }
  }

  Future<void> _exportRosterToCSV(
    BuildContext context,
    WorkRosterData rosterData,
  ) async {
    try {
      _showExportDialog(context, 'CSV wird erstellt...', Icons.table_chart);

      final days = rosterData.getDays();
      final csvContent = _generateCSVContent(days);

      if (kIsWeb) {
        await _downloadCSVWeb(context, csvContent);
      } else {
        await _saveCSVMobile(context, csvContent);
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Fehler beim CSV-Export: $e');
    }
  }

  // Show export dialog (reusable version of your existing PDF dialog)
  void _showExportDialog(BuildContext context, String message, IconData icon) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                child: Icon(icon, size: 32, color: Colors.white),
              ),
              SizedBox(height: 24),
              Text(
                message,
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
  }

  // Success snackbar
  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 4),
      ),
    );
  }

  // Error snackbar
  void _showErrorSnackBar(BuildContext context, String message) {
    Navigator.pop(context); // Close dialog if open
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
        margin: EdgeInsets.all(16),
      ),
    );
  }

  // Full day names for CSV
  String _getDayNameFull(int weekday) {
    final days = [
      'Montag',
      'Dienstag',
      'Mittwoch',
      'Donnerstag',
      'Freitag',
      'Samstag',
      'Sonntag',
    ];
    return days[weekday - 1];
  }

  // Date formatting for CSV
  String _formatDateCSV(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  // Date/time formatting for ICS files
  String _formatDateTimeICS(DateTime date, String time) {
    try {
      // Handle overnight shifts with +1 notation
      bool isNextDay = time.contains('+1');
      String cleanTime = time.replaceAll('+1', '').trim();

      // Convert time to 24-hour format if needed
      final cleanTime24h = _convertTo24Hour(cleanTime);
      final timeParts = cleanTime24h.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      // Create the datetime, adding a day if it's an overnight shift
      DateTime dateTime = DateTime(
        date.year,
        date.month,
        date.day,
        hour,
        minute,
      );
      if (isNextDay) {
        dateTime = dateTime.add(Duration(days: 1));
      }

      // ICS format: YYYYMMDDTHHMMSS
      return '${dateTime.year}'
          '${dateTime.month.toString().padLeft(2, '0')}'
          '${dateTime.day.toString().padLeft(2, '0')}'
          'T'
          '${dateTime.hour.toString().padLeft(2, '0')}'
          '${dateTime.minute.toString().padLeft(2, '0')}'
          '00';
    } catch (e) {
      // Fallback to date only
      return '${date.year}'
          '${date.month.toString().padLeft(2, '0')}'
          '${date.day.toString().padLeft(2, '0')}';
    }
  }

  // Mobile file saving for CSV
  Future<void> _saveCSVMobile(BuildContext context, String content) async {
    try {
      // Use same permission logic as your PDF method
      if (Platform.isAndroid) {
        var status = await Permission.storage.request();
        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
          if (!status.isGranted) {
            Navigator.pop(context);
            _showErrorSnackBar(context, 'Speicherberechtigung erforderlich');
            return;
          }
        }
      }

      Directory? directory;
      if (Platform.isAndroid) {
        try {
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
        } catch (e) {
          directory = await getApplicationDocumentsDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Konnte Speicherort nicht finden');
      }

      final filename = _generateFilename('csv');
      final file = File('${directory.path}/$filename');
      await file.writeAsString(content, encoding: utf8);

      Navigator.pop(context);
      _showSuccessSnackBar(context, 'CSV gespeichert: $filename');
    } catch (e) {
      _showErrorSnackBar(context, 'Fehler beim Speichern: $e');
    }
  }

  // Mobile file saving for ICS
  Future<void> _saveICSMobile(BuildContext context, String content) async {
    try {
      // Same permission and directory logic as CSV
      if (Platform.isAndroid) {
        var status = await Permission.storage.request();
        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
          if (!status.isGranted) {
            Navigator.pop(context);
            _showErrorSnackBar(context, 'Speicherberechtigung erforderlich');
            return;
          }
        }
      }

      Directory? directory;
      if (Platform.isAndroid) {
        try {
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
        } catch (e) {
          directory = await getApplicationDocumentsDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Konnte Speicherort nicht finden');
      }

      final filename = _generateFilename('ics');
      final file = File('${directory.path}/$filename');
      await file.writeAsString(content, encoding: utf8);

      Navigator.pop(context);
      _showSuccessSnackBar(context, 'iCalendar gespeichert: $filename');
    } catch (e) {
      _showErrorSnackBar(context, 'Fehler beim Speichern: $e');
    }
  }

  String _generateCSVContent(List<WorkDay> days) {
    final buffer = StringBuffer();

    // CSV Header
    buffer.writeln('Datum,Tag,Zeiten,Stunden,Typ');

    // CSV Rows
    for (int i = 0; i < days.length; i++) {
      final day = days[i];
      final actualDate = startDate.add(Duration(days: i));
      final dayName = _getDayNameFull(actualDate.weekday);
      final isWeekend = actualDate.weekday >= 6;

      final shifts = day.shifts.isNotEmpty
          ? day.shifts.map((s) => _formatShiftInterval(s.interval)).join('; ')
          : (isWeekend ? 'Wochenende' : 'Frei');

      final hours = day.hoursWorked != '0:00' ? day.hoursWorked : '';
      final type = day.shifts.isNotEmpty
          ? 'Arbeit'
          : (isWeekend ? 'Wochenende' : 'Frei');

      buffer.writeln(
        '"${_formatDateCSV(actualDate)}","$dayName","$shifts","$hours","$type"',
      );
    }

    return buffer.toString();
  }

  Future<void> _exportRosterToICS(
    BuildContext context,
    WorkRosterData rosterData,
  ) async {
    try {
      _showExportDialog(
        context,
        'iCalendar wird erstellt...',
        Icons.calendar_today,
      );

      final days = rosterData.getDays();
      final icsContent = _generateICSContent(days);

      if (kIsWeb) {
        await _downloadICSWeb(context, icsContent);
      } else {
        await _saveICSMobile(context, icsContent);
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Fehler beim iCalendar-Export: $e');
    }
  }

  String _generateICSContent(List<WorkDay> days) {
    final buffer = StringBuffer();

    // ICS Header
    buffer.writeln('BEGIN:VCALENDAR');
    buffer.writeln('VERSION:2.0');
    buffer.writeln('PRODID:-//Austrian Airlines//Planoviewer//DE');
    buffer.writeln('CALSCALE:GREGORIAN');

    // Events
    for (int i = 0; i < days.length; i++) {
      final day = days[i];
      final actualDate = startDate.add(Duration(days: i));

      if (day.shifts.isNotEmpty) {
        for (final shift in day.shifts) {
          // Better interval parsing
          final intervalParts = shift.interval.contains(' - ')
              ? shift.interval.split(' - ')
              : shift.interval.split('-');

          if (intervalParts.length >= 2) {
            final startTime = intervalParts[0].trim();
            final endTime = intervalParts[1].trim();

            buffer.writeln('BEGIN:VEVENT');
            buffer.writeln(
              'UID:${DateTime.now().millisecondsSinceEpoch}-$i-${shift.hashCode}@austrianairlines.com',
            );
            buffer.writeln(
              'DTSTART:${_formatDateTimeICS(actualDate, startTime)}',
            );
            buffer.writeln('DTEND:${_formatDateTimeICS(actualDate, endTime)}');
            buffer.writeln('SUMMARY:Schicht');
            buffer.writeln('DESCRIPTION:Arbeitszeit: ${shift.interval}');
            buffer.writeln('END:VEVENT');
          }
        }
      }
    }

    buffer.writeln('END:VCALENDAR');
    return buffer.toString();
  }

  Future<void> exportRosterToPDF(
    BuildContext context,
    WorkRosterData rosterData,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
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

  Future<void> _downloadCSVWeb(BuildContext context, String content) async {
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final filename = _generateFilename('csv');
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();

    html.Url.revokeObjectUrl(url);
    Navigator.pop(context);
    _showSuccessSnackBar(context, 'CSV heruntergeladen: $filename');
  }

  Future<void> _downloadICSWeb(BuildContext context, String content) async {
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes], 'text/calendar;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final filename = _generateFilename('ics');
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();

    html.Url.revokeObjectUrl(url);
    Navigator.pop(context);
    _showSuccessSnackBar(context, 'iCalendar heruntergeladen: $filename');
  }

  // Web PDF download
  Future<void> _generateAndDownloadPDFWeb(
    BuildContext context,
    List<WorkDay> days,
    WorkRosterData rosterData,
  ) async {
    try {
      final pdf = await _generateCompactPDF(days, rosterData);
      final pdfBytes = await pdf.save();

      // Create blob and trigger download
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);

      // Create filename with timestamp and actual date range
      final timestamp = DateTime.now()
          .toString()
          .replaceAll(':', '-')
          .substring(0, 19);
      final filename = _generateFilename('pdf');

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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
  Future<void> _generateAndSavePDFMobile(
    BuildContext context,
    List<WorkDay> days,
    WorkRosterData rosterData,
  ) async {
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

      final pdf = await _generateCompactPDF(days, rosterData);

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
      final timestamp = DateTime.now()
          .toString()
          .replaceAll(':', '-')
          .substring(0, 19);
      final filename = _generateFilename('pdf');
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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

  String _generateFilename(String extension) {
    final timestamp = DateTime.now()
        .toString()
        .replaceAll(':', '-')
        .substring(0, 19);
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
      'Dezember',
    ];

    final startMonth = monthNames[startDate.month];
    final endMonth = monthNames[endDate.month];

    final monthPart = startDate.month == endDate.month
        ? startMonth
        : '${startMonth}_${endMonth}';

    return 'Austrian_Airlines_Dienstplan_${monthPart}_${startDate.year}_$timestamp.$extension';
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
      'DEZEMBER',
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
  Future<pw.Document> _generateCompactPDF(
    List<WorkDay> days,
    WorkRosterData rosterData,
  ) async {
    final pdf = pw.Document();
    final workingDays = days.where((d) => d.hasWork).length;
    final totalHours = rosterData.getTotalHours();

    // Colors
    final primaryRed = PdfColor.fromHex('#E30613');
    final lightGray = PdfColor.fromHex('#F9FAFB');
    final mediumGray = PdfColor.fromHex('#6B7280');
    final darkGray = PdfColor.fromHex('#111827');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(16), // Reduced margins
        build: (pw.Context context) {
          return [
            // Compact Header
            pw.Container(
              padding: pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: lightGray,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                children: [
                  pw.Container(width: 3, height: 24, color: primaryRed),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'AUSTRIAN AIRLINES DIENSTPLAN',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          _getPDFHeaderText(),
                          style: pw.TextStyle(fontSize: 11, color: mediumGray),
                        ),
                      ],
                    ),
                  ),
                  pw.Text(
                    '$workingDays Arbeitstage • ${totalHours}h',
                    style: pw.TextStyle(fontSize: 10, color: mediumGray),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 12),

            // Compact table
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColor.fromHex('#E5E7EB'),
                width: 0.5,
              ),
              columnWidths: {
                0: pw.FixedColumnWidth(50), // Date
                1: pw.FixedColumnWidth(40), // Day
                2: pw.FlexColumnWidth(2.5), // Shifts
                3: pw.FixedColumnWidth(40), // Hours
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: lightGray),
                  children: [
                    _buildCompactCell('DATUM', isHeader: true),
                    _buildCompactCell('TAG', isHeader: true),
                    _buildCompactCell('ZEITEN', isHeader: true),
                    _buildCompactCell('STD', isHeader: true),
                  ],
                ),
                // Data rows
                ...List.generate(days.length, (index) {
                  final day = days[index];
                  final actualDate = startDate.add(Duration(days: index));
                  final dayName = _getDayNameShort(actualDate.weekday);
                  final isWeekend = actualDate.weekday >= 6;

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: index % 2 == 0 ? PdfColors.white : lightGray,
                    ),
                    children: [
                      _buildCompactCell(
                        '${actualDate.day}.${actualDate.month}.',
                      ),
                      _buildCompactCell(
                        dayName,
                        color: isWeekend ? PdfColor.fromHex('#F59E0B') : null,
                      ),
                      _buildCompactCell(
                        day.shifts.isNotEmpty
                            ? day.shifts
                                  .map((s) => _formatShiftInterval(s.interval))
                                  .join(', ')
                            : (isWeekend ? 'WE' : 'Frei'),
                        fontSize: 9,
                      ),
                      _buildCompactCell(
                        day.hoursWorked != '0:00' ? day.hoursWorked : '—',
                      ),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 8),

            // Compact footer
            pw.Container(
              padding: pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: lightGray,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                'Erstellt ${_formatDateForPDF(DateTime.now())} • ${_formatDateForPDF(startDate)} - ${_formatDateForPDF(endDate.subtract(Duration(days: 1)))}',
                style: pw.TextStyle(fontSize: 8, color: mediumGray),
              ),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildCompactCell(
    String text, {
    bool isHeader = false,
    double? fontSize,
    PdfColor? color,
  }) {
    return pw.Container(
      padding: pw.EdgeInsets.all(isHeader ? 6 : 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize ?? (isHeader ? 9 : 10),
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color:
              color ??
              (isHeader
                  ? PdfColor.fromHex('#6B7280')
                  : PdfColor.fromHex('#111827')),
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  Future<pw.Document> _generateCalendarPDF(
    List<WorkDay> days,
    WorkRosterData rosterData,
  ) async {
    final pdf = pw.Document();

    // Group days by month
    final monthGroups = <int, List<MapEntry<int, WorkDay>>>{};
    for (int i = 0; i < days.length; i++) {
      final date = startDate.add(Duration(days: i));
      monthGroups.putIfAbsent(date.month, () => []).add(MapEntry(i, days[i]));
    }

    for (final monthEntry in monthGroups.entries) {
      pdf.addPage(_buildCalendarPage(monthEntry.key, monthEntry.value));
    }

    return pdf;
  }

  pw.Page _buildCalendarPage(
    int month,
    List<MapEntry<int, WorkDay>> monthDays,
  ) {
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
      'DEZEMBER',
    ];

    final firstDay = startDate.add(Duration(days: monthDays.first.key));
    final year = firstDay.year;

    // Create calendar grid
    final firstDayOfMonth = DateTime(year, month, 1);
    final lastDayOfMonth = DateTime(year, month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday; // 1 = Monday

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(20),
      build: (pw.Context context) {
        return pw.Column(
          children: [
            // Month header
            pw.Container(
              padding: pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F9FAFB'),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                children: [
                  pw.Container(
                    width: 4,
                    height: 24,
                    color: PdfColor.fromHex('#E30613'),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Text(
                    'AUSTRIAN AIRLINES • ${monthNames[month]} $year',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 16),

            // Calendar grid
            pw.Expanded(
              child: pw.Table(
                border: pw.TableBorder.all(color: PdfColor.fromHex('#E5E7EB')),
                children: [
                  // Week header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F3F4F6'),
                    ),
                    children: ['MO', 'DI', 'MI', 'DO', 'FR', 'SA', 'SO']
                        .map(
                          (day) => pw.Container(
                            height: 30,
                            padding: pw.EdgeInsets.all(4),
                            child: pw.Center(
                              child: pw.Text(
                                day,
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),

                  // Calendar weeks
                  ..._buildCalendarWeeks(
                    monthDays,
                    firstDayOfMonth,
                    lastDayOfMonth,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  List<pw.TableRow> _buildCalendarWeeks(
    List<MapEntry<int, WorkDay>> monthDays,
    DateTime firstDay,
    DateTime lastDay,
  ) {
    final weeks = <pw.TableRow>[];
    final dayMap = <int, WorkDay>{};

    // Create lookup map
    for (final entry in monthDays) {
      final date = startDate.add(Duration(days: entry.key));
      dayMap[date.day] = entry.value;
    }

    DateTime current = firstDay.subtract(Duration(days: firstDay.weekday - 1));

    while (current.isBefore(lastDay.add(Duration(days: 7)))) {
      final weekCells = <pw.Widget>[];

      for (int i = 0; i < 7; i++) {
        final cellDate = current.add(Duration(days: i));
        final isCurrentMonth = cellDate.month == firstDay.month;
        final workDay = isCurrentMonth ? dayMap[cellDate.day] : null;

        weekCells.add(_buildCalendarCell(cellDate, workDay, isCurrentMonth));
      }

      weeks.add(pw.TableRow(children: weekCells));
      current = current.add(Duration(days: 7));

      if (current.isAfter(lastDay.add(Duration(days: 6)))) break;
    }

    return weeks;
  }

  pw.Widget _buildCalendarCell(
    DateTime date,
    WorkDay? workDay,
    bool isCurrentMonth,
  ) {
    final isWeekend = date.weekday >= 6;
    final hasWork = workDay?.shifts.isNotEmpty == true;

    PdfColor bgColor = PdfColors.white;
    if (!isCurrentMonth)
      bgColor = PdfColor.fromHex('#F9FAFB');
    else if (hasWork)
      bgColor = PdfColor.fromHex('#DCFDF7');
    else if (isWeekend)
      bgColor = PdfColor.fromHex('#FEF3C7');

    return pw.Container(
      height: 80,
      decoration: pw.BoxDecoration(color: bgColor),
      padding: pw.EdgeInsets.all(4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '${date.day}',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: isCurrentMonth
                  ? PdfColor.fromHex('#111827')
                  : PdfColor.fromHex('#9CA3AF'),
            ),
          ),
          if (hasWork && workDay != null) ...[
            pw.SizedBox(height: 2),
            ...workDay.shifts
                .take(2)
                .map(
                  (shift) => pw.Text(
                    _formatShiftInterval(shift.interval),
                    style: pw.TextStyle(
                      fontSize: 7,
                      color: PdfColor.fromHex('#059669'),
                    ),
                  ),
                ),
            if (workDay.shifts.length > 2)
              pw.Text(
                '...',
                style: pw.TextStyle(
                  fontSize: 7,
                  color: PdfColor.fromHex('#6B7280'),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // Helper method to build clean stat columns

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
      'Dez',
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

    final amPmRegex = RegExp(
      r'(\d{1,2}):(\d{2})\s*(AM|PM)',
      caseSensitive: false,
    );
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
}
