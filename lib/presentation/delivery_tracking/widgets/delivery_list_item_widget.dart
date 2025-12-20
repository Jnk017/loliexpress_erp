import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class DeliveryListItemWidget extends StatelessWidget {
  final Map<String, dynamic> delivery;
  final VoidCallback onNavigate;
  final VoidCallback onCall;
  final VoidCallback onMarkDelivered;
  final VoidCallback onReportIssue;

  const DeliveryListItemWidget({
    super.key,
    required this.delivery,
    required this.onNavigate,
    required this.onCall,
    required this.onMarkDelivered,
    required this.onReportIssue,
  });

  Color _getStatusColor(BuildContext context, String status) {
    final theme = Theme.of(context);
    switch (status) {
      case 'completed':
        return AppTheme.successLight;
      case 'in_progress':
        return AppTheme.warningLight;
      case 'pending':
      default:
        return theme.colorScheme.primary;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'Livré';
      case 'in_progress':
        return 'En cours';
      case 'pending':
      default:
        return 'En attente';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = delivery["status"] as String;
    final isCompleted = status == "completed";

    return Slidable(
      key: ValueKey(delivery["id"]),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onNavigate(),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            icon: Icons.navigation,
            label: 'Naviguer',
          ),
          SlidableAction(
            onPressed: (_) => onCall(),
            backgroundColor: AppTheme.successLight,
            foregroundColor: Colors.white,
            icon: Icons.phone,
            label: 'Appeler',
          ),
        ],
      ),
      endActionPane: isCompleted
          ? null
          : ActionPane(
              motion: const ScrollMotion(),
              children: [
                SlidableAction(
                  onPressed: (_) => onMarkDelivered(),
                  backgroundColor: AppTheme.successLight,
                  foregroundColor: Colors.white,
                  icon: Icons.check_circle,
                  label: 'Livré',
                ),
                SlidableAction(
                  onPressed: (_) => onReportIssue(),
                  backgroundColor: AppTheme.errorLight,
                  foregroundColor: Colors.white,
                  icon: Icons.report_problem,
                  label: 'Problème',
                ),
              ],
            ),
      child: Card(
        margin: EdgeInsets.only(bottom: 2.h),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Order Number Badge
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getStatusColor(context, status),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${delivery["orderNumber"]}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 3.w),

                  // Customer Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          delivery["customerName"] as String,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          delivery["address"] as String,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Status Badge
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: _getStatusColor(context, status)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(status),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _getStatusColor(context, status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 2.h),

              // Time and Package Info
              Row(
                children: [
                  // Time Window
                  Expanded(
                    child: Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'access_time',
                          color: theme.colorScheme.primary,
                          size: 16,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          delivery["timeWindow"] as String,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),

                  // Estimated Arrival
                  if (!isCompleted)
                    Expanded(
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'schedule',
                            color: AppTheme.warningLight,
                            size: 16,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            'ETA: ${delivery["estimatedArrival"]}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.warningLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Completed Time
                  if (isCompleted)
                    Expanded(
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'check_circle',
                            color: AppTheme.successLight,
                            size: 16,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            'Livré à ${delivery["completedAt"]}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.successLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              SizedBox(height: 1.h),

              // Package Count and Payment
              Row(
                children: [
                  // Package Count
                  Expanded(
                    child: Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'inventory_2',
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 16,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          '${delivery["packageCount"]} colis',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),

                  // Payment Required
                  if (delivery["paymentRequired"] == true)
                    Expanded(
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'payments',
                            color: AppTheme.errorLight,
                            size: 16,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            delivery["paymentAmount"] as String,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.errorLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              // Notes Section
              if (delivery["notes"] != null &&
                  (delivery["notes"] as String).isNotEmpty) ...[
                SizedBox(height: 1.h),
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'info_outline',
                        color: theme.colorScheme.primary,
                        size: 16,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          delivery["notes"] as String,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
