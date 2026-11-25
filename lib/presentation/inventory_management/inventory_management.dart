import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../routes/app_routes.dart';
import '../../services/inventory_service.dart';
import '../../services/role_service.dart';
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
  bool _operationPending = false;
  int _stockRevision = 0;
  final _inventory = InventoryService.instance;
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
      final rows = await _inventory.getWarehouses();
      if (!mounted) return;
      setState(() {
        _locations = {
          _allWarehouses: 'Tous les entrepôts',
          for (final row in rows)
            if (row['is_active'] == true) row['id'] as String: row['name'] as String,
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

  Future<void> _showStockOperation({required bool transfer}) async {
    if (_operationPending) return;
    setState(() => _operationPending = true);
    try {
      final rows = await _inventory.getStock(
        warehouseId: _warehouseId.isEmpty ? null : _warehouseId,
      );
      if (!mounted) return;
      final eligible = rows.where((row) =>
        row['product_id'] is String &&
        _locations.containsKey(row['warehouse_id']) &&
        (!transfer || (row['quantity'] as num) > 0)
      ).toList();
      if (eligible.isEmpty || (transfer && _locations.length < 3)) {
        _stockMessage(transfer
            ? 'Le transfert nécessite du stock et deux entrepôts actifs.'
            : 'Aucune ligne de stock à compter dans cet entrepôt.');
        return;
      }
      Map<String, dynamic>? selected;
      String? destination;
      var quantityText = '';
      var reasonText = '';
      String? error;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (_, updateDialog) => AlertDialog(
            title: Text(transfer ? 'Transfert de stock' : 'Inventaire physique'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Map<String, dynamic>>(
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Article et entrepôt'),
                    items: [
                      for (final row in eligible)
                        DropdownMenuItem(
                          value: row,
                          child: Text(
                            "${(row['products'] as Map?)?['name'] ?? 'Article'} · "
                            "${_locations[row['warehouse_id']]} · ${row['quantity']}",
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) => updateDialog(() {
                      selected = value;
                      if (destination == value?['warehouse_id']) destination = null;
                    }),
                  ),
                  if (transfer)
                    DropdownButtonFormField<String>(
                      key: ValueKey(selected?['warehouse_id']),
                      initialValue: destination,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Entrepôt de destination'),
                      items: [
                        for (final entry in _locations.entries)
                          if (entry.key.isNotEmpty && entry.key != selected?['warehouse_id'])
                            DropdownMenuItem(value: entry.key, child: Text(entry.value)),
                      ],
                      onChanged: (value) => destination = value,
                    ),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: transfer ? 'Quantité à transférer' : 'Quantité comptée',
                    ),
                    onChanged: (value) => quantityText = value,
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Motif'),
                    onChanged: (value) => reasonText = value,
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(error!, style: TextStyle(
                        color: Theme.of(dialogContext).colorScheme.error,
                      )),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () {
                  final quantity = int.tryParse(quantityText.trim());
                  if (selected == null || quantity == null || quantity < 0 ||
                      reasonText.trim().isEmpty ||
                      (transfer && (destination == null || quantity == 0 ||
                          quantity > (selected!['quantity'] as num)))) {
                    updateDialog(() => error = 'Vérifiez l’article, la quantité et le motif.');
                    return;
                  }
                  Navigator.pop(dialogContext, true);
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      );
      if (confirmed != true || !mounted) return;
      final stock = selected!;
      final quantity = int.parse(quantityText.trim());
      final reason = reasonText.trim();
      if (transfer) {
        await _inventory.transferStock(
          productId: stock['product_id'] as String,
          sourceId: stock['warehouse_id'] as String,
          destinationId: destination!,
          quantity: quantity,
          reason: reason,
        );
      } else {
        await _inventory.recordPhysicalCount(
          productId: stock['product_id'] as String,
          warehouseId: stock['warehouse_id'] as String,
          expectedQuantity: (stock['quantity'] as num).toInt(),
          countedQuantity: quantity,
          reason: reason,
        );
      }
      if (!mounted) return;
      setState(() => _stockRevision++);
      _stockMessage(transfer ? 'Transfert enregistré.' : 'Comptage enregistré.');
    } catch (_) {
      if (mounted) {
        _stockMessage('Opération non confirmée. Actualisez le stock avant de réessayer.');
      }
    } finally {
      if (mounted) setState(() => _operationPending = false);
    }
  }

  void _stockMessage(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

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
              if (RoleService.instance.canViewStockReports)
                _buildQuickActionItem(
                  icon: 'swap_horiz',
                  label: 'Transfert de Stock',
                  onTap: () {
                    Navigator.pop(context);
                    _showStockOperation(transfer: true);
                  },
                ),
              if (RoleService.instance.canViewStockReports)
                _buildQuickActionItem(
                  icon: 'fact_check',
                  label: 'Inventaire Physique',
                  onTap: () {
                    Navigator.pop(context);
                    _showStockOperation(transfer: false);
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
        root: true,
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
                  key: ValueKey(('stock', _warehouseId, _stockRevision)),
                  warehouseId: _warehouseId.isEmpty ? null : _warehouseId,
                ),
                MovementsViewWidget(
                  key: ValueKey(('movements', _warehouseId, _stockRevision)),
                  warehouseId: _warehouseId.isEmpty ? null : _warehouseId,
                ),
                StockOverviewWidget(
                  key: ValueKey(('alerts', _warehouseId, _stockRevision)),
                  warehouseId: _warehouseId.isEmpty ? null : _warehouseId,
                  alertsOnly: true,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _operationPending ? null : _showQuickActions,
        icon: CustomIconWidget(
          iconName: 'add',
          color: theme.colorScheme.onPrimary,
          size: 24,
        ),
        label: Text(
          'Actions',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
      ),
      bottomNavigationBar: const CustomBottomBar(currentIndex: 1),
    );
  }
}
