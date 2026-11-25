import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../widgets/treasury_account_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../core/request_id.dart';
import '../../services/customer_service.dart';
import '../../services/company_settings_service.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/quick_currency_converter_widget.dart';
import './widgets/invoice_details_widget.dart';
import './widgets/invoice_header_widget.dart';
import './widgets/invoice_summary_widget.dart';
import './widgets/line_items_widget.dart';
import './widgets/notes_widget.dart';
import './widgets/payment_terms_widget.dart';

class InvoiceGeneration extends StatefulWidget {
  const InvoiceGeneration({super.key});

  @override
  State<InvoiceGeneration> createState() => _InvoiceGenerationState();
}

class _InvoiceGenerationState extends State<InvoiceGeneration> {
  // Controllers
  final TextEditingController _termsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _deliveryFeeController = TextEditingController();

  // Invoice Data
  String _invoiceNumber = '';
  String? _draftId;
  String? _selectedCustomer;
  Map<String, dynamic>? _selectedCustomerData;
  DateTime _issueDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  String _currency = 'CDF';
  bool _currencyChosen = false;
  String _paymentMethod = 'Virement bancaire';
  int _paymentDays = 30;
  final List<Map<String, dynamic>> _lineItems = [];
  bool _isProcessing = false;
  bool _homeDelivery = false;
  bool _canIssueInvoice = false;
  bool _canCreditDeliveryFee = false;

  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _generateInvoiceNumber();
    _loadInvoiceSources();
    _loadDefaultInvoiceCurrency();
    _loadInvoicePermissions();
    _termsController.text =
        'Paiement à effectuer dans les $_paymentDays jours suivant la date de facturation. Pénalités de retard applicables selon les conditions générales de vente.';
  }

  Future<void> _loadDefaultInvoiceCurrency() async {
    try {
      final settings = await const CompanySettingsService().load();
      if (mounted && !_currencyChosen && _lineItems.isEmpty) {
        setState(() => _currency = settings['default_currency'] as String);
      }
    } catch (_) {
      // Access and network errors do not overwrite the current selection.
    }
  }

  Future<void> _loadInvoicePermissions() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final profile = await client
          .from('user_profiles')
          .select('role,is_active,must_change_password')
          .eq('id', userId)
          .maybeSingle();
      if (!mounted || profile == null) return;
      setState(() {
        final active = profile['is_active'] == true &&
            profile['must_change_password'] == false;
        _canIssueInvoice =
            active && const ['admin', 'comptable'].contains(profile['role']);
        _canCreditDeliveryFee = active && profile['role'] == 'admin';
      });
    } catch (_) {
      // The issuance action stays unavailable when permissions cannot be read.
    }
  }

  Future<void> _recordInvoicePayment() async {
    if (_isProcessing) return;
    final client = Supabase.instance.client;
    setState(() => _isProcessing = true);
    try {
      final invoices = await client.from('invoice_open_balances')
          .select('invoice_id,currency,outstanding_amount')
          .order('due_date')
          .limit(100);
      final ids = invoices.map((invoice) => invoice['invoice_id'] as String).toList();
      if (!mounted) return;
      if (ids.isEmpty) {
        _showErrorSnackBar('Aucune facture ouverte à encaisser.');
        return;
      }
      final invoiceDetails = await client.from('invoices')
          .select('id,invoice_number')
          .inFilter('id', ids);
      final numbers = {for (final row in invoiceDetails) row['id']: row['invoice_number']};
      if (!mounted) return;
      final invoice = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Facture à encaisser'),
          children: [
            for (final invoice in invoices)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, invoice),
                child: Text("${numbers[invoice['invoice_id']]} · "
                    "${invoice['outstanding_amount']} ${invoice['currency']}"),
              ),
          ],
        ),
      );
      if (!mounted || invoice == null) return;
      var amountText = '';
      var reference = '';
      final account = await pickTreasuryAccount(context, invoice['currency'] as String, incoming: true);
      if (!mounted || account == null) return;
      final requestId = newRequestId();
      var busy = false;
      String? error;
      final saved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
          builder: (dialogContext, updateDialog) => PopScope(
            canPop: !busy,
            child: AlertDialog(
              title: const Text('Encaissement client'),
              content: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                    enabled: !busy,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'Montant (${invoice['currency']})'),
                    onChanged: (value) => amountText = value.trim().replaceAll(',', '.'),
                  ),
                  TextField(
                    enabled: !busy,
                    decoration: const InputDecoration(labelText: 'Référence du paiement'),
                    onChanged: (value) => reference = value.trim(),
                  ),
                  if (error != null) Text(error!),
                ]),
              ),
              actions: [
                TextButton(onPressed: busy ? null : () => Navigator.pop(dialogContext),
                    child: const Text('Fermer')),
                FilledButton(
                  onPressed: busy ? null : () async {
                    final amount = RegExp(r'^\d{1,10}(\.\d{1,2})?$').hasMatch(amountText)
                        ? double.tryParse(amountText)
                        : null;
                    if (amount == null || amount <= 0 || reference.isEmpty || reference.length > 100) {
                      updateDialog(() => error = 'Vérifiez le montant et la référence.');
                      return;
                    }
                    updateDialog(() { busy = true; error = null; });
                    try {
                      await client.rpc('receive_invoice_payment', params: {
                        'p_invoice_id': invoice['invoice_id'],
                        'p_amount': amount,
                        'p_currency': invoice['currency'],
                        'p_reference': reference,
                        'p_kind': account.kind,
                        'p_account_id': account.id,
                        'p_request_id': requestId,
                      });
                      if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                    } catch (_) {
                      if (dialogContext.mounted) updateDialog(() {
                        busy = false;
                        error = 'Paiement non confirmé. Vérifiez le solde ou réessayez avec la même référence.';
                      });
                    }
                  },
                  child: const Text('Enregistrer le paiement'),
                ),
              ],
            ),
          ),
        ),
      );
      if (mounted && saved == true) _showSuccessSnackBar('Encaissement enregistré.');
    } catch (_) {
      if (mounted) _showErrorSnackBar('Les factures à encaisser sont indisponibles.');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _creditReturnedItem() async {
    if (_isProcessing) return;
    final client = Supabase.instance.client;
    setState(() => _isProcessing = true);
    try {
      final inspections = await client.from('customer_return_inspections')
          .select('id,sellable_quantity,order_items(products(name),sales_orders(order_number))')
          .gt('sellable_quantity', 0)
          .order('inspected_at', ascending: false)
          .limit(100);
      if (!mounted) return;
      if (inspections.isEmpty) {
        _showErrorSnackBar('Aucun retour avec des unités revendables.');
        return;
      }
      final selection = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Retour contrôlé à créditer'),
          children: [
            for (final inspection in inspections)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, inspection),
                child: Text(
                  "${inspection['order_items']?['sales_orders']?['order_number'] ?? 'Commande'} · "
                  "${inspection['order_items']?['products']?['name'] ?? 'Article'} · "
                  "${inspection['sellable_quantity']} revendable(s)",
                ),
              ),
          ],
        ),
      );
      if (!mounted || selection == null) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Accorder l’avoir article ?'),
          content: Text(
            "L’avoir couvrira ${selection['sellable_quantity']} unité(s) revendable(s), au prix net facturé.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Accorder l’avoir'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
      await client.rpc('record_return_item_credit', params: {
        'p_inspection_id': selection['id'],
      });
      if (mounted) _showSuccessSnackBar('Avoir article enregistré.');
    } catch (_) {
      if (mounted) _showErrorSnackBar('Avoir indisponible. Vérifiez la facture et le retour.');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _creditDeliveryFee() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    final client = Supabase.instance.client;
    try {
      final invoices = (await client.from('invoices')
              .select('id,invoice_number,currency,delivery_fee,delivery_fee_credited')
              .eq('home_delivery', true)
              .gt('delivery_fee', 0)
              .order('created_at', ascending: false)
              .limit(100))
          .where((invoice) => (invoice['delivery_fee'] as num) >
              (invoice['delivery_fee_credited'] as num))
          .toList();
      if (!mounted) return;
      if (invoices.isEmpty) {
        _showErrorSnackBar('Aucun frais de livraison à créditer.');
        return;
      }
      final invoice = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Facture avec frais de livraison'),
          children: [
            for (final invoice in invoices)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, invoice),
                child: Text('${invoice['invoice_number']} · ${invoice['currency']}'),
              ),
          ],
        ),
      );
      if (!mounted || invoice == null) return;
      final maximum = ((invoice['delivery_fee'] as num) -
          (invoice['delivery_fee_credited'] as num)).toDouble();
      final requestId = newRequestId();
      var amountText = '';
      var reason = '';
      var pending = false;
      var submitted = false;
      String? error;
      final saved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
          builder: (dialogContext, updateDialog) => PopScope(
            canPop: !pending,
            child: AlertDialog(
              title: const Text('Accorder un avoir sur la livraison'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Maximum : ${_formatCurrency(maximum)} ${invoice['currency']}'),
                    TextField(
                      enabled: !pending && !submitted,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Montant de l’avoir'),
                      onChanged: (value) => amountText = value,
                    ),
                    TextField(
                      enabled: !pending && !submitted,
                      decoration: const InputDecoration(labelText: 'Motif'),
                      onChanged: (value) => reason = value,
                    ),
                    if (error != null) Text(error!),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: pending ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Fermer'),
                ),
                FilledButton(
                  onPressed: pending ? null : () async {
                    final normalized = amountText.trim().replaceAll(',', '.');
                    final amount = RegExp(r'^\d{1,10}(\.\d{1,2})?$').hasMatch(normalized)
                        ? double.tryParse(normalized)
                        : null;
                    if (amount == null || amount <= 0 || amount > maximum || reason.trim().isEmpty) {
                      updateDialog(() => error = 'Saisissez un montant valide et un motif.');
                      return;
                    }
                    updateDialog(() {
                      pending = true;
                      submitted = true;
                      error = null;
                    });
                    try {
                      await client.rpc('record_delivery_fee_credit', params: {
                        'p_invoice_id': invoice['id'],
                        'p_amount': amount,
                        'p_reason': reason.trim(),
                        'p_request_id': requestId,
                      });
                      if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                    } catch (_) {
                      if (dialogContext.mounted) {
                        updateDialog(() {
                          pending = false;
                          error = 'Avoir non confirmé. Réessayez ou vérifiez la facture.';
                        });
                      }
                    }
                  },
                  child: Text(submitted ? 'Réessayer' : 'Accorder l’avoir'),
                ),
              ],
            ),
          ),
        ),
      );
      if (mounted && saved == true) _showSuccessSnackBar('Avoir de livraison enregistré.');
    } catch (_) {
      if (mounted) _showErrorSnackBar('Les factures avec livraison sont indisponibles.');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _issueFromOrder() async {
    if (_isProcessing || !_validateDeliveryFee()) return;
    final dueDate = _dueDate;
    final homeDelivery = _homeDelivery;
    final fee = _readDeliveryFee()!;
    setState(() => _isProcessing = true);
    try {
      final orders = (await OrderService.instance.getOrders())
          .where((order) => const ['confirmed', 'processing', 'shipped', 'delivered']
              .contains(order['order_status']))
          .toList();
      if (!mounted) return;
      if (orders.isEmpty) {
        _showErrorSnackBar('Aucune commande confirmée à facturer.');
        return;
      }
      final order = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Commande à facturer'),
          children: [
            for (final order in orders)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, order),
                child: Text('${order['order_number']} · ${order['currency']}'),
              ),
          ],
        ),
      );
      if (!mounted || order == null) return;
      final currency = order['currency'] as String;
      if (fee > 0 && currency != _currency) {
        _showErrorSnackBar('Saisissez les frais dans la devise de la commande.');
        return;
      }
      final subtotal = (order['subtotal'] as num).toDouble();
      final discount = (order['discount_amount'] as num?)?.toDouble() ?? 0;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmer l’émission'),
          content: Text('Total TTC : ${_formatCurrency(subtotal - discount + fee)} $currency'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Émettre la facture'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
      final orderDetails = await OrderService.instance.getOrderById(order['id'] as String);
      if (!mounted || orderDetails == null) return;
      final invoice = await OrderService.instance.issueInvoice(
        orderId: order['id'] as String,
        dueDate: dueDate,
        homeDelivery: homeDelivery,
        deliveryFee: fee,
      );
      if (!mounted) return;
      final action = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Facture ${invoice['invoice_number']} émise'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'pdf'),
              child: const Text('PDF'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'share'),
              child: const Text('Partager'),
            ),
          ],
        ),
      );
      if (!mounted || action == null) return;
      final filename = '${invoice['invoice_number']}.pdf';
      try {
        final bytes = await _buildInvoicePdf(issuedInvoice: invoice, issuedOrder: orderDetails);
        if (action == 'pdf') {
          await Printing.sharePdf(bytes: bytes, filename: filename);
        } else {
          await SharePlus.instance.share(ShareParams(files: [
            XFile.fromData(bytes, name: filename, mimeType: 'application/pdf'),
          ]));
        }
      } catch (_) {
        if (mounted) _showErrorSnackBar('Facture émise. Le PDF n’a pas pu être ouvert.');
      }
    } catch (_) {
      if (mounted) _showErrorSnackBar('La facture n’a pas pu être émise.');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _termsController.dispose();
    _notesController.dispose();
    _deliveryFeeController.dispose();
    super.dispose();
  }

  void _generateInvoiceNumber() {
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final random =
        (now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    setState(() {
      _invoiceNumber = 'INV-$year$month-$random';
    });
  }

  Future<void> _loadInvoiceSources() async {
    final results = await Future.wait([
      CustomerService.instance.getCustomers(limit: 1000),
      ProductService.instance.getProducts(limit: 1000),
    ]);
    if (!mounted) return;
    setState(() {
      _customers = (results[0]).map((customer) {
        return {
          'id': customer['id'],
          'name': customer['company_name'] ?? 'Client inconnu',
          'email': customer['email'] ?? '',
          'phone': customer['phone'] ?? '',
          'address': customer['address'] ?? '',
          'paymentTerms': 30,
        };
      }).toList();
      _products = (results[1]).map((product) {
        return {
          'id': product['id'],
          'name': product['name'] ?? 'Produit inconnu',
          'unitPrice': (product['unit_price'] as num?)?.toDouble() ?? 0,
          'taxRate': 0.0,
        };
      }).toList();
    });
  }

  double _calculateSubtotal() {
    return _lineItems.fold(0.0, (sum, item) {
      final quantity = item['quantity'] as int;
      final unitPrice = item['unitPrice'] as double;
      return sum + (quantity * unitPrice);
    });
  }

  double _calculateTax() => 0;

  double? _readDeliveryFee() {
    if (!_homeDelivery) return 0;
    final text = _deliveryFeeController.text.trim().replaceAll(',', '.');
    if (text.isEmpty) return 0;
    if (!RegExp(r'^\d{1,10}(\.\d{1,2})?$').hasMatch(text)) return null;
    return double.tryParse(text);
  }

  bool _validateDeliveryFee() {
    if (_readDeliveryFee() != null) return true;
    _showErrorSnackBar('Saisissez des frais de livraison valides.');
    return false;
  }

  double _calculateTotal() {
    return _calculateSubtotal() + (_readDeliveryFee() ?? 0);
  }

  Future<void> _selectCustomer() async {
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCustomerSelector(),
    );

    if (selected != null) {
      setState(() {
        _selectedCustomerData = selected;
        _selectedCustomer = selected['name'] as String;
        _paymentDays = selected['paymentTerms'] as int;
        _dueDate = _issueDate.add(Duration(days: _paymentDays));
        _termsController.text =
            'Paiement à effectuer dans les $_paymentDays jours suivant la date de facturation. Pénalités de retard applicables selon les conditions générales de vente.';
      });
    }
  }

  Widget _buildCustomerSelector() {
    final theme = Theme.of(context);

    return Container(
      height: 70.h,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sélectionner un client',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: CustomIconWidget(
                    iconName: 'close',
                    color: theme.colorScheme.onSurface,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.all(4.w),
              itemCount: _customers.length,
              separatorBuilder: (context, index) => SizedBox(height: 2.h),
              itemBuilder: (context, index) {
                final customer = _customers[index];
                return InkWell(
                  onTap: () => Navigator.pop(context, customer),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer['name'] as String,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'email',
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 16,
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: Text(
                                customer['email'] as String,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 0.5.h),
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'phone',
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 16,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              customer['phone'] as String,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(bool isIssueDate) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: isIssueDate ? _issueDate : _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (selectedDate != null) {
      setState(() {
        if (isIssueDate) {
          _issueDate = selectedDate;
          _dueDate = _issueDate.add(Duration(days: _paymentDays));
        } else {
          _dueDate = selectedDate;
        }
      });
    }
  }

  Future<void> _selectCurrency() async {
    final currencies = ['CDF', 'USD'];
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildOptionSelector(
        title: 'Sélectionner la devise',
        options: currencies,
      ),
    );

    if (selected != null) {
      setState(() {
        _currencyChosen = true;
        _currency = selected;
      });
    }
  }

  Future<void> _selectPaymentMethod() async {
    final methods = [
      'Virement bancaire',
      'Chèque',
      'Espèces',
      'Mobile Money',
      'Carte bancaire',
    ];
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildOptionSelector(
        title: 'Mode de paiement',
        options: methods,
      ),
    );

    if (selected != null) {
      setState(() => _paymentMethod = selected);
    }
  }

  Future<void> _selectPaymentDays() async {
    final days = [15, 30, 45, 60, 90];
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildOptionSelector(
        title: 'Délai de paiement',
        options: days.map((d) => '$d jours').toList(),
        values: days,
      ),
    );

    if (selected != null) {
      setState(() {
        _paymentDays = selected;
        _dueDate = _issueDate.add(Duration(days: _paymentDays));
        _termsController.text =
            'Paiement à effectuer dans les $_paymentDays jours suivant la date de facturation. Pénalités de retard applicables selon les conditions générales de vente.';
      });
    }
  }

  Widget _buildOptionSelector<T>({
    required String title,
    required List<String> options,
    List<T>? values,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: CustomIconWidget(
                      iconName: 'close',
                      color: theme.colorScheme.onSurface,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.all(4.w),
              itemCount: options.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(options[index]),
                  onTap: () => Navigator.pop(
                    context,
                    values != null ? values[index] : options[index],
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addProduct() async {
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildProductSelector(),
    );

    if (selected != null) {
      final quantity = await _showQuantityDialog();
      if (quantity != null && quantity > 0) {
        setState(() {
          _lineItems.add({
            'productId': selected['id'],
            'productName': selected['name'],
            'quantity': quantity,
            'unitPrice': selected['unitPrice'],
            'taxRate': selected['taxRate'],
          });
        });
      }
    }
  }

  Widget _buildProductSelector() {
    final theme = Theme.of(context);

    return Container(
      height: 70.h,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ajouter un produit',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/barcode-scanner');
                      },
                      icon: CustomIconWidget(
                        iconName: 'qr_code_scanner',
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: CustomIconWidget(
                        iconName: 'close',
                        color: theme.colorScheme.onSurface,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.all(4.w),
              itemCount: _products.length,
              separatorBuilder: (context, index) => SizedBox(height: 2.h),
              itemBuilder: (context, index) {
                final product = _products[index];
                return InkWell(
                  onTap: () => Navigator.pop(context, product),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['name'] as String,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 0.5.h),
                              Text(
                                'TVA ${(product['taxRate'] as double).toStringAsFixed(0)}%',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${(product['unitPrice'] as double).toStringAsFixed(0)} FC',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<int?> _showQuantityDialog() async {
    final controller = TextEditingController(text: '1');
    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Quantité'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Entrez la quantité',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final quantity = int.tryParse(controller.text);
                Navigator.pop(context, quantity);
              },
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );
  }

  void _editLineItem(int index) async {
    final quantity = await _showQuantityDialog();
    if (quantity != null && quantity > 0) {
      setState(() {
        _lineItems[index]['quantity'] = quantity;
      });
    }
  }

  void _removeLineItem(int index) {
    setState(() {
      _lineItems.removeAt(index);
    });
  }

  Future<void> _saveDraft() async {
    if (_isProcessing) return;
    if (!_validateDeliveryFee()) return;
    if (_selectedCustomer == null) {
      _showErrorSnackBar('Veuillez sélectionner un client');
      return;
    }

    if (_lineItems.isEmpty) {
      _showErrorSnackBar('Veuillez ajouter au moins un article');
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final result = await Supabase.instance.client.rpc('save_invoice_draft', params: {
        'p_draft_id': _draftId,
        'p_customer_id': _selectedCustomer,
        'p_currency': _currency,
        'p_payload': {
          'issue_date': _issueDate.toIso8601String(),
          'due_date': _dueDate.toIso8601String(),
          'payment_method': _paymentMethod,
          'payment_days': _paymentDays,
          'terms': _termsController.text,
          'notes': _notesController.text,
          'home_delivery': _homeDelivery,
          'delivery_fee': _readDeliveryFee(),
          'items': _lineItems.map((item) => Map<String, dynamic>.from(item)).toList(),
        },
      });
      if (result is! String) {
        throw const FormatException('Identifiant de brouillon invalide');
      }
      if (!mounted) return;
      _draftId = result;
      _showSuccessSnackBar('Brouillon enregistré avec succès');
    } catch (_) {
      if (mounted) _showErrorSnackBar('Le brouillon n’a pas pu être enregistré');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _generatePDF() async {
    if (_isProcessing || !_validateDeliveryFee()) return;
    if (_selectedCustomer == null) {
      _showErrorSnackBar('Veuillez sélectionner un client');
      return;
    }

    if (_lineItems.isEmpty) {
      _showErrorSnackBar('Veuillez ajouter au moins un article');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final bytes = await _buildInvoicePdf();
      await Printing.sharePdf(
        bytes: bytes,
        filename: '$_invoiceNumber.pdf',
      );

      _showSuccessSnackBar('PDF généré avec succès');
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la génération du PDF');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<Uint8List> _buildInvoicePdf({
    Map<String, dynamic>? issuedInvoice,
    Map<String, dynamic>? issuedOrder,
  }) async {
    final storedPresentation = issuedInvoice?['company_presentation'];
    final presentation = storedPresentation is Map
        ? Map<String, dynamic>.from(storedPresentation)
        : await const CompanySettingsService().load();
    final currency = issuedInvoice?['currency'] as String? ?? _currency;
    final invoiceNumber = issuedInvoice?['invoice_number'] as String? ?? _invoiceNumber;
    final issueDate = issuedInvoice == null
        ? _issueDate
        : DateTime.parse(issuedInvoice['invoice_date'] as String).toLocal();
    final dueDate = issuedInvoice == null
        ? _dueDate
        : DateTime.parse(issuedInvoice['due_date'] as String).toLocal();
    final customer = issuedOrder == null
        ? _selectedCustomerData!
        : {
            'name': (issuedOrder['customers'] as Map?)?['company_name'] ?? '',
            'address': '',
            'email': '',
            'phone': '',
          };
    final items = issuedOrder == null
        ? _lineItems
        : (issuedOrder['order_items'] as List).map((raw) {
            final item = raw as Map;
            return <String, dynamic>{
              'productName': (item['products'] as Map?)?['name'] ?? item['product_id'],
              'quantity': item['quantity'],
              'unitPrice': (item['unit_price'] as num).toDouble(),
              'taxRate': 0.0,
            };
          }).toList();
    final subtotal = (issuedInvoice?['subtotal'] as num?)?.toDouble() ?? _calculateSubtotal();
    final discount = (issuedInvoice?['discount_amount'] as num?)?.toDouble() ?? 0.0;
    final fee = (issuedInvoice?['delivery_fee'] as num?)?.toDouble() ?? _readDeliveryFee() ?? 0.0;
    final totalAmount = (issuedInvoice?['total_amount'] as num?)?.toDouble() ?? _calculateTotal();
    final homeDelivery = issuedInvoice?['home_delivery'] as bool? ?? _homeDelivery;
    final terms = issuedInvoice == null ? _termsController.text : '';
    final notes = issuedInvoice == null ? _notesController.text : issuedInvoice['notes'] as String? ?? '';
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        presentation['company_name'] as String? ?? 'LoliExpress',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      for (final key in ['company_address', 'company_phone', 'tax_identifier'])
                        if (presentation[key] is String) pw.Text(presentation[key] as String),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        issuedInvoice == null
                            ? 'BROUILLON · ${presentation['pdf_title'] ?? 'FACTURE'}'
                            : presentation['pdf_title'] as String? ?? 'FACTURE',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(invoiceNumber),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 32),
              // Customer Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Facturé à:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(customer['name'] as String),
                      pw.Text(customer['address'] as String),
                      pw.Text(customer['email'] as String),
                      pw.Text(customer['phone'] as String),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Date d\'émission: ${_formatDate(issueDate)}'),
                      pw.Text('Date d\'échéance: ${_formatDate(dueDate)}'),
                      if (issuedInvoice == null)
                        pw.Text('Mode de paiement: $_paymentMethod'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 32),
              // Line Items Table
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Produit',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Qté',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Prix unitaire',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('TVA',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Total',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...items.map((item) {
                    final quantity = item['quantity'] as int;
                    final unitPrice = item['unitPrice'] as double;
                    final taxRate = item['taxRate'] as double;
                    final subtotal = quantity * unitPrice;
                    final tax = subtotal * (taxRate / 100);
                    final total = subtotal + tax;

                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(item['productName'] as String),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(quantity.toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                              '${_formatCurrency(unitPrice)} $currency'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('${taxRate.toStringAsFixed(0)}%'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child:
                              pw.Text('${_formatCurrency(total)} $currency'),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 16),
              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                          'Sous-total: ${_formatCurrency(subtotal)} $currency'),
                      pw.Text(
                          'TVA: ${_formatCurrency(_calculateTax())} $currency'),
                      if (discount > 0)
                        pw.Text('Remise: ${_formatCurrency(discount)} $currency'),
                      if (homeDelivery)
                        pw.Text(
                            'Livraison à domicile: ${_formatCurrency(fee)} $currency'),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Total: ${_formatCurrency(totalAmount)} $currency',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 32),
              // Terms
              if (terms.isNotEmpty) ...[
                pw.Text(
                  'Conditions de paiement:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.Text(terms),
                pw.SizedBox(height: 16),
              ],
              // Notes
              if (notes.isNotEmpty) ...[
                pw.Text(
                  'Notes:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.Text(notes),
              ],
              if (presentation['pdf_footer'] is String) ...[
                pw.SizedBox(height: 16),
                pw.Text(presentation['pdf_footer'] as String),
              ],
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<void> _sendInvoice() async {
    if (_isProcessing || !_validateDeliveryFee()) return;
    if (_selectedCustomer == null) {
      _showErrorSnackBar('Veuillez sélectionner un client');
      return;
    }

    if (_lineItems.isEmpty) {
      _showErrorSnackBar('Veuillez ajouter au moins un article');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final bytes = await _buildInvoicePdf();
      final tempFile = XFile.fromData(
        bytes,
        name: '$_invoiceNumber.pdf',
        mimeType: 'application/pdf',
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [tempFile],
          subject: 'Facture $_invoiceNumber',
          text:
              'Veuillez trouver ci-joint la facture $_invoiceNumber pour un montant de ${_formatCurrency(_calculateTotal())} $_currency.',
        ),
      );

      _showSuccessSnackBar('Facture partagée avec succès');
    } catch (e) {
      _showErrorSnackBar('Erreur lors du partage de la facture');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(2).replaceAll('.', ',').replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successLight,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorLight,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Nouvelle facture',
        showBackButton: true,
        variant: CustomAppBarVariant.standard,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  InvoiceHeaderWidget(
                    invoiceNumber: _invoiceNumber,
                    selectedCustomer: _selectedCustomer,
                    onCustomerTap: _selectCustomer,
                  ),
                  SizedBox(height: 2.h),
                  InvoiceDetailsWidget(
                    issueDate: _issueDate,
                    dueDate: _dueDate,
                    currency: _currency,
                    paymentMethod: _paymentMethod,
                    onIssueDateTap: () => _selectDate(true),
                    onDueDateTap: () => _selectDate(false),
                    onCurrencyTap: _selectCurrency,
                    onPaymentMethodTap: _selectPaymentMethod,
                  ),
                  SizedBox(height: 2.h),
                  LineItemsWidget(
                    lineItems: _lineItems,
                    onAddProduct: _addProduct,
                    onEditItem: _editLineItem,
                    onRemoveItem: _removeLineItem,
                  ),
                  SizedBox(height: 2.h),
                  PaymentTermsWidget(
                    termsController: _termsController,
                    paymentDays: _paymentDays,
                    onPaymentDaysTap: _selectPaymentDays,
                  ),
                  SizedBox(height: 2.h),
                  NotesWidget(notesController: _notesController),
                  SwitchListTile(
                    title: const Text('Livraison à domicile'),
                    value: _homeDelivery,
                    onChanged: _isProcessing
                        ? null
                        : (value) => setState(() => _homeDelivery = value),
                  ),
                  if (_homeDelivery)
                    TextField(
                      controller: _deliveryFeeController,
                      enabled: !_isProcessing,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Frais de livraison facultatifs',
                        suffixText: _currency,
                        errorText: _readDeliveryFee() == null ? 'Montant invalide' : null,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  if (_canIssueInvoice)
                    FilledButton(
                      onPressed: _isProcessing ? null : _issueFromOrder,
                      child: const Text('Émettre depuis une commande'),
                    ),
                  if (_canIssueInvoice)
                    OutlinedButton(
                      onPressed: _isProcessing ? null : _recordInvoicePayment,
                      child: const Text('Encaisser une facture'),
                    ),
                  if (_canCreditDeliveryFee)
                    OutlinedButton(
                      onPressed: _isProcessing ? null : _creditReturnedItem,
                      child: const Text('Créditer un article retourné'),
                    ),
                  if (_canCreditDeliveryFee)
                    OutlinedButton(
                      onPressed: _isProcessing ? null : _creditDeliveryFee,
                      child: const Text('Créditer des frais de livraison'),
                    ),
                  SizedBox(height: 2.h),
                  const QuickCurrencyConverterWidget(),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
          InvoiceSummaryWidget(
            subtotal: _calculateSubtotal(),
            discount: 0.0,
            tax: _calculateTax(),
            total: _calculateTotal(),
            currency: _currency,
            onSaveDraft: _saveDraft,
            onGeneratePDF: _generatePDF,
            onSendInvoice: _sendInvoice,
            isProcessing: _isProcessing,
          ),
        ],
      ),
    );
  }
}
