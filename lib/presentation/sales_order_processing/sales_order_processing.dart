import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
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
  final List<Map<String, dynamic>> _orderItems = [];

  // Mock customer data
  final Map<String, dynamic> _customerData = {
    "id": "CUST001",
    "name": "Supermarché Le Palmier",
    "phone": "+225 07 12 34 56 78",
    "email": "contact@lepalmier.ci",
    "address": "Boulevard de la République, Abidjan, Côte d'Ivoire",
    "tier": "Premium",
    "paymentTerms": "Net 30 jours",
    "creditLimit": "5 000 000",
  };

  // Mock product catalog with tier-based pricing
  final List<Map<String, dynamic>> _products = [
    {
      "id": "PROD001",
      "code": "COC001",
      "name": "Coca-Cola 33cl (Pack de 24)",
      "price": 12000.0,
      "stock": 150,
      "image":
          "https://images.unsplash.com/photo-1646009760728-9ff56d4910de",
      "semanticLabel":
          "Pack of red Coca-Cola cans arranged in rows on white background",
      "tierDiscounts": {
        "Premium": 0.15,
        "Gold": 0.10,
        "Silver": 0.05,
        "Standard": 0.0,
      },
    },
    {
      "id": "PROD002",
      "code": "FAN001",
      "name": "Fanta Orange 50cl (Pack de 12)",
      "price": 8500.0,
      "stock": 8,
      "image":
          "https://images.unsplash.com/photo-1598419161288-9f2f26c85590",
      "semanticLabel":
          "Orange Fanta bottles in plastic crate with orange branding visible",
      "tierDiscounts": {
        "Premium": 0.15,
        "Gold": 0.10,
        "Silver": 0.05,
        "Standard": 0.0,
      },
    },
    {
      "id": "PROD003",
      "code": "SPR001",
      "name": "Sprite 1L (Pack de 6)",
      "price": 6000.0,
      "stock": 200,
      "image":
          "https://images.unsplash.com/photo-1699543908097-3017da4d6859",
      "semanticLabel":
          "Green Sprite bottles with clear liquid and lemon-lime branding",
      "tierDiscounts": {
        "Premium": 0.15,
        "Gold": 0.10,
        "Silver": 0.05,
        "Standard": 0.0,
      },
    },
    {
      "id": "PROD004",
      "code": "PEP001",
      "name": "Pepsi 33cl (Pack de 24)",
      "price": 11500.0,
      "stock": 120,
      "image":
          "https://images.unsplash.com/photo-1708098009770-afacce238e96",
      "semanticLabel":
          "Blue Pepsi cans stacked in pyramid formation with brand logo visible",
      "tierDiscounts": {
        "Premium": 0.15,
        "Gold": 0.10,
        "Silver": 0.05,
        "Standard": 0.0,
      },
    },
    {
      "id": "PROD005",
      "code": "WAT001",
      "name": "Eau Minérale 1.5L (Pack de 6)",
      "price": 3500.0,
      "stock": 300,
      "image":
          "https://images.unsplash.com/photo-1633288485223-84bafb2a1e2d",
      "semanticLabel":
          "Clear plastic water bottles with blue caps arranged in pack of six",
      "tierDiscounts": {
        "Premium": 0.10,
        "Gold": 0.08,
        "Silver": 0.05,
        "Standard": 0.0,
      },
    },
  ];

  double _getCustomPrice(Map<String, dynamic> product) {
    final basePrice = product["price"] as double;
    final discount =
        product["tierDiscounts"][_customerData["tier"]] as double? ?? 0.0;
    return basePrice * (1 - discount);
  }

  void _handleProductAdd(Map<String, dynamic> product) {
    final stock = product["stock"] as int;

    if (stock < 1) {
      _showStockAlert(product["name"] as String, 0);
      return;
    }

    final existingIndex = _orderItems.indexWhere(
      (item) => item["productId"] == product["id"],
    );

    setState(() {
      if (existingIndex >= 0) {
        final currentQty = _orderItems[existingIndex]["quantity"] as int;
        if (currentQty + 1 > stock) {
          _showStockAlert(product["name"] as String, stock);
          return;
        }
        _orderItems[existingIndex]["quantity"] = currentQty + 1;
      } else {
        _orderItems.add({
          "productId": product["id"],
          "name": product["name"],
          "code": product["code"],
          "unitPrice": _getCustomPrice(product),
          "quantity": 1,
          "image": product["image"],
          "semanticLabel": product["semanticLabel"],
          "maxStock": stock,
        });
      }
    });

    HapticFeedback.lightImpact();
  }

  void _handleQuantityChange(int index, int newQuantity) {
    final maxStock = _orderItems[index]["maxStock"] as int;

    if (newQuantity > maxStock) {
      _showStockAlert(_orderItems[index]["name"] as String, maxStock);
      return;
    }

    setState(() {
      _orderItems[index]["quantity"] = newQuantity;
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
        index, item["quantity"] as int, item["maxStock"] as int);
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
                _showStockAlert(_orderItems[index]["name"] as String, maxStock);
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
      final quantity = item["quantity"] as int;
      final unitPrice = item["unitPrice"] as double;
      return sum + (quantity * unitPrice);
    });
  }

  double _calculateDiscount() {
    final subtotal = _calculateSubtotal();
    final tierDiscount = _customerData["tier"] == "Premium" ? 0.05 : 0.0;
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

    setState(() {
      _isProcessing = true;
    });

    // Simulate order creation
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
    });

    // Show success dialog
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
              'Numéro de commande: CMD${DateTime.now().millisecondsSinceEpoch}',
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtotal = _calculateSubtotal();
    final discount = _calculateDiscount();
    final tax = _calculateTax();
    final total = _calculateTotal();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Nouvelle commande',
        variant: CustomAppBarVariant.detail,
        showBackButton: true,
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'history',
              color: theme.colorScheme.primary,
              size: 24,
            ),
            onPressed: () {
              // Navigate to order history
            },
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
                  // Customer info section
                  CustomerInfoSection(
                    customerData: _customerData,
                    onExpand: () {
                      setState(() {
                        _isCustomerInfoExpanded = !_isCustomerInfoExpanded;
                      });
                    },
                    isExpanded: _isCustomerInfoExpanded,
                  ),
                  // Order items list
                  OrderItemsList(
                    orderItems: _orderItems,
                    onQuantityChange: _handleQuantityChange,
                    onRemove: _handleRemoveItem,
                    onEdit: _handleEditItem,
                  ),
                  // Product selection section
                  ProductSelectionSection(
                    products: _products,
                    onProductAdd: _handleProductAdd,
                    onBarcodeScan: _handleBarcodeScan,
                    customerTier: _customerData["tier"] as String,
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
          // Order summary card (sticky bottom)
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
