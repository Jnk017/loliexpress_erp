import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/alerts_view_widget.dart';
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
  int _currentBottomNavIndex = 1; // Inventory tab active
  String _selectedLocation = 'Tous les entrepôts';
  bool _isRefreshing = false;

  final List<String> _locations = [
    'Tous les entrepôts',
    'Entrepôt Principal',
    'Entrepôt Secondaire',
    'Zone de Transit',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    // Simulate sync operation
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isRefreshing = false);
  }

  void _showQuickActions() {
    final theme = Theme.of(context);
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
                  // Navigate to receive goods screen
                },
              ),
              _buildQuickActionItem(
                icon: 'swap_horiz',
                label: 'Transfert de Stock',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to stock transfer screen
                },
              ),
              _buildQuickActionItem(
                icon: 'fact_check',
                label: 'Inventaire Physique',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to physical count screen
                },
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
    required VoidCallback onTap,
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
          IconButton(
            icon: CustomIconWidget(
              iconName: 'filter_list',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: () {
              // Show filter options
            },
            tooltip: 'Filtrer',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: Column(
          children: [
            // Location Selector
            LocationSelectorWidget(
              selectedLocation: _selectedLocation,
              locations: _locations,
              onLocationChanged: (location) {
                setState(() => _selectedLocation = location);
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
                    selectedLocation: _selectedLocation,
                    isRefreshing: _isRefreshing,
                  ),
                  MovementsViewWidget(
                    selectedLocation: _selectedLocation,
                  ),
                  AlertsViewWidget(
                    selectedLocation: _selectedLocation,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showQuickActions,
        icon: CustomIconWidget(
          iconName: 'add',
          color: theme.colorScheme.onTertiary,
          size: 24,
        ),
        label: Text(
          'Actions',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onTertiary,
          ),
        ),
        backgroundColor: theme.colorScheme.tertiary,
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentBottomNavIndex,
        onTap: (index) {
          setState(() => _currentBottomNavIndex = index);
          // Navigate based on index
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/main-dashboard');
              break;
            case 1:
              // Already on inventory
              break;
            case 2:
              Navigator.pushNamed(context, '/sales-order-processing');
              break;
            case 3:
              Navigator.pushNamed(context, '/customer-management');
              break;
            case 4:
              Navigator.pushNamed(context, '/financial-dashboard');
              break;
          }
        },
      ),
    );
  }
}
