import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class AlertsViewWidget extends StatefulWidget {
  final String selectedLocation;

  const AlertsViewWidget({
    super.key,
    required this.selectedLocation,
  });

  @override
  State<AlertsViewWidget> createState() => _AlertsViewWidgetState();
}

class _AlertsViewWidgetState extends State<AlertsViewWidget> {
  final List<Map<String, dynamic>> _alerts = [
    {
      "id": "ALT001",
      "type": "expired",
      "priority": "critical",
      "product": "Jus d'Orange 25cl",
      "quantity": 15,
      "unit": "unités",
      "location": "Zone de Transit",
      "date": DateTime(2024, 12, 31),
      "batchNumber": "LOT2024-JO-005",
      "message": "Produit expiré depuis 15 jours",
      "actionRequired": true,
    },
    {
      "id": "ALT002",
      "type": "expiring",
      "priority": "high",
      "product": "Fanta Orange 50cl",
      "quantity": 420,
      "unit": "unités",
      "location": "Entrepôt Secondaire",
      "date": DateTime(2025, 1, 20),
      "batchNumber": "LOT2024-FO-003",
      "message": "Expire dans 5 jours",
      "actionRequired": true,
    },
    {
      "id": "ALT003",
      "type": "low_stock",
      "priority": "high",
      "product": "Sprite 1.5L",
      "quantity": 85,
      "unit": "unités",
      "location": "Entrepôt Principal",
      "reorderPoint": 200,
      "batchNumber": "LOT2024-SP-002",
      "message": "Stock en dessous du point de réapprovisionnement",
      "actionRequired": true,
    },
    {
      "id": "ALT004",
      "type": "discrepancy",
      "priority": "medium",
      "product": "Eau Minérale 1L",
      "expectedQuantity": 2150,
      "actualQuantity": 2100,
      "difference": -50,
      "unit": "unités",
      "location": "Entrepôt Principal",
      "date": DateTime(2025, 1, 14),
      "batchNumber": "LOT2024-EM-004",
      "message": "Écart de 50 unités détecté lors de l'inventaire",
      "actionRequired": true,
    },
    {
      "id": "ALT005",
      "type": "reorder",
      "priority": "medium",
      "product": "Coca-Cola 33cl",
      "quantity": 1250,
      "unit": "unités",
      "location": "Entrepôt Principal",
      "reorderPoint": 500,
      "suggestedOrder": 2000,
      "batchNumber": "LOT2024-CC-001",
      "message": "Suggestion de réapprovisionnement",
      "actionRequired": false,
    },
  ];

