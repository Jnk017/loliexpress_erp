import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Customer card widget with swipe actions
class CustomerCardWidget extends StatelessWidget {
  final Map<String, dynamic> customer;
  final VoidCallback onTap;
  final VoidCallback onCall;
  final VoidCallback onEmail;
  final VoidCallback onNewOrder;
  final VoidCallback onPaymentReceipt;
  final VoidCallback onCreditLimit;
  final VoidCallback onNotes;

  const CustomerCardWidget({
    super.key,
    required this.customer,
    required this.onTap,
    required this.onCall,
    required this.onEmail,
    required this.onNewOrder,
    required this.onPaymentReceipt,
    required this.onCreditLimit,
    required this.onNotes,
  });

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status.toLowerCase()) {
      case 'current':
        return const Color(0xFF27AE60);
      case 'approaching':
        return const Color(0xFFF39C12);
      case 'overdue':
        return const Color(0xFFE74C3C);
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Slidable(
        key: ValueKey(customer['id']),
        startActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => onCall(),
              backgroundColor: const Color(0xFF2E5984),
              foregroundColor: Colors.white,
              icon: Icons.phone,
              label: 'Appeler',
            ),
            SlidableAction(
              onPressed: (_) => onEmail(),
              backgroundColor: const Color(0xFF1B365D),
              foregroundColor: Colors.white,
              icon: Icons.email,
              label: 'Email',
            ),
            SlidableAction(
              onPressed: (_) => onNewOrder(),
              backgroundColor: const Color(0xFFFF6B35),
              foregroundColor: Colors.white,
              icon: Icons.add_shopping_cart,
              label: 'Commande',
            ),
            SlidableAction(
              onPressed: (_) => onPaymentReceipt(),
              backgroundColor: const Color(0xFF27AE60),
              foregroundColor: Colors.white,
              icon: Icons.payment,
              label: 'Paiement',
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => onCreditLimit(),
              backgroundColor: const Color(0xFFF39C12),
              foregroundColor: Colors.white,
              icon: Icons.credit_card,
              label: 'Crédit',
            ),
            SlidableAction(
              onPressed: (_) => onNotes(),
              backgroundColor: const Color(0xFF7F8C8D),
              foregroundColor: Colors.white,
              icon: Icons.note,
              label: 'Notes',
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer['companyName'] as String,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            customer['contactPerson'] as String,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          customer['paymentStatus'] as String,
                          theme,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        customer['paymentStatus'] as String,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _getStatusColor(
                            customer['paymentStatus'] as String,
                            theme,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        icon: 'account_balance_wallet',
                        label: 'Solde',
                        value: customer['outstandingBalance'] as String,
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoItem(
                        icon: 'calendar_today',
                        label: 'Dernière commande',
                        value: customer['lastOrderDate'] as String,
                        theme: theme,
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

  Widget _buildInfoItem({
    required String icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CustomIconWidget(
              iconName: icon,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
