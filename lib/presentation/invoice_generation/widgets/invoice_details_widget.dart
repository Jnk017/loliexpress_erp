import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Invoice details section with date pickers, currency, and payment method
class InvoiceDetailsWidget extends StatelessWidget {
  final DateTime issueDate;
  final DateTime dueDate;
  final String currency;
  final String paymentMethod;
  final VoidCallback onIssueDateTap;
  final VoidCallback onDueDateTap;
  final VoidCallback onCurrencyTap;
  final VoidCallback onPaymentMethodTap;

  const InvoiceDetailsWidget({
    super.key,
    required this.issueDate,
    required this.dueDate,
    required this.currency,
    required this.paymentMethod,
    required this.onIssueDateTap,
    required this.onDueDateTap,
    required this.onCurrencyTap,
    required this.onPaymentMethodTap,
  });

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Détails de la facture',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          // Issue Date
          _buildDetailItem(
            context: context,
            icon: 'calendar_today',
            label: 'Date d\'émission',
            value: _formatDate(issueDate),
            onTap: onIssueDateTap,
          ),
          SizedBox(height: 2.h),
          // Due Date
          _buildDetailItem(
            context: context,
            icon: 'event',
            label: 'Date d\'échéance',
            value: _formatDate(dueDate),
            onTap: onDueDateTap,
          ),
          SizedBox(height: 2.h),
          // Currency
          _buildDetailItem(
            context: context,
            icon: 'attach_money',
            label: 'Devise',
            value: currency,
            onTap: onCurrencyTap,
          ),
          SizedBox(height: 2.h),
          // Payment Method
          _buildDetailItem(
            context: context,
            icon: 'payment',
            label: 'Mode de paiement',
            value: paymentMethod,
            onTap: onPaymentMethodTap,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required BuildContext context,
    required String icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: icon,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            CustomIconWidget(
              iconName: 'arrow_forward_ios',
              color: theme.colorScheme.onSurfaceVariant,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
