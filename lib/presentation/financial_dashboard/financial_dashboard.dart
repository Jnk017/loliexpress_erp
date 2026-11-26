import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../services/financial_dashboard_service.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/treasury_account_form.dart';
import '../../services/role_service.dart';
import './widgets/accounts_receivable_list_widget.dart';
import './widgets/cash_flow_chart_widget.dart';
import './widgets/cash_position_card_widget.dart';
import './widgets/expense_card_widget.dart';
import './widgets/quick_action_fab_widget.dart';
import './widgets/receivables_card_widget.dart';
import './widgets/revenue_card_widget.dart';

class FinancialDashboard extends StatefulWidget {
  const FinancialDashboard({super.key});

  @override
  State<FinancialDashboard> createState() => _FinancialDashboardState();
}

class _FinancialDashboardState extends State<FinancialDashboard> {
  DateTime _selectedStartDate =
      DateTime.now().subtract(const Duration(days: 30));
  DateTime _selectedEndDate = DateTime.now();
  bool _isRefreshing = false;

  // Financial service for real-time data
  final FinancialDashboardService _financialService =
      FinancialDashboardService();

  // Real-time financial data
  final Map<String, dynamic> _financialData = {
    "cashPosition": {
      "amount": 0,
      "currency": "CDF",
      "change": 0.0,
      "trend": "neutral"
    },
    "dailyRevenue": {
      "amount": 0,
      "currency": "CDF",
      "change": 0.0,
      "trend": "neutral"
    },
    "outstandingReceivables": {
      "amount": 0,
      "currency": "CDF",
      "change": 0.0,
      "trend": "neutral"
    },
    "monthlyExpenses": {
      "amount": 0,
      "currency": "CDF",
      "change": 0.0,
      "trend": "neutral"
    },
    "cashFlowData": <Map<String, dynamic>>[],
    "accountsReceivable": <Map<String, dynamic>>[],
  };

  @override
  void initState() {
    super.initState();
    _initializeRealtimeData();
  }

  Future<void> _initializeRealtimeData() async {
    // Initialize real-time subscriptions
    await _financialService.initializeRealtimeSubscriptions();

    // Listen to financial metrics stream
    _financialService.financialMetricsStream.listen((metrics) {
      if (mounted) {
        setState(() {
          _financialData['cashPosition'] = metrics['cashPosition'];
          _financialData['dailyRevenue'] = metrics['dailyRevenue'];
          _financialData['outstandingReceivables'] =
              metrics['outstandingReceivables'];
          _financialData['monthlyExpenses'] = metrics['monthlyExpenses'];
        });
      }
    });

    // Listen to receivables stream
    _financialService.receivablesStream.listen((receivables) {
      if (mounted) {
        setState(() {
          _financialData['accountsReceivable'] = receivables;
        });
      }
    });

    // Initial data load
    await _loadFinancialData();
  }