  Color _getAlertPriorityColor(String priority, ThemeData theme) {
    switch (priority) {
      case 'critical':
        return theme.colorScheme.error;
      case 'high':
        return const Color(0xFFF39C12);
      case 'medium':
        return const Color(0xFF2E5984);
      case 'low':
        return const Color(0xFF27AE60);
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  IconData _getAlertTypeIcon(String type) {
    switch (type) {
      case 'expired':
        return Icons.dangerous;
      case 'expiring':
        return Icons.warning;
      case 'low_stock':
        return Icons.inventory_2;
      case 'discrepancy':
        return Icons.error_outline;
      case 'reorder':
        return Icons.shopping_cart;
      default:
        return Icons.notifications;
    }
  }

  String _getAlertTypeLabel(String type) {
    switch (type) {
      case 'expired':
        return 'Produit Expiré';
      case 'expiring':
        return 'Expiration Proche';
      case 'low_stock':
        return 'Stock Faible';
      case 'discrepancy':
        return 'Écart Inventaire';
      case 'reorder':
        return 'Réapprovisionnement';
      default:
        return 'Alerte';
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'critical':
        return 'Critique';
      case 'high':
        return 'Élevée';
      case 'medium':
        return 'Moyenne';
      case 'low':
        return 'Faible';
      default:
        return 'Inconnue';
    }
  }

  void _showAlertDetails(Map<String, dynamic> alert) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 12.w,
                    height: 0.5.h,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Container(
                      width: 12.w,
                      height: 12.w,
                      decoration: BoxDecoration(
                        color: _getAlertPriorityColor(
                          alert["priority"] as String,
                          theme,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          _getAlertTypeIcon(alert["type"] as String),
                          color: _getAlertPriorityColor(
                            alert["priority"] as String,
                            theme,
                          ),
                          size: 24,
                        ),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getAlertTypeLabel(alert["type"] as String),
                            style: theme.textTheme.titleLarge,
                          ),
                          Text(
                            'Priorité: ${_getPriorityLabel(alert["priority"] as String)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: _getAlertPriorityColor(
                                alert["priority"] as String,
                                theme,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 3.h),
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: _getAlertPriorityColor(
                      alert["priority"] as String,
                      theme,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: _getAlertPriorityColor(
                          alert["priority"] as String,
                          theme,
                        ),
                        size: 20,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          alert["message"] as String,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 3.h),
                _buildDetailRow('Produit', alert["product"] as String, theme),
                if (alert["quantity"] != null)
                  _buildDetailRow(
                    'Quantité',
                    '${alert["quantity"]} ${alert["unit"]}',
                    theme,
                  ),
                if (alert["location"] != null)
                  _buildDetailRow(
                    'Emplacement',
                    alert["location"] as String,
                    theme,
                  ),
                if (alert["batchNumber"] != null)
                  _buildDetailRow(
                    'Numéro de Lot',
                    alert["batchNumber"] as String,
                    theme,
                  ),
                if (alert["date"] != null)
                  _buildDetailRow(
                    'Date',
                    '${(alert["date"] as DateTime).day}/${(alert["date"] as DateTime).month}/${(alert["date"] as DateTime).year}',
                    theme,
                  ),
                if (alert["reorderPoint"] != null)
                  _buildDetailRow(
                    'Point de Réapprovisionnement',
                    '${alert["reorderPoint"]} ${alert["unit"]}',
                    theme,
                  ),
                if (alert["suggestedOrder"] != null)
                  _buildDetailRow(
                    'Commande Suggérée',
                    '${alert["suggestedOrder"]} ${alert["unit"]}',
                    theme,
                  ),
                if (alert["difference"] != null)
                  _buildDetailRow(
                    'Écart',
                    '${alert["difference"]} ${alert["unit"]}',
                    theme,
                  ),
                SizedBox(height: 3.h),
                if (alert["actionRequired"] == true)
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _handleAlertAction(alert);
                          },
                          child: const Text('Résoudre l\'Alerte'),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // Dismiss alert action
                          },
                          child: const Text('Ignorer'),
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

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40.w,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _handleAlertAction(Map<String, dynamic> alert) {
    final type = alert["type"] as String;
    switch (type) {
      case 'expired':
        // Navigate to disposal/return screen
        break;
      case 'expiring':
        // Navigate to promotion/discount screen
        break;
      case 'low_stock':
        // Navigate to purchase order screen
        break;
      case 'discrepancy':
        // Navigate to adjustment screen
        break;
      case 'reorder':
        // Navigate to purchase order screen
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _alerts.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomIconWidget(
                  iconName: 'notifications_none',
                  color:
                      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  size: 64,
                ),
                SizedBox(height: 2.h),
                Text(
                  'Aucune alerte active',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        : ListView.separated(
            padding: EdgeInsets.all(4.w),
            itemCount: _alerts.length,
            separatorBuilder: (context, index) => SizedBox(height: 1.h),
            itemBuilder: (context, index) {
              final alert = _alerts[index];
              return InkWell(
                onTap: () => _showAlertDetails(alert),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getAlertPriorityColor(
                        alert["priority"] as String,
                        theme,
                      ).withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10.w,
                            height: 10.w,
                            decoration: BoxDecoration(
                              color: _getAlertPriorityColor(
                                alert["priority"] as String,
                                theme,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Icon(
                                _getAlertTypeIcon(alert["type"] as String),
                                color: _getAlertPriorityColor(
                                  alert["priority"] as String,
                                  theme,
                                ),
                                size: 20,
                              ),
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  alert["product"] as String,
                                  style: theme.textTheme.titleMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _getAlertTypeLabel(alert["type"] as String),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: _getAlertPriorityColor(
                                alert["priority"] as String,
                                theme,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getPriorityLabel(alert["priority"] as String),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: _getAlertPriorityColor(
                                  alert["priority"] as String,
                                  theme,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.5.h),
                      Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: _getAlertPriorityColor(
                            alert["priority"] as String,
                            theme,
                          ).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          alert["message"] as String,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      if (alert["actionRequired"] == true) ...[
                        SizedBox(height: 1.5.h),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _handleAlertAction(alert),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: _getAlertPriorityColor(
                                      alert["priority"] as String,
                                      theme,
                                    ),
                                  ),
                                  foregroundColor: _getAlertPriorityColor(
                                    alert["priority"] as String,
                                    theme,
                                  ),
                                ),
                                child: const Text('Résoudre'),
                              ),
                            ),
                            SizedBox(width: 2.w),
                            IconButton(
                              onPressed: () {
                                // Dismiss alert
                              },
                              icon: CustomIconWidget(
                                iconName: 'close',
                                color: theme.colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                              tooltip: 'Ignorer',
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
  }
}
