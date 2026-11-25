import 'package:flutter/material.dart';
import '../../widgets/treasury_account_picker.dart';
import '../../widgets/custom_bottom_bar.dart';
import 'package:sizer/sizer.dart';
import '../../services/expense_service.dart';
import '../../services/role_service.dart';
import '../../services/currency_service.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _expenseService = ExpenseService.instance;
  final _roleService = RoleService.instance;

  List<Map<String, dynamic>> _myExpenses = [];
  List<Map<String, dynamic>> _pendingApprovals = [];
  List<Map<String, dynamic>> _pendingPayments = [];
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _getTabCount(), vsync: this);
    _loadData();
  }

  int _getTabCount() {
    if (_roleService.canApproveExpenses && _roleService.canPayExpenses) {
      return 4;
    }
    if (_roleService.canApproveExpenses || _roleService.canPayExpenses) {
      return 3;
    }
    return 2;
  }

  List<Tab> _getTabs() {
    final tabs = <Tab>[const Tab(text: 'Mes Demandes')];
    if (_roleService.canApproveExpenses) {
      tabs.add(const Tab(text: 'En Attente'));
    }
    if (_roleService.canPayExpenses) {
      tabs.add(const Tab(text: 'À Payer'));
    }
    tabs.add(const Tab(text: 'Historique'));
    return tabs;
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final userId = _expenseService.toString().isNotEmpty ? null : null;
      _myExpenses = await _expenseService.getExpenses(userId: userId);
      if (_roleService.canApproveExpenses) {
        _pendingApprovals = await _expenseService.getPendingApprovals();
      }
      if (_roleService.canPayExpenses) {
        _pendingPayments = await _expenseService.getPendingPayments();
      }
      _history = await _expenseService.getExpenses(status: 'paid');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Impossible de terminer l’opération. Réessayez.'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dépenses'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: _getTabs(),
          isScrollable: true,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: _getTabViews(),
            ),
      bottomNavigationBar: const CustomBottomBar(currentIndex: -1),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateExpenseDialog,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle dépense'),
      ),
    );
  }

  List<Widget> _getTabViews() {
    final views = <Widget>[_buildExpenseList(_myExpenses, 'my')];
    if (_roleService.canApproveExpenses) {
      views.add(_buildExpenseList(_pendingApprovals, 'approval'));
    }
    if (_roleService.canPayExpenses) {
      views.add(_buildExpenseList(_pendingPayments, 'payment'));
    }
    views.add(_buildExpenseList(_history, 'history'));
    return views;
  }

  Widget _buildExpenseList(List<Map<String, dynamic>> expenses, String type) {
    if (expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 48.sp, color: Colors.grey[400]),
            SizedBox(height: 2.h),
            Text(
              'Aucune dépense',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(2.w, 2.w, 2.w,
            88 + MediaQuery.paddingOf(context).bottom),
        itemCount: expenses.length,
        itemBuilder: (context, index) =>
            _buildExpenseCard(expenses[index], type),
      ),
    );
  }

  Widget _buildExpenseCard(Map<String, dynamic> expense, String type) {
    final status = expense['status'] as String? ?? 'draft';
    final amount = (expense['amount'] as num?)?.toDouble() ?? 0;
    final currency = expense['currency'] as String? ?? 'CDF';
    final description = expense['description'] as String? ?? '';
    final category = expense['category'] as String? ?? '';
    final createdAt = expense['created_at'] as String? ?? '';
    final requester = expense['user_profiles'] as Map<String, dynamic>?;
    final requesterName = requester?['full_name'] as String? ?? 'Inconnu';

    return Card(
      margin: EdgeInsets.only(bottom: 1.5.h),
      elevation: 2,
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
                    description,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Icon(Icons.category, size: 12.sp, color: Colors.grey[600]),
                SizedBox(width: 1.w),
                Text(category,
                    style: TextStyle(fontSize: 10.sp, color: Colors.grey[600])),
              ],
            ),
            SizedBox(height: 0.5.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  CurrencyService.instance.formatAmount(amount, currency),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                Text(
                  requesterName,
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 0.5.h),
            Text(
              _formatDate(createdAt),
              style: TextStyle(fontSize: 9.sp, color: Colors.grey[500]),
            ),
            if (type == 'approval') ...[
              SizedBox(height: 1.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showRejectDialog(expense['id']),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Rejeter',
                        style: TextStyle(color: Colors.red)),
                  ),
                  SizedBox(width: 2.w),
                  ElevatedButton.icon(
                    onPressed: () => _approveExpense(expense['id']),
                    icon: const Icon(Icons.check),
                    label: const Text('Approuver'),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ],
              ),
            ],
            if (type == 'payment') ...[
              SizedBox(height: 1.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _markAsPaid(expense['id'] as String, expense['currency'] as String),
                    icon: const Icon(Icons.payment),
                    label: const Text('Marquer Payé'),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'draft':
        color = Colors.grey;
        label = 'Brouillon';
        break;
      case 'pending_approval':
        color = Colors.orange;
        label = 'En attente';
        break;
      case 'pending_payment':
        color = Colors.blue;
        label = 'Approuvé';
        break;
      case 'approved':
        color = Colors.blue;
        label = 'Approuvé';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Rejeté';
        break;
      case 'paid':
        color = Colors.green;
        label = 'Payé';
        break;
      case 'executed':
        color = Colors.green;
        label = 'Exécuté';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    if (isoDate.isEmpty) return '';
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return isoDate;
    }
  }

  Future<void> _approveExpense(String id) async {
    try {
      await _expenseService.approveExpense(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Dépense approuvée'),
              backgroundColor: Colors.green),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Impossible de terminer l’opération. Réessayez.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _markAsPaid(String id, String currency) async {
    final account = await pickTreasuryAccount(context, currency, incoming: false);
    if (!mounted || account == null) return;
    try {
      await _expenseService.markAsPaid(id, accountKind: account.kind, accountId: account.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Dépense marquée comme payée'),
              backgroundColor: Colors.green),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Impossible de terminer l’opération. Réessayez.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showRejectDialog(String id) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter la dépense'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Raison du rejet',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await _expenseService.rejectExpense(id,
                    reason: reasonController.text);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Dépense rejetée'),
                        backgroundColor: Colors.orange),
                  );
                }
                _loadData();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: const Text('Impossible de terminer l’opération. Réessayez.'),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }

  void _showCreateExpenseDialog() {
    final categoryController = TextEditingController();
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    final beneficiaryController = TextEditingController();
    String currency = 'CDF';
    String urgency = 'normal';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 4.w,
            right: 4.w,
            top: 3.h,
            bottom: MediaQuery.of(context).viewInsets.bottom + 2.h,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Nouvelle Demande de Dépense',
                  style:
                      TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2.h),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Catégorie',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                ),
                SizedBox(height: 1.5.h),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 1.5.h),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Montant',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: currency,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'CDF', child: Text('CDF')),
                          DropdownMenuItem(value: 'USD', child: Text('USD')),
                        ],
                        onChanged: (v) =>
                            setModalState(() => currency = v ?? 'CDF'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.5.h),
                TextField(
                  controller: beneficiaryController,
                  decoration: const InputDecoration(
                    labelText: 'Bénéficiaire (optionnel)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                SizedBox(height: 1.5.h),
                DropdownButtonFormField<String>(
                  initialValue: urgency,
                  decoration: const InputDecoration(
                    labelText: 'Urgence',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.priority_high),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Basse')),
                    DropdownMenuItem(value: 'normal', child: Text('Normale')),
                    DropdownMenuItem(value: 'high', child: Text('Haute')),
                    DropdownMenuItem(value: 'urgent', child: Text('Urgente')),
                  ],
                  onChanged: (v) =>
                      setModalState(() => urgency = v ?? 'normal'),
                ),
                SizedBox(height: 2.h),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (categoryController.text.isEmpty ||
                        descriptionController.text.isEmpty ||
                        amountController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Veuillez remplir tous les champs obligatoires'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await _expenseService.createExpenseRequest(
                        category: categoryController.text,
                        description: descriptionController.text,
                        amount: double.parse(amountController.text),
                        currency: currency,
                        beneficiary: beneficiaryController.text.isEmpty
                            ? null
                            : beneficiaryController.text,
                        urgency: urgency,
                      );
                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Demande créée avec succès'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                      _loadData();
                    } catch (e) {
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                              content: const Text('Impossible de terminer l’opération. Réessayez.'),
                              backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Soumettre la Demande'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
