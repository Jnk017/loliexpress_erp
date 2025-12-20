import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ProductCardWidget extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onViewHistory;
  final VoidCallback onToggleLowStockAlert;
  final bool isSelected;

  const ProductCardWidget({
    super.key,
    required this.product,
    required this.onTap,
    required this.onEdit,
    required this.onDuplicate,
    required this.onViewHistory,
    required this.onToggleLowStockAlert,
    this.isSelected = false,
  });

  Color _getStockIndicatorColor(int stock, int minStock, int criticalStock) {
    if (stock <= criticalStock) {
      return const Color(0xFFE74C3C); // Red - Critical
    } else if (stock <= minStock) {
      return const Color(0xFFF39C12); // Yellow - Low
    } else {
      return const Color(0xFF27AE60); // Green - Adequate
    }
  }

  String _getStockStatus(int stock, int minStock, int criticalStock) {
    if (stock <= criticalStock) {
      return 'Critique';
    } else if (stock <= minStock) {
      return 'Faible';
    } else {
      return 'Suffisant';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final int currentStock = product['currentStock'] as int;
    final int minStock = product['minStock'] as int;
    final int criticalStock = product['criticalStock'] as int;
    final Color stockColor =
        _getStockIndicatorColor(currentStock, minStock, criticalStock);
    final String stockStatus =
        _getStockStatus(currentStock, minStock, criticalStock);

    return Slidable(
      key: ValueKey(product['id']),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            icon: Icons.edit,
            label: 'Modifier',
          ),
          SlidableAction(
            onPressed: (_) => onDuplicate(),
            backgroundColor: colorScheme.secondary,
            foregroundColor: colorScheme.onSecondary,
            icon: Icons.content_copy,
            label: 'Dupliquer',
          ),
          SlidableAction(
            onPressed: (_) => onViewHistory(),
            backgroundColor: colorScheme.tertiary,
            foregroundColor: colorScheme.onTertiary,
            icon: Icons.history,
            label: 'Historique',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onToggleLowStockAlert(),
            backgroundColor: const Color(0xFFF39C12),
            foregroundColor: Colors.white,
            icon: product['lowStockAlertEnabled'] == true
                ? Icons.notifications_off
                : Icons.notifications_active,
            label: product['lowStockAlertEnabled'] == true
                ? 'Désactiver'
                : 'Activer',
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        elevation: isSelected ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide(color: colorScheme.primary, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Container(
                  width: 20.w,
                  height: 20.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: colorScheme.surface,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CustomImageWidget(
                      imageUrl: product['image'] as String,
                      width: 20.w,
                      height: 20.w,
                      fit: BoxFit.cover,
                      semanticLabel: product['semanticLabel'] as String,
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name
                      Text(
                        product['name'] as String,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 0.5.h),
                      // SKU
                      Text(
                        'SKU: ${product['sku']}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      // Stock and Price Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Stock Indicator
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: stockColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: stockColor,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: stockColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 1.w),
                                Text(
                                  '$currentStock unités',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: stockColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Price
                          Text(
                            '${product['price']} FCFA',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 0.5.h),
                      // Stock Status
                      Text(
                        'Statut: $stockStatus',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: stockColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Selection Indicator
                if (isSelected)
                  Container(
                    padding: EdgeInsets.all(1.w),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: CustomIconWidget(
                      iconName: 'check',
                      color: colorScheme.onPrimary,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}