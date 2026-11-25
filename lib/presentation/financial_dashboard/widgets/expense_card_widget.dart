import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ExpenseCardWidget extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  const ExpenseCardWidget({
    super.key,
    required this.data,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount = data["amount"] as num;
    final currency = data["currency"] as String;
    final change = data["change"] as num;
    final trend = data["trend"] as String;

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showContextMenu(context),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.errorLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomIconWidget(
                    iconName: 'payments',
                    color: AppTheme.errorLight,
                    size: 20,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: trend == 'up'
                        ? AppTheme.successLight.withValues(alpha: 0.1)
                        : AppTheme.errorLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName:
                            trend == 'up' ? 'arrow_upward' : 'arrow_downward',
                        color: trend == 'up'
                            ? AppTheme.successLight
                            : AppTheme.errorLight,
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${change.abs()}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: trend == 'up'
                              ? AppTheme.successLight
                              : AppTheme.errorLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              'Dépenses',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              [
                _formatCurrency(amount, currency),
                if (data['amountUsd'] case final num usd) _formatCurrency(usd, 'USD'),
              ].join('\n'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 18.sp,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(num amount, String currency) {
    final formatted = amount.toStringAsFixed(currency == 'USD' ? 2 : 0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
    return '$formatted $currency';
  }

  void _showContextMenu(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CustomIconWidget(
                iconName: 'file_download',
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              title: Text('Exporter', style: theme.textTheme.bodyLarge),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'notifications',
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              title:
                  Text('Définir une alerte', style: theme.textTheme.bodyLarge),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'history',
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              title:
                  Text('Voir l\'historique', style: theme.textTheme.bodyLarge),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
