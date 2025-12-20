import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class FilterBottomSheetWidget extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onApplyFilters;

  const FilterBottomSheetWidget({
    super.key,
    required this.currentFilters,
    required this.onApplyFilters,
  });

  @override
  State<FilterBottomSheetWidget> createState() =>
      _FilterBottomSheetWidgetState();
}

class _FilterBottomSheetWidgetState extends State<FilterBottomSheetWidget> {
  late Map<String, dynamic> _filters;

  final List<String> _categories = [
    'Toutes',
    'Boissons gazeuses',
    'Jus',
    'Eau',
    'Boissons énergétiques',
    'Bières',
    'Vins',
  ];

  final List<String> _suppliers = [
    'Tous',
    'Coca-Cola',
    'PepsiCo',
    'Nestlé',
    'Danone',
    'Red Bull',
  ];

  final List<String> _stockStatus = ['Tous', 'Suffisant', 'Faible', 'Critique'];

  final List<String> _sortOptions = [
    'FIFO (Premier entré, premier sorti)',
    'FEFO (Premier expiré, premier sorti)',
    'Nom (A-Z)',
    'Nom (Z-A)',
    'Prix (Croissant)',
    'Prix (Décroissant)',
    'Stock (Croissant)',
    'Stock (Décroissant)',
  ];

  @override
  void initState() {
    super.initState();
    _filters = Map<String, dynamic>.from(widget.currentFilters);
  }

  void _resetFilters() {
    setState(() {
      _filters = {
        'category': 'Toutes',
        'supplier': 'Tous',
        'stockStatus': 'Tous',
        'sortBy': 'FIFO (Premier entré, premier sorti)',
        'showExpiringSoon': false,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar
          Container(
            margin: EdgeInsets.only(top: 1.h),
            width: 12.w,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filtres',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: _resetFilters,
                  child: Text(
                    'Réinitialiser',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.2)),
          // Filter Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Filter
                  _buildFilterSection(
                    'Catégorie',
                    _buildDropdown(
                      context,
                      _filters['category'] as String,
                      _categories,
                      (value) => setState(() => _filters['category'] = value),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  // Supplier Filter
                  _buildFilterSection(
                    'Fournisseur',
                    _buildDropdown(
                      context,
                      _filters['supplier'] as String,
                      _suppliers,
                      (value) => setState(() => _filters['supplier'] = value),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  // Stock Status Filter
                  _buildFilterSection(
                    'Statut du stock',
                    _buildDropdown(
                      context,
                      _filters['stockStatus'] as String,
                      _stockStatus,
                      (value) =>
                          setState(() => _filters['stockStatus'] = value),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  // Sort By Filter
                  _buildFilterSection(
                    'Trier par',
                    _buildDropdown(
                      context,
                      _filters['sortBy'] as String,
                      _sortOptions,
                      (value) => setState(() => _filters['sortBy'] = value),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  // Expiring Soon Toggle
                  _buildFilterSection(
                    'Produits expirant bientôt',
                    SwitchListTile(
                      value: _filters['showExpiringSoon'] as bool,
                      onChanged: (value) {
                        setState(() => _filters['showExpiringSoon'] = value);
                      },
                      title: Text(
                        'Afficher uniquement les produits expirant dans 30 jours',
                        style: theme.textTheme.bodyMedium,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Apply Button
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApplyFilters(_filters);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                ),
                child: Text(
                  'Appliquer les filtres',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(String title, Widget child) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        child,
      ],
    );
  }

  Widget _buildDropdown(
    BuildContext context,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: theme.textTheme.bodyMedium),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
