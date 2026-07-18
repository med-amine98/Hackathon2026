// lib/services/pdf_service.dart

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PdfService {
  static Future<File> generateConstatPDF(Map<String, dynamic> constatData) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              pw.SizedBox(height: 20),
              _buildTitle(),
              pw.SizedBox(height: 16),
              _buildInfoSection(constatData),
              pw.SizedBox(height: 16),
              _buildDescriptionSection(constatData),
              pw.SizedBox(height: 16),
              _buildSignatureSection(),
              pw.SizedBox(height: 16),
              _buildFooter(),
            ],
          );
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/constat_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  static Future<void> sharePDF(Map<String, dynamic> constatData) async {
    final file = await generateConstatPDF(constatData);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: '📋 Constat amiable d\'accident automobile',
    );
  }

  static pw.Widget _buildHeader() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'ASSURIA',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue700,
              ),
            ),
            pw.Text(
              'Assurance Intelligente',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            'N° ${DateTime.now().millisecondsSinceEpoch.toString().substring(8, 13)}',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTitle() {
    return pw.Column(
      children: [
        pw.Text(
          'CONSTAT AMIABLE D\'ACCIDENT AUTOMOBILE',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 4),
        pw.Container(height: 2, color: PdfColors.blue300),
        pw.SizedBox(height: 8),
        pw.Text(
          'Article L. 211-1 du Code des assurances',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
        ),
      ],
    );
  }

  static pw.Widget _buildInfoSection(Map<String, dynamic> constatData) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildInfoRow('📅 Date', constatData['date']?.toString() ?? 'Non renseigné'),
        _buildInfoRow('⏰ Heure', constatData['time']?.toString() ?? 'Non renseigné'),
        _buildInfoRow('📍 Lieu', constatData['location']?.toString() ?? 'Non renseigné'),
        _buildInfoRow('🚗 Véhicule', constatData['vehicle']?.toString() ?? 'Non renseigné'),
        _buildInfoRow('👤 Conducteur', constatData['driver']?.toString() ?? 'Non renseigné'),
      ],
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDescriptionSection(Map<String, dynamic> constatData) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '📝 Description de l\'accident',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Text(
            constatData['description']?.toString() ?? 'Non renseigné',
            style: pw.TextStyle(fontSize: 12, height: 1.5),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSignatureSection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '✍️ Signature électronique',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Column(
                children: [
                  pw.Container(height: 1, color: PdfColors.black),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Signature du conducteur',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 20),
            pw.Expanded(
              child: pw.Column(
                children: [
                  pw.Container(height: 1, color: PdfColors.black),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Signature de l\'assureur',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          color: PdfColors.green100,
          child: pw.Row(
            children: [
              pw.Icon(pw.IconData(0xE876), color: PdfColors.green700),
              pw.SizedBox(width: 8),
              pw.Text(
                '✅ Document signé électroniquement',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.green700,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              '© ${DateTime.now().year} AssurIA - Tous droits réservés',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Document généré par intelligence artificielle',
          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey400),
        ),
      ],
    );
  }
}