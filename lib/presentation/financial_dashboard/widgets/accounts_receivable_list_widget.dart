import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AccountsReceivableListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> receivables;
  final Function(Map<String, dynamic>) onItemTap;
  final Function(Map<String, dynamic>) onSendReminder;
  final Function(Map<String, dynamic>) onRecordPayment;
  final Function(Map<String, dynamic>) onViewInvoice;
  final Function(Map<String, dynamic>) onContactCustomer;

  const AccountsReceivableListWidget({
    super.key,
    required this.receivables,
    required this.onItemTap,
    required this.onSendReminder,
    required this.onRecordPayment,
    required this.onViewInvoice,
    required this.onContactCustomer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      itemCount: receivables.length,
      separatorBuilder: (context, index) => SizedBox(height: 2.h),
      itemBuilder: (context, index) {
        final receivable = receivables[index];
        return _buildReceivableItem(context, receivable, theme);
      },
    );
  }

  Widget _buildReceivableItem(
    BuildContext context,
    Map<String, dynamic> receivable,
    ThemeData theme,
  ) {
    final status = receivable["status"] as String;
    final amount = receivable["amount"] as num;
    final currency = receivable["currency"] as String;
    final customerName = receivable["customerName"] as String;
    final invoiceNumber = receivable["invoiceNumber"] as String;
    final daysOverdue = receivable["daysOverdue"] as int;

    Color statusColor;
    Color statusBgColor;
    String statusText;

    switch (status) {
      case 'current':
        statusColor = AppTheme.successLight;
        statusBgColor = AppTheme.successLight.withValues(alpha: 0.1);
        statusText = 'À jour';
        break;
      case '30-day':
        statusColor = AppTheme.warningLight;
        statusBgColor = AppTheme.warningLight.withValues(alpha: 0.1);
        statusText = '30 jours';
        break;
      case '60-day':
        statusColor = AppTheme.errorLight;
        statusBgColor = AppTheme.errorLight.withValues(alpha: 0.1);
        statusText = '60+ jours';
        break;
      default:
        statusColor = theme.colorScheme.onSurfaceVariant;
        statusBgColor = theme.colorScheme.surfaceContainerHighest;
        statusText = 'Inconnu';
    }

    return Slidable(
      key: ValueKey(receivable["id"]),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onSendReminder(receivable),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            icon: Icons.notifications_outlined,
            label: 'Rappel',
          ),
          SlidableAction(
            onPressed: (_) => onRecordPayment(receivable),
            backgroundColor: AppTheme.successLight,
            foregroundColor: Colors.white,
            icon: Icons.payment,
            label: 'Paiement',
          ),
          SlidableAction(
            onPressed: (_) => onViewInvoice(receivable),
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.onSecondary,
            icon: Icons.receipt_long,
            label: 'Facture',
          ),
          SlidableAction(
            onPressed: (_) => onContactCustomer(receivable),
            backgroundColor: AppTheme.accentLight,
            foregroundColor: Colors.white,
            icon: Icons.phone,
            label: 'Contact',
          ),
        ],
      ),
      child: InkWell(
        onTap: () => onItemTap(receivable),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.05),
                blurRadius: 4,
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
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: CustomImageWidget(
                        imageUrl: receivable["customerAvatar"] as String,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        semanticLabel: receivable["semanticLabel"] as String,
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          invoiceNumber,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Montant',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        _formatCurrency(amount, currency),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  if (daysOverdue > 0)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'En retard',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          '$daysOverdue jours',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.errorLight,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCurrency(num amount, String currency) {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
    return '$formatted $currency';
  }
}
