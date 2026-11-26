import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

/// Advanced notification card with swipe gestures for contextual actions
class NotificationSwipeCardWidget extends StatelessWidget {
  final Map<String, dynamic> notification;
  final String priority;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onTakeAction;
  final VoidCallback? onDismiss;

  const NotificationSwipeCardWidget({
    super.key,
    required this.notification,
    required this.priority,
    this.onMarkAsRead,
    this.onTakeAction,
    this.onDismiss,
  });

  IconData _getNotificationIcon(String notificationType) {
    switch (notificationType) {
      case 'new_order':
        return Icons.shopping_cart;
      case 'overdue_invoice':
      case 'payment_pending':
        return Icons.warning;
      case 'low_stock':
        return Icons.inventory_2;
      case 'payment_received':
        return Icons.payment;
      case 'order_delivered':
      case 'order_delayed':
        return Icons.local_shipping;
      case 'system_error':
        return Icons.error;
      default:
        return Icons.notifications;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'critical':
        return Colors.red;
      case 'important':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  Color _getNotificationColor(String notificationType) {
    switch (notificationType) {
      case 'new_order':
        return Colors.blue;
      case 'overdue_invoice':
      case 'payment_pending':
        return Colors.orange;
      case 'low_stock':
      case 'system_error':
        return Colors.red;
      case 'payment_received':
        return Colors.green;
      case 'order_delivered':
        return Colors.purple;
      case 'order_delayed':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationType = notification['notification_type'] as String;
    final subject = notification['subject'] as String;
    final message = notification['message'] as String;
    final createdAt = DateTime.parse(notification['created_at'] as String);

    final isUnread = notification['read_at'] == null;
    final iconColor = _getNotificationColor(notificationType);
    final priorityColor = _getPriorityColor(priority);

    return Dismissible(
      key: Key(notification['id']),
      background: _buildSwipeBackground(
        alignment: Alignment.centerLeft,
        color: Colors.green.shade400,
        icon: Icons.check_circle,
        label: 'Marquer lu',
      ),
      secondaryBackground: _buildSwipeBackground(
        alignment: Alignment.centerRight,
        color: Colors.red.shade400,
        icon: Icons.delete,
        label: 'Rejeter',
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onMarkAsRead?.call();
        } else {
          onDismiss?.call();
        }
        return false;
      },
      child: Card(
        margin: EdgeInsets.only(bottom: 2.h),
        elevation: isUnread ? 4 : 2,
        color: isUnread ? Colors.white : Colors.grey[50],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(color: priorityColor.withAlpha(51), width: 2),
        ),
        child: InkWell(
          onTap: onTakeAction,
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Priority indicator + icon
                Column(
                  children: [
                    Container(
                      width: 12.w,
                      height: 12.w,
                      decoration: BoxDecoration(
                        color: iconColor.withAlpha(26),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Icon(
                        _getNotificationIcon(notificationType),
                        color: iconColor,
                        size: 24,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: priorityColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 3.w),

                // Notification content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              margin: EdgeInsets.only(right: 2.w),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              subject,
                              style: TextStyle(
                                fontWeight: isUnread
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                fontSize: 14.sp,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isUnread ? Colors.black87 : Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 1.h),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(createdAt),
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.grey[500],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: priorityColor.withAlpha(26),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Text(
                              priority == 'critical'
                                  ? 'Critique'
                                  : priority == 'important'
                                      ? 'Important'
                                      : 'Info',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: priorityColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action buttons
                if (isUnread)
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline, size: 20),
                        onPressed: onMarkAsRead,
                        color: Colors.green,
                        tooltip: 'Marquer comme lu',
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward, size: 20),
                        onPressed: onTakeAction,
                        color: Colors.blue,
                        tooltip: 'Voir détails',
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

  Widget _buildSwipeBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      alignment: alignment,
      color: color,
      padding: EdgeInsets.symmetric(horizontal: 5.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }
}
