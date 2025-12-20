import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Order items list widget
/// Displays selected products with quantity controls and swipe actions
class OrderItemsList extends StatelessWidget {
  final List<Map<String, dynamic>> orderItems;
  final Function(int, int) onQuantityChange;
  final Function(int) onRemove;
  final Function(int) onEdit;

  const OrderItemsList({
    super.key,
    required this.orderItems,
    required this.onQuantityChange,
    required this.onRemove,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (orderItems.isEmpty) {
      return Card(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Column(
            children: [
              CustomIconWidget(
                iconName: 'shopping_cart',
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                size: 48,
              ),
              SizedBox(height: 2.h),
              Text(
                'Aucun produit ajouté',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'Ajoutez des produits pour créer une commande',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Text(
              'Articles de la commande (${orderItems.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: orderItems.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
            itemBuilder: (context, index) {
              return _buildOrderItem(context, orderItems[index], index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(
    BuildContext context,
    Map<String, dynamic> item,
    int index,
  ) {
    final theme = Theme.of(context);
    final quantity = item["quantity"] as int;
    final unitPrice = item["unitPrice"] as double;
    final total = quantity * unitPrice;

    return Slidable(
      key: ValueKey(item["productId"]),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(index),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            icon: Icons.edit,
            label: 'Modifier',
          ),
          SlidableAction(
            onPressed: (_) => onRemove(index),
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
            icon: Icons.delete,
            label: 'Supprimer',
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          children: [
            // Product image
            Container(
              width: 15.w,
              height: 15.w,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CustomImageWidget(
                  imageUrl: item["image"] as String,
                  width: 15.w,
                  height: 15.w,
                  fit: BoxFit.cover,
                  semanticLabel: item["semanticLabel"] as String,
                ),
              ),
            ),
            SizedBox(width: 3.w),
            // Product details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item["name"] as String,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    '${unitPrice.toStringAsFixed(0)} FCFA × $quantity',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    '${total.toStringAsFixed(0)} FCFA',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Quantity controls
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: CustomIconWidget(
                      iconName: 'remove',
                      color: quantity > 1
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.5),
                      size: 20,
                    ),
                    onPressed: quantity > 1
                        ? () => onQuantityChange(index, quantity - 1)
                        : null,
                    constraints: BoxConstraints(
                      minWidth: 8.w,
                      minHeight: 8.w,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  Container(
                    constraints: BoxConstraints(minWidth: 10.w),
                    child: Text(
                      quantity.toString(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: CustomIconWidget(
                      iconName: 'add',
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    onPressed: () => onQuantityChange(index, quantity + 1),
                    constraints: BoxConstraints(
                      minWidth: 8.w,
                      minHeight: 8.w,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
