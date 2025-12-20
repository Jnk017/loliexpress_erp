import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget for displaying a notification card
class NotificationCardWidget extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback? onMarkAsRead;

  const NotificationCardWidget({
    Key? key,
    required this.notification,
    this.onMarkAsRead,
  }) : super(key: key);

  IconData _getNotificationIcon(String notificationType) {
    switch (notificationType) {
      case 'new_order':
        return Icons.shopping_cart;
      case 'overdue_invoice':
        return Icons.warning;
      case 'low_stock':
        return Icons.inventory_2;
      case 'payment_received':
        return Icons.payment;
      case 'order_delivered':
        return Icons.local_shipping;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String notificationType) {
    switch (notificationType) {
      case 'new_order':
        return Colors.blue;
      case 'overdue_invoice':
        return Colors.orange;
      case 'low_stock':
        return Colors.red;
      case 'payment_received':
        return Colors.green;
      case 'order_delivered':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationType = notification['notification_type'] as String;
    final subject = notification['subject'] as String;
    final message = notification['message'] as String;
    final status = notification['status'] as String;
    final createdAt = DateTime.parse(notification['created_at'] as String);

    final isPending = status == 'pending';
    final iconColor = _getNotificationColor(notificationType);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isPending ? 3 : 1,
      color: isPending ? Colors.white : Colors.grey[50],
      child: InkWell(
        onTap: isPending ? onMarkAsRead : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getNotificationIcon(notificationType),
                  color: iconColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),

              // Notification content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isPending)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            subject,
                            style: TextStyle(
                              fontWeight:
                                  isPending ? FontWeight.w600 : FontWeight.w500,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 13,
                        color: isPending ? Colors.black87 : Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),

              // Mark as read button for pending notifications
              if (isPending)
                IconButton(
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  onPressed: onMarkAsRead,
                  color: Colors.green,
                  tooltip: 'Marquer comme lu',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
