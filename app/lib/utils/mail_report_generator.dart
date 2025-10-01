import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../model/mail_analysis.dart';

class MailReportGenerator {
  const MailReportGenerator._();

  static Future<Uint8List> buildReport(MailAnalysis mail) async {
    final doc = pw.Document();
    final formattedDate = _formatDate(mail.analyzedAt);
    final indicators = mail.buildSampleIndicators();

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
        ),
        build: (context) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Rapport d\'analyse d\'email',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 16),
              pw.Text('Objet : ${mail.subject}', style: const pw.TextStyle(fontSize: 16)),
              pw.Text('Expéditeur : ${mail.sender}'),
              pw.Text('Date d\'analyse : $formattedDate'),
              pw.SizedBox(height: 12),
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                padding: const pw.EdgeInsets.all(12),
                child: pw.Text(mail.summary),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Score de maliciousness : ${mail.maliciousnessScore}%',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: mail.maliciousnessScore >= 60 ? PdfColors.red : PdfColors.blueGrey800,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text('Indicateurs générés :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              ...indicators.map(
                (indicator) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('• ', style: const pw.TextStyle(fontSize: 14)),
                      pw.Expanded(child: pw.Text(indicator)),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Notes complémentaires', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text(
                'Analyse générée automatiquement pour les besoins de la démonstration. '
                'Les données chiffrées et conclusions sont aléatoires.',
              ),
            ],
          ),
        ],
      ),
    );

    return doc.save();
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}
