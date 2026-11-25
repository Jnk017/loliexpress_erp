import 'package:flutter/material.dart';

import '../../widgets/screen_state_view.dart';
import '../../widgets/create_reference_form.dart';
import '../../widgets/treasury_account_picker.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/request_id.dart';
import '../../services/company_settings_service.dart';
import '../../services/delivery_service.dart';
import '../../services/purchase_service.dart';
import '../../services/role_service.dart';
import '../../services/product_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/role_workspace_panel.dart';

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
  bool get _canCreatePurchase => const [UserRole.admin, UserRole.acheteur]
      .contains(RoleService.instance.currentRole);

  bool get _isWarehouseStaff =>
      RoleService.instance.currentRole == UserRole.warehouseStaff;

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
      final service = PurchaseService.instance;
      final purchases = _isWarehouseStaff
          ? await service.getWarehouseReceiptQueue()
          : await service.getPurchases(status: _getStatusFilter());
      if (!mounted) return;
      setState(() {
        _purchases = purchases;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Impossible de charger les achats.';
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

  Future<void> _showCreatePurchaseDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const _CreatePurchaseDialog(),
    );
    if (result == true && mounted) await _loadPurchases();
  }

  Future<void> _openPurchaseOperations(Map<String, dynamic> purchase) async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    final service = PurchaseService.instance;
    try {
      final profile = await client.from('user_profiles')
          .select('role,is_active,must_change_password')
          .eq('id', userId)
          .maybeSingle();
      if (!mounted || profile == null || profile['is_active'] != true ||
          profile['must_change_password'] != false) {
        return;
      }
      final role = profile['role'];
      final purchaseId = purchase['id'] as String;
      final detail = await service.getPurchaseById(purchaseId);
      if (!mounted || detail == null) return;
      final lines = List<Map<String, dynamic>>.from(detail['purchase_items'] as List);
      final bills = List<Map<String, dynamic>>.from(detail['supplier_bills'] as List);
      final currency = detail['currency'] as String;
      final canReceive = const ['admin', 'acheteur', 'warehouse_staff'].contains(role)
          && const ['pending', 'partial'].contains(detail['status']);
      final canBill = const ['admin', 'acheteur', 'comptable'].contains(role)
          && detail['status'] != 'cancelled';
      final canPay = const ['admin', 'comptable'].contains(role)
          && detail['status'] != 'cancelled';
      if (!canReceive && !canBill && !canPay) return;
      final operation = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: Text('Achat ${detail['purchase_number']}'),
          children: [
            if (canReceive)
              SimpleDialogOption(onPressed: () => Navigator.pop(context, 'receive'),
                  child: const Text('Réceptionner des articles')),
            if (canBill)
              SimpleDialogOption(onPressed: () => Navigator.pop(context, 'bill'),
                  child: const Text('Enregistrer une facture fournisseur')),
            if (canPay)
              SimpleDialogOption(onPressed: () => Navigator.pop(context, 'pay'),
                  child: const Text('Enregistrer un règlement')),
          ],
        ),
      );
      if (!mounted || operation == null) return;

      if (operation == 'receive') {
        final line = await _choosePurchaseRow(
          'Article à réceptionner',
          lines.where((row) => (row['quantity'] as int) > (row['received_quantity'] as int? ?? 0)),
          (row) => "${row['products']?['name'] ?? 'Article'} · ${(row['quantity'] as int) - (row['received_quantity'] as int? ?? 0)} restant(s)",
        );
        if (!mounted || line == null) return;
        final warehouses = await DeliveryService.instance.getActiveWarehouses();
        if (!mounted) return;
        final warehouse = await _choosePurchaseRow('Entrepôt de réception', warehouses, (row) => row['name'] as String);
        if (!mounted || warehouse == null) return;
        final requestId = newRequestId();
        await _submitPurchaseOperation('Réception physique', const ['Quantité reçue'], (values) async {
          final quantity = int.tryParse(values.single);
          if (quantity == null || quantity <= 0) throw const FormatException('Quantité invalide');
          await service.receivePurchaseItem(
            purchaseItemId: line['id'] as String,
            warehouseId: warehouse['id'] as String,
            quantity: quantity,
            requestId: requestId,
          );
        });
      } else if (operation == 'bill') {
        await _submitPurchaseOperation('Facture fournisseur', [
          'Numéro de facture', 'Échéance (AAAA-MM-JJ)', 'Montant ($currency)',
        ], (values) async {
          final date = DateTime.tryParse(values[1]);
          if (date == null || DateFormat('yyyy-MM-dd').format(date) != values[1]) {
            throw const FormatException('Échéance invalide');
          }
          await service.registerSupplierBill(purchaseId: purchaseId, billNumber: values[0],
              dueDate: values[1], amount: _readOperationAmount(values[2]));
        });
      } else {
        final bill = await _choosePurchaseRow('Facture à régler',
          bills.where((row) => (row['amount'] as num) > (row['amount_paid'] as num)),
          (row) => "${row['bill_number']} · ${(row['amount'] as num) - (row['amount_paid'] as num)} ${row['currency']}",
        );
        if (!mounted || bill == null) return;
        final requestId = newRequestId();
        final account = await pickTreasuryAccount(context, bill['currency'] as String, incoming: false, includeMobileMoney: true);
        if (!mounted || account == null) return;
        await _submitPurchaseOperation('Règlement fournisseur',
          ['Montant (${bill['currency']})', 'Référence du règlement'],
          (values) => service.recordSupplierBillPayment(
            billId: bill['id'] as String,
            amount: _readOperationAmount(values[0]),
            currency: bill['currency'] as String,
            reference: values[1],
            requestId: requestId,
            accountKind: account.kind,
            paymentMethod: account.method,
            accountId: account.id,
          ),
        );
      }
      if (mounted) await _loadPurchases();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opération fournisseur indisponible.')),
      );
    }
  }

  double _readOperationAmount(String value) {
    final text = value.replaceAll(',', '.');
    if (!RegExp(r'^\d{1,10}(\.\d{1,2})?$').hasMatch(text)) {
      throw const FormatException('Montant invalide');
    }
    final amount = double.parse(text);
    if (amount <= 0) throw const FormatException('Montant invalide');
    return amount;
  }

  Future<Map<String, dynamic>?> _choosePurchaseRow(
    String title, Iterable<Map<String, dynamic>> rows,
    String Function(Map<String, dynamic>) label,
  ) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(title),
        children: [
          if (rows.isEmpty)
            const Padding(padding: EdgeInsets.all(16), child: Text('Aucun élément disponible.')),
          for (final row in rows)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, row),
              child: Text(label(row)),
            ),
        ],
      ),
    );
  }

  Future<void> _submitPurchaseOperation(String title, List<String> fields,
      Future<void> Function(List<String>) submit) async {
    final values = List<String>.filled(fields.length, '');
    var busy = false;
    var submitted = false;
    String? error;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, update) => PopScope(
          canPop: !busy,
          child: AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                for (var index = 0; index < fields.length; index++)
                  TextField(enabled: !submitted,
                    decoration: InputDecoration(labelText: fields[index]),
                    onChanged: (value) => values[index] = value.trim()),
                if (error != null) Text(error!),
              ]),
            ),
            actions: [
              TextButton(onPressed: busy ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Fermer')),
              FilledButton(
                onPressed: busy ? null : () async {
                  if (values.any((value) => value.isEmpty)) {
                    update(() => error = 'Tous les champs sont requis.');
                    return;
                  }
                  update(() { busy = true; error = null; });
                  try {
                    await submit(values);
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  } on FormatException catch (e) {
                    if (dialogContext.mounted) update(() { busy = false; error = e.message; });
                  } catch (_) {
                    if (dialogContext.mounted) {
                      update(() {
                        busy = false;
                        submitted = true;
                        error = 'Opération non confirmée. Réessayez ou vérifiez les données.';
                      });
                    }
                  }
                },
                child: Text(submitted ? 'Réessayer' : 'Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _receiveWarehouseLine(Map<String, dynamic> line) async {
    try {
      final warehouses = await DeliveryService.instance.getActiveWarehouses();
      if (!mounted) return;
      final warehouse = await _choosePurchaseRow(
        'Entrepôt de réception',
        warehouses,
        (row) => row['name'] as String,
      );
      if (!mounted || warehouse == null) return;
      final requestId = newRequestId();
      await _submitPurchaseOperation(
        'Réception physique',
        const ['Quantité reçue'],
        (values) async {
          final quantity = int.tryParse(values.single);
          final remaining = line['remaining_quantity'] as int;
          if (quantity == null || quantity < 1 || quantity > remaining) {
            throw FormatException('Saisissez une quantité de 1 à $remaining.');
          }
          await PurchaseService.instance.receivePurchaseItem(
            purchaseItemId: line['purchase_item_id'] as String,
            warehouseId: warehouse['id'] as String,
            quantity: quantity,
            requestId: requestId,
          );
        },
      );
      if (mounted) await _loadPurchases();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de préparer la réception.')),
      );
    }
  }

  Widget _buildWarehouseReceiptQueue() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Réception des marchandises'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _isLoading ? null : _loadPurchases,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : _purchases.isEmpty
                    ? const Center(child: Text('Aucun article à réceptionner.'))
                    : ListView(
                        children: [
                          for (final line in _purchases)
                            ListTile(
                              title: Text(line['product_name'] as String),
                              subtitle: Text(
                                '${line['purchase_number']} · '
                                '${line['remaining_quantity']} restant(s)',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _receiveWarehouseLine(line),
                            ),
                        ],
                      ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isWarehouseStaff) return _buildWarehouseReceiptQueue();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Achats',
        root: true,
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
          if (RoleService.instance.currentRole == UserRole.acheteur)
            RoleWorkspacePanel(onNewPurchase: _showCreatePurchaseDialog),
          Container(
            color: theme.cardColor,
            child: TabBar(
              controller: _tabController,
              labelColor: theme.primaryColor,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
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
      floatingActionButton: _canCreatePurchase ? FloatingActionButton(
        onPressed: _showCreatePurchaseDialog,
        tooltip: 'Nouvel achat',
        child: const Icon(Icons.add),
      ) : null,
      bottomNavigationBar: const CustomBottomBar(currentIndex: 0),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ScreenStateView.error(
        message: 'Impossible de charger les achats.',
        onAction: _loadPurchases,
      );
    }

    if (_purchases.isEmpty) {
      return ScreenStateView(
        icon: Icons.shopping_bag_outlined,
        message: 'Aucun achat trouvé.',
        actionLabel: 'Nouvel achat',
        onAction: _canCreatePurchase ? _showCreatePurchaseDialog : null,
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(3.w, 3.w, 3.w,
          (_canCreatePurchase ? 88 : 24) + MediaQuery.paddingOf(context).bottom),
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
            TextButton(
              onPressed: () => _openPurchaseOperations(purchase),
              child: const Text('Réception, facture et règlement'),
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
      final settings = await const CompanySettingsService().load();
      if (!mounted) return;
      setState(() {
        _suppliers = results[0];
        _products = results[1];
        _selectedCurrency = settings['default_currency'] as String;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de charger le formulaire d’achat.')),
      );
    }
  }

  Future<void> _createSupplier() async {
    Map<String, dynamic>? supplier;
    final created = await showCreateReferenceForm(
      context,
      title: 'Nouveau fournisseur',
      save: (name, address) async {
        supplier = await PurchaseService.instance.createSupplier({
          'company_name': name,
          'address': address,
          'is_active': true,
        });
      },
    );
    if (!created || !mounted || supplier == null) return;
    setState(() {
      _suppliers = [..._suppliers, supplier!];
      _selectedSupplierId = supplier!['id'] as String;
    });
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
        SnackBar(content: Text('L’achat n’a pas pu être enregistré.')),
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
                    'Nouvel achat',
                    style:
                        TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_selectedSupplierId),
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
                  if (const [UserRole.admin, UserRole.acheteur].contains(RoleService.instance.currentRole))
                    TextButton.icon(
                      onPressed: _isSubmitting ? null : _createSupplier,
                      icon: const Icon(Icons.person_add_alt),
                      label: const Text('Nouveau fournisseur'),
                    ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCurrency,
                    decoration: const InputDecoration(
                      labelText: 'Devise',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.currency_exchange),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'CDF', child: Text('CDF (franc congolais)')),
                      DropdownMenuItem(
                          value: 'USD', child: Text('USD (Dollar US)')),
                    ],
                    onChanged: (v) =>
                        setState(() => _selectedCurrency = v ?? 'CDF'),
                  ),
                  const SizedBox(height: 12),
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
                        label: const Text('Ajouter un produit'),
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
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
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
