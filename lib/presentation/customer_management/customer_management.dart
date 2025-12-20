import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
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
  final List<Map<String, dynamic>> _allCustomers = [
    {
      "id": 1,
      "companyName": "Supermarché Chez Fatou",
      "contactPerson": "Fatou Diop",
      "phone": "+221 77 123 45 67",
      "email": "fatou.diop@chezfatou.sn",
      "outstandingBalance": "1 250 000 FCFA",
      "lastOrderDate": "15/11/2024",
      "paymentStatus": "Current",
      "location": "Dakar",
      "paymentTerms": "30 jours",
      "customerTier": "Premium",
      "accountStatus": "Actif",
      "accountNumber": "CL-001",
    },
    {
      "id": 2,
      "companyName": "Boutique Moderne",
      "contactPerson": "Mamadou Sall",
      "phone": "+221 76 234 56 78",
      "email": "m.sall@boutiquemoderne.sn",
      "outstandingBalance": "850 000 FCFA",
      "lastOrderDate": "20/11/2024",
      "paymentStatus": "Approaching",
      "location": "Thiès",
      "paymentTerms": "60 jours",
      "customerTier": "Standard",
      "accountStatus": "Actif",
      "accountNumber": "CL-002",
    },
    {
      "id": 3,
      "companyName": "Alimentation Générale",
      "contactPerson": "Aïssatou Ndiaye",
      "phone": "+221 77 345 67 89",
      "email": "a.ndiaye@aligen.sn",
      "outstandingBalance": "2 100 000 FCFA",
      "lastOrderDate": "05/10/2024",
      "paymentStatus": "Overdue",
      "location": "Saint-Louis",
      "paymentTerms": "30 jours",
      "customerTier": "Premium",
      "accountStatus": "Actif",
      "accountNumber": "CL-003",
    },
    {
      "id": 4,
      "companyName": "Épicerie du Coin",
      "contactPerson": "Ousmane Ba",
      "phone": "+221 76 456 78 90",
      "email": "o.ba@epicerieducoin.sn",
      "outstandingBalance": "450 000 FCFA",
      "lastOrderDate": "22/11/2024",
      "paymentStatus": "Current",
      "location": "Kaolack",
      "paymentTerms": "Comptant",
      "customerTier": "Standard",
      "accountStatus": "Actif",
      "accountNumber": "CL-004",
    },
    {
      "id": 5,
      "companyName": "Distribution Sénégal",
      "contactPerson": "Khady Sarr",
      "phone": "+221 77 567 89 01",
      "email": "k.sarr@distsenegal.sn",
      "outstandingBalance": "3 500 000 FCFA",
      "lastOrderDate": "18/11/2024",
      "paymentStatus": "Current",
      "location": "Dakar",
      "paymentTerms": "90 jours",
      "customerTier": "Premium",
      "accountStatus": "Actif",
      "accountNumber": "CL-005",
    },
    {
      "id": 6,
      "companyName": "Mini Market Express",
      "contactPerson": "Ibrahima Diallo",
      "phone": "+221 76 678 90 12",
      "email": "i.diallo@minimarket.sn",
      "outstandingBalance": "0 FCFA",
      "lastOrderDate": "10/09/2024",
      "paymentStatus": "Current",
      "location": "Thiès",
      "paymentTerms": "Comptant",
      "customerTier": "Nouveau",
      "accountStatus": "Inactif",
      "accountNumber": "CL-006",
    },
  ];

  List<Map<String, dynamic>> _filteredCustomers = [];
  Set<int> _selectedCustomers = {};
  bool _isMultiSelectMode = false;
  Map<String, dynamic> _currentFilters = {
    'location': 'Tous',
    'paymentTerms': 'Tous',
    'customerTier': 'Tous',
    'accountStatus': 'Tous',
  };

  @override
  void initState() {
    super.initState();
    _filteredCustomers = List.from(_allCustomers);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _applyFilters();
    });
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    _filteredCustomers = _allCustomers.where((customer) {
      final matchesSearch = query.isEmpty ||
          (customer['companyName'] as String).toLowerCase().contains(query) ||
          (customer['contactPerson'] as String).toLowerCase().contains(query) ||
          (customer['phone'] as String).contains(query) ||
          (customer['accountNumber'] as String).toLowerCase().contains(query);

      final matchesLocation = _currentFilters['location'] == 'Tous' ||
          customer['location'] == _currentFilters['location'];

      final matchesPaymentTerms = _currentFilters['paymentTerms'] == 'Tous' ||
          customer['paymentTerms'] == _currentFilters['paymentTerms'];

      final matchesTier = _currentFilters['customerTier'] == 'Tous' ||
          customer['customerTier'] == _currentFilters['customerTier'];

      final matchesStatus = _currentFilters['accountStatus'] == 'Tous' ||
          customer['accountStatus'] == _currentFilters['accountStatus'];

      return matchesSearch &&
          matchesLocation &&
          matchesPaymentTerms &&
          matchesTier &&
          matchesStatus;
    }).toList();
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _filteredCustomers = List.from(_allCustomers);
    });
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
            _applyFilters();
          });
        },
      ),
    );
  }

  void _toggleMultiSelect(int customerId) {
    setState(() {
      if (_selectedCustomers.contains(customerId)) {
        _selectedCustomers.remove(customerId);
        if (_selectedCustomers.isEmpty) {
          _isMultiSelectMode = false;
        }
      } else {
        _selectedCustomers.add(customerId);
        _isMultiSelectMode = true;
      }
    });
  }

  void _exportContacts() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export de ${0} contacts en cours...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _sendStatements() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Envoi des relevés à ${0} clients...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _updateTerms() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mise à jour des conditions pour ${0} clients...'),
        duration: Duration(seconds: 2),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Formulaire de nouveau client'),
        duration: Duration(seconds: 2),
      ),
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
            child: _filteredCustomers.isEmpty
                ? EmptyStateWidget(
                    onAddCustomer: _showNewCustomerForm,
                    onImportContacts: _importContacts,
                  )
                : RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: ListView.builder(
                      itemCount: _filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final customer = _filteredCustomers[index];
                        final isSelected =
                            _selectedCustomers.contains(customer['id'] as int);

                        return GestureDetector(
                          onLongPress: () {
                            _toggleMultiSelect(customer['id'] as int);
                          },
                          child: Stack(
                            children: [
                              CustomerCardWidget(
                                customer: customer,
                                onTap: () {
                                  if (_isMultiSelectMode) {
                                    _toggleMultiSelect(customer['id'] as int);
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
                                              color:
                                                  theme.colorScheme.onPrimary,
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
                  ),
          ),
        ],
      ),
      floatingActionButton: !_isMultiSelectMode
          ? FloatingActionButton(
              onPressed: _showNewCustomerForm,
              tooltip: 'Nouveau client',
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
}
