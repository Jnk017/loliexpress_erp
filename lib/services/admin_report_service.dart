import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminReportService {
  static AdminReportService? _instance;
  static AdminReportService get instance =>
      _instance ??= AdminReportService._();
  AdminReportService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<Map<String, dynamic>> getTotalReport({
    required DateTime start,
    required DateTime end,
  }) async {
    final response = await _client.rpc(
      'get_admin_total_report',
      params: {
        'p_start': start.toIso8601String(),
        'p_end': end.toIso8601String(),
      },
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<List<Map<String, dynamic>>> getAiInsights() async {
    final response = await _client
        .from('ai_insights')
        .select('*')
        .order('generated_at', ascending: false)
        .limit(20);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> exportReportPdf(Map<String, dynamic> report) async {
    final bytes = await buildReportPdf(report);
    await Printing.sharePdf(bytes: bytes, filename: 'rapport_admin.pdf');
  }

  Future<Uint8List> buildReportPdf(Map<String, dynamic> report) async {
    final pdf = pw.Document();
    final sales = Map<String, dynamic>.from(report['sales'] as Map? ?? {});
    final finance = Map<String, dynamic>.from(report['finance'] as Map? ?? {});
    final operations =
        Map<String, dynamic>.from(report['operations'] as Map? ?? {});

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text('Rapport admin LoliExpress ERP',
              style:
                  pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 16),
          _pdfMetric('Chiffre d’affaires CDF', sales['revenue_cdf']),
          _pdfMetric('Bénéfice net CDF', finance['net_profit_cdf']),
          _pdfMetric('Dépenses CDF', finance['expenses_cdf']),
          _pdfMetric('Achats CDF', finance['purchase_cost_cdf']),
          _pdfMetric('Créances CDF', operations['receivables_cdf']),
          _pdfMetric('Valeur stock CDF', operations['stock_value_cdf']),
          _pdfMetric('Caisse CDF', operations['cash_balance_cdf']),
          _pdfMetric('Banques CDF', operations['bank_balance_cdf']),
        ],
      ),
    );
    return pdf.save();
  }

  pw.Widget _pdfMetric(String label, dynamic value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text('${(value as num?)?.toStringAsFixed(2) ?? value ?? 0}'),
        ],
      ),
    );
  }
}
