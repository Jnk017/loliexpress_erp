import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class EmptyStateWidget extends StatelessWidget {
  final String message;
  final String actionText;
  final VoidCallback? onActionPressed;
  final bool showFilterAdjustment;

  const EmptyStateWidget({
    super.key,
    required this.message,
    required this.actionText,
    this.onActionPressed,
    this.showFilterAdjustment = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Empty State Icon
            Container(
              width: 30.w,
              height: 30.w,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName:
                      showFilterAdjustment ? 'filter_list_off' : 'inventory_2',
                  color: colorScheme.primary,
                  size: 60,
                ),
              ),
            ),
            SizedBox(height: 3.h),
            // Message
            Text(
              message,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            // Subtitle
            Text(
              showFilterAdjustment
                  ? 'Essayez d\'ajuster vos filtres pour voir plus de résultats'
                  : 'Commencez par ajouter votre premier produit',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            // Action Button
            if (onActionPressed != null)
              ElevatedButton.icon(
                onPressed: onActionPressed,
                icon: CustomIconWidget(
                  iconName: showFilterAdjustment ? 'filter_list' : 'add',
                  color: colorScheme.onPrimary,
                  size: 20,
                ),
                label: Text(
                  actionText,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onPrimary,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 6.w,
                    vertical: 2.h,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
