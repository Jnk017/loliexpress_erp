import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/inventory_service.dart';

class StockOverviewWidget extends StatefulWidget {
  final String selectedLocation;
  final bool isRefreshing;

  const StockOverviewWidget({
    super.key,
    required this.selectedLocation,
    required this.isRefreshing,
  });

  @override
  State<StockOverviewWidget> createState() => _StockOverviewWidgetState();
}

class _StockOverviewWidgetState extends State<StockOverviewWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _stockItems = [];

  @override
  void initState() {
    super.initState();
    _loadStock();
  }

  @override
  void didUpdateWidget(covariant StockOverviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRefreshing && !oldWidget.isRefreshing) {
      _loadStock();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStock() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final stock = await InventoryService.instance.getStock();
      if (!mounted) return;
      setState(() {
        _stockItems = stock.map(_mapStockItem).toList();
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

  Map<String, dynamic> _mapStockItem(Map<String, dynamic> row) {
    final product = row['products'] as Map<String, dynamic>?;
    final warehouse = row['warehouse_locations'] as Map<String, dynamic>?;
    final quantity = (row['quantity'] as num?)?.toInt() ?? 0;
    final reorderLevel = (row['reorder_level'] as num?)?.toInt() ?? 10;
    return {
      "id": row['id'] as String? ?? '',
      "name": product?['name'] as String? ?? 'Produit inconnu',
      "sku": product?['sku'] as String? ?? 'N/A',
      "currentQuantity": quantity,
      "unit": "unités",
      "reservedStock": 0,
      "reorderPoint": reorderLevel,
      "nextExpiration": DateTime.now().add(const Duration(days: 365)),
      "location": warehouse?['name'] as String? ?? 'Entrepôt non défini',
      "status": quantity <= reorderLevel ? "low" : "normal",
      "image": product?['image_url'] as String? ?? '',
      "semanticLabel": product?['name'] as String? ?? 'Produit',
      "batchNumber": row['id'] as String? ?? '',
    };
  }

  List<Map<String, dynamic>> get _filteredItems {
    if (_searchQuery.isEmpty) {
      return _stockItems;
    }
    return _stockItems.where((item) {
      final name = (item["name"] as String).toLowerCase();
      final sku = (item["sku"] as String).toLowerCase();
      final batch = (item["batchNumber"] as String).toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) ||
          sku.contains(query) ||
          batch.contains(query);
    }).toList();
  }

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status) {
      case 'expired':
        return theme.colorScheme.error;
      case 'expiring':
        return const Color(0xFFF39C12);
      case 'low':
        return const Color(0xFFF39C12);
      default:
        return const Color(0xFF27AE60);
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'expired':
        return 'Expiré';
      case 'expiring':
        return 'Expire Bientôt';
      case 'low':
        return 'Stock Faible';
      default:
        return 'Normal';
    }
  }

  void _showStockDetails(Map<String, dynamic> item) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 12.w,
                    height: 0.5.h,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CustomImageWidget(
                        imageUrl: item["image"] as String,
                        width: 20.w,
                        height: 20.w,
                        fit: BoxFit.cover,
                        semanticLabel: item["semanticLabel"] as String,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item["name"] as String,
                            style: theme.textTheme.titleLarge,
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            'SKU: ${item["sku"]}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 3.h),
                _buildDetailRow(
                  'Stock Actuel',
                  '${item["currentQuantity"]} ${item["unit"]}',
                  theme,
                ),
                _buildDetailRow(
                  'Stock Réservé',
                  '${item["reservedStock"]} ${item["unit"]}',
                  theme,
                ),
                _buildDetailRow(
                  'Point de Réapprovisionnement',
                  '${item["reorderPoint"]} ${item["unit"]}',
                  theme,
                ),
                _buildDetailRow(
                  'Prochaine Expiration',
                  _formatDate(item["nextExpiration"] as DateTime),
                  theme,
                ),
                _buildDetailRow(
                  'Numéro de Lot',
                  item["batchNumber"] as String,
                  theme,
                ),
                _buildDetailRow(
                  'Emplacement',
                  item["location"] as String,
                  theme,
                ),
                SizedBox(height: 3.h),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // Adjust stock action
                        },
                        icon: CustomIconWidget(
                          iconName: 'edit',
                          color: theme.colorScheme.onPrimary,
                          size: 20,
                        ),
                        label: const Text('Ajuster'),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // Move location action
                        },
                        icon: CustomIconWidget(
                          iconName: 'swap_horiz',
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        label: const Text('Déplacer'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference < 0) {
      return 'Expiré le ${date.day}/${date.month}/${date.year}';
    } else if (difference < 30) {
      return 'Dans $difference jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  color: theme.colorScheme.error, size: 48),
              SizedBox(height: 2.h),
              Text(
                'Erreur de chargement du stock',
                style: theme.textTheme.titleMedium,
              ),
              SizedBox(height: 1.h),
              Text(_error!, textAlign: TextAlign.center),
              SizedBox(height: 2.h),
              ElevatedButton(
                onPressed: _loadStock,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Search Bar
        Container(
          margin: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Rechercher par nom, SKU, lot...',
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.all(3.w),
                child: CustomIconWidget(
                  iconName: 'search',
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: CustomIconWidget(
                        iconName: 'clear',
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 4.w,
                vertical: 1.5.h,
              ),
            ),
          ),
        ),

        // Stock Items List
        Expanded(
          child: _filteredItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'inventory_2',
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.5),
                        size: 64,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Aucun produit trouvé',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  itemCount: _filteredItems.length,
                  separatorBuilder: (context, index) => SizedBox(height: 1.h),
                  itemBuilder: (context, index) {
                    final item = _filteredItems[index];
                    return Slidable(
                      key: ValueKey(item["id"]),
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        children: [
                          SlidableAction(
                            onPressed: (context) {
                              // Adjust stock action
                            },
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            icon: Icons.edit,
                            label: 'Ajuster',
                            borderRadius: BorderRadius.circular(12),
                          ),
                          SlidableAction(
                            onPressed: (context) {
                              // Move location action
                            },
                            backgroundColor: const Color(0xFF2E5984),
                            foregroundColor: Colors.white,
                            icon: Icons.swap_horiz,
                            label: 'Déplacer',
                            borderRadius: BorderRadius.circular(12),
                          ),
                          SlidableAction(
                            onPressed: (context) {
                              // Set reorder point action
                            },
                            backgroundColor: const Color(0xFFF39C12),
                            foregroundColor: Colors.white,
                            icon: Icons.notifications,
                            label: 'Alerte',
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () => _showStockDetails(item),
                        onLongPress: () {
                          // Enable batch selection mode
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: EdgeInsets.all(3.w),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.outline
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CustomImageWidget(
                                  imageUrl: item["image"] as String,
                                  width: 16.w,
                                  height: 16.w,
                                  fit: BoxFit.cover,
                                  semanticLabel:
                                      item["semanticLabel"] as String,
                                ),
                              ),
                              SizedBox(width: 3.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item["name"] as String,
                                            style: theme.textTheme.titleMedium,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 2.w,
                                            vertical: 0.5.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(
                                              item["status"] as String,
                                              theme,
                                            ).withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            _getStatusLabel(
                                                item["status"] as String),
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                              color: _getStatusColor(
                                                item["status"] as String,
                                                theme,
                                              ),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 0.5.h),
                                    Text(
                                      'SKU: ${item["sku"]}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    SizedBox(height: 1.h),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Stock Actuel',
                                                style: theme
                                                    .textTheme.labelSmall
                                                    ?.copyWith(
                                                  color: theme.colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                              Text(
                                                '${item["currentQuantity"]} ${item["unit"]}',
                                                style: theme
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Réservé',
                                                style: theme
                                                    .textTheme.labelSmall
                                                    ?.copyWith(
                                                  color: theme.colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                              Text(
                                                '${item["reservedStock"]} ${item["unit"]}',
                                                style: theme
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 1.h),
                                    Row(
                                      children: [
                                        CustomIconWidget(
                                          iconName: 'event',
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                          size: 14,
                                        ),
                                        SizedBox(width: 1.w),
                                        Text(
                                          _formatDate(item["nextExpiration"]
                                              as DateTime),
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: theme
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
