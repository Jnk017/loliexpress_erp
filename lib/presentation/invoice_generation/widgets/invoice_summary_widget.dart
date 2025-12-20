import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Sticky bottom summary card with totals and action buttons
class InvoiceSummaryWidget extends StatelessWidget {
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final String currency;
  final VoidCallback onSaveDraft;
  final VoidCallback onGeneratePDF;
  final VoidCallback onSendInvoice;
  final bool isProcessing;

  const InvoiceSummaryWidget({
    super.key,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.currency,
    required this.onSaveDraft,
    required this.onGeneratePDF,
    required this.onSendInvoice,
    this.isProcessing = false,
  });

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(2).replaceAll('.', ',').replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Summary Details
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      context: context,
                      label: 'Sous-total',
                      value: '${_formatCurrency(subtotal)} $currency',
                      isSubtotal: true,
                    ),
                    if (discount > 0) ...[
                      SizedBox(height: 1.h),
                      _buildSummaryRow(
                        context: context,
                        label: 'Remise',
                        value: '-${_formatCurrency(discount)} $currency',
                        isDiscount: true,
                      ),
                    ],
                    SizedBox(height: 1.h),
                    _buildSummaryRow(
                      context: context,
                      label: 'TVA',
                      value: '${_formatCurrency(tax)} $currency',
                      isSubtotal: true,
                    ),
                    Divider(height: 2.h, thickness: 1),
                    _buildSummaryRow(
                      context: context,
                      label: 'Total',
                      value: '${_formatCurrency(total)} $currency',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2.h),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isProcessing ? null : onSaveDraft,
                      icon: CustomIconWidget(
                        iconName: 'save',
                        color: isProcessing
                            ? theme.colorScheme.onSurface
                                .withValues(alpha: 0.38)
                            : theme.colorScheme.primary,
                        size: 20,
                      ),
                      label: const Text('Brouillon'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: isProcessing ? null : onGeneratePDF,
                      icon: isProcessing
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
                          : CustomIconWidget(
                              iconName: 'picture_as_pdf',
                              color: theme.colorScheme.onPrimary,
                              size: 20,
                            ),
                      label:
                          Text(isProcessing ? 'Génération...' : 'Générer PDF'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: isProcessing ? null : onSendInvoice,
                  icon: CustomIconWidget(
                    iconName: 'send',
                    color: isProcessing
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                        : theme.colorScheme.primary,
                    size: 20,
                  ),
                  label: const Text('Envoyer la facture'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required BuildContext context,
    required String label,
    required String value,
    bool isTotal = false,
    bool isSubtotal = false,
    bool isDiscount = false,
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
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                )
              : isDiscount
                  ? theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.successLight,
                      fontWeight: FontWeight.w500,
                    )
                  : theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
        ),
      ],
    );
  }
}
