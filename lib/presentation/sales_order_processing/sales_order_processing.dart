import 'package:flutter/material.dart';

import '../../widgets/screen_state_view.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/company_settings_service.dart';
import '../../services/customer_service.dart';
import '../../services/delivery_service.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';
import '../../services/role_service.dart';
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
        ProductService.instance.getProducts(
          includeStock: RoleService.instance.canViewAllOrders,
        ),
      ]);
      final settings = await const CompanySettingsService().load();

      if (!mounted) return;

      final rawCustomers = results[0];
      final rawProducts = results[1];

      setState(() {
        _customers = rawCustomers.map(_mapCustomerForUi).toList();
        _products = rawProducts.map(_mapProductForUi).toList();
        if (_orderItems.isEmpty) {
          _orderCurrency = settings['default_currency'] as String;
        }
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
      'address': '${raw['address'] ?? ''}, ${raw['city'] ?? ''}'
          .trim()
          .replaceAll(RegExp(r'^,\s*|,\s*$'), ''),
      'tier': tier,
      'paymentTerms': 'Net 30 jours',
      'creditLimit': _formatNumber(creditLimit.toInt()),
    };
  }

  Map<String, dynamic> _mapProductForUi(Map<String, dynamic> raw) {
    final unitPrice = (raw['unit_price'] as num?)?.toDouble() ?? 0;
    final stockRows = raw['inventory_stock'] as List?;
    final stock = stockRows?.fold<int>(
      0,
      (sum, row) => sum + ((row['quantity'] as num?)?.toInt() ?? 0),
    );
    return {
      'id': raw['id'] as String,
      'code': raw['sku'] ?? '',
      'name': raw['name'] ?? '',
      'price': unitPrice,
      'currency': raw['currency'] ?? 'CDF',
      'stock': stock,
      'image': raw['image_url'] ??
          'https://images.unsplash.com/photo-1633288485223-84bafb2a1e2d',
      'semanticLabel': raw['name'] ?? 'Product image',
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

  Future<void> _handleProductAdd(Map<String, dynamic> product) async {
    final customerId = _selectedCustomer?['id'] as String?;
    if (customerId == null || _isProcessing) return;
    final stock = product['stock'] as int?;

    if (stock != null && stock < 1) {
      _showStockAlert(product['name'] as String, 0);
      return;
    }

    final double unitPrice;
    final currency = _orderCurrency;
    try {
      unitPrice = await OrderService.instance.getOrderUnitPrice(
        customerId: customerId,
        productId: product['id'] as String,
        currency: currency,
      );
    } catch (_) {
      if (!mounted || _selectedCustomer?['id'] != customerId) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarif client indisponible. Réessayez.')),
      );
      return;
    }
    if (!mounted || _selectedCustomer?['id'] != customerId ||
        _orderCurrency != currency || _isProcessing) {
      return;
    }

    final existingIndex = _orderItems.indexWhere(
      (item) => item['productId'] == product['id'],
    );

    setState(() {
      if (existingIndex >= 0) {
        final currentQty = _orderItems[existingIndex]['quantity'] as int;
        if (stock != null && currentQty + 1 > stock) {
          _showStockAlert(product['name'] as String, stock);
          return;
        }
        _orderItems[existingIndex]['quantity'] = currentQty + 1;
        _orderItems[existingIndex]['unitPrice'] = unitPrice;
      } else {
        _orderItems.add({
          'productId': product['id'],
          'name': product['name'],
          'code': product['code'],
          'unitPrice': unitPrice,
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
    final maxStock = _orderItems[index]['maxStock'] as int?;

    if (maxStock != null && newQuantity > maxStock) {
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
        index, item['quantity'] as int, item['maxStock'] as int?);
  }

  void _showQuantityDialog(int index, int currentQty, int? maxStock) {
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
            hintText: maxStock == null ? null : 'Max: $maxStock',
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
              if (newQty > 0 && (maxStock == null || newQty <= maxStock)) {
                _handleQuantityChange(index, newQty);
                Navigator.pop(context);
              } else if (maxStock != null) {
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

  String _orderCurrency = 'CDF';

  double _calculateSubtotal() {
    return _orderItems.fold(0.0, (sum, item) {
      final quantity = item['quantity'] as int;
      final unitPrice = item['unitPrice'] as double;
      return sum + (quantity * unitPrice);
    });
  }

  double _calculateDiscount() {
    // PostgreSQL is authoritative. The current RPC has no server-side customer
    // tier pricing rule, so Flutter must not invent a discount.
    return 0;
  }

  double _calculateTax() {
    // create_order_with_items currently stores tax_amount = 0. Keep the preview
    // aligned with the persisted total until a server-side tax rule exists.
    return 0;
  }

  double _calculateTotal() {
    final subtotal = _calculateSubtotal();
    final discount = _calculateDiscount();
    final tax = _calculateTax();
    return subtotal - discount + tax;
  }

  static const _orderNextStatus = {
    'pending': ('confirmed', 'Confirmer'),
    'confirmed': ('processing', 'Mettre en préparation'),
    'processing': ('shipped', 'Marquer expédiée'),
  };

  Future<void> _showOrderFollowup() async {
    final service = OrderService.instance;
    try {
      final orders = await service.getOrders();
      if (!mounted) return;
      final selected = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Suivre les commandes'),
          children: [
            if (orders.isEmpty)
              const ListTile(title: Text('Aucune commande à afficher.')),
            for (final order in orders)
              ListTile(
                title: Text(order['order_number'] as String),
                subtitle: Text(
                  (order['customers'] as Map?)?['company_name'] as String? ??
                      'Client non renseigné',
                ),
                trailing: Text(
                  _canPlanDelivery(order)
                      ? 'Planifier la livraison'
                      : _orderNextStatus[order['order_status']]?.$2 ?? 'Consulter',
                ),
                onTap: () => Navigator.pop(context, order),
              ),
          ],
        ),
      );
      if (!mounted || selected == null) return;
      if (_canPlanDelivery(selected)) {
        await _planDelivery(selected);
        return;
      }
      final next = _orderNextStatus[selected['order_status']];
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Commande ${selected['order_number']}'),
          content: Text(next?.$2 ??
              'Cette commande a atteint une étape gérée par la livraison ou est clôturée.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Fermer'),
            ),
            if (next != null)
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(next.$2),
              ),
          ],
        ),
      );
      if (confirmed != true || next == null || !mounted) return;
      await service.updateOrderStatus(selected['id'] as String, next.$1);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Statut de la commande mis à jour.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de suivre cette commande.')),
      );
    }
  }

  bool _canPlanDelivery(Map<String, dynamic> order) =>
      RoleService.instance.currentRole == UserRole.admin &&
      order['order_status'] == 'shipped';

  Future<void> _planDelivery(Map<String, dynamic> order) async {
    final service = DeliveryService.instance;
    final choices = await Future.wait([
      service.getActiveDrivers(),
      service.getActiveWarehouses(),
    ]);
    if (!mounted) return;
    final drivers = choices[0];
    final warehouses = choices[1];
    if (drivers.isEmpty || warehouses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Un livreur et un entrepôt actifs sont requis.')),
      );
      return;
    }

    String? driverId;
    String? warehouseId;
    var address = '';
    var routeDate = DateUtils.dateOnly(DateTime.now());
    final planned = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, update) => AlertDialog(
          title: Text('Planifier ${order['order_number']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Livreur'),
                  isExpanded: true,
                  items: [
                    for (final driver in drivers)
                      DropdownMenuItem(
                        value: driver['id'] as String,
                        child: Text(driver['full_name'] as String? ?? 'Livreur'),
                      ),
                  ],
                  onChanged: (value) => update(() => driverId = value),
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Entrepôt'),
                  isExpanded: true,
                  items: [
                    for (final warehouse in warehouses)
                      DropdownMenuItem(
                        value: warehouse['id'] as String,
                        child: Text(warehouse['name'] as String),
                      ),
                  ],
                  onChanged: (value) => update(() => warehouseId = value),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Adresse de livraison'),
                  maxLength: 500,
                  onChanged: (value) => update(() => address = value.trim()),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(MaterialLocalizations.of(dialogContext).formatShortDate(routeDate)),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: dialogContext,
                      initialDate: routeDate,
                      firstDate: DateUtils.dateOnly(DateTime.now()),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null && dialogContext.mounted) {
                      update(() => routeDate = date);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Fermer'),
            ),
            FilledButton(
              onPressed: driverId == null || warehouseId == null || address.isEmpty
                  ? null
                  : () => Navigator.pop(dialogContext, true),
              child: const Text('Planifier la livraison'),
            ),
          ],
        ),
      ),
    );
    if (planned != true || !mounted) return;
    await service.planOrderDelivery(
      orderId: order['id'] as String,
      driverId: driverId!,
      warehouseId: warehouseId!,
      address: address,
      routeDate: routeDate.toIso8601String().substring(0, 10),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Livraison planifiée.')),
    );
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
                          backgroundColor:
                              theme.colorScheme.primary.withValues(alpha: 0.1),
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
                            if (_selectedCustomer?['id'] != customer['id']) {
                              _orderItems.clear();
                            }
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
      final items = _orderItems
          .map((item) => {
                'product_id': item['productId'] as String,
                'quantity': item['quantity'] as int,
                'unit_price': item['unitPrice'] as double,
              })
          .toList();

      final order = await OrderService.instance.createOrder(
        customerId: _selectedCustomer!['id'] as String,
        items: items,
        currency: _orderCurrency,
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
            if (RoleService.instance.canViewAllOrders)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showOrderFollowup();
                },
                child: const Text('Suivre les commandes'),
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
        body: ScreenStateView.error(
          message: 'Impossible de charger les données de la commande.',
          onAction: _loadInitialData,
        ),
      );
    }

    final subtotal = _calculateSubtotal();
    final discount = _calculateDiscount();
    final tax = _calculateTax();
    final total = _calculateTotal();

    final customerData = _selectedCustomer ??
        {
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
          if (RoleService.instance.canViewAllOrders)
            IconButton(
              icon: const Icon(Icons.list_alt),
              tooltip: 'Suivre les commandes',
              onPressed: _showOrderFollowup,
            ),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'swap_horiz',
              color: theme.colorScheme.primary,
              size: 24,
            ),
            onPressed: _customers.length > 1 ? _showCustomerSelector : null,
            tooltip: 'Changer de client',
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButton<String>(
                      value: _orderCurrency,
                      items: const [
                        DropdownMenuItem(value: 'CDF', child: Text('Commande en CDF')),
                        DropdownMenuItem(value: 'USD', child: Text('Commande en USD')),
                      ],
                      onChanged: _isProcessing ? null : (currency) {
                        if (currency == null || currency == _orderCurrency) return;
                        setState(() {
                          _orderCurrency = currency;
                          _orderItems.clear();
                        });
                      },
                    ),
                  ),
                  OrderItemsList(
                    orderItems: _orderItems,
                    currency: _orderCurrency,
                    onQuantityChange: _handleQuantityChange,
                    onRemove: _handleRemoveItem,
                    onEdit: _handleEditItem,
                  ),
                  ProductSelectionSection(
                    products: _products,
                    onProductAdd: _handleProductAdd,
                    onBarcodeScan: _handleBarcodeScan,
                  ),
                  SizedBox(height: 16 + MediaQuery.paddingOf(context).bottom),
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
              currency: _orderCurrency,
              onCreateOrder: _handleCreateOrder,
              isProcessing: _isProcessing,
            ),
        ],
      ),
    );
  }
}
