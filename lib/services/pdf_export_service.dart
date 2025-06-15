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

      // Create filename with timestamp
      final timestamp =
          DateTime.now().toString().replaceAll(':', '-').substring(0, 19);
      final filename = 'Austrian_Airlines_Dienstplan_Juli_2024_$timestamp.pdf';

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

      // Create filename with timestamp
      final timestamp =
          DateTime.now().toString().replaceAll(':', '-').substring(0, 19);
      final filename = 'Austrian_Airlines_Dienstplan_Juli_2024_$timestamp.pdf';
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

  // Generate PDF document
  Future<pw.Document> _generatePDF(
      List<WorkDay> days, WorkRosterData rosterData) async {
    final pdf = pw.Document();
    final workingDays = days.where((d) => d.hasWork).length;
    final totalHours = rosterData.getTotalHours();

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
                        'Crew Roster System',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    'DIENSTPLAN JULI 2024',
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
            pw.Container(
              padding: pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColor.fromHex('#E0E0E0')),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'CREW INFORMATION',
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    children: [
                      pw.Expanded(child: pw.Text('Name: [Zu ergänzen]')),
                      pw.Expanded(
                          child: pw.Text('Mitarbeiter-Nr: [Zu ergänzen]')),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    children: [
                      pw.Expanded(child: pw.Text('Abteilung: Cabin Crew')),
                      pw.Expanded(child: pw.Text('Periode: Juli 2024')),
                    ],
                  ),
                ],
              ),
            ),

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
                    'MONATSÜBERSICHT',
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      pw.Column(
                        children: [
                          pw.Text('31',
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
                          pw.Text('${31 - workingDays}',
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
                      child: pw.Text('Tag',
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
                // Data rows
                ...List.generate(days.length, (index) {
                  final day = days[index];
                  final dayNumber = index + 1;
                  final dayName = _getDayNameGerman(dayNumber);
                  final isWeekend = _isWeekendDay(dayNumber);

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
                        child: pw.Text('$dayNumber. Juli',
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
                              ? day.shifts.map((s) => s.interval).join('\n')
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
                    'Austrian Airlines Crew Roster System v1.0',
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

  String _getDayNameGerman(int dayNumber) {
    final days = [
      'Montag',
      'Dienstag',
      'Mittwoch',
      'Donnerstag',
      'Freitag',
      'Samstag',
      'Sonntag'
    ];
    return days[(dayNumber - 1) % 7];
  }

  bool _isWeekendDay(int dayNumber) {
    final dayOfWeek = (dayNumber - 1) % 7;
    return dayOfWeek == 5 || dayOfWeek == 6;
  }
}
