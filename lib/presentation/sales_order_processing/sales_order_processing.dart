import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/customer_service.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/customer_info_section.dart';
import './widgets/order_items_list.dart';
import './widgets/order_summary_card.dart';
import './widgets/product_selection_section.dart';

/// Sales Order Processing Screen
/// Streamlines mobile order creation and management for sales representatives
class SalesOrderProcessing extends StatefulWidget {
  const SalesOrderProcessing({super.key});

  @override
  State<SalesOrderProcessing> createState() => _SalesOrderProcessingState();
}

class _SalesOrderProcessingState extends State<SalesOrderProcessing> {
  bool _isCustomerInfoExpanded = false;
  bool _isProcessing = false;
  bool _isLoadingData = true;
  String? _loadError;

  final List<Map<String, dynamic>> _orderItems = [];

  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _products = [];
  Map<String, dynamic>? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingData = true;
      _loadError = null;
    });

    try {
      final results = await Future.wait([
        CustomerService.instance.getCustomers(),
        ProductService.instance.getProducts(),
      ]);

      if (!mounted) return;

      final rawCustomers = results[0];
      final rawProducts = results[1];

      setState(() {
        _customers = rawCustomers.map(_mapCustomerForUi).toList();
        _products = rawProducts.map(_mapProductForUi).toList();
        if (_customers.isNotEmpty) {
          _selectedCustomer = _customers.first;
        }
        _isLoadingData = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString().replaceFirst('Exception: ', '');
        _isLoadingData = false;
      });
    }
  }

  Map<String, dynamic> _mapCustomerForUi(Map<String, dynamic> raw) {
    final creditLimit = (raw['credit_limit'] as num?)?.toDouble() ?? 0;
    String tier = 'Standard';
    if (creditLimit >= 5000000) {
      tier = 'Premium';
    } else if (creditLimit >= 2000000) {
      tier = 'Gold';
    } else if (creditLimit >= 500000) {
      tier = 'Silver';
    }

    return {
      'id': raw['id'] as String,
      'name': raw['company_name'] ?? '',
      'phone': raw['phone'] ?? '',
      'email': raw['email'] ?? '',
      'address': '${raw['address'] ?? ''}, ${raw['city'] ?? ''}'.trim().replaceAll(RegExp(r'^,\s*|,\s*$'), ''),
      'tier': tier,
      'paymentTerms': 'Net 30 jours',
      'creditLimit': _formatNumber(creditLimit.toInt()),
    };
  }

  Map<String, dynamic> _mapProductForUi(Map<String, dynamic> raw) {
    final unitPrice = (raw['unit_price'] as num?)?.toDouble() ?? 0;
    return {
      'id': raw['id'] as String,
      'code': raw['sku'] ?? '',
      'name': raw['name'] ?? '',
      'price': unitPrice,
      'stock': 999,
      'image': raw['image_url'] ?? 'https://images.unsplash.com/photo-1633288485223-84bafb2a1e2d',
      'semanticLabel': raw['name'] ?? 'Product image',
      'tierDiscounts': <String, double>{
        'Premium': 0.15,
        'Gold': 0.10,
        'Silver': 0.05,
        'Standard': 0.0,
      },
    };
  }

  String _formatNumber(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  double _getCustomPrice(Map<String, dynamic> product) {
    final basePrice = product['price'] as double;
    final tier = _selectedCustomer?['tier'] as String? ?? 'Standard';
    final discounts = product['tierDiscounts'] as Map<String, double>?;
    final discount = discounts?[tier] ?? 0.0;
    return basePrice * (1 - discount);
  }

  void _handleProductAdd(Map<String, dynamic> product) {
    final stock = product['stock'] as int;

    if (stock < 1) {
      _showStockAlert(product['name'] as String, 0);
      return;
    }

    final existingIndex = _orderItems.indexWhere(
      (item) => item['productId'] == product['id'],
    );

    setState(() {
      if (existingIndex >= 0) {
        final currentQty = _orderItems[existingIndex]['quantity'] as int;
        if (currentQty + 1 > stock) {
          _showStockAlert(product['name'] as String, stock);
          return;
        }
        _orderItems[existingIndex]['quantity'] = currentQty + 1;
      } else {
        _orderItems.add({
          'productId': product['id'],
          'name': product['name'],
          'code': product['code'],
          'unitPrice': _getCustomPrice(product),
          'quantity': 1,
          'image': product['image'],
          'semanticLabel': product['semanticLabel'],
          'maxStock': stock,
        });
      }
    });

    HapticFeedback.lightImpact();
  }

  void _handleQuantityChange(int index, int newQuantity) {
    final maxStock = _orderItems[index]['maxStock'] as int;

    if (newQuantity > maxStock) {
      _showStockAlert(_orderItems[index]['name'] as String, maxStock);
      return;
    }

    setState(() {
      _orderItems[index]['quantity'] = newQuantity;
    });
  }

  void _handleRemoveItem(int index) {
    setState(() {
      _orderItems.removeAt(index);
    });
    HapticFeedback.mediumImpact();
  }

  void _handleEditItem(int index) {
    final item = _orderItems[index];
    _showQuantityDialog(
        index, item['quantity'] as int, item['maxStock'] as int);
  }

  void _showQuantityDialog(int index, int currentQty, int maxStock) {
    final theme = Theme.of(context);
    final controller = TextEditingController(text: currentQty.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Modifier la quantité',
          style: theme.textTheme.titleMedium,
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Quantité',
            hintText: 'Max: $maxStock',
            border: const OutlineInputBorder(),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final newQty = int.tryParse(controller.text) ?? currentQty;
              if (newQty > 0 && newQty <= maxStock) {
                _handleQuantityChange(index, newQty);
                Navigator.pop(context);
              } else {
                _showStockAlert(_orderItems[index]['name'] as String, maxStock);
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showStockAlert(String productName, int availableStock) {
    final theme = Theme.of(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          availableStock > 0
              ? 'Stock insuffisant pour $productName. Disponible: $availableStock'
              : '$productName est en rupture de stock',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onError,
          ),
        ),
        backgroundColor: theme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: theme.colorScheme.onError,
          onPressed: () {},
        ),
      ),
    );

    HapticFeedback.heavyImpact();
  }

  void _handleBarcodeScan() {
    Navigator.pushNamed(context, '/barcode-scanner');
  }

  double _calculateSubtotal() {
    return _orderItems.fold(0.0, (sum, item) {
      final quantity = item['quantity'] as int;
      final unitPrice = item['unitPrice'] as double;
      return sum + (quantity * unitPrice);
    });
  }

  double _calculateDiscount() {
    final subtotal = _calculateSubtotal();
    final tier = _selectedCustomer?['tier'] as String? ?? 'Standard';
    final tierDiscount = tier == 'Premium' ? 0.05 : 0.0;
    return subtotal * tierDiscount;
  }

  double _calculateTax() {
    final subtotal = _calculateSubtotal();
    final discount = _calculateDiscount();
    return (subtotal - discount) * 0.18;
  }

  double _calculateTotal() {
    final subtotal = _calculateSubtotal();
    final discount = _calculateDiscount();
    final tax = _calculateTax();
    return subtotal - discount + tax;
  }

  void _showCustomerSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Sélectionner un client',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _customers.length,
                    itemBuilder: (context, index) {
                      final customer = _customers[index];
                      final isSelected =
                          _selectedCustomer?['id'] == customer['id'];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary
                              .withValues(alpha: 0.1),
                          child: Text(
                            (customer['name'] as String)
                                .substring(0, 1)
                                .toUpperCase(),
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        title: Text(customer['name'] as String),
                        subtitle: Text(customer['tier'] as String),
                        trailing: isSelected
                            ? Icon(Icons.check_circle,
                                color: theme.colorScheme.primary)
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedCustomer = customer;
                            _orderItems.clear();
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleCreateOrder() async {
    if (_orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez ajouter au moins un produit'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez sélectionner un client'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final items = _orderItems.map((item) => {
        'product_id': item['productId'] as String,
        'quantity': item['quantity'] as int,
        'unit_price': item['unitPrice'] as double,
      }).toList();

      final discount = _calculateDiscount();
      final order = await OrderService.instance.createOrder(
        customerId: _selectedCustomer!['id'] as String,
        items: items,
        discount: discount > 0 ? discount : null,
      );

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      final orderId = order['id'] as String? ?? '';

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              CustomIconWidget(
                iconName: 'check_circle',
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              SizedBox(width: 2.w),
              const Text('Commande créée'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'La commande a été créée avec succès.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: 2.h),
              Text(
                'ID: ${orderId.substring(0, 8).toUpperCase()}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/invoice-generation');
              },
              child: const Text('Créer facture'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _orderItems.clear();
                });
              },
              child: const Text('Nouvelle commande'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoadingData) {
      return Scaffold(
        appBar: CustomAppBar(
          title: 'Nouvelle commande',
          variant: CustomAppBarVariant.detail,
          showBackButton: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: CustomAppBar(
          title: 'Nouvelle commande',
          variant: CustomAppBarVariant.detail,
          showBackButton: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomIconWidget(
                  iconName: 'error_outline',
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur de chargement',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _loadError!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadInitialData,
                  icon: CustomIconWidget(
                    iconName: 'refresh',
                    size: 20,
                    color: theme.colorScheme.onPrimary,
                  ),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final subtotal = _calculateSubtotal();
    final discount = _calculateDiscount();
    final tax = _calculateTax();
    final total = _calculateTotal();

    final customerData = _selectedCustomer ?? {
      'id': '',
      'name': 'Aucun client',
      'phone': '',
      'email': '',
      'address': '',
      'tier': 'Standard',
      'paymentTerms': '-',
      'creditLimit': '0',
    };

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Nouvelle commande',
        variant: CustomAppBarVariant.detail,
        showBackButton: true,
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'swap_horiz',
              color: theme.colorScheme.primary,
              size: 24,
            ),
            onPressed: _customers.length > 1 ? _showCustomerSelector : null,
            tooltip: 'Changer client',
          ),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'history',
              color: theme.colorScheme.primary,
              size: 24,
            ),
            onPressed: () {},
            tooltip: 'Historique',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  CustomerInfoSection(
                    customerData: customerData,
                    onExpand: () {
                      setState(() {
                        _isCustomerInfoExpanded = !_isCustomerInfoExpanded;
                      });
                    },
                    isExpanded: _isCustomerInfoExpanded,
                  ),
                  OrderItemsList(
                    orderItems: _orderItems,
                    onQuantityChange: _handleQuantityChange,
                    onRemove: _handleRemoveItem,
                    onEdit: _handleEditItem,
                  ),
                  ProductSelectionSection(
                    products: _products,
                    onProductAdd: _handleProductAdd,
                    onBarcodeScan: _handleBarcodeScan,
                    customerTier: customerData['tier'] as String,
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
          if (_orderItems.isNotEmpty)
            OrderSummaryCard(
              subtotal: subtotal,
              discount: discount,
              tax: tax,
              total: total,
              onCreateOrder: _handleCreateOrder,
              isProcessing: _isProcessing,
            ),
        ],
      ),
    );
  }
}
