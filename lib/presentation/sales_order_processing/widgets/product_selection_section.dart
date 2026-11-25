import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Product selection section widget
/// Displays searchable product list with barcode scan integration
class ProductSelectionSection extends StatefulWidget {
  final List<Map<String, dynamic>> products;
  final Function(Map<String, dynamic>) onProductAdd;
  final VoidCallback onBarcodeScan;
  final String customerTier;

  const ProductSelectionSection({
    super.key,
    required this.products,
    required this.onProductAdd,
    required this.onBarcodeScan,
    required this.customerTier,
  });

  @override
  State<ProductSelectionSection> createState() =>
      _ProductSelectionSectionState();
}

class _ProductSelectionSectionState extends State<ProductSelectionSection> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _filteredProducts = widget.products;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = widget.products;
      } else {
        _filteredProducts = widget.products.where((product) {
          final name = (product["name"] as String).toLowerCase();
          final code = (product["code"] as String).toLowerCase();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) || code.contains(searchLower);
        }).toList();
      }
    });
  }

  double _getCustomPrice(Map<String, dynamic> product) {
    final basePrice = product["price"] as double;
    final discount =
        product["tierDiscounts"][widget.customerTier] as double? ?? 0.0;
    return basePrice * (1 - discount);
  }

  bool _hasDiscount(Map<String, dynamic> product) {
    final discount =
        product["tierDiscounts"][widget.customerTier] as double? ?? 0.0;
    return discount > 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Sélection de produits',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: CustomIconWidget(
                    iconName: 'qr_code_scanner',
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  onPressed: widget.onBarcodeScan,
                  tooltip: 'Scanner code-barres',
                ),
              ],
            ),
          ),
          // Search field
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: TextField(
              controller: _searchController,
              onChanged: _filterProducts,
              decoration: InputDecoration(
                hintText: 'Rechercher un produit…',
                prefixIcon: CustomIconWidget(
                  iconName: 'search',
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: CustomIconWidget(
                          iconName: 'clear',
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _filterProducts('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4.w,
                  vertical: 1.5.h,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Product list
          Container(
            constraints: const BoxConstraints(maxHeight: 260),
            child: _filteredProducts.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(4.w),
                      child: Text(
                        'Aucun produit trouvé',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    primary: false,
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 4),
                    itemCount: _filteredProducts.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return _buildProductItem(context, product);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(BuildContext context, Map<String, dynamic> product) {
    final theme = Theme.of(context);
    final customPrice = _getCustomPrice(product);
    final hasDiscount = _hasDiscount(product);
    final stock = product["stock"] as int;
    final isLowStock = stock < 10;

    return InkWell(
      onTap: () => widget.onProductAdd(product),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          children: [
            // Product image
            Container(
              width: 15.w,
              height: 15.w,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CustomImageWidget(
                  imageUrl: product["image"] as String,
                  width: 15.w,
                  height: 15.w,
                  fit: BoxFit.cover,
                  semanticLabel: product["semanticLabel"] as String,
                ),
              ),
            ),
            SizedBox(width: 3.w),
            // Product details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product["name"] as String,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Code: ${product["code"]}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    children: [
                      if (hasDiscount) ...[
                        Text(
                          '${product["price"]} ${product["currency"] ?? 'CDF'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        SizedBox(width: 2.w),
                      ],
                      Text(
                        'Catalogue ${customPrice.toStringAsFixed(2)} ${product["currency"] ?? 'CDF'}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: hasDiscount
                              ? theme.colorScheme.tertiary
                              : theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'inventory_2',
                        color: isLowStock
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                        size: 14,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        '$stock en stock',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isLowStock
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Add button
            IconButton(
              icon: CustomIconWidget(
                iconName: 'add_circle',
                color: theme.colorScheme.primary,
                size: 28,
              ),
              onPressed: () => widget.onProductAdd(product),
            ),
          ],
        ),
      ),
    );
  }
}
