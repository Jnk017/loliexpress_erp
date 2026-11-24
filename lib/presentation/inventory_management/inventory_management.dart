import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../routes/app_routes.dart';
import '../../services/inventory_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/location_selector_widget.dart';
import './widgets/movements_view_widget.dart';
import './widgets/stock_overview_widget.dart';

class InventoryManagement extends StatefulWidget {
  const InventoryManagement({super.key});

  @override
  State<InventoryManagement> createState() => _InventoryManagementState();
}

class _InventoryManagementState extends State<InventoryManagement>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const _allWarehouses = '';
  String _warehouseId = _allWarehouses;
  Map<String, String> _locations = {_allWarehouses: 'Tous les entrepôts'};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadWarehouses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWarehouses() async {
    try {
      final rows = await InventoryService.instance.getWarehouses();
      if (!mounted) return;
      setState(() {
        _locations = {
          _allWarehouses: 'Tous les entrepôts',
          for (final row in rows) row['id'] as String: row['name'] as String,
        };
        if (!_locations.containsKey(_warehouseId)) _warehouseId = _allWarehouses;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de charger les entrepôts.')),
      );
    }
  }

  void _showQuickActions() {
    final theme = Theme.of(context);
    final navigator = Navigator.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Actions Rapides',
                style: theme.textTheme.titleLarge,
              ),
              SizedBox(height: 3.h),
              _buildQuickActionItem(
                icon: 'inventory',
                label: 'Recevoir Marchandises',
                onTap: () {
                  Navigator.pop(context);
                  navigator.pushNamed(AppRoutes.purchases);
                },
              ),
              _buildQuickActionItem(
                icon: 'swap_horiz',
                label: 'Transfert de Stock · indisponible',
              ),
              _buildQuickActionItem(
                icon: 'fact_check',
                label: 'Inventaire Physique · indisponible',
              ),
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionItem({
    required String icon,
    required String label,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Row(
          children: [
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: icon,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            CustomIconWidget(
              iconName: 'chevron_right',
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Gestion des Stocks',
        variant: CustomAppBarVariant.standard,
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'qr_code_scanner',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/barcode-scanner');
            },
            tooltip: 'Scanner Code-barres',
          ),
        ],
      ),
      body: Column(
        children: [
          // Location Selector
          LocationSelectorWidget(
            selectedLocation: _warehouseId,
            locations: _locations,
            onLocationChanged: (location) {
              setState(() => _warehouseId = location);
            },
          ),

          // Segmented Control (Tab Bar)
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: theme.colorScheme.onPrimary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              labelStyle: theme.textTheme.labelLarge,
              unselectedLabelStyle: theme.textTheme.labelLarge,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Aperçu'),
                Tab(text: 'Mouvements'),
                Tab(text: 'Alertes'),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                StockOverviewWidget(
                  key: ValueKey(('stock', _warehouseId)),
                  warehouseId: _warehouseId.isEmpty ? null : _warehouseId,
                ),
                MovementsViewWidget(
                  key: ValueKey(('movements', _warehouseId)),
                  warehouseId: _warehouseId.isEmpty ? null : _warehouseId,
                ),
                StockOverviewWidget(
                  key: ValueKey(('alerts', _warehouseId)),
                  warehouseId: _warehouseId.isEmpty ? null : _warehouseId,
                  alertsOnly: true,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showQuickActions,
        icon: CustomIconWidget(
          iconName: 'add',
          color: const Color(0xFF121212),
          size: 24,
        ),
        label: Text(
          'Actions',
          style: theme.textTheme.labelLarge?.copyWith(
            color: const Color(0xFF121212),
          ),
        ),
        backgroundColor: theme.colorScheme.tertiary,
      ),
      bottomNavigationBar: const CustomBottomBar(currentIndex: 1),
    );
  }
}
