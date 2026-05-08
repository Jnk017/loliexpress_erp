import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/product_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/add_product_dialog_widget.dart';
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
  final ProductService _productService = ProductService.instance;
  final Set<String> _selectedProducts = {};

  bool _isMultiSelectMode = false;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String _searchQuery = '';

  List<Map<String, dynamic>> _allProducts = [];

  Map<String, dynamic> _currentFilters = {
    'category': 'Toutes',
    'supplier': 'Tous',
    'stockStatus': 'Tous',
    'sortBy': 'Nom (A-Z)',
    'showExpiringSoon': false,
  };

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final categoryId = _currentFilters['category'] != 'Toutes'
          ? _currentFilters['category'] as String?
          : null;

      final products = await _productService.getProducts(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        categoryId: categoryId is String && categoryId.contains('-')
            ? categoryId
            : null,
      );

      if (!mounted) return;
      setState(() {
        _allProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    List<Map<String, dynamic>> filtered = List.from(_allProducts);

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) {
        final name = (product['name'] as String? ?? '').toLowerCase();
        final sku = (product['sku'] as String? ?? '').toLowerCase();
        final barcode = (product['barcode'] as String? ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) ||
            sku.contains(query) ||
            barcode.contains(query);
      }).toList();
    }

    if (_currentFilters['category'] != 'Toutes') {
      final filterCategory = _currentFilters['category'] as String;
      filtered = filtered.where((product) {
        final catData = product['product_categories'];
        if (catData is Map) {
          return catData['name'] == filterCategory;
        }
        return false;
      }).toList();
    }

    if (_currentFilters['stockStatus'] != 'Tous') {
      filtered = filtered.where((product) {
        final stock = (product['current_stock'] ?? product['currentStock'] ?? 0) as num;
        final minStock = (product['min_stock_level'] ?? product['minStock'] ?? 0) as num;
        final criticalStock = (product['critical_stock_level'] ?? product['criticalStock'] ?? 0) as num;

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

    final sortBy = _currentFilters['sortBy'] as String;
    if (sortBy.contains('Nom (A-Z)')) {
      filtered.sort(
          (a, b) => (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? ''));
    } else if (sortBy.contains('Nom (Z-A)')) {
      filtered.sort(
          (a, b) => (b['name'] as String? ?? '').compareTo(a['name'] as String? ?? ''));
    } else if (sortBy.contains('Prix (Croissant)')) {
      filtered.sort((a, b) {
        final priceA = (a['unit_price'] ?? a['price'] ?? 0) as num;
        final priceB = (b['unit_price'] ?? b['price'] ?? 0) as num;
        return priceA.compareTo(priceB);
      });
    } else if (sortBy.contains('Prix (Décroissant)')) {
      filtered.sort((a, b) {
        final priceA = (a['unit_price'] ?? a['price'] ?? 0) as num;
        final priceB = (b['unit_price'] ?? b['price'] ?? 0) as num;
        return priceB.compareTo(priceA);
      });
    } else if (sortBy.contains('Stock (Croissant)')) {
      filtered.sort((a, b) {
        final stockA = (a['current_stock'] ?? a['currentStock'] ?? 0) as num;
        final stockB = (b['current_stock'] ?? b['currentStock'] ?? 0) as num;
        return stockA.compareTo(stockB);
      });
    } else if (sortBy.contains('Stock (Décroissant)')) {
      filtered.sort((a, b) {
        final stockA = (a['current_stock'] ?? a['currentStock'] ?? 0) as num;
        final stockB = (b['current_stock'] ?? b['currentStock'] ?? 0) as num;
        return stockB.compareTo(stockA);
      });
    }

    return filtered;
  }

  Future<void> _refreshProducts() async {
    await _loadProducts();
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
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

  Future<void> _openAddProductDialog({Map<String, dynamic>? product}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => AddProductDialogWidget(
          existingProduct: product,
        ),
      ),
    );

    if (result == true) {
      _refreshProducts();
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

  void _toggleProductSelection(String productId) {
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

  Map<String, dynamic> _adaptProductForCard(Map<String, dynamic> product) {
    return {
      'id': product['id'] ?? '',
      'name': product['name'] ?? 'Sans nom',
      'sku': product['sku'] ?? '',
      'currentStock': product['current_stock'] ?? product['currentStock'] ?? 0,
      'minStock': product['min_stock_level'] ?? product['minStock'] ?? 0,
      'criticalStock':
          product['critical_stock_level'] ?? product['criticalStock'] ?? 0,
      'price': (product['unit_price'] ?? product['price'] ?? 0).toString(),
      'category': product['product_categories'] is Map
          ? product['product_categories']['name'] ?? 'Non classé'
          : 'Non classé',
      'supplier': product['supplier'] ?? '',
      'image': product['image_url'] ?? product['image'] ?? '',
      'semanticLabel': product['name'] ?? 'Image du produit',
      'lowStockAlertEnabled': product['low_stock_alert_enabled'] ?? false,
      'expiryDate': product['expiry_date'] != null
          ? DateTime.tryParse(product['expiry_date']) ?? DateTime.now().add(const Duration(days: 365))
          : DateTime.now().add(const Duration(days: 365)),
    };
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
          SearchBarWidget(
            controller: _searchController,
            onChanged: _onSearchChanged,
            onScanBarcode: _scanBarcode,
            onFilter: _showFilterBottomSheet,
          ),
          Expanded(
            child: _buildBody(theme, colorScheme, filteredProducts),
          ),
        ],
      ),
      floatingActionButton: _isMultiSelectMode
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'add_product_fab',
                  onPressed: () => _openAddProductDialog(),
                  tooltip: 'Ajouter un produit',
                  child: CustomIconWidget(
                    iconName: 'add',
                    color: colorScheme.onPrimary,
                    size: 28,
                  ),
                ),
                SizedBox(height: 1.5.h),
                FloatingActionButton.small(
                  heroTag: 'scan_barcode_fab',
                  onPressed: _scanBarcode,
                  tooltip: 'Scanner code-barres',
                  child: CustomIconWidget(
                    iconName: 'qr_code_scanner',
                    color: colorScheme.onPrimary,
                    size: 22,
                  ),
                ),
              ],
            ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/main-dashboard');
              break;
            case 1:
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

  Widget _buildBody(
    ThemeData theme,
    ColorScheme colorScheme,
    List<Map<String, dynamic>> filteredProducts,
  ) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 60,
                color: colorScheme.error,
              ),
              SizedBox(height: 2.h),
              Text(
                'Erreur de chargement',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.error,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                _errorMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 3.h),
              ElevatedButton.icon(
                onPressed: _refreshProducts,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredProducts.isEmpty) {
      return EmptyStateWidget(
        message: _searchQuery.isNotEmpty || _currentFilters['category'] != 'Toutes'
            ? 'Aucun produit trouvé'
            : 'Aucun produit dans le catalogue',
        actionText: _searchQuery.isNotEmpty || _currentFilters['category'] != 'Toutes'
            ? 'Ajuster les filtres'
            : 'Ajouter un produit',
        showFilterAdjustment:
            _searchQuery.isNotEmpty || _currentFilters['category'] != 'Toutes',
        onActionPressed: _searchQuery.isNotEmpty ||
                _currentFilters['category'] != 'Toutes'
            ? _showFilterBottomSheet
            : () => _openAddProductDialog(),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshProducts,
      color: colorScheme.primary,
      child: ListView.builder(
        padding: EdgeInsets.only(bottom: 12.h),
        itemCount: filteredProducts.length,
        itemBuilder: (context, index) {
          final product = filteredProducts[index];
          final adaptedProduct = _adaptProductForCard(product);
          final productId = (product['id'] ?? '').toString();
          final isSelected = _selectedProducts.contains(productId);

          return ProductCardWidget(
            product: adaptedProduct,
            isSelected: isSelected,
            onTap: () {
              if (_isMultiSelectMode) {
                _toggleProductSelection(productId);
              } else {
                _openAddProductDialog(product: product);
              }
            },
            onEdit: () => _openAddProductDialog(product: product),
            onDuplicate: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Dupliquer ${product['name']}'),
                ),
              );
            },
            onViewHistory: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Historique de ${product['name']}'),
                ),
              );
            },
            onToggleLowStockAlert: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    adaptedProduct['lowStockAlertEnabled'] == true
                        ? 'Alerte de stock faible désactivée'
                        : 'Alerte de stock faible activée',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
