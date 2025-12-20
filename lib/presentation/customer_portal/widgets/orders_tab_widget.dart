import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Orders Tab Widget
/// Displays customer's order history with status tracking and quick actions
class OrdersTabWidget extends StatefulWidget {
  const OrdersTabWidget({super.key});

  @override
  State<OrdersTabWidget> createState() => _OrdersTabWidgetState();
}

class _OrdersTabWidgetState extends State<OrdersTabWidget> {
  bool _isRefreshing = false;

  // Mock orders data
  final List<Map<String, dynamic>> _orders = [
    {
      "id": "CMD-2024-1156",
      "date": DateTime(2025, 11, 25),
      "status": "shipped",
      "statusLabel": "Expédiée",
      "items": 12,
      "total": "245 000 XOF",
      "deliveryDate": DateTime(2025, 11, 28),
      "products": [
        {"name": "Coca-Cola 1.5L", "quantity": 24},
        {"name": "Sprite 1L", "quantity": 12},
      ],
    },
    {
      "id": "CMD-2024-1142",
      "date": DateTime(2025, 11, 20),
      "status": "delivered",
      "statusLabel": "Livrée",
      "items": 8,
      "total": "180 000 XOF",
      "deliveryDate": DateTime(2025, 11, 22),
      "products": [
        {"name": "Fanta Orange 1L", "quantity": 18},
        {"name": "Eau Minérale 1.5L", "quantity": 30},
      ],
    },
    {
      "id": "CMD-2024-1128",
      "date": DateTime(2025, 11, 18),
      "status": "confirmed",
      "statusLabel": "Confirmée",
      "items": 15,
      "total": "320 000 XOF",
      "deliveryDate": DateTime(2025, 11, 29),
      "products": [
        {"name": "Jus Tropical 1L", "quantity": 24},
        {"name": "Coca-Cola 2L", "quantity": 12},
      ],
    },
    {
      "id": "CMD-2024-1115",
      "date": DateTime(2025, 11, 15),
      "status": "pending",
      "statusLabel": "En attente",
      "items": 6,
      "total": "95 000 XOF",
      "deliveryDate": DateTime(2025, 11, 30),
      "products": [
        {"name": "Sprite 2L", "quantity": 12},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: theme.colorScheme.primary,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Mes Commandes',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          _showNewOrderDialog(context);
                        },
                        icon: CustomIconWidget(
                          iconName: 'add',
                          color: theme.colorScheme.onPrimary,
                          size: 18,
                        ),
                        label: Text('Nouvelle'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4.w,
                            vertical: 1.5.h,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  _buildStatusFilters(context),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final order = _orders[index];
                  return _buildOrderCard(context, order);
                },
                childCount: _orders.length,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: 2.h),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilters(BuildContext context) {
    final theme = Theme.of(context);

    final filters = [
      {'label': 'Toutes', 'count': _orders.length},
      {
        'label': 'En attente',
        'count': _orders.where((o) => o['status'] == 'pending').length
      },
      {
        'label': 'Confirmées',
        'count': _orders.where((o) => o['status'] == 'confirmed').length
      },
      {
        'label': 'Expédiées',
        'count': _orders.where((o) => o['status'] == 'shipped').length
      },
      {
        'label': 'Livrées',
        'count': _orders.where((o) => o['status'] == 'delivered').length
      },
    ];

    return SizedBox(
      height: 5.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => SizedBox(width: 2.w),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = index == 0;

          return FilterChip(
            label: Text(
              '${filter['label']} (${filter['count']})',
              style: theme.textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            selected: isSelected,
            onSelected: (selected) {},
            backgroundColor: theme.colorScheme.surface,
            selectedColor: theme.colorScheme.primary,
            side: BorderSide(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order) {
    final theme = Theme.of(context);

    return Slidable(
      key: ValueKey(order['id']),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => _reorderAction(order),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            icon: Icons.refresh,
            label: 'Recommander',
          ),
          SlidableAction(
            onPressed: (context) => _trackDeliveryAction(order),
            backgroundColor: AppTheme.warningLight,
            foregroundColor: Colors.white,
            icon: Icons.local_shipping,
            label: 'Suivre',
          ),
          SlidableAction(
            onPressed: (context) => _downloadInvoiceAction(order),
            backgroundColor: AppTheme.successLight,
            foregroundColor: Colors.white,
            icon: Icons.download,
            label: 'Facture',
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.only(bottom: 2.h),
        child: InkWell(
          onTap: () => _showOrderDetails(context, order),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order['id'],
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            _formatDate(order['date']),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(
                        context, order['status'], order['statusLabel']),
                  ],
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        'shopping_cart',
                        '${order['items']} articles',
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        'local_shipping',
                        _formatDate(order['deliveryDate']),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.5.h),
                Divider(height: 1),
                SizedBox(height: 1.5.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      order['total'],
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
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

  Widget _buildStatusBadge(BuildContext context, String status, String label) {
    final theme = Theme.of(context);

    Color backgroundColor;
    Color textColor;

    switch (status) {
      case 'pending':
        backgroundColor = AppTheme.warningLight.withValues(alpha: 0.1);
        textColor = AppTheme.warningLight;
        break;
      case 'confirmed':
        backgroundColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue;
        break;
      case 'shipped':
        backgroundColor = Colors.purple.withValues(alpha: 0.1);
        textColor = Colors.purple;
        break;
      case 'delivered':
        backgroundColor = AppTheme.successLight.withValues(alpha: 0.1);
        textColor = AppTheme.successLight;
        break;
      default:
        backgroundColor = theme.colorScheme.surfaceContainerHighest;
        textColor = theme.colorScheme.onSurface;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String iconName, String text) {
    final theme = Theme.of(context);

    return Row(
      children: [
        CustomIconWidget(
          iconName: iconName,
          color: theme.colorScheme.onSurfaceVariant,
          size: 16,
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Août',
      'Sep',
      'Oct',
      'Nov',
      'Déc'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isRefreshing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Commandes mises à jour'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showOrderDetails(BuildContext context, Map<String, dynamic> order) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
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
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Détails de la commande',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: CustomIconWidget(
                          iconName: 'close',
                          color: theme.colorScheme.onSurface,
                          size: 24,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        _buildDetailRow(context, 'Numéro', order['id']),
                        _buildDetailRow(
                            context, 'Date', _formatDate(order['date'])),
                        _buildDetailRow(
                            context, 'Statut', order['statusLabel']),
                        _buildDetailRow(context, 'Livraison prévue',
                            _formatDate(order['deliveryDate'])),
                        SizedBox(height: 2.h),
                        Text(
                          'Produits',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        ...(order['products'] as List).map((product) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: 1.h),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    product['name'],
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                                Text(
                                  'x${product['quantity']}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        SizedBox(height: 2.h),
                        Divider(),
                        SizedBox(height: 1.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              order['total'],
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 3.h),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _reorderAction(order);
                                },
                                icon: CustomIconWidget(
                                  iconName: 'refresh',
                                  color: theme.colorScheme.primary,
                                  size: 18,
                                ),
                                label: const Text('Recommander'),
                              ),
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _trackDeliveryAction(order);
                                },
                                icon: CustomIconWidget(
                                  iconName: 'local_shipping',
                                  color: theme.colorScheme.onPrimary,
                                  size: 18,
                                ),
                                label: const Text('Suivre'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 1.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showNewOrderDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Nouvelle Commande',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Accédez au catalogue produits pour créer une nouvelle commande avec vos prix personnalisés.',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/product-catalog');
              },
              child: const Text('Voir Catalogue'),
            ),
          ],
        );
      },
    );
  }

  void _reorderAction(Map<String, dynamic> order) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Recommande de ${order['id']} en cours...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _trackDeliveryAction(Map<String, dynamic> order) {
    Navigator.pushNamed(context, '/delivery-tracking');
  }

  void _downloadInvoiceAction(Map<String, dynamic> order) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Téléchargement de la facture ${order['id']}...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}