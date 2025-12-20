import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ScanResultBottomSheet extends StatelessWidget {
  final Map<String, dynamic> product;
  final String code;
  final String format;
  final VoidCallback onAddToOrder;
  final VoidCallback onViewDetails;
  final VoidCallback onAdjustStock;
  final VoidCallback onScanAnother;

  const ScanResultBottomSheet({
    super.key,
    required this.product,
    required this.code,
    required this.format,
    required this.onAddToOrder,
    required this.onViewDetails,
    required this.onAdjustStock,
    required this.onScanAnother,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 2.h),
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 2.h),

          // Success indicator
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: CustomIconWidget(
              iconName: 'check_circle',
              size: 48,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 2.h),

          Text(
            'Produit trouvé',
            style: theme.textTheme.titleLarge,
          ),
          SizedBox(height: 1.h),

          // Barcode info
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName: 'qr_code_2',
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 2.w),
                Text(
                  '$code • $format',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),

          // Product card
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                // Product image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CustomImageWidget(
                    imageUrl: product["image"] as String,
                    width: 20.w,
                    height: 20.w,
                    fit: BoxFit.cover,
                    semanticLabel: product["semanticLabel"] as String,
                  ),
                ),
                SizedBox(width: 3.w),

                // Product info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product["name"] as String,
                        style: theme.textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'SKU: ${product["sku"]}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: (product["stock"] as int) > 100
                                  ? theme.colorScheme.primary
                                      .withValues(alpha: 0.1)
                                  : theme.colorScheme.error
                                      .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CustomIconWidget(
                                  iconName: 'inventory_2',
                                  size: 14,
                                  color: (product["stock"] as int) > 100
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.error,
                                ),
                                SizedBox(width: 1.w),
                                Text(
                                  '${product["stock"]} unités',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: (product["stock"] as int) > 100
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        product["price"] as String,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),

          // Action buttons
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onAddToOrder,
                        icon: CustomIconWidget(
                          iconName: 'add_shopping_cart',
                          size: 20,
                          color: theme.colorScheme.onPrimary,
                        ),
                        label: const Text('Ajouter'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onViewDetails,
                        icon: CustomIconWidget(
                          iconName: 'info_outline',
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        label: const Text('Détails'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onAdjustStock,
                        icon: CustomIconWidget(
                          iconName: 'edit',
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        label: const Text('Ajuster stock'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: onScanAnother,
                        icon: CustomIconWidget(
                          iconName: 'qr_code_scanner',
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        label: const Text('Scanner'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),
        ],
      ),
    );
  }
}
