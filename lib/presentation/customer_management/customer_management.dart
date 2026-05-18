import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../services/customer_service.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/customer_card_widget.dart';
import './widgets/empty_state_widget.dart';
import './widgets/filter_bottom_sheet_widget.dart';

class CustomerManagement extends StatefulWidget {
  const CustomerManagement({super.key});

  @override
  State<CustomerManagement> createState() => _CustomerManagementState();
}

class _CustomerManagementState extends State<CustomerManagement> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Set<int> _selectedCustomers = {};
  bool _isMultiSelectMode = false;
  Timer? _debounce;

  Map<String, dynamic> _currentFilters = {
    'location': 'Tous',
    'paymentTerms': 'Tous',
    'customerTier': 'Tous',
    'accountStatus': 'Tous',
  };

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadCustomers();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _loadCustomers();
    });
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final query = _searchController.text.trim();
      final results = await CustomerService.instance.getCustomers(
        search: query.isNotEmpty ? query : null,
      );
      if (!mounted) return;
      setState(() {
        _customers = results.map(_mapCustomerToUi).toList();
        _applyLocalFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _mapCustomerToUi(Map<String, dynamic> raw) {
    final balance = (raw['current_balance'] as num?)?.toDouble() ?? 0;
    final creditLimit = (raw['credit_limit'] as num?)?.toDouble() ?? 0;
    final isActive = raw['is_active'] as bool? ?? true;

    String paymentStatus = 'Current';
    if (balance > 0 && creditLimit > 0) {
      final ratio = balance / creditLimit;
      if (ratio > 0.9) {
        paymentStatus = 'Overdue';
      } else if (ratio > 0.6) {
        paymentStatus = 'Approaching';
      }
    }

    final formattedBalance = '${_formatNumber(balance.toInt())} CDF';

    return {
      'id': raw['id'],
      'companyName': raw['company_name'] ?? '',
      'contactPerson': raw['contact_person'] ?? raw['contact_name'] ?? '',
      'phone': raw['phone'] ?? '',
      'email': raw['email'] ?? '',
      'outstandingBalance': formattedBalance,
      'lastOrderDate': _formatDate(raw['updated_at']),
      'paymentStatus': paymentStatus,
      'location': raw['city'] ?? '',
      'paymentTerms': '30 jours',
      'customerTier': creditLimit >= 5000000
          ? 'Premium'
          : creditLimit >= 1000000
              ? 'Standard'
              : 'Nouveau',
      'accountStatus': isActive ? 'Actif' : 'Inactif',
      'accountNumber': 'CL-${(raw['id'] as String).substring(0, 4).toUpperCase()}',
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

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr.toString());
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return '-';
    }
  }

  List<Map<String, dynamic>> _filteredCustomers = [];

  void _applyLocalFilters() {
    _filteredCustomers = _customers.where((customer) {
      final matchesLocation = _currentFilters['location'] == 'Tous' ||
          customer['location'] == _currentFilters['location'];

      final matchesPaymentTerms = _currentFilters['paymentTerms'] == 'Tous' ||
          customer['paymentTerms'] == _currentFilters['paymentTerms'];

      final matchesTier = _currentFilters['customerTier'] == 'Tous' ||
          customer['customerTier'] == _currentFilters['customerTier'];

      final matchesStatus = _currentFilters['accountStatus'] == 'Tous' ||
          customer['accountStatus'] == _currentFilters['accountStatus'];

      return matchesLocation &&
          matchesPaymentTerms &&
          matchesTier &&
          matchesStatus;
    }).toList();
  }

  Future<void> _onRefresh() async {
    await _loadCustomers();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheetWidget(
        currentFilters: _currentFilters,
        onApplyFilters: (filters) {
          setState(() {
            _currentFilters = filters;
            _applyLocalFilters();
          });
        },
      ),
    );
  }

  void _toggleMultiSelect(dynamic customerId) {
    setState(() {
      final id = customerId.hashCode;
      if (_selectedCustomers.contains(id)) {
        _selectedCustomers.remove(id);
        if (_selectedCustomers.isEmpty) {
          _isMultiSelectMode = false;
        }
      } else {
        _selectedCustomers.add(id);
        _isMultiSelectMode = true;
      }
    });
  }

  void _exportContacts() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export de ${_selectedCustomers.length} contacts en cours...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _sendStatements() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Envoi des relevés à ${_selectedCustomers.length} clients...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _updateTerms() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mise à jour des conditions pour ${_selectedCustomers.length} clients...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de passer l\'appel'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir l\'application email'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _navigateToCustomerDetail(Map<String, dynamic> customer) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ouverture du profil de ${customer['companyName']}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showNewCustomerForm() {
    final companyController = TextEditingController();
    final contactController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final cityController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        bool isCreating = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Ajouter un client'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: companyController,
                        decoration: const InputDecoration(
                          labelText: 'Nom de l\'entreprise *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Champ requis' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: contactController,
                        decoration: const InputDecoration(
                          labelText: 'Personne de contact *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Champ requis' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Téléphone *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Champ requis' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Champ requis' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: cityController,
                        decoration: const InputDecoration(
                          labelText: 'Ville',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isCreating ? null : () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: isCreating
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isCreating = true);
                          try {
                            await CustomerService.instance.createCustomer({
                              'company_name': companyController.text.trim(),
                              'contact_person': contactController.text.trim(),
                              'phone': phoneController.text.trim(),
                              'email': emailController.text.trim(),
                              'city': cityController.text.trim(),
                            });
                            if (context.mounted) Navigator.pop(context);
                            _loadCustomers();
                            if (mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text('Client créé avec succès'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isCreating = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    e.toString().replaceFirst('Exception: ', ''),
                                  ),
                                  backgroundColor:
                                      Theme.of(context).colorScheme.error,
                                ),
                              );
                            }
                          }
                        },
                  child: isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Créer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _importContacts() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Import de contacts'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: _isMultiSelectMode
            ? Text('${_selectedCustomers.length} sélectionné(s)')
            : const Text('Gestion Clients'),
        leading: _isMultiSelectMode
            ? IconButton(
                icon: CustomIconWidget(
                  iconName: 'close',
                  size: 24,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: () {
                  setState(() {
                    _isMultiSelectMode = false;
                    _selectedCustomers.clear();
                  });
                },
              )
            : null,
        actions: _isMultiSelectMode
            ? [
                IconButton(
                  icon: CustomIconWidget(
                    iconName: 'file_download',
                    size: 24,
                    color: theme.colorScheme.onSurface,
                  ),
                  onPressed: _exportContacts,
                  tooltip: 'Exporter',
                ),
                IconButton(
                  icon: CustomIconWidget(
                    iconName: 'email',
                    size: 24,
                    color: theme.colorScheme.onSurface,
                  ),
                  onPressed: _sendStatements,
                  tooltip: 'Envoyer relevés',
                ),
                IconButton(
                  icon: CustomIconWidget(
                    iconName: 'edit',
                    size: 24,
                    color: theme.colorScheme.onSurface,
                  ),
                  onPressed: _updateTerms,
                  tooltip: 'Modifier conditions',
                ),
              ]
            : [
                IconButton(
                  icon: CustomIconWidget(
                    iconName: 'filter_list',
                    size: 24,
                    color: theme.colorScheme.onSurface,
                  ),
                  onPressed: _showFilterBottomSheet,
                  tooltip: 'Filtrer',
                ),
              ],
      ),
      body: Column(
        children: [
          if (!_isMultiSelectMode)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher un client...',
                  prefixIcon: CustomIconWidget(
                    iconName: 'search',
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: CustomIconWidget(
                            iconName: 'clear',
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          Expanded(
            child: _buildBody(theme),
          ),
        ],
      ),
      floatingActionButton: !_isMultiSelectMode
          ? FloatingActionButton(
              onPressed: _showNewCustomerForm,
              tooltip: 'Ajouter un client',
              child: CustomIconWidget(
                iconName: 'add',
                size: 24,
                color: theme.colorScheme.onPrimary,
              ),
            )
          : null,
      bottomNavigationBar: CustomBottomBar(
        currentIndex: 3,
        onTap: (index) {
          final routes = [
            '/main-dashboard',
            '/inventory-management',
            '/sales-order-processing',
            '/customer-management',
            '/financial-dashboard',
          ];
          if (index != 3) {
            Navigator.pushReplacementNamed(context, routes[index]);
          }
        },
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
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
                _errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadCustomers,
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
      );
    }

    if (_filteredCustomers.isEmpty) {
      return EmptyStateWidget(
        onAddCustomer: _showNewCustomerForm,
        onImportContacts: _importContacts,
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        itemCount: _filteredCustomers.length,
        itemBuilder: (context, index) {
          final customer = _filteredCustomers[index];
          final isSelected =
              _selectedCustomers.contains(customer['id'].hashCode);

          return GestureDetector(
            onLongPress: () {
              _toggleMultiSelect(customer['id']);
            },
            child: Stack(
              children: [
                CustomerCardWidget(
                  customer: customer,
                  onTap: () {
                    if (_isMultiSelectMode) {
                      _toggleMultiSelect(customer['id']);
                    } else {
                      _navigateToCustomerDetail(customer);
                    }
                  },
                  onCall: () =>
                      _makePhoneCall(customer['phone'] as String),
                  onEmail: () =>
                      _sendEmail(customer['email'] as String),
                  onNewOrder: () {
                    Navigator.pushNamed(
                        context, '/sales-order-processing');
                  },
                  onPaymentReceipt: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Reçu de paiement pour ${customer['companyName']}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  onCreditLimit: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Ajustement limite de crédit pour ${customer['companyName']}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  onNotes: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Notes pour ${customer['companyName']}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                if (_isMultiSelectMode)
                  Positioned(
                    top: 16,
                    right: 24,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Center(
                              child: CustomIconWidget(
                                iconName: 'check',
                                size: 16,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : null,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
