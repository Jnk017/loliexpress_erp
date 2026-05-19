import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/order_service.dart';

/// Orders Tab Widget
/// Displays customer's order history with status tracking and quick actions
class OrdersTabWidget extends StatefulWidget {
  const OrdersTabWidget({super.key});

  @override
  State<OrdersTabWidget> createState() => _OrdersTabWidgetState();
}

class _OrdersTabWidgetState extends State<OrdersTabWidget> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final orders = await OrderService.instance.getOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: theme.colorScheme.error),
              SizedBox(height: 2.h),
              Text(
                'Erreur de chargement',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                _errorMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 3.h),
              ElevatedButton.icon(
                onPressed: _loadOrders,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_orders.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_bag_outlined, size: 60, color: theme.colorScheme.onSurfaceVariant),
              SizedBox(height: 2.h),
              Text(
                'Aucune commande',
                style: theme.textTheme.titleMedium,
              ),
              SizedBox(height: 1.h),
              Text(
                'Vous n\'avez pas encore passé de commande.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 3.h),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/product-catalog'),
                icon: const Icon(Icons.add),
                label: const Text('Nouvelle Commande'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
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
                          Navigator.pushNamed(context, '/product-catalog');
                        },
                        icon: CustomIconWidget(
                          iconName: 'add',
                          color: theme.colorScheme.onPrimary,
                          size: 18,
                        ),
                        label: const Text('Nouvelle Commande'),
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
        'count': _orders.where((o) => o['order_status'] == 'pending').length
      },
      {
        'label': 'Confirmées',
        'count': _orders.where((o) => o['order_status'] == 'confirmed').length
      },
      {
        'label': 'Expédiées',
        'count': _orders.where((o) => o['order_status'] == 'shipped').length
      },
      {
        'label': 'Livrées',
        'count': _orders.where((o) => o['order_status'] == 'delivered').length
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
    final status = order['order_status'] as String? ?? 'pending';
    final statusLabel = _getStatusLabel(status);
    final totalAmount = (order['total_amount'] as num?)?.toDouble() ?? 0;
    final orderId = order['id']?.toString() ?? '';
    final createdAt = DateTime.tryParse(order['created_at'] ?? '') ?? DateTime.now();

    return Slidable(
      key: ValueKey(orderId),
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
          if (status == 'delivered')
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
                            orderId.length > 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            _formatDate(createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(context, status, statusLabel),
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
                      '${_formatCurrency(totalAmount)} FC',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                if (status == 'delivered') ...[
                  SizedBox(height: 1.5.h),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _downloadInvoiceAction(order),
                      icon: const Icon(Icons.picture_as_pdf, size: 18),
                      label: const Text('Télécharger Facture'),
                    ),
                  ),
                ],
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

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Confirmée';
      case 'shipped':
        return 'Expédiée';
      case 'delivered':
        return 'Livrée';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }

  void _showOrderDetails(BuildContext context, Map<String, dynamic> order) {
    final theme = Theme.of(context);
    final status = order['order_status'] as String? ?? 'pending';
    final totalAmount = (order['total_amount'] as num?)?.toDouble() ?? 0;
    final orderId = order['id']?.toString() ?? '';
    final createdAt = DateTime.tryParse(order['created_at'] ?? '') ?? DateTime.now();
    final customerData = order['customers'] as Map<String, dynamic>?;

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
                        _buildDetailRow(context, 'Numéro', orderId.length > 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase()),
                        _buildDetailRow(context, 'Date', _formatDate(createdAt)),
                        _buildDetailRow(context, 'Statut', _getStatusLabel(status)),
                        if (customerData != null)
                          _buildDetailRow(context, 'Client', customerData['company_name'] ?? ''),
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
                              '${_formatCurrency(totalAmount)} FC',
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
                        if (status == 'delivered') ...[
                          SizedBox(height: 2.h),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _downloadInvoiceAction(order);
                              },
                              icon: const Icon(Icons.picture_as_pdf),
                              label: const Text('Télécharger Facture'),
                            ),
                          ),
                        ],
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

  void _reorderAction(Map<String, dynamic> order) {
    final orderId = order['id']?.toString() ?? '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Recommande de $orderId en cours...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _trackDeliveryAction(Map<String, dynamic> order) {
    Navigator.pushNamed(context, '/delivery-tracking');
  }

  void _downloadInvoiceAction(Map<String, dynamic> order) {
    Navigator.pushNamed(context, '/invoice-generation', arguments: order);
  }
}
