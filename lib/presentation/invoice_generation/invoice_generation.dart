
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
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

  // Invoice Data
  String _invoiceNumber = '';
  String? _selectedCustomer;
  Map<String, dynamic>? _selectedCustomerData;
  DateTime _issueDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  String _currency = 'FCFA';
  String _paymentMethod = 'Virement bancaire';
  int _paymentDays = 30;
  List<Map<String, dynamic>> _lineItems = [];
  bool _isProcessing = false;

  // Mock Data
  final List<Map<String, dynamic>> _customers = [
    {
      "id": 1,
      "name": "Supermarché Carrefour Dakar",
      "email": "contact@carrefour-dakar.sn",
      "phone": "+221 33 824 50 00",
      "address": "Avenue Cheikh Anta Diop, Dakar",
      "paymentTerms": 30,
    },
    {
      "id": 2,
      "name": "Hôtel Terrou-Bi",
      "email": "achats@terroubihotel.com",
      "phone": "+221 33 839 90 00",
      "address": "Route de la Corniche Ouest, Dakar",
      "paymentTerms": 45,
    },
    {
      "id": 3,
      "name": "Restaurant Le Lagon",
      "email": "direction@lelagon.sn",
      "phone": "+221 33 820 10 20",
      "address": "Almadies, Dakar",
      "paymentTerms": 15,
    },
  ];

  final List<Map<String, dynamic>> _products = [
    {
      "id": 1,
      "name": "Coca-Cola 33cl (Pack de 24)",
      "unitPrice": 12000.0,
      "taxRate": 18.0,
    },
    {
      "id": 2,
      "name": "Sprite 1.5L (Pack de 12)",
      "unitPrice": 18000.0,
      "taxRate": 18.0,
    },
    {
      "id": 3,
      "name": "Fanta Orange 33cl (Pack de 24)",
      "unitPrice": 11500.0,
      "taxRate": 18.0,
    },
    {
      "id": 4,
      "name": "Eau minérale Kirène 1.5L (Pack de 12)",
      "unitPrice": 6000.0,
      "taxRate": 18.0,
    },
    {
      "id": 5,
      "name": "Jus Tropicana Orange 1L (Pack de 12)",
      "unitPrice": 24000.0,
      "taxRate": 18.0,
    },
  ];

  @override
  void initState() {
    super.initState();
    _generateInvoiceNumber();
    _termsController.text =
        'Paiement à effectuer dans les ${_paymentDays} jours suivant la date de facturation. Pénalités de retard applicables selon les conditions générales de vente.';
  }

  @override
  void dispose() {
    _termsController.dispose();
    _notesController.dispose();
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

  double _calculateSubtotal() {
    return _lineItems.fold(0.0, (sum, item) {
      final quantity = item['quantity'] as int;
      final unitPrice = item['unitPrice'] as double;
      return sum + (quantity * unitPrice);
    });
  }

  double _calculateTax() {
    return _lineItems.fold(0.0, (sum, item) {
      final quantity = item['quantity'] as int;
      final unitPrice = item['unitPrice'] as double;
      final taxRate = item['taxRate'] as double;
      final subtotal = quantity * unitPrice;
      return sum + (subtotal * (taxRate / 100));
    });
  }

  double _calculateTotal() {
    return _calculateSubtotal() + _calculateTax();
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
            'Paiement à effectuer dans les ${_paymentDays} jours suivant la date de facturation. Pénalités de retard applicables selon les conditions générales de vente.';
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
    final currencies = ['FCFA', 'EUR'];
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildOptionSelector(
        title: 'Sélectionner la devise',
        options: currencies,
      ),
    );

    if (selected != null) {
      setState(() => _currency = selected);
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
            'Paiement à effectuer dans les ${_paymentDays} jours suivant la date de facturation. Pénalités de retard applicables selon les conditions générales de vente.';
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
                          '${(product['unitPrice'] as double).toStringAsFixed(0)} FCFA',
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
        final theme = Theme.of(context);
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
    final item = _lineItems[index];
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
    if (_selectedCustomer == null) {
      _showErrorSnackBar('Veuillez sélectionner un client');
      return;
    }

    if (_lineItems.isEmpty) {
      _showErrorSnackBar('Veuillez ajouter au moins un article');
      return;
    }

    _showSuccessSnackBar('Brouillon enregistré avec succès');
  }

  Future<void> _generatePDF() async {
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
                          'Loliexpress Distribution',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text('Distribution de boissons importées'),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'FACTURE',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(_invoiceNumber),
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
                        pw.Text(_selectedCustomerData!['name'] as String),
                        pw.Text(_selectedCustomerData!['address'] as String),
                        pw.Text(_selectedCustomerData!['email'] as String),
                        pw.Text(_selectedCustomerData!['phone'] as String),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Date d\'émission: ${_formatDate(_issueDate)}'),
                        pw.Text('Date d\'échéance: ${_formatDate(_dueDate)}'),
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
                    ..._lineItems.map((item) {
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
                                '${_formatCurrency(unitPrice)} $_currency'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('${taxRate.toStringAsFixed(0)}%'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child:
                                pw.Text('${_formatCurrency(total)} $_currency'),
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
                            'Sous-total: ${_formatCurrency(_calculateSubtotal())} $_currency'),
                        pw.Text(
                            'TVA: ${_formatCurrency(_calculateTax())} $_currency'),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'Total: ${_formatCurrency(_calculateTotal())} $_currency',
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
                if (_termsController.text.isNotEmpty) ...[
                  pw.Text(
                    'Conditions de paiement:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(_termsController.text),
                  pw.SizedBox(height: 16),
                ],
                // Notes
                if (_notesController.text.isNotEmpty) ...[
                  pw.Text(
                    'Notes:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(_notesController.text),
                ],
              ],
            );
          },
        ),
      );

      final bytes = await pdf.save();
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

  Future<void> _sendInvoice() async {
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
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text('Invoice PDF Content'),
            );
          },
        ),
      );

      final bytes = await pdf.save();
      final tempFile = XFile.fromData(
        bytes,
        name: '$_invoiceNumber.pdf',
        mimeType: 'application/pdf',
      );

      await Share.shareXFiles(
        [tempFile],
        subject: 'Facture $_invoiceNumber',
        text:
            'Veuillez trouver ci-joint la facture $_invoiceNumber pour un montant de ${_formatCurrency(_calculateTotal())} $_currency.',
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
    final theme = Theme.of(context);

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
