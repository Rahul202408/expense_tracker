import 'dart:io';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/transaction_model.dart';
import 'firebase_analytics_service.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  /// Export transactions to PDF and open print/share sheet
  Future<void> exportToPdf({
    required List<TransactionModel> transactions,
    required String currencySymbol,
    String? userEmail,
  }) async {
    final pdf = pw.Document();

    final dateFormat = DateFormat('dd MMM yyyy');
    final timeFormat = DateFormat('hh:mm a');

    double totalIncome = 0;
    double totalExpense = 0;

    for (var t in transactions) {
      if (t.isExpense) {
        totalExpense += t.amount;
      } else {
        totalIncome += t.amount;
      }
    }

    final netBalance = totalIncome - totalExpense;

    // Standard PDF fonts do not support the Unicode Rupee sign (U+20B9), resulting in missing-glyph boxes.
    // Convert Rupee to 'Rs.' so it renders cleanly and professionally across all PDF viewers.
    final String displayCurrency =
        (currencySymbol == '₹' || currencySymbol.contains('₹') || currencySymbol.contains('â‚¹'))
            ? 'Rs.'
            : currencySymbol;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Expense Tracker Report',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Generated on: ${DateFormat('dd MMMM yyyy, hh:mm a').format(DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                    if (userEmail != null && userEmail.isNotEmpty)
                      pw.Text(
                        'Account: $userEmail',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.amber100,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text(
                    'PRO STATEMENT',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.amber900,
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Summary Cards
            pw.Row(
              children: [
                _buildSummaryBox('Total Income', '$displayCurrency ${totalIncome.toStringAsFixed(2)}', PdfColors.green800, PdfColors.green50),
                pw.SizedBox(width: 12),
                _buildSummaryBox('Total Expense', '$displayCurrency ${totalExpense.toStringAsFixed(2)}', PdfColors.red800, PdfColors.red50),
                pw.SizedBox(width: 12),
                _buildSummaryBox('Net Balance', '$displayCurrency ${netBalance.toStringAsFixed(2)}', PdfColors.blue800, PdfColors.blue50),
              ],
            ),
            pw.SizedBox(height: 24),

            // Table of Transactions
            pw.Text(
              'Transactions (${transactions.length})',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),

            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Title', 'Category', 'Type', 'Amount'],
              data: transactions.map((t) {
                return [
                  '${dateFormat.format(t.date)}\n${timeFormat.format(t.date)}',
                  t.title,
                  t.category,
                  t.isExpense ? 'Expense' : 'Income',
                  '${t.isExpense ? '-' : '+'} $displayCurrency ${t.amount.toStringAsFixed(2)}',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                4: pw.Alignment.centerRight,
              },
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
              ),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),

            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Text(
                'Expense Tracker: Money Manager - End of Report',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
              ),
            ),
          ];
        },
      ),
    );

    final Uint8List bytes = await pdf.save();
    FirebaseAnalyticsService().logExportReport('pdf');
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Expense_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  pw.Widget _buildSummaryBox(String title, String amount, PdfColor textColor, PdfColor bgColor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: textColor, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 10, color: textColor)),
            pw.SizedBox(height: 4),
            pw.Text(
              amount,
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: textColor),
            ),
          ],
        ),
      ),
    );
  }

  /// Export transactions to CSV and share
  Future<void> exportToCsv({
    required List<TransactionModel> transactions,
    required String currencySymbol,
  }) async {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    List<List<dynamic>> rows = [
      ['ID', 'Date', 'Title', 'Category', 'Type', 'Amount', 'Currency']
    ];

    for (var t in transactions) {
      rows.add([
        t.id,
        dateFormat.format(t.date),
        t.title,
        t.category,
        t.isExpense ? 'Expense' : 'Income',
        t.amount,
        currencySymbol,
      ]);
    }

    final String csvData = const ListToCsvConverter().convert(rows);

    final directory = await getTemporaryDirectory();
    final String filePath =
        '${directory.path}/Expense_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
    final File file = File(filePath);
    await file.writeAsString(csvData);

    FirebaseAnalyticsService().logExportReport('csv');

    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'Expense Tracker CSV Report',
    );
  }
}