  Future<void> _loadFinancialData() async {
    await _financialService.refreshFinancialMetrics();
    await _financialService.refreshReceivables();
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    await _loadFinancialData();

    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  void dispose() {
    _financialService.dispose();
    super.dispose();
  }

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _selectedStartDate,
        end: _selectedEndDate,
      ),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedStartDate = picked.start;
        _selectedEndDate = picked.end;
      });
      _handleRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 60),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              children: [
                // App Bar
                Container(
                  height: kToolbarHeight,
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Tableau financier',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      // Real-time indicator
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 2.w, vertical: 0.5.h),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              'Live',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 2.w),
                      IconButton(
                        icon: CustomIconWidget(
                          iconName: 'refresh',
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                        onPressed: _isRefreshing ? null : _handleRefresh,
                        tooltip: 'Actualiser',
                      ),
                      IconButton(
                        icon: CustomIconWidget(
                          iconName: 'more_vert',
                          color: theme.colorScheme.onSurface,
                          size: 24,
                        ),
                        onPressed: () {
                          _showOptionsMenu();
                        },
                        tooltip: 'Options',
                      ),
                    ],
                  ),
                ),
                // Date Range Selector
                Container(
                  height: 60,
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  child: InkWell(
                    onTap: _showDateRangePicker,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              theme.colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'calendar_today',
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Text(
                              '${_formatDate(_selectedStartDate)} - ${_formatDate(_selectedEndDate)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          CustomIconWidget(
                            iconName: 'arrow_drop_down',
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: 88 + MediaQuery.paddingOf(context).bottom),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 2.h),
              // Financial Metrics Cards
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CashPositionCardWidget(
                            data: _financialData["cashPosition"]
                                as Map<String, dynamic>,
                            onTap: _showTreasuryAccounts,
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: RevenueCardWidget(
                            data: _financialData["dailyRevenue"]
                                as Map<String, dynamic>,
                            onTap: () => _navigateToDetail('revenue'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Expanded(
                          child: ReceivablesCardWidget(
                            data: _financialData["outstandingReceivables"]
                                as Map<String, dynamic>,
                            onTap: () => _navigateToDetail('receivables'),
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: ExpenseCardWidget(
                            data: _financialData["monthlyExpenses"]
                                as Map<String, dynamic>,
                            onTap: () => _navigateToDetail('expenses'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 3.h),
              // Cash Flow Chart
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: CashFlowChartWidget(
                  data: (_financialData["cashFlowData"] as List)
                      .cast<Map<String, dynamic>>(),
                ),
              ),
              SizedBox(height: 3.h),
              // Accounts Receivable Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Comptes Clients',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/customer-management');
                      },
                      child: Text(
                        'Voir tout',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 1.h),
              AccountsReceivableListWidget(
                receivables: (_financialData["accountsReceivable"] as List)
                    .cast<Map<String, dynamic>>(),
                onItemTap: _handleReceivableItemTap,
                onSendReminder: _handleSendReminder,
                onRecordPayment: _handleRecordPayment,
                onViewInvoice: _handleViewInvoice,
                onContactCustomer: _handleContactCustomer,
              ),
              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
      floatingActionButton: QuickActionFabWidget(
        onRecordExpense: _handleRecordExpense,
        onCreateReceipt: _handleCreateReceipt,
        onGenerateReport: _handleGenerateReport,
      ),
      bottomNavigationBar: const CustomBottomBar(currentIndex: -1),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showOptionsMenu() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CustomIconWidget(
                iconName: 'file_download',
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              title: Text('Exporter les données',
                  style: theme.textTheme.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                _handleExportData();
              },
            ),
            if (RoleService.instance.canManageUsers) ListTile(
              leading: CustomIconWidget(
                iconName: 'notifications',
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              title: Text('Alertes de sécurité',
                  style: theme.textTheme.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                _handleSetAlerts();
              },
            ),
            if (RoleService.instance.canManageUsers) ListTile(
              leading: CustomIconWidget(
                iconName: 'history',
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              title:
                  Text('Journal d’audit', style: theme.textTheme.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                _handleViewHistory();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTreasuryAccounts() {
    final future = _financialService.getTreasuryAccounts();
    showDialog<void>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Trésorerie'),
        children: [
          FutureBuilder<List<List<Map<String, dynamic>>>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const ListTile(title: Text('Soldes indisponibles.'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final groups = snapshot.data!;
              if (groups.every((group) => group.isEmpty)) {
                return const ListTile(title: Text('Aucun compte actif.'));
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final group in groups.indexed)
                    for (final row in group.$2)
                      ListTile(
                        title: Text((row['name'] ?? row['account_name']) as String),
                        subtitle: Text(group.$1 == 0 ? 'Caisse'
                            : row['account_channel'] == 'mobile_money' ? 'Mobile Money' : 'Banque'),
                        trailing: Text("${row['current_balance']} ${row['currency']}"),
                      ),
                ],
              );
            },
          ),
          if (RoleService.instance.canManageUsers)
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _openTreasuryAccount();
              },
              child: const Text('Ouvrir un compte'),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _openTreasuryAccount() async {
    if (await showTreasuryAccountForm(context) && mounted) {
      await _financialService.refreshFinancialMetrics();
      if (mounted) _showTreasuryAccounts();
    }
  }

  void _navigateToDetail(String type) {
    Navigator.pushNamed(
      context,
      type == 'expenses' ? AppRoutes.expenses : AppRoutes.reportsAnalytics,
    );
  }

  void _handleReceivableItemTap(Map<String, dynamic> receivable) =>
      _handleViewInvoice(receivable);

  Future<void> _openCustomerEmail(
    Map<String, dynamic> receivable, {
    required bool reminder,
  }) async {
    final email = (receivable['customerEmail'] as String?)?.trim();
    if (email != null && email.isNotEmpty) {
      final number = receivable['invoiceNumber'];
      final query = reminder
          ? 'subject=${Uri.encodeComponent('Rappel de paiement – facture $number')}'
              '&body=${Uri.encodeComponent("Bonjour,\n\nLe solde de la facture $number est de ${receivable['amount']} ${receivable['currency']}.\n\nCordialement.")}'
          : null;
      try {
        if (await launchUrl(Uri(scheme: 'mailto', path: email, query: query))) {
          return;
        }
      } catch (_) {
        // The system may not have an email app configured.
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(email == null || email.isEmpty
          ? 'Aucune adresse e-mail renseignée pour ce client.'
          : 'Impossible d’ouvrir la messagerie.'),
    ));
  }

  void _handleSendReminder(Map<String, dynamic> receivable) =>
      _openCustomerEmail(receivable, reminder: true);

  Future<void> _handleRecordPayment(Map<String, dynamic> receivable) async {
    await Navigator.pushNamed(context, AppRoutes.invoiceGeneration,
        arguments: receivable['id'] as String);
    if (mounted) await _financialService.refreshFinancialMetrics();
  }

  void _handleViewInvoice(Map<String, dynamic> receivable) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Facture ${receivable['invoiceNumber']}"),
        content: Text(
          "${receivable['customerName']}\n"
          "Échéance : ${ receivable['dueDate'] ?? 'non renseignée'}\n"
          "Solde : ${receivable['amount']} ${receivable['currency']}",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _handleContactCustomer(Map<String, dynamic> receivable) =>
      _openCustomerEmail(receivable, reminder: false);

  void _handleRecordExpense() => Navigator.pushNamed(context, AppRoutes.expenses);

  void _handleCreateReceipt() =>
      Navigator.pushNamed(context, AppRoutes.invoiceGeneration);

  void _handleGenerateReport() =>
      Navigator.pushNamed(context, AppRoutes.reportsAnalytics);

  void _handleExportData() =>
      Navigator.pushNamed(context, AppRoutes.reportsAnalytics, arguments: true);

  void _handleSetAlerts() =>
      Navigator.pushNamed(context, AppRoutes.securityAlertCenter);

  void _handleViewHistory() => Navigator.pushNamed(context, AppRoutes.auditLog);
}
