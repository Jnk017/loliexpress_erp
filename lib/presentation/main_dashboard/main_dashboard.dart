import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/kpi_card_widget.dart';
import './widgets/quick_action_button_widget.dart';
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
  DateTime _lastSyncTime = DateTime.now();
  final ScrollController _scrollController = ScrollController();

  // Mock data for KPIs
  final List<Map<String, dynamic>> _kpiData = [
    {
      "title": "Ventes du Jour",
      "value": "2 450 000",
      "currency": "FCFA",
      "change": "+12.5%",
      "isPositive": true,
      "icon": "trending_up",
      "route": "/sales-order-processing"
    },
    {
      "title": "Commandes en Attente",
      "value": "23",
      "subtitle": "commandes",
      "change": "+5",
      "isPositive": false,
      "icon": "pending_actions",
      "route": "/sales-order-processing"
    },
    {
      "title": "Stock Faible",
      "value": "8",
      "subtitle": "produits",
      "change": "Critique",
      "isPositive": false,
      "icon": "inventory_2",
      "route": "/inventory-management"
    },
    {
      "title": "Paiements en Retard",
      "value": "1 850 000",
      "currency": "FCFA",
      "change": "15 clients",
      "isPositive": false,
      "icon": "payment",
      "route": "/financial-dashboard"
    },
  ];

  // Mock data for weekly revenue
  final List<Map<String, dynamic>> _weeklyRevenue = [
    {"day": "Lun", "amount": 1850000},
    {"day": "Mar", "amount": 2100000},
    {"day": "Mer", "amount": 1950000},
    {"day": "Jeu", "amount": 2450000},
    {"day": "Ven", "amount": 2800000},
    {"day": "Sam", "amount": 3200000},
    {"day": "Dim", "amount": 2650000},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _handleTabChange(_tabController.index);
      }
    });
    _autoRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleTabChange(int index) {
    final routes = [
      '/main-dashboard',
      '/inventory-management',
      '/sales-order-processing',
      '/customer-management',
      '/financial-dashboard',
    ];
    if (index != 0) {
      Navigator.pushNamed(context, routes[index]);
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isSyncing = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isSyncing = false;
      _lastSyncTime = DateTime.now();
    });
  }

  void _autoRefresh() {
    Future.delayed(const Duration(minutes: 5), () {
      if (mounted) {
        _refreshData();
        _autoRefresh();
      }
    });
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Aucune nouvelle notification')),
              );
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
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
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
                      tabs: const [
                        Tab(text: 'Tableau de Bord'),
                        Tab(text: 'Inventaire'),
                        Tab(text: 'Ventes'),
                        Tab(text: 'Clients'),
                        Tab(text: 'Rapports'),
                      ],
                    ),
                  ),
                  SizedBox(height: 2.h),
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
                          onTap: () =>
                              Navigator.pushNamed(context, kpi["route"]),
                        ),
                      ),
                    );
                  },
                  childCount: _kpiData.length,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                child: RevenueChartWidget(weeklyData: _weeklyRevenue),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 10.h)),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          QuickActionButtonWidget(
            icon: 'add_shopping_cart',
            label: 'Nouvelle Vente',
            onPressed: () =>
                Navigator.pushNamed(context, '/sales-order-processing'),
          ),
          SizedBox(height: 2.h),
          QuickActionButtonWidget(
            icon: 'qr_code_scanner',
            label: 'Scanner Produit',
            onPressed: () => Navigator.pushNamed(context, '/barcode-scanner'),
          ),
          SizedBox(height: 2.h),
          QuickActionButtonWidget(
            icon: 'person_add',
            label: 'Ajouter Client',
            onPressed: () =>
                Navigator.pushNamed(context, '/customer-management'),
          ),
        ],
      ),
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
}
