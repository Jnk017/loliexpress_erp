import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../services/reports_analytics_service.dart';
import './widgets/chart_widget.dart';
import './widgets/date_range_selector_widget.dart';
import './widgets/kpi_widget.dart';
import './widgets/report_card_widget.dart';

class ReportsAnalyticsScreen extends StatefulWidget {
  const ReportsAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsAnalyticsScreen> createState() => _ReportsAnalyticsScreenState();
}

class _ReportsAnalyticsScreenState extends State<ReportsAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String _selectedDateRange = 'This Month';
  bool _isLiveUpdatesEnabled = true;

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
    _tabController = TabController(length: 5, vsync: this);
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
      print('Error initializing realtime data: $e');
    } finally {
      setState(() => _isLoading = false);
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
              title: Text('Export as PDF'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Exporting as PDF...')));
              },
            ),
            ListTile(
              leading: Icon(Icons.table_chart, color: Colors.green),
              title: Text('Export as Excel'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Exporting as Excel...')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.email, color: Colors.blue),
              title: Text('Email Report'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Preparing email...')));
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
        title: Text('Generate Custom Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Report Type'),
              items: [
                'Sales',
                'Inventory',
                'Financial',
                'Customer',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (value) {},
            ),
            SizedBox(height: 2.h),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Chart Type'),
              items: [
                'Bar Chart',
                'Line Chart',
                'Pie Chart',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Generating custom report...')),
              );
            },
            child: Text('Generate'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Reports & Analytics',
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
            tooltip: 'Export',
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
                      Tab(text: 'Reports'),
                      Tab(text: 'Sales'),
                      Tab(text: 'Inventory'),
                      Tab(text: 'Financial'),
                      Tab(text: 'Customer'),
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
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCustomReportBuilder,
        icon: Icon(Icons.add_chart),
        label: Text('Custom Report'),
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
                'Key Performance Indicators',
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
                  title: 'Total Revenue',
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
                  title: 'Gross Margin',
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
                  title: 'Net Profit',
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
                  title: 'Total Expenses',
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
            'Performance Charts',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2.h),
          ChartWidget(
            title: 'Sales Performance',
            chartType: 'line',
            data: _salesMetrics?['chartData'] ?? [],
          ),
          SizedBox(height: 2.h),
          ChartWidget(
            title: 'Inventory Turnover',
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
            title: 'Sales Trend',
            chartType: 'line',
            data: _salesMetrics?['chartData'] ?? [],
          ),
          SizedBox(height: 2.h),
          ReportCardWidget(
            title: 'Sales by Product Category',
            subtitle: 'Top performing categories',
            icon: Icons.category,
            onTap: () {},
          ),
          SizedBox(height: 2.h),
          ReportCardWidget(
            title: 'Sales by Representative',
            subtitle: 'Performance by sales team',
            icon: Icons.people,
            onTap: () {},
          ),
          SizedBox(height: 2.h),
          ReportCardWidget(
            title: 'Sales Forecast',
            subtitle: 'Predicted sales for next period',
            icon: Icons.insights,
            onTap: () {},
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
            title: 'Stock Levels',
            chartType: 'bar',
            data: _inventoryMetrics?['stockLevels'] ?? [],
          ),
          SizedBox(height: 2.h),
          ReportCardWidget(
            title: 'Inventory Turnover Analysis',
            subtitle: 'Fast vs slow moving items',
            icon: Icons.inventory,
            onTap: () {},
          ),
          SizedBox(height: 2.h),
          ReportCardWidget(
            title: 'Stock Valuation Report',
            subtitle: 'Current inventory value',
            icon: Icons.monetization_on,
            onTap: () {},
          ),
          SizedBox(height: 2.h),
          ReportCardWidget(
            title: 'Warehouse Performance',
            subtitle: 'Multi-location analysis',
            icon: Icons.warehouse,
            onTap: () {},
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
            title: 'Cash Flow',
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
                      'Accounts Receivable Aging',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    _buildAgingBucket('Current',
                        _agingReport!['agingTotals']['current'] ?? 0),
                    _buildAgingBucket('30-Day Overdue',
                        _agingReport!['agingTotals']['30-day'] ?? 0),
                    _buildAgingBucket('60-Day Overdue',
                        _agingReport!['agingTotals']['60-day'] ?? 0),
                    _buildAgingBucket('90+ Day Overdue',
                        _agingReport!['agingTotals']['90-day'] ?? 0),
                    Divider(),
                    _buildAgingBucket('Total Outstanding',
                        _agingReport!['totalOutstanding'] ?? 0,
                        isBold: true),
                  ],
                ),
              ),
            ),
            SizedBox(height: 2.h),
          ],
          ReportCardWidget(
            title: 'Profit & Loss Statement',
            subtitle: 'Income and expenses breakdown',
            icon: Icons.account_balance,
            onTap: () {},
          ),
          SizedBox(height: 2.h),
          ReportCardWidget(
            title: 'Expense Analysis',
            subtitle: 'Category-wise expenses',
            icon: Icons.pie_chart,
            onTap: () {},
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
            title: 'Customer Acquisition',
            chartType: 'bar',
            data: [],
          ),
          SizedBox(height: 2.h),
          ReportCardWidget(
            title: 'Customer Segmentation',
            subtitle: 'High, medium, low value customers',
            icon: Icons.pie_chart_outline,
            onTap: () {},
          ),
          SizedBox(height: 2.h),
          ReportCardWidget(
            title: 'Customer Lifetime Value',
            subtitle: 'Total revenue per customer',
            icon: Icons.person_outline,
            onTap: () {},
          ),
          SizedBox(height: 2.h),
          ReportCardWidget(
            title: 'Customer Retention Rate',
            subtitle: 'Repeat purchase analysis',
            icon: Icons.repeat,
            onTap: () {},
          ),
        ],
      ),
    );
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
