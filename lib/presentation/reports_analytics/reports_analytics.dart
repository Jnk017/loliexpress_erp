import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../services/reports_analytics_service.dart';
import './widgets/chart_widget.dart';
import './widgets/date_range_selector_widget.dart';
import './widgets/kpi_widget.dart';
import './widgets/purchases_report_widget.dart';
import './widgets/receivables_report_widget.dart';
import './widgets/report_card_widget.dart';

class ReportsAnalyticsScreen extends StatefulWidget {
  const ReportsAnalyticsScreen({super.key, this.openExport = false});

  final bool openExport;

  @override
  State<ReportsAnalyticsScreen> createState() => _ReportsAnalyticsScreenState();
}

class _ReportsAnalyticsScreenState extends State<ReportsAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String _selectedDateRange = 'Ce mois';
  final bool _isLiveUpdatesEnabled = true;

  // Service instance
  final ReportsAnalyticsService _analyticsService = ReportsAnalyticsService();

  // Real-time data
  Map<String, dynamic>? _salesMetrics;
  Map<String, dynamic>? _inventoryMetrics;
  Map<String, dynamic>? _financialMetrics;
  Map<String, dynamic>? _customerMetrics;
  Map<String, dynamic>? _agingReport;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _initializeRealtimeData();
  }

  /// Initialize real-time subscriptions and load initial data
  Future<void> _initializeRealtimeData() async {
    setState(() => _isLoading = true);

    try {
      // Initialize WebSocket subscriptions
      await _analyticsService.initializeRealtimeSubscriptions();

      // Listen to real-time streams
      _analyticsService.salesMetricsStream.listen((metrics) {
        if (mounted && _isLiveUpdatesEnabled) {
          setState(() => _salesMetrics = metrics);
        }
      });

      _analyticsService.inventoryMetricsStream.listen((metrics) {
        if (mounted && _isLiveUpdatesEnabled) {
          setState(() => _inventoryMetrics = metrics);
        }
      });

      _analyticsService.financialMetricsStream.listen((metrics) {
        if (mounted && _isLiveUpdatesEnabled) {
          setState(() => _financialMetrics = metrics);
        }
      });

      _analyticsService.customerMetricsStream.listen((metrics) {
        if (mounted && _isLiveUpdatesEnabled) {
          setState(() => _customerMetrics = metrics);
        }
      });

      _analyticsService.agingReportStream.listen((report) {
        if (mounted && _isLiveUpdatesEnabled) {
          setState(() => _agingReport = report);
        }
      });

      // Load initial data
      await _refreshAllData();
    } catch (e) {
      debugPrint('Error initializing realtime data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        if (widget.openExport) _showExportOptions();
      }
    }
  }

  /// Refresh all analytics data
  Future<void> _refreshAllData() async {
    await Future.wait([
      _analyticsService.refreshSalesMetrics(),
      _analyticsService.refreshInventoryMetrics(),
      _analyticsService.refreshFinancialMetrics(),
      _analyticsService.refreshCustomerMetrics(),
      _analyticsService.refreshAgingReport(),
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _analyticsService.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await _refreshAllData();
    setState(() => _isLoading = false);
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.picture_as_pdf, color: Colors.red),
              title: Text('Exporter en PDF'),
              onTap: () {
                Navigator.pop(context);
                _exportToPDF();
              },
            ),
            ListTile(
              leading: Icon(Icons.table_chart, color: Colors.green),
              title: Text('Exporter en CSV'),
              onTap: () {
                Navigator.pop(context);
                _exportToCSV();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomReportBuilder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Générer un Rapport Personnalisé'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Type de Rapport'),
              items: [
                'Ventes',
                'Inventaire',
                'Financier',
                'Client',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (value) {},
            ),
            SizedBox(height: 2.h),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Type de Graphique'),
              items: [
                'Graphique à Barres',
                'Graphique en Lignes',
                'Graphique Circulaire',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Génération du rapport personnalisé...')),
              );
            },
            child: Text('Générer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Rapports et analyses',
        root: true,
        actions: [
          // Live updates indicator
          Container(
            margin: EdgeInsets.symmetric(horizontal: 2.w),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isLiveUpdatesEnabled ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 1.w),
                Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: _isLiveUpdatesEnabled ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.file_download),
            onPressed: _showExportOptions,
            tooltip: 'Exporter',
          ),
          IconButton(icon: Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(3.w),
              child: Column(
                children: [
                  DateRangeSelectorWidget(
                    selectedRange: _selectedDateRange,
                    onRangeChanged: (range) {
                      setState(() => _selectedDateRange = range);
                    },
                  ),
                  SizedBox(height: 2.h),
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: Theme.of(context).primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Theme.of(context).primaryColor,
                    tabs: [
                      Tab(text: 'Rapports'),
                      Tab(text: 'Ventes'),
                      Tab(text: 'Inventaire'),
                      Tab(text: 'Financier'),
                      Tab(text: 'Client'),
                      Tab(text: 'Créances'),
                      Tab(text: 'Achats'),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildReportsTab(),
                        _buildSalesTab(),
                        _buildInventoryTab(),
                        _buildFinancialTab(),
                        _buildCustomerTab(),
                        const ReceivablesReportWidget(),
                        const PurchasesReportWidget(),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCustomReportBuilder,
        icon: Icon(Icons.add_chart),
        label: Text('Rapport Personnalisé'),
      ),
      bottomNavigationBar: CustomBottomBar(currentIndex: 0),
    );
  }

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Indicateurs Clés de Performance',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              if (_financialMetrics != null)
                Text(
                  'Updated: ${_formatTimestamp(_financialMetrics!['timestamp'])}',
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: KPIWidget(
                  title: 'Revenu Total',
                  value:
                      '\$${_financialMetrics?['totalRevenue']?.toStringAsFixed(0) ?? '0'}',
                  change: '+12.5%',
                  isPositive: true,
                  icon: Icons.attach_money,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: KPIWidget(
                  title: 'Marge Brute',
                  value:
                      '${_financialMetrics?['profitMargin']?.toStringAsFixed(1) ?? '0'}%',
                  change: '+2.1%',
                  isPositive: true,
                  icon: Icons.trending_up,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: KPIWidget(
                  title: 'Profit Net',
                  value:
                      '\$${_financialMetrics?['netProfit']?.toStringAsFixed(0) ?? '0'}',
                  change: '+8.3%',
                  isPositive: true,
                  icon: Icons.account_balance_wallet,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: KPIWidget(
                  title: 'Dépenses Totales',
                  value:
                      '\$${_financialMetrics?['totalExpenses']?.toStringAsFixed(0) ?? '0'}',
                  change: '-3.2%',
                  isPositive: true,
                  icon: Icons.production_quantity_limits,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Text(
            'Graphiques de Performance',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2.h),
          ChartWidget(
            title: 'Performance des Ventes',
            chartType: 'line',
            data: _salesMetrics?['chartData'] ?? [],
          ),
          SizedBox(height: 2.h),
          ChartWidget(
            title: 'Rotation des Stocks',
            chartType: 'bar',
            data: _inventoryMetrics?['stockLevels'] ?? [],
          ),
        ],
      ),
    );
  }

  Widget _buildSalesTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        children: [
          if (_salesMetrics != null)
            Text(
              'Live data updated: ${_formatTimestamp(_salesMetrics!['timestamp'])}',
              style: TextStyle(fontSize: 10.sp, color: Colors.green),
            ),
          SizedBox(height: 1.h),
          ChartWidget(
            title: 'Tendance des Ventes',
            chartType: 'line',
            data: _salesMetrics?['chartData'] ?? [],
          ),
          SizedBox(height: 2.h),
          ReportCardWidget(
            title: 'Ventes par Catégorie de Produit',
            subtitle: 'Catégories les plus performantes',
            icon: Icons.category,
            onTap: () => _showReportDetail(
              'Ventes par Catégorie de Produit',
              'Répartition des ventes par catégorie de produits.\n\n'
                  'Total ventes: ${_salesMetrics?['totalSales'] ?? 0} FC\n'
                  'Catégories actives: ${_salesMetrics?['activeCategories'] ?? 'N/A'}',
            ),
          ),
          SizedBox(height: 2.h),
          ReportCardWidget(
            title: 'Ventes par Représentant',
            subtitle: 'Performance de l\'équipe commerciale',
            icon: Icons.people,
            onTap: () => _showReportDetail(
              'Ventes par Représentant',
              'Performance de l\'équipe de vente.\n\n'
                  'Nombre de transactions: ${_salesMetrics?['transactionCount'] ?? 0}\n'
                  'Vente moyenne: ${_salesMetrics?['averageSale'] ?? 0} FC',
            ),
          ),
          SizedBox(height: 2.h),
          ReportCardWidget(
            title: 'Prévisions de Ventes',
            subtitle: 'Ventes prévues pour la prochaine période',
            icon: Icons.insights,
            onTap: () => _showReportDetail(
              'Prévisions de Ventes',
              'Prévisions de vente pour la prochaine période.\n\n'
                  'Tendance actuelle: ${_salesMetrics?['trend'] ?? 'Stable'}\n'
                  'Estimation: ${(_salesMetrics?['totalSales'] ?? 0) * 1.1} FC',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        children: [
          if (_inventoryMetrics != null)
            Text(
              'Live data updated: ${_formatTimestamp(_inventoryMetrics!['timestamp'])}',
              style: TextStyle(fontSize: 10.sp, color: Colors.green),
            ),
          SizedBox(height: 1.h),
          ChartWidget(
            title: 'Niveaux de Stock',
            chartType: 'bar',
            data: _inventoryMetrics?['stockLevels'] ?? [],
          ),
          SizedBox(height: 2.h),
          ReportCardWidget(
            title: 'Analyse de Rotation des Stocks',
            subtitle: 'Articles à rotation rapide vs lente',
            icon: Icons.inventory,
            onTap: () => _showReportDetail(
              'Analyse de Rotation des Stocks',
              'Analyse de rotation des stocks.\n\n'
                  'Produits total: ${_inventoryMetrics?['totalProducts'] ?? 0}\n'
                  'Ruptures de stock: ${_inventoryMetrics?['outOfStock'] ?? 0}\n'
                  'Stock faible: ${_inventoryMetrics?['lowStock'] ?? 0}',
            ),
          ),
          SizedBox(height: 2.h),
          ReportCardWidget(
            title: 'Rapport d\'Évaluation du Stock',
            subtitle: 'Valeur actuelle du stock',
            icon: Icons.monetization_on,
            onTap: () => _showReportDetail(
              'Rapport d\'Évaluation du Stock',
              'Évaluation de la valeur du stock.\n\n'
                  'Valeur totale: ${_inventoryMetrics?['totalValue'] ?? 0} FC\n'
                  'Produits en stock: ${_inventoryMetrics?['totalProducts'] ?? 0}',
            ),
          ),
          SizedBox(height: 2.h),
          ReportCardWidget(
            title: 'Performance Entrepôt',
            subtitle: 'Analyse multi-sites',
            icon: Icons.warehouse,
            onTap: () => _showReportDetail(
              'Performance Entrepôt',
              'Analyse multi-entrepôt.\n\n'
                  'Taux de rotation: ${_inventoryMetrics?['turnoverRate'] ?? 'N/A'}\n'
                  'Efficacité: ${_inventoryMetrics?['efficiency'] ?? 'N/A'}%',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        children: [
          if (_agingReport != null)
            Text(
              'Aging report updated: ${_formatTimestamp(_agingReport!['timestamp'])}',
              style: TextStyle(fontSize: 10.sp, color: Colors.green),
            ),
          SizedBox(height: 1.h),
          ChartWidget(
            title: 'Flux de Trésorerie',
            chartType: 'line',
            data: [],
          ),
          SizedBox(height: 2.h),
          // Display aging report data
          if (_agingReport != null) ...[
            Card(
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vieillissement des Comptes Clients',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    _buildAgingBucket('Courant',
                        _agingReport!['agingTotals']['current'] ?? 0),
                    _buildAgingBucket('Retard 30 jours',
                        _agingReport!['agingTotals']['30-day'] ?? 0),
                    _buildAgingBucket('Retard 60 jours',
                        _agingReport!['agingTotals']['60-day'] ?? 0),
                    _buildAgingBucket('Retard 90+ jours',
                        _agingReport!['agingTotals']['90-day'] ?? 0),
                    Divider(),
                    _buildAgingBucket(
                        'Total Impayé', _agingReport!['totalOutstanding'] ?? 0,
                        isBold: true),
                  ],
                ),
              ),
            ),
            SizedBox(height: 2.h),
          ],
          ReportCardWidget(
            title: 'Compte de Résultat',
            subtitle: 'Détail des revenus et dépenses',
            icon: Icons.account_balance,
            onTap: () => _showReportDetail(
              'Compte de Résultat',
              'Compte de résultat.\n\n'
                  'Revenu Total: ${_financialMetrics?['totalRevenue'] ?? 0} FC\n'
                  'Dépenses Totales: ${_financialMetrics?['totalExpenses'] ?? 0} FC\n'
                  'Profit Net: ${_financialMetrics?['netProfit'] ?? 0} FC\n'
                  'Marge: ${_financialMetrics?['profitMargin'] ?? 0}%',
            ),
          ),
          SizedBox(height: 2.h),
          ReportCardWidget(
            title: 'Analyse des Dépenses',
            subtitle: 'Dépenses par catégorie',
            icon: Icons.pie_chart,
            onTap: () => _showReportDetail(
              'Analyse des Dépenses',
              'Analyse des dépenses par catégorie.\n\n'
                  'Dépenses Totales: ${_financialMetrics?['totalExpenses'] ?? 0} FC\n'
                  'Ratio dépenses/revenu: ${_financialMetrics?['totalRevenue'] != null && _financialMetrics!['totalRevenue'] != 0 ? ((_financialMetrics!['totalExpenses'] ?? 0) / _financialMetrics!['totalRevenue'] * 100).toStringAsFixed(1) : 'N/A'}%',
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'Créances',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          SizedBox(
            height: 400,
            child: const ReceivablesReportWidget(),
          ),
          SizedBox(height: 3.h),
          Text(
            'Rapport Achats',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          SizedBox(
            height: 500,
            child: const PurchasesReportWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        children: [
          if (_customerMetrics != null)
            Text(
              'Live data updated: ${_formatTimestamp(_customerMetrics!['timestamp'])}',
              style: TextStyle(fontSize: 10.sp, color: Colors.green),
            ),
          SizedBox(height: 1.h),
          ChartWidget(
            title: 'Acquisition Clients',
            chartType: 'bar',
            data: [],
          ),
          SizedBox(height: 2.h),
          ReportCardWidget(
            title: 'Segmentation des Clients',
            subtitle: 'Clients haute, moyenne, faible valeur',
            icon: Icons.pie_chart_outline,
            onTap: () => _showReportDetail(
              'Segmentation des Clients',
              'Segmentation des clients.\n\n'
                  'Total clients: ${_customerMetrics?['totalCustomers'] ?? 0}\n'
                  'Clients actifs: ${_customerMetrics?['activeCustomers'] ?? 0}\n'
                  'Nouveaux ce mois: ${_customerMetrics?['newThisMonth'] ?? 0}',
            ),
          ),
          SizedBox(height: 2.h),
          ReportCardWidget(
            title: 'Valeur Vie Client',
            subtitle: 'Revenu total par client',
            icon: Icons.person_outline,
            onTap: () => _showReportDetail(
              'Valeur Vie Client',
              'Valeur vie client (CLV).\n\n'
                  'CLV moyen: ${_customerMetrics?['averageCLV'] ?? 'N/A'} FC\n'
                  'Panier moyen: ${_customerMetrics?['averageOrderValue'] ?? 'N/A'} FC',
            ),
          ),
          SizedBox(height: 2.h),
          ReportCardWidget(
            title: 'Taux de Rétention Client',
            subtitle: 'Analyse des achats récurrents',
            icon: Icons.repeat,
            onTap: () => _showReportDetail(
              'Taux de Rétention Client',
              'Taux de rétention des clients.\n\n'
                  'Taux de rétention: ${_customerMetrics?['retentionRate'] ?? 'N/A'}%\n'
                  'Clients récurrents: ${_customerMetrics?['returningCustomers'] ?? 0}',
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDetail(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(content, style: TextStyle(fontSize: 12.sp)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _exportToPDF();
            },
            icon: const Icon(Icons.picture_as_pdf, size: 18),
            label: const Text('Exporter PDF'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToPDF() async {
    if (_financialMetrics == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les données financières sont indisponibles.')),
      );
      return;
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Header(level: 0, text: 'LoliExpress - Rapport Analytique'),
            pw.Header(
                level: 1,
                text: 'Date: ${DateTime.now().toString().substring(0, 10)}'),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['Indicateur', 'Valeur'],
              data: [
                [
                  'Revenu Total',
                  '${_financialMetrics?['totalRevenue'] ?? 0} FC'
                ],
                ['Marge Brute', '${_financialMetrics?['profitMargin'] ?? 0}%'],
                ['Profit Net', '${_financialMetrics?['netProfit'] ?? 0} FC'],
                [
                  'Dépenses Totales',
                  '${_financialMetrics?['totalExpenses'] ?? 0} FC'
                ],
              ],
            ),
          ],
        ),
      ),
    );
    await Printing.sharePdf(
        bytes: await pdf.save(), filename: 'rapport_loliexpress.pdf');
  }

  Future<void> _exportToCSV() async {
    if (_financialMetrics == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les données financières sont indisponibles.')),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('Indicateur,Valeur,Devise');
    buffer
        .writeln('Revenu Total,${_financialMetrics?['totalRevenue'] ?? 0},FC');
    buffer.writeln('Marge Brute,${_financialMetrics?['profitMargin'] ?? 0},%');
    buffer.writeln('Profit Net,${_financialMetrics?['netProfit'] ?? 0},FC');
    buffer.writeln(
        'Dépenses Totales,${_financialMetrics?['totalExpenses'] ?? 0},FC');

    await SharePlus.instance.share(ShareParams(
        files: [XFile.fromData(Uint8List.fromList(utf8.encode(buffer.toString())), mimeType: 'text/csv')],
        fileNameOverrides: const ['rapport_loliexpress.csv'], subject: 'Rapport LoliExpress CSV'));
  }

  Widget _buildAgingBucket(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: amount > 0 ? Colors.red : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inSeconds < 60) {
        return '${diff.inSeconds}s ago';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m ago';
      } else {
        return '${diff.inHours}h ago';
      }
    } catch (e) {
      return 'N/A';
    }
  }
}
