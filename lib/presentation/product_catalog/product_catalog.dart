import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/empty_state_widget.dart';
import './widgets/filter_bottom_sheet_widget.dart';
import './widgets/product_card_widget.dart';
import './widgets/search_bar_widget.dart';

class ProductCatalog extends StatefulWidget {
  const ProductCatalog({super.key});

  @override
  State<ProductCatalog> createState() => _ProductCatalogState();
}

class _ProductCatalogState extends State<ProductCatalog> {
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _selectedProducts = {};
  bool _isMultiSelectMode = false;
  bool _isLoading = false;
  String _searchQuery = '';

  Map<String, dynamic> _currentFilters = {
    'category': 'Toutes',
    'supplier': 'Tous',
    'stockStatus': 'Tous',
    'sortBy': 'FIFO (Premier entré, premier sorti)',
    'showExpiringSoon': false,
  };

  final List<Map<String, dynamic>> _allProducts = [
    {
      'id': 1,
      'name': 'Coca-Cola 1.5L',
      'sku': 'CC-1500-001',
      'currentStock': 150,
      'minStock': 50,
      'criticalStock': 20,
      'price': '750',
      'category': 'Boissons gazeuses',
      'supplier': 'Coca-Cola',
      'image':
          'https://images.unsplash.com/photo-1592121667233-aa734bbcafb5',
      'semanticLabel':
          'Bouteille de Coca-Cola de 1,5 litre avec étiquette rouge et blanche sur fond blanc',
      'lowStockAlertEnabled': true,
      'expiryDate': DateTime.now().add(const Duration(days: 180)),
    },
    {
      'id': 2,
      'name': 'Pepsi 2L',
      'sku': 'PP-2000-002',
      'currentStock': 45,
      'minStock': 50,
      'criticalStock': 20,
      'price': '800',
      'category': 'Boissons gazeuses',
      'supplier': 'PepsiCo',
      'image':
          'https://images.unsplash.com/photo-1616014725808-b51d4f365b8f',
      'semanticLabel':
          'Bouteille de Pepsi de 2 litres avec étiquette bleue et rouge sur fond blanc',
      'lowStockAlertEnabled': true,
      'expiryDate': DateTime.now().add(const Duration(days: 150)),
    },
    {
      'id': 3,
      'name': 'Jus d\'Orange Tropicana 1L',
      'sku': 'TR-1000-003',
      'currentStock': 15,
      'minStock': 30,
      'criticalStock': 10,
      'price': '1200',
      'category': 'Jus',
      'supplier': 'PepsiCo',
      'image':
          'https://images.unsplash.com/photo-1600271886742-f049cd451bba?w=400',
      'semanticLabel':
          'Carton de jus d\'orange Tropicana de 1 litre avec image d\'oranges fraîches',
      'lowStockAlertEnabled': true,
      'expiryDate': DateTime.now().add(const Duration(days: 45)),
    },
    {
      'id': 4,
      'name': 'Eau Minérale Evian 1.5L',
      'sku': 'EV-1500-004',
      'currentStock': 200,
      'minStock': 100,
      'criticalStock': 50,
      'price': '500',
      'category': 'Eau',
      'supplier': 'Danone',
      'image':
          'https://images.unsplash.com/photo-1548839140-29a749e1cf4d?w=400',
      'semanticLabel':
          'Bouteille d\'eau minérale Evian de 1,5 litre transparente avec étiquette rose',
      'lowStockAlertEnabled': false,
      'expiryDate': DateTime.now().add(const Duration(days: 365)),
    },
    {
      'id': 5,
      'name': 'Red Bull Energy Drink 250ml',
      'sku': 'RB-250-005',
      'currentStock': 80,
      'minStock': 60,
      'criticalStock': 30,
      'price': '1500',
      'category': 'Boissons énergétiques',
      'supplier': 'Red Bull',
      'image':
          'https://images.unsplash.com/photo-1620785028101-2e388da4aaa8',
      'semanticLabel':
          'Canette de Red Bull de 250ml bleue et argentée avec logo de taureau',
      'lowStockAlertEnabled': true,
      'expiryDate': DateTime.now().add(const Duration(days: 270)),
    },
    {
      'id': 6,
      'name': 'Heineken Bière 330ml',
      'sku': 'HK-330-006',
      'currentStock': 120,
      'minStock': 80,
      'criticalStock': 40,
      'price': '900',
      'category': 'Bières',
      'supplier': 'Heineken',
      'image':
          'https://images.unsplash.com/photo-1618885472179-5e474019f2a9',
      'semanticLabel':
          'Bouteille de bière Heineken de 330ml verte avec étiquette rouge et étoile',
      'lowStockAlertEnabled': false,
      'expiryDate': DateTime.now().add(const Duration(days: 210)),
    },
    {
      'id': 7,
      'name': 'Sprite 1L',
      'sku': 'SP-1000-007',
      'currentStock': 18,
      'minStock': 40,
      'criticalStock': 15,
      'price': '650',
      'category': 'Boissons gazeuses',
      'supplier': 'Coca-Cola',
      'image':
          'https://images.unsplash.com/photo-1699543908097-3017da4d6859',
      'semanticLabel':
          'Bouteille de Sprite de 1 litre transparente avec étiquette verte et jaune',
      'lowStockAlertEnabled': true,
      'expiryDate': DateTime.now().add(const Duration(days: 25)),
    },
    {
      'id': 8,
      'name': 'Fanta Orange 2L',
      'sku': 'FT-2000-008',
      'currentStock': 95,
      'minStock': 50,
      'criticalStock': 25,
      'price': '800',
      'category': 'Boissons gazeuses',
      'supplier': 'Coca-Cola',
      'image':
          'https://images.unsplash.com/photo-1670969658708-9542cd32a008',
      'semanticLabel':
          'Bouteille de Fanta Orange de 2 litres avec étiquette orange vif',
      'lowStockAlertEnabled': false,
      'expiryDate': DateTime.now().add(const Duration(days: 160)),
    },
  ];

