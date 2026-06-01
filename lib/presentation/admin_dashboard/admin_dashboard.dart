import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/admin_report_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  DateTime _start = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _end = DateTime.now();
  bool _isLoading = true;
  Map<String, dynamic> _report = {};
  List<Map<String, dynamic>> _insights = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final report = await AdminReportService.instance.getTotalReport(
        start: _start,
        end: _end,
      );
      final insights = await AdminReportService.instance.getAiInsights();
      if (!mounted) return;
      setState(() {
        _report = report;
        _insights = insights;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() => _start = picked);
    await _load();
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _end,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() => _end = picked);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard admin')),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                SizedBox(height: 2.h),
                ElevatedButton(
                    onPressed: _load, child: const Text('Réessayer')),
              ],
            ),
          ),
        ),
      );
    }

    final sales = Map<String, dynamic>.from(_report['sales'] as Map? ?? {});
    final finance = Map<String, dynamic>.from(_report['finance'] as Map? ?? {});
    final operations =
        Map<String, dynamic>.from(_report['operations'] as Map? ?? {});
    final daily =
        List<Map<String, dynamic>>.from(sales['daily'] as List? ?? []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard admin'),
        actions: [
          IconButton(
            onPressed: () =>
                AdminReportService.instance.exportReportPdf(_report),
            icon: const Icon(Icons.picture_as_pdf),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/ai-assistant'),
            icon: const Icon(Icons.auto_awesome),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: EdgeInsets.all(4.w),
          children: [
            Wrap(
              spacing: 2.w,
              children: [
                ActionChip(
                  label: Text('Début ${_formatDate(_start)}'),
                  onPressed: _pickStart,
                ),
                ActionChip(
                  label: Text('Fin ${_formatDate(_end)}'),
                  onPressed: _pickEnd,
                ),
              ],
            ),
            SizedBox(height: 2.h),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.25,
              crossAxisSpacing: 2.w,
              mainAxisSpacing: 2.w,
              children: [
                _metric('Ventes', sales['revenue_cdf'], 'CDF', Icons.sell),
                _metric('Résultat net', finance['net_profit_cdf'], 'CDF',
                    Icons.trending_up),
                _metric('Dépenses', finance['expenses_cdf'], 'CDF',
                    Icons.receipt_long),
                _metric('Achats', finance['purchase_cost_cdf'], 'CDF',
                    Icons.shopping_bag),
                _metric('Créances', operations['receivables_cdf'], 'CDF',
                    Icons.warning_amber),
                _metric('Stock', operations['stock_value_cdf'], 'CDF',
                    Icons.inventory_2),
                _metric('Caisse', operations['cash_balance_cdf'], 'CDF',
                    Icons.point_of_sale),
                _metric('Banques', operations['bank_balance_cdf'], 'CDF',
                    Icons.account_balance),
              ],
            ),
            SizedBox(height: 3.h),
            Text('Évolution des ventes', style: theme.textTheme.titleMedium),
            SizedBox(height: 180, child: _salesChart(daily)),
            SizedBox(height: 3.h),
            Text('Analyses IA', style: theme.textTheme.titleMedium),
            ..._insights.map((insight) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.auto_awesome),
                    title: Text(insight['title'] ?? ''),
                    subtitle: Text(insight['description'] ?? ''),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _metric(String title, dynamic value, String suffix, IconData icon) {
    final number = (value as num?)?.toDouble() ?? 0;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const Spacer(),
            Text(title),
            Text(
              '${number.toStringAsFixed(0)} $suffix',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _salesChart(List<Map<String, dynamic>> daily) {
    if (daily.isEmpty) return const Center(child: Text('Aucune vente'));
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < daily.length; i++)
                FlSpot(
                  i.toDouble(),
                  ((daily[i]['revenue_cdf'] as num?)?.toDouble() ?? 0),
                ),
            ],
            isCurved: true,
            barWidth: 3,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
