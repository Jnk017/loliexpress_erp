import 'package:flutter/material.dart';

/// Filter bottom sheet for customer management
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

  final List<String> _locations = [
    'Tous',
    'Dakar',
    'Thiès',
    'Saint-Louis',
    'Kaolack',
  ];

  final List<String> _paymentTerms = [
    'Tous',
    'Comptant',
    '30 jours',
    '60 jours',
    '90 jours',
  ];

  final List<String> _customerTiers = [
    'Tous',
    'Premium',
    'Standard',
    'Nouveau',
  ];

  final List<String> _accountStatuses = [
    'Tous',
    'Actif',
    'Inactif',
    'Suspendu',
  ];

  @override
  void initState() {
    super.initState();
    _filters = Map<String, dynamic>.from(widget.currentFilters);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Filtres',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filters = {
                        'location': 'Tous',
                        'paymentTerms': 'Tous',
                        'customerTier': 'Tous',
                        'accountStatus': 'Tous',
                      };
                    });
                  },
                  child: Text(
                    'Réinitialiser',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterSection(
                    title: 'Localisation',
                    options: _locations,
                    selectedValue: _filters['location'] as String? ?? 'Tous',
                    onChanged: (value) {
                      setState(() => _filters['location'] = value);
                    },
                    theme: theme,
                  ),
                  const SizedBox(height: 24),
                  _buildFilterSection(
                    title: 'Conditions de paiement',
                    options: _paymentTerms,
                    selectedValue:
                        _filters['paymentTerms'] as String? ?? 'Tous',
                    onChanged: (value) {
                      setState(() => _filters['paymentTerms'] = value);
                    },
                    theme: theme,
                  ),
                  const SizedBox(height: 24),
                  _buildFilterSection(
                    title: 'Niveau client',
                    options: _customerTiers,
                    selectedValue:
                        _filters['customerTier'] as String? ?? 'Tous',
                    onChanged: (value) {
                      setState(() => _filters['customerTier'] = value);
                    },
                    theme: theme,
                  ),
                  const SizedBox(height: 24),
                  _buildFilterSection(
                    title: 'Statut du compte',
                    options: _accountStatuses,
                    selectedValue:
                        _filters['accountStatus'] as String? ?? 'Tous',
                    onChanged: (value) {
                      setState(() => _filters['accountStatus'] = value);
                    },
                    theme: theme,
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApplyFilters(_filters);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Appliquer'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required List<String> options,
    required String selectedValue,
    required Function(String) onChanged,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = option == selectedValue;
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (_) => onChanged(option),
              backgroundColor: theme.colorScheme.surface,
              selectedColor: theme.colorScheme.primary.withValues(
                alpha: 0.2,
              ),
              checkmarkColor: theme.colorScheme.primary,
              labelStyle: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              side: BorderSide(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
