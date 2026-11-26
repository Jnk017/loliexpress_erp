import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Order summary card widget
/// Displays order totals and create order button (sticky bottom)
class OrderSummaryCard extends StatelessWidget {
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final VoidCallback onCreateOrder;
  final bool isProcessing;
  final String currency;

  const OrderSummaryCard({
    super.key,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.onCreateOrder,
    this.isProcessing = false,
    this.currency = 'CDF',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Summary rows
              _buildSummaryRow(
                context,
                'Sous-total',
                '${subtotal.toStringAsFixed(2)} $currency',
                false,
              ),
              if (discount > 0) ...[
                SizedBox(height: 1.h),
                _buildSummaryRow(
                  context,
                  'Remise',
                  '-${discount.toStringAsFixed(2)} $currency',
                  false,
                  color: theme.colorScheme.tertiary,
                ),
              ],
              SizedBox(height: 1.h),
              _buildSummaryRow(
                context,
                'TVA (18%)',
                '${tax.toStringAsFixed(2)} $currency',
                false,
              ),
              SizedBox(height: 1.h),
              Divider(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
              SizedBox(height: 1.h),
              _buildSummaryRow(
                context,
                'Total',
                '${total.toStringAsFixed(2)} $currency',
                true,
              ),
              SizedBox(height: 2.h),
              // Create order button
              SizedBox(
                width: double.infinity,
                height: 6.h,
                child: ElevatedButton(
                  onPressed: isProcessing ? null : onCreateOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isProcessing
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomIconWidget(
                              iconName: 'check_circle',
                              color: theme.colorScheme.onPrimary,
                              size: 20,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              'Créer la commande',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value,
    bool isTotal, {
    Color? color,
  }) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                )
              : theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
        ),
        Text(
          value,
          style: isTotal
              ? theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                )
              : theme.textTheme.bodyMedium?.copyWith(
                  color: color ?? theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
        ),
      ],
    );
  }
}
