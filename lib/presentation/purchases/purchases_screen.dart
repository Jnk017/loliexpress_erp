import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

import '../../services/purchase_service.dart';
import '../../services/product_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<Map<String, dynamic>> _purchases = [];
  String? _errorMessage;

  final List<String> _statusTabs = ['Tous', 'En attente', 'Reçus'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadPurchases();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _loadPurchases();
    }
  }

  String? _getStatusFilter() {
    switch (_tabController.index) {
      case 1:
        return 'pending';
      case 2:
        return 'received';
      default:
        return null;
    }
  }

  Future<void> _loadPurchases() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final purchases = await PurchaseService.instance.getPurchases(
        status: _getStatusFilter(),
      );
      if (!mounted) return;
      setState(() {
        _purchases = purchases;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'received':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'received':
        return 'Reçu';
      case 'pending':
        return 'En attente';
      case 'cancelled':
        return 'Annulé';
      default:
        return 'Inconnu';
    }
  }

  Color _getPaymentStatusColor(String? paymentStatus) {
    switch (paymentStatus) {
      case 'paid':
        return Colors.green;
      case 'partial':
        return Colors.orange;
      case 'pending':
        return Colors.red.shade300;
      default:
        return Colors.grey;
    }
  }

  String _getPaymentStatusLabel(String? paymentStatus) {
    switch (paymentStatus) {
      case 'paid':
        return 'Payé';
      case 'partial':
        return 'Partiel';
      case 'pending':
        return 'Non payé';
      default:
        return 'Inconnu';
    }
  }

  void _showCreatePurchaseDialog() {
    showDialog(
      context: context,
      builder: (context) => const _CreatePurchaseDialog(),
    ).then((result) {
      if (result == true) {
        _loadPurchases();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Achats',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPurchases,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: theme.cardColor,
            child: TabBar(
              controller: _tabController,
              labelColor: theme.primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: theme.primaryColor,
              tabs: _statusTabs.map((t) => Tab(text: t)).toList(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadPurchases,
              child: _buildBody(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePurchaseDialog,
        tooltip: 'Nouvel achat',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const CustomBottomBar(currentIndex: 0),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              SizedBox(height: 2.h),
              Text(
                'Erreur de chargement',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 1.h),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.sp, color: Colors.grey),
              ),
              SizedBox(height: 2.h),
              ElevatedButton.icon(
                onPressed: _loadPurchases,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_purchases.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined,
                size: 64, color: Colors.grey.shade400),
            SizedBox(height: 2.h),
            Text(
              'Aucun achat trouvé',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(3.w),
      itemCount: _purchases.length,
      itemBuilder: (context, index) => _buildPurchaseCard(_purchases[index]),
    );
  }

  Widget _buildPurchaseCard(Map<String, dynamic> purchase) {
    final theme = Theme.of(context);
    final supplier = purchase['suppliers'] as Map<String, dynamic>?;
    final supplierName = supplier?['company_name'] ?? 'Fournisseur inconnu';
    final status = purchase['status'] as String?;
    final paymentStatus = purchase['payment_status'] as String?;
    final currency = purchase['currency'] ?? 'CDF';
    final totalAmount = (purchase['total_amount'] as num?)?.toDouble() ?? 0;
    final createdAt = purchase['created_at'] as String?;

    String formattedDate = '';
    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt);
        formattedDate = DateFormat('dd/MM/yyyy').format(date);
      } catch (_) {
        formattedDate = createdAt;
      }
    }

    final formattedAmount = NumberFormat.currency(
      symbol: currency == 'USD' ? '\$' : 'FC ',
      decimalDigits: currency == 'USD' ? 2 : 0,
    ).format(totalAmount);

    return Card(
      margin: EdgeInsets.only(bottom: 1.5.h),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    supplierName,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusLabel(status),
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    SizedBox(width: 1.w),
                    Text(
                      formattedDate,
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                    ),
                  ],
                ),
                Text(
                  formattedAmount,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Icon(Icons.payment, size: 14, color: Colors.grey),
                SizedBox(width: 1.w),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.3.h),
                  decoration: BoxDecoration(
                    color: _getPaymentStatusColor(paymentStatus)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getPaymentStatusLabel(paymentStatus),
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w500,
                      color: _getPaymentStatusColor(paymentStatus),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatePurchaseDialog extends StatefulWidget {
  const _CreatePurchaseDialog();

  @override
  State<_CreatePurchaseDialog> createState() => _CreatePurchaseDialogState();
}

class _CreatePurchaseDialogState extends State<_CreatePurchaseDialog> {
  bool _isLoading = false;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _products = [];
  String? _selectedSupplierId;
  String _selectedCurrency = 'CDF';
  final List<_PurchaseItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        PurchaseService.instance.getSuppliers(),
        ProductService.instance.getProducts(),
      ]);
      if (!mounted) return;
      setState(() {
        _suppliers = results[0];
        _products = results[1];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement données: $e')),
      );
    }
  }

  void _addItem() {
    setState(() {
      _items.add(_PurchaseItem());
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  double get _totalAmount {
    double total = 0;
    for (final item in _items) {
      total += item.quantity * item.unitCost;
    }
    return total;
  }

  Future<void> _submit() async {
    if (_selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un fournisseur')),
      );
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez ajouter au moins un produit')),
      );
      return;
    }

    final validItems = _items
        .where((i) => i.productId != null && i.quantity > 0 && i.unitCost > 0)
        .toList();
    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez remplir les détails des produits')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await PurchaseService.instance.createPurchase(
        supplierId: _selectedSupplierId!,
        items: validItems
            .map((i) => {
                  'product_id': i.productId!,
                  'quantity': i.quantity,
                  'unit_cost': i.unitCost,
                })
            .toList(),
        currency: _selectedCurrency,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Achat créé avec succès')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencySymbol = _selectedCurrency == 'USD' ? '\$' : 'FC';

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: _isLoading
          ? SizedBox(
              height: 30.h,
              child: const Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nouvel Achat',
                    style:
                        TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 2.h),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSupplierId,
                    decoration: const InputDecoration(
                      labelText: 'Fournisseur',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                    items: _suppliers
                        .map((s) => DropdownMenuItem<String>(
                              value: s['id'] as String,
                              child: Text(s['company_name'] ?? 'Sans nom'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedSupplierId = v),
                  ),
                  SizedBox(height: 2.h),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCurrency,
                    decoration: const InputDecoration(
                      labelText: 'Devise',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.monetization_on),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'CDF', child: Text('CDF (Franc Congolais)')),
                      DropdownMenuItem(
                          value: 'USD', child: Text('USD (Dollar US)')),
                    ],
                    onChanged: (v) =>
                        setState(() => _selectedCurrency = v ?? 'CDF'),
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Produits',
                        style: TextStyle(
                            fontSize: 13.sp, fontWeight: FontWeight.w600),
                      ),
                      TextButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Ajouter'),
                      ),
                    ],
                  ),
                  ..._items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return _buildItemRow(item, index);
                  }),
                  if (_items.isNotEmpty) ...[
                    Divider(height: 3.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total:',
                          style: TextStyle(
                              fontSize: 14.sp, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '$currencySymbol ${_totalAmount.toStringAsFixed(_selectedCurrency == "USD" ? 2 : 0)}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 2.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed:
                            _isSubmitting ? null : () => Navigator.pop(context),
                        child: const Text('Annuler'),
                      ),
                      SizedBox(width: 2.w),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Créer'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildItemRow(_PurchaseItem item, int index) {
    return Card(
      margin: EdgeInsets.only(bottom: 1.h),
      child: Padding(
        padding: EdgeInsets.all(2.w),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: item.productId,
                    decoration: const InputDecoration(
                      labelText: 'Produit',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    isExpanded: true,
                    items: _products
                        .map((p) => DropdownMenuItem<String>(
                              value: p['id'] as String,
                              child: Text(
                                p['name'] ?? 'Sans nom',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => item.productId = v),
                  ),
                ),
                SizedBox(width: 2.w),
                IconButton(
                  onPressed: () => _removeItem(index),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  iconSize: 20,
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Quantité',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    initialValue:
                        item.quantity > 0 ? item.quantity.toString() : '',
                    onChanged: (v) {
                      setState(() {
                        item.quantity = int.tryParse(v) ?? 0;
                      });
                    },
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Coût unitaire',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    initialValue:
                        item.unitCost > 0 ? item.unitCost.toString() : '',
                    onChanged: (v) {
                      setState(() {
                        item.unitCost = double.tryParse(v) ?? 0;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseItem {
  String? productId;
  int quantity = 0;
  double unitCost = 0;
}
