import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../theme/app_theme.dart';

class HistoryPdfExport {
  static Future<void> exportEntry({
    required Map<String, dynamic> entry,
    required double balanceAfter,
  }) async {
    final photoPath = entry['photoPath'] as String?;
    if (photoPath == null || photoPath.isEmpty) {
      throw Exception('This has no photo proof attached.');
    }

    final imageFile = File(photoPath);
    if (!await imageFile.exists()) {
      throw Exception('The attached photo could not be found.');
    }
    final imageBytes = await imageFile.readAsBytes();
    final pdfImage = pw.MemoryImage(imageBytes);

    final isExpense = entry['type'] == 'EXPENSE';
    final amount = entry['amount'] as double;
    final desc = entry['desc'] as String;
    final time = entry['time'] as DateTime;
    final category = entry['category'] as String?;
    final notes = entry['notes'] as String?;

    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(28),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text(
                  'CSO Finance',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  isExpense ? 'Expense Record' : 'Funding Source Record',
                  style: const pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 18),
                _row('Generated', formatDateTime(DateTime.now())),
                _row('Date', formatDateTime(time)),
                if (category != null) _row('Category', category),
                pw.SizedBox(height: 8),
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 8),
                _row(
                  desc,
                  '${isExpense ? '-' : '+'}${formatCurrency(amount)}',
                  bold: true,
                ),
                if (notes != null && notes.trim().isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    notes,
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
                pw.SizedBox(height: 4),
                _row(
                  isExpense ? 'Category Balance' : 'Total Funds',
                  formatCurrency(balanceAfter),
                ),
                pw.SizedBox(height: 22),
                pw.Text(
                  'Photo Proof',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  width: double.infinity,
                  height: 340,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
                ),
              ],
            ),
          );
        },
      ),
    );

    final bytes = await doc.save();
    final tempDir = await getTemporaryDirectory();
    final fileName =
        'CSO_${isExpense ? 'Expense' : 'Funding'}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(file.path)], text: 'CSO Finance — $desc');
  }

  static pw.Widget _row(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
