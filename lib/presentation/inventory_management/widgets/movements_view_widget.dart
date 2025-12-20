import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class MovementsViewWidget extends StatefulWidget {
  final String selectedLocation;

  const MovementsViewWidget({
    super.key,
    required this.selectedLocation,
  });

  @override
  State<MovementsViewWidget> createState() => _MovementsViewWidgetState();
}

class _MovementsViewWidgetState extends State<MovementsViewWidget> {
  final List<Map<String, dynamic>> _movements = [
    {
      "id": "MOV001",
      "type": "reception",
      "product": "Coca-Cola 33cl",
      "quantity": 500,
      "unit": "unités",
      "from": "Fournisseur ABC",
      "to": "Entrepôt Principal",
      "date": DateTime(2025, 1, 15, 10, 30),
      "user": "Jean Dupont",
      "batchNumber": "LOT2024-CC-001",
      "reference": "BR-2025-001",
      "status": "completed",
    },
    {
      "id": "MOV002",
      "type": "transfer",
      "product": "Sprite 1.5L",
      "quantity": 150,
      "unit": "unités",
      "from": "Entrepôt Principal",
      "to": "Entrepôt Secondaire",
      "date": DateTime(2025, 1, 14, 14, 15),
      "user": "Marie Martin",
      "batchNumber": "LOT2024-SP-002",
      "reference": "TR-2025-002",
      "status": "completed",
    },
    {
      "id": "MOV003",
      "type": "adjustment",
      "product": "Fanta Orange 50cl",
      "quantity": -25,
      "unit": "unités",
      "from": "Entrepôt Secondaire",
      "to": "Ajustement Inventaire",
      "date": DateTime(2025, 1, 13, 16, 45),
      "user": "Pierre Bernard",
      "batchNumber": "LOT2024-FO-003",
      "reference": "ADJ-2025-003",
      "status": "completed",
      "reason": "Casse pendant manutention",
    },
    {
      "id": "MOV004",
      "type": "shipment",
      "product": "Eau Minérale 1L",
      "quantity": 320,
      "unit": "unités",
      "from": "Entrepôt Principal",
      "to": "Client XYZ",
      "date": DateTime(2025, 1, 12, 9, 20),
      "user": "Sophie Dubois",
      "batchNumber": "LOT2024-EM-004",
      "reference": "LIV-2025-004",
      "status": "completed",
    },
    {
      "id": "MOV005",
      "type": "return",
      "product": "Jus d'Orange 25cl",
      "quantity": 45,
      "unit": "unités",
      "from": "Client ABC",
      "to": "Zone de Transit",
      "date": DateTime(2025, 1, 11, 11, 10),
      "user": "Luc Petit",
      "batchNumber": "LOT2024-JO-005",
      "reference": "RET-2025-005",
      "status": "pending",
      "reason": "Produits endommagés",
    },
  ];

  Color _getMovementTypeColor(String type, ThemeData theme) {
    switch (type) {
      case 'reception':
        return const Color(0xFF27AE60);
      case 'transfer':
        return theme.colorScheme.primary;
      case 'adjustment':
        return const Color(0xFFF39C12);
      case 'shipment':
        return const Color(0xFF2E5984);
      case 'return':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  IconData _getMovementTypeIcon(String type) {
    switch (type) {
      case 'reception':
        return Icons.arrow_downward;
      case 'transfer':
        return Icons.swap_horiz;
      case 'adjustment':
        return Icons.edit;
      case 'shipment':
        return Icons.arrow_upward;
      case 'return':
        return Icons.keyboard_return;
      default:
        return Icons.help_outline;
    }
  }

  String _getMovementTypeLabel(String type) {
    switch (type) {
      case 'reception':
        return 'Réception';
      case 'transfer':
        return 'Transfert';
      case 'adjustment':
        return 'Ajustement';
      case 'shipment':
        return 'Expédition';
      case 'return':
        return 'Retour';
      default:
        return 'Inconnu';
    }
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showMovementDetails(Map<String, dynamic> movement) {
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
                        color: _getMovementTypeColor(
                          movement["type"] as String,
                          theme,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          _getMovementTypeIcon(movement["type"] as String),
                          color: _getMovementTypeColor(
                            movement["type"] as String,
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
                            _getMovementTypeLabel(movement["type"] as String),
                            style: theme.textTheme.titleLarge,
                          ),
                          Text(
                            movement["reference"] as String,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 3.h),
                _buildDetailRow(
                    'Produit', movement["product"] as String, theme),
                _buildDetailRow(
                  'Quantité',
                  '${movement["quantity"]} ${movement["unit"]}',
                  theme,
                ),
                _buildDetailRow('De', movement["from"] as String, theme),
                _buildDetailRow('Vers', movement["to"] as String, theme),
                _buildDetailRow(
                  'Date',
                  _formatDateTime(movement["date"] as DateTime),
                  theme,
                ),
                _buildDetailRow(
                    'Utilisateur', movement["user"] as String, theme),
                _buildDetailRow(
                  'Numéro de Lot',
                  movement["batchNumber"] as String,
                  theme,
                ),
                if (movement["reason"] != null)
                  _buildDetailRow(
                      'Raison', movement["reason"] as String, theme),
                SizedBox(height: 3.h),
                if (movement["status"] == "pending")
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Validate movement action
                      },
                      child: const Text('Valider le Mouvement'),
                    ),
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
            width: 35.w,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _movements.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomIconWidget(
                  iconName: 'history',
                  color:
                      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  size: 64,
                ),
                SizedBox(height: 2.h),
                Text(
                  'Aucun mouvement enregistré',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        : ListView.separated(
            padding: EdgeInsets.all(4.w),
            itemCount: _movements.length,
            separatorBuilder: (context, index) => SizedBox(height: 1.h),
            itemBuilder: (context, index) {
              final movement = _movements[index];
              return InkWell(
                onTap: () => _showMovementDetails(movement),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.all(3.w),
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
                      Row(
                        children: [
                          Container(
                            width: 10.w,
                            height: 10.w,
                            decoration: BoxDecoration(
                              color: _getMovementTypeColor(
                                movement["type"] as String,
                                theme,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Icon(
                                _getMovementTypeIcon(
                                    movement["type"] as String),
                                color: _getMovementTypeColor(
                                  movement["type"] as String,
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
                                  movement["product"] as String,
                                  style: theme.textTheme.titleMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _getMovementTypeLabel(
                                      movement["type"] as String),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${movement["quantity"] > 0 ? '+' : ''}${movement["quantity"]}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: movement["quantity"] > 0
                                  ? const Color(0xFF27AE60)
                                  : theme.colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      Divider(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                      SizedBox(height: 1.h),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                CustomIconWidget(
                                  iconName: 'location_on',
                                  color: theme.colorScheme.onSurfaceVariant,
                                  size: 14,
                                ),
                                SizedBox(width: 1.w),
                                Expanded(
                                  child: Text(
                                    '${movement["from"]} → ${movement["to"]}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 0.5.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CustomIconWidget(
                                iconName: 'event',
                                color: theme.colorScheme.onSurfaceVariant,
                                size: 14,
                              ),
                              SizedBox(width: 1.w),
                              Text(
                                _formatDateTime(movement["date"] as DateTime),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            movement["reference"] as String,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }
}
