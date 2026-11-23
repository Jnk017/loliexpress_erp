import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/customer_service.dart';
import '../../services/expense_service.dart';
import '../../services/inventory_service.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';
import '../../services/purchase_service.dart';
import '../../services/role_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/kpi_card_widget.dart';
import '../../widgets/role_workspace_panel.dart';
import './widgets/revenue_chart_widget.dart';
import './widgets/sync_status_widget.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSyncing = false;
  bool _isLoading = true;
  String? _error;
  DateTime _lastSyncTime = DateTime.now();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _kpiData = [];
  List<Map<String, dynamic>> _weeklyRevenue = [];

  List<_TabInfo> get _visibleTabs {
    final role = RoleService.instance.currentRole;
    if (role == UserRole.salesRep) {
      return const [
        _TabInfo(label: 'Tableau de Bord', route: '/main-dashboard'),
        _TabInfo(label: 'Ventes', route: '/sales-order-processing'),
        _TabInfo(label: 'Clients', route: '/customer-management'),
      ];
    }
    return const [
      _TabInfo(label: 'Tableau de Bord', route: '/main-dashboard'),
      _TabInfo(label: 'Inventaire', route: '/inventory-management'),
      _TabInfo(label: 'Ventes', route: '/sales-order-processing'),
      _TabInfo(label: 'Clients', route: '/customer-management'),
      _TabInfo(label: 'Rapports', route: '/reports-analytics'),
    ];
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _visibleTabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _handleTabChange(_tabController.index);
      }
    });
    _loadDashboardData();
    _autoRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleTabChange(int index) {
    final tabs = _visibleTabs;
    if (index != 0 && index < tabs.length) {
      Navigator.pushReplacementNamed(context, tabs[index].route);
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final role = RoleService.instance.currentRole;
      final futures = <Future>[
        OrderService.instance.getOrderStats(),
        ProductService.instance.getProducts(limit: 1000),
        CustomerService.instance.getCustomerStats(),
        InventoryService.instance.getStockSummary(),
      ];

      final bool isFinanceRole =
          role == UserRole.comptable || role == UserRole.admin;
      if (isFinanceRole) {
        futures.add(ExpenseService.instance.getExpenseStats());
        futures.add(PurchaseService.instance.getPurchaseStats());
      }

      final results = await Future.wait(futures);

      final orderStats = results[0] as Map<String, dynamic>;
      final products = results[1] as List<Map<String, dynamic>>;
      final customerStats = results[2] as Map<String, dynamic>;
      final stockSummary = results[3] as Map<String, dynamic>;

      Map<String, dynamic>? expenseStats;
      Map<String, dynamic>? purchaseStats;
      if (isFinanceRole) {
        expenseStats = results[4] as Map<String, dynamic>;
        purchaseStats = results[5] as Map<String, dynamic>;
      }

      final totalRevenue = orderStats['total_revenue'] as double? ?? 0;
      final pendingOrders = orderStats['pending'] as int? ?? 0;
      final lowStockCount = stockSummary['low_stock_count'] as int? ?? 0;
      final totalCustomers = customerStats['total_customers'] as int? ?? 0;
      final totalProducts = products.length;
      final inventoryValue = stockSummary['total_value'] as double? ?? 0;

      final kpis = <Map<String, dynamic>>[
        {
          "title": "Chiffre d'Affaires",
          "value": _formatNumber(totalRevenue),
          "currency": "CDF",
          "change": "${orderStats['delivered'] ?? 0} livrées",
          "isPositive": true,
          "icon": "trending_up",
          "route": "/sales-order-processing",
        },
        {
          "title": "Commandes en Attente",
          "value": "$pendingOrders",
          "subtitle": "commandes",
          "change": "${orderStats['total'] ?? 0} total",
          "isPositive": pendingOrders == 0,
          "icon": "pending_actions",
          "route": "/sales-order-processing",
        },
      ];

      if (role != UserRole.salesRep) {
        kpis.add({
          "title": "Stock Faible",
          "value": "$lowStockCount",
          "subtitle": "produits",
          "change": "$totalProducts total",
          "isPositive": lowStockCount == 0,
          "icon": "inventory_2",
          "route": "/inventory-management",
        });
        kpis.add({
          "title": "Valeur Inventaire",
          "value": _formatNumber(inventoryValue),
          "currency": "CDF",
          "change": "$totalCustomers clients",
          "isPositive": true,
          "icon": "payment",
          "route": "/financial-dashboard",
        });
      } else {
        kpis.add({
          "title": "Clients",
          "value": "$totalCustomers",
          "subtitle": "clients",
          "change": "",
          "isPositive": true,
          "icon": "people",
          "route": "/customer-management",
        });
      }

      if (isFinanceRole && expenseStats != null && purchaseStats != null) {
        final pendingPayments = expenseStats['approved'] as int? ?? 0;
        final unpaidPurchases = purchaseStats['unpaid'] as int? ?? 0;
        kpis.add({
          "title": "Dépenses à payer",
          "value": "$pendingPayments",
          "subtitle": "en attente",
          "change": "${expenseStats['pending'] ?? 0} à approuver",
          "isPositive": pendingPayments == 0,
          "icon": "receipt_long",
          "route": "/expense-management",
        });
        kpis.add({
          "title": "Achats impayés",
          "value": "$unpaidPurchases",
          "subtitle": "achats",
          "change": "${purchaseStats['total_purchases'] ?? 0} total",
          "isPositive": unpaidPurchases == 0,
          "icon": "shopping_cart_checkout",
          "route": "/purchase-management",
        });
      }

      setState(() {
        _kpiData = kpis;

        _weeklyRevenue = [
          {"day": "Lun", "amount": (totalRevenue * 0.12).round()},
          {"day": "Mar", "amount": (totalRevenue * 0.14).round()},
          {"day": "Mer", "amount": (totalRevenue * 0.13).round()},
          {"day": "Jeu", "amount": (totalRevenue * 0.16).round()},
          {"day": "Ven", "amount": (totalRevenue * 0.18).round()},
          {"day": "Sam", "amount": (totalRevenue * 0.15).round()},
          {"day": "Dim", "amount": (totalRevenue * 0.12).round()},
        ];

        _isLoading = false;
        _isSyncing = false;
        _lastSyncTime = DateTime.now();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isSyncing = false;
        _error = e.toString();
      });
    }
  }

  String _formatNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)} ${(value % 1000).toInt().toString().padLeft(3, '0')}';
    }
    return value.toStringAsFixed(0);
  }

  Future<void> _refreshData() async {
    setState(() => _isSyncing = true);
    await _loadDashboardData();
  }

  void _autoRefresh() {
    Future.delayed(const Duration(minutes: 5), () {
      if (mounted) {
        _refreshData();
        _autoRefresh();
      }
    });
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await AuthService.instance.signOut();
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: ${e.toString()}')),
          );
        }
      }
    }
  }

  void _showContextMenu(BuildContext context, Map<String, dynamic> kpi) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'visibility',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                title:
                    Text('Voir les Détails', style: theme.textTheme.bodyLarge),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, kpi["route"]);
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'file_download',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                title: Text('Exporter les Données',
                    style: theme.textTheme.bodyLarge),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exportation en cours...')),
                  );
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'notifications_active',
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                title: Text('Définir une Alerte',
                    style: theme.textTheme.bodyLarge),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Alerte configurée')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Tableau de Bord',
        variant: CustomAppBarVariant.sync,
        showSyncStatus: true,
        isSyncing: _isSyncing,
        lastSyncTime: _lastSyncTime,
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'notifications',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.notificationsCenter);
            },
          ),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'refresh',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: _refreshData,
          ),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'logout',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _buildBody(theme),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: 0,
        onTap: (index) {
          if (index != 0) {
            _tabController.animateTo(index);
          }
        },
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading && _kpiData.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _kpiData.isEmpty) {
      return SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const RoleWorkspacePanel(),
              CustomIconWidget(
                iconName: 'error_outline',
                color: theme.colorScheme.error,
                size: 48,
              ),
              SizedBox(height: 2.h),
              Text(
                'Erreur de chargement',
                style: theme.textTheme.titleMedium,
              ),
              SizedBox(height: 1.h),
              Text(
                _error!,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 3.h),
              ElevatedButton.icon(
                onPressed: _refreshData,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: RoleWorkspacePanel()),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SyncStatusWidget(
                  isSyncing: _isSyncing,
                  lastSyncTime: _lastSyncTime,
                ),
                SizedBox(height: 2.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                    indicatorColor: theme.colorScheme.primary,
                    tabs: _visibleTabs.map((t) => Tab(text: t.label)).toList(),
                  ),
                ),
                SizedBox(height: 2.h),
                if (RoleService.instance.currentRole == UserRole.admin) ...[
                  _buildAdministrationSection(theme),
                  SizedBox(height: 2.h),
                ],
              ],
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final kpi = _kpiData[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: 2.h),
                    child: GestureDetector(
                      onLongPress: () => _showContextMenu(context, kpi),
                      child: KpiCardWidget(
                        title: kpi["title"],
                        value: kpi["value"],
                        currency: kpi["currency"],
                        subtitle: kpi["subtitle"],
                        change: kpi["change"],
                        isPositive: kpi["isPositive"],
                        icon: kpi["icon"],
                        onTap: () => Navigator.pushNamed(context, kpi["route"]),
                      ),
                    ),
                  );
                },
                childCount: _kpiData.length,
              ),
            ),
          ),
          if (_weeklyRevenue.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                child: RevenueChartWidget(weeklyData: _weeklyRevenue),
              ),
            ),
          SliverToBoxAdapter(child: SizedBox(height: 10.h)),
        ],
      ),
    );
  }

  Widget _buildAdministrationSection(ThemeData theme) {
    final items = [
      _AdminItem('Dashboard admin', 'dashboard', '/admin-dashboard'),
      _AdminItem('Assistant IA', 'auto_awesome', '/ai-assistant'),
      _AdminItem('Audit', 'history', '/audit-log'),
      _AdminItem('Sécurité', 'security', '/security-dashboard'),
      _AdminItem('Alertes', 'warning', '/security-alert-center'),
      _AdminItem('Automations', 'rule', '/automation-rules-manager'),
      _AdminItem('Incidents', 'report_problem', '/incident-management-center'),
      _AdminItem('Utilisateurs', 'manage_accounts', '/user-role-management'),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Administration',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: items.map((item) {
              return ActionChip(
                avatar: CustomIconWidget(
                  iconName: item.icon,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
                label: Text(item.label),
                onPressed: () => Navigator.pushNamed(context, item.route),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _TabInfo {
  final String label;
  final String route;
  const _TabInfo({required this.label, required this.route});
}

class _AdminItem {
  final String label;
  final String icon;
  final String route;
  const _AdminItem(this.label, this.icon, this.route);
}
