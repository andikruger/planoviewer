// services/pdf_export_service.dart

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
          content: Row(
            children: [
              CircularProgressIndicator(color: Color(0xFFE30613)),
              SizedBox(width: 16),
              Text('PDF wird erstellt...'),
            ],
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
          backgroundColor: Color(0xFF2E7D32),
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
              Icon(Icons.check, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('PDF gespeichert: $filename')),
            ],
          ),
          backgroundColor: Color(0xFF2E7D32),
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
      return 'DIENSTPLAN $startMonth ${startDate.year}';
    } else {
      // Cross-month
      return 'DIENSTPLAN $startMonth-$endMonth ${startDate.year}';
    }
  }

  // Generate PDF document
  Future<pw.Document> _generatePDF(
      List<WorkDay> days, WorkRosterData rosterData) async {
    final pdf = pw.Document();
    final workingDays = days.where((d) => d.hasWork).length;
    final totalHours = rosterData.getTotalHours();
    final totalDays = days.length;

    // Calculate the period text for staff info
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
    final periodText = startDate.month == endDate.month
        ? '$startMonth ${startDate.year}'
        : '$startMonth-$endMonth ${startDate.year}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            // Header with Austrian Airlines branding
            pw.Container(
              padding: pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#E30613'),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'AUSTRIAN AIRLINES',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        'Dienstplan',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    _getPDFHeaderText(),
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Crew Information Section
            // pw.Container(
            //   padding: pw.EdgeInsets.all(15),
            //   decoration: pw.BoxDecoration(
            //     border: pw.Border.all(color: PdfColor.fromHex('#E0E0E0')),
            //     borderRadius: pw.BorderRadius.circular(8),
            //   ),
            //   child: pw.Column(
            //     crossAxisAlignment: pw.CrossAxisAlignment.start,
            //     children: [
            //       pw.Text(
            //         'STAFF INFORMATION',
            //         style: pw.TextStyle(
            //             fontSize: 16, fontWeight: pw.FontWeight.bold),
            //       ),
            //       pw.SizedBox(height: 10),
            //       pw.Row(
            //         children: [
            //           pw.Expanded(child: pw.Text('Name: [Zu ergänzen]')),
            //           pw.Expanded(
            //               child: pw.Text('Mitarbeiter-Nr: [Zu ergänzen]')),
            //         ],
            //       ),
            //       pw.SizedBox(height: 5),
            //       pw.Row(
            //         children: [
            //           pw.Expanded(child: pw.Text('Abteilung: O/GPO')),
            //           pw.Expanded(child: pw.Text('Periode: $periodText')),
            //         ],
            //       ),
            //     ],
            //   ),
            // ),

            pw.SizedBox(height: 20),

            // Monthly Summary
            pw.Container(
              padding: pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F5F5F5'),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'ÜBERSICHT',
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      pw.Column(
                        children: [
                          pw.Text('$totalDays',
                              style: pw.TextStyle(
                                  fontSize: 20,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColor.fromHex('#E30613'))),
                          pw.Text('Tage Gesamt',
                              style: pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Text('$workingDays',
                              style: pw.TextStyle(
                                  fontSize: 20,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColor.fromHex('#2E7D32'))),
                          pw.Text('Arbeitstage',
                              style: pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Text('${totalDays - workingDays}',
                              style: pw.TextStyle(
                                  fontSize: 20,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColor.fromHex('#FF8F00'))),
                          pw.Text('Freie Tage',
                              style: pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Text('${totalHours}h',
                              style: pw.TextStyle(
                                  fontSize: 20,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColor.fromHex('#1976D2'))),
                          pw.Text('Gesamtstunden',
                              style: pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Daily breakdown table
            pw.Text(
              'DETAILLIERTE TAGESÜBERSICHT',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),

            pw.Table(
              border: pw.TableBorder.all(color: PdfColor.fromHex('#E0E0E0')),
              children: [
                // Header row
                pw.TableRow(
                  decoration:
                      pw.BoxDecoration(color: PdfColor.fromHex('#E30613')),
                  children: [
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text('Datum',
                          style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12)),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text('Wochentag',
                          style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12)),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text('Dienstzeiten',
                          style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12)),
                    ),
                    pw.Padding(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text('Stunden',
                          style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12)),
                    ),
                  ],
                ),
                // Data rows with actual dates
                ...List.generate(days.length, (index) {
                  final day = days[index];
                  final actualDate = startDate.add(Duration(days: index));
                  final dayName = _getDayNameGerman(actualDate.weekday);
                  final isWeekend =
                      actualDate.weekday >= 6; // 6 = Saturday, 7 = Sunday

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: isWeekend
                          ? PdfColor.fromHex('#FFF8E1')
                          : day.hasWork
                              ? PdfColors.white
                              : PdfColor.fromHex('#F5F5F5'),
                    ),
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(_formatDateForPDF(actualDate),
                            style: pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child:
                            pw.Text(dayName, style: pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          day.shifts.isNotEmpty
                              ? day.shifts
                                  .map((s) => _formatShiftInterval(s.interval))
                                  .join('\n')
                              : (isWeekend ? 'Wochenende' : 'Frei'),
                          style: pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          day.hoursWorked != '0:00' ? day.hoursWorked : '-',
                          style: pw.TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 20),

            // Footer
            pw.Container(
              padding: pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                    top: pw.BorderSide(color: PdfColor.fromHex('#E0E0E0'))),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Erstellt: ${DateTime.now().toString().substring(0, 19)}',
                    style: pw.TextStyle(
                        fontSize: 8, color: PdfColor.fromHex('#666666')),
                  ),
                  pw.Text(
                    'Austrian Airlines Ground Staff Roster System v1.0',
                    style: pw.TextStyle(
                        fontSize: 8, color: PdfColor.fromHex('#666666')),
                  ),
                  pw.Text(
                    'Zeitraum: ${_formatDateForPDF(startDate)} - ${_formatDateForPDF(endDate.subtract(Duration(days: 1)))}',
                    style: pw.TextStyle(
                        fontSize: 8, color: PdfColor.fromHex('#666666')),
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