  List<Map<String, dynamic>> get _filteredProducts {
    List<Map<String, dynamic>> filtered = List.from(_allProducts);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) {
        final name = (product['name'] as String).toLowerCase();
        final sku = (product['sku'] as String).toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || sku.contains(query);
      }).toList();
    }

    // Apply category filter
    if (_currentFilters['category'] != 'Toutes') {
      filtered = filtered.where((product) {
        return product['category'] == _currentFilters['category'];
      }).toList();
    }

    // Apply supplier filter
    if (_currentFilters['supplier'] != 'Tous') {
      filtered = filtered.where((product) {
        return product['supplier'] == _currentFilters['supplier'];
      }).toList();
    }

    // Apply stock status filter
    if (_currentFilters['stockStatus'] != 'Tous') {
      filtered = filtered.where((product) {
        final stock = product['currentStock'] as int;
        final minStock = product['minStock'] as int;
        final criticalStock = product['criticalStock'] as int;

        switch (_currentFilters['stockStatus']) {
          case 'Suffisant':
            return stock > minStock;
          case 'Faible':
            return stock <= minStock && stock > criticalStock;
          case 'Critique':
            return stock <= criticalStock;
          default:
            return true;
        }
      }).toList();
    }

    // Apply expiring soon filter
    if (_currentFilters['showExpiringSoon'] == true) {
      final now = DateTime.now();
      filtered = filtered.where((product) {
        final expiryDate = product['expiryDate'] as DateTime;
        return expiryDate.difference(now).inDays <= 30;
      }).toList();
    }

    // Apply sorting
    final sortBy = _currentFilters['sortBy'] as String;
    if (sortBy.contains('FIFO')) {
      filtered.sort((a, b) {
        final dateA = a['expiryDate'] as DateTime;
        final dateB = b['expiryDate'] as DateTime;
        return dateA.compareTo(dateB);
      });
    } else if (sortBy.contains('FEFO')) {
      filtered.sort((a, b) {
        final dateA = a['expiryDate'] as DateTime;
        final dateB = b['expiryDate'] as DateTime;
        return dateA.compareTo(dateB);
      });
    } else if (sortBy.contains('Nom (A-Z)')) {
      filtered
          .sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    } else if (sortBy.contains('Nom (Z-A)')) {
      filtered
          .sort((a, b) => (b['name'] as String).compareTo(a['name'] as String));
    } else if (sortBy.contains('Prix (Croissant)')) {
      filtered.sort((a, b) => int.parse(a['price'] as String)
          .compareTo(int.parse(b['price'] as String)));
    } else if (sortBy.contains('Prix (Décroissant)')) {
      filtered.sort((a, b) => int.parse(b['price'] as String)
          .compareTo(int.parse(a['price'] as String)));
    } else if (sortBy.contains('Stock (Croissant)')) {
      filtered.sort((a, b) =>
          (a['currentStock'] as int).compareTo(b['currentStock'] as int));
    } else if (sortBy.contains('Stock (Décroissant)')) {
      filtered.sort((a, b) =>
          (b['currentStock'] as int).compareTo(a['currentStock'] as int));
    }

    return filtered;
  }

  Future<void> _refreshProducts() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: 80.h,
        child: FilterBottomSheetWidget(
          currentFilters: _currentFilters,
          onApplyFilters: (filters) {
            setState(() => _currentFilters = filters);
          },
        ),
      ),
    );
  }

  Future<void> _scanBarcode() async {
    try {
      HapticFeedback.mediumImpact();
      Navigator.pushNamed(context, '/barcode-scanner');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du scan: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _toggleMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedProducts.clear();
      }
    });
  }

  void _toggleProductSelection(int productId) {
    setState(() {
      if (_selectedProducts.contains(productId)) {
        _selectedProducts.remove(productId);
      } else {
        _selectedProducts.add(productId);
      }
    });
  }

  void _handleBatchOperation(String operation) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '$operation appliqué à ${_selectedProducts.length} produit(s)'),
      ),
    );
    setState(() {
      _isMultiSelectMode = false;
      _selectedProducts.clear();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filteredProducts = _filteredProducts;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: CustomAppBar(
          title: _isMultiSelectMode
              ? '${_selectedProducts.length} sélectionné(s)'
              : 'Catalogue Produits',
          variant: CustomAppBarVariant.standard,
          showBackButton: _isMultiSelectMode,
          onBackPressed: _toggleMultiSelectMode,
          actions: _isMultiSelectMode
              ? [
                  IconButton(
                    icon: CustomIconWidget(
                      iconName: 'edit',
                      color: colorScheme.onSurface,
                      size: 24,
                    ),
                    onPressed: () => _handleBatchOperation('Modification'),
                    tooltip: 'Modifier',
                  ),
                  IconButton(
                    icon: CustomIconWidget(
                      iconName: 'file_download',
                      color: colorScheme.onSurface,
                      size: 24,
                    ),
                    onPressed: () => _handleBatchOperation('Export'),
                    tooltip: 'Exporter',
                  ),
                  IconButton(
                    icon: CustomIconWidget(
                      iconName: 'category',
                      color: colorScheme.onSurface,
                      size: 24,
                    ),
                    onPressed: () =>
                        _handleBatchOperation('Attribution de catégorie'),
                    tooltip: 'Catégorie',
                  ),
                ]
              : null,
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          SearchBarWidget(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            onScanBarcode: _scanBarcode,
            onFilter: _showFilterBottomSheet,
          ),
          // Product List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  )
                : filteredProducts.isEmpty
                    ? EmptyStateWidget(
                        message: _searchQuery.isNotEmpty ||
                                _currentFilters['category'] != 'Toutes'
                            ? 'Aucun produit trouvé'
                            : 'Aucun produit dans le catalogue',
                        actionText: _searchQuery.isNotEmpty ||
                                _currentFilters['category'] != 'Toutes'
                            ? 'Ajuster les filtres'
                            : 'Ajouter un produit',
                        showFilterAdjustment: _searchQuery.isNotEmpty ||
                            _currentFilters['category'] != 'Toutes',
                        onActionPressed: _searchQuery.isNotEmpty ||
                                _currentFilters['category'] != 'Toutes'
                            ? _showFilterBottomSheet
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Fonctionnalité d\'ajout de produit à venir'),
                                  ),
                                );
                              },
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshProducts,
                        color: colorScheme.primary,
                        child: ListView.builder(
                          padding: EdgeInsets.only(bottom: 2.h),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            final productId = product['id'] as int;
                            final isSelected =
                                _selectedProducts.contains(productId);

                            return ProductCardWidget(
                              product: product,
                              isSelected: isSelected,
                              onTap: () {
                                if (_isMultiSelectMode) {
                                  _toggleProductSelection(productId);
                                } else {
                                  Navigator.pushNamed(
                                    context,
                                    '/product-detail',
                                    arguments: product,
                                  );
                                }
                              },
                              onEdit: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('Modifier ${product['name']}'),
                                  ),
                                );
                              },
                              onDuplicate: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('Dupliquer ${product['name']}'),
                                  ),
                                );
                              },
                              onViewHistory: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Historique de ${product['name']}'),
                                  ),
                                );
                              },
                              onToggleLowStockAlert: () {
                                setState(() {
                                  product['lowStockAlertEnabled'] =
                                      !(product['lowStockAlertEnabled']
                                          as bool);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      product['lowStockAlertEnabled'] == true
                                          ? 'Alerte de stock faible activée'
                                          : 'Alerte de stock faible désactivée',
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: _isMultiSelectMode
          ? null
          : FloatingActionButton(
              onPressed: _scanBarcode,
              tooltip: 'Scanner code-barres',
              child: CustomIconWidget(
                iconName: 'qr_code_scanner',
                color: colorScheme.onPrimary,
                size: 28,
              ),
            ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/main-dashboard');
              break;
            case 1:
              // Current screen
              break;
            case 2:
              Navigator.pushReplacementNamed(
                  context, '/sales-order-processing');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/customer-management');
              break;
            case 4:
              Navigator.pushReplacementNamed(context, '/financial-dashboard');
              break;
          }
        },
        customItems: const [
          CustomBottomBarItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            label: 'Tableau de bord',
            route: '/main-dashboard',
          ),
          CustomBottomBarItem(
            icon: Icons.inventory_2_outlined,
            activeIcon: Icons.inventory_2,
            label: 'Inventaire',
            route: '/product-catalog',
          ),
          CustomBottomBarItem(
            icon: Icons.shopping_cart_outlined,
            activeIcon: Icons.shopping_cart,
            label: 'Commandes',
            route: '/sales-order-processing',
          ),
          CustomBottomBarItem(
            icon: Icons.people_outline,
            activeIcon: Icons.people,
            label: 'Clients',
            route: '/customer-management',
          ),
          CustomBottomBarItem(
            icon: Icons.analytics_outlined,
            activeIcon: Icons.analytics,
            label: 'Rapports',
            route: '/financial-dashboard',
          ),
        ],
      ),
    );
  }
}
