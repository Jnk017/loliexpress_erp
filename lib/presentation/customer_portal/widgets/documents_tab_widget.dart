import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/document_service.dart';

/// Documents Tab Widget
/// Provides secure access to invoices, delivery notes, and statements
class DocumentsTabWidget extends StatefulWidget {
  const DocumentsTabWidget({super.key});

  @override
  State<DocumentsTabWidget> createState() => _DocumentsTabWidgetState();
}

class _DocumentsTabWidgetState extends State<DocumentsTabWidget> {
  String _selectedFilter = 'all';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _documents = [];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    try {
      final documents = await DocumentService().getMyDocuments();
      if (!mounted) return;
      setState(() {
        _documents = documents.map(_mapDocument).toList();
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _mapDocument(Map<String, dynamic> row) {
    final type = row['entity_type'] as String? ?? 'document';
    return {
      "id": row['id'] as String? ?? '',
      "type": type,
      "typeLabel": _typeLabel(type),
      "date": DateTime.tryParse(row['uploaded_at'] as String? ?? '') ??
          DateTime.now(),
      "amount": "",
      "status": "available",
      "statusLabel": "Disponible",
      "orderId": row['entity_id'] as String?,
      "filePath": row['file_path'],
      "fileName": row['file_name'],
    };
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'invoice':
        return 'Facture';
      case 'delivery':
        return 'Bon de livraison';
      case 'expense':
        return 'Dépense';
      case 'purchase_order':
        return 'Bon d’achat';
      default:
        return 'Document';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(6.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  color: theme.colorScheme.error, size: 48),
              SizedBox(height: 2.h),
              Text('Erreur de chargement des documents',
                  style: theme.textTheme.titleMedium),
              SizedBox(height: 1.h),
              SizedBox(height: 2.h),
              ElevatedButton(
                onPressed: _loadDocuments,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final filteredDocuments = _filterDocuments();

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mes Documents',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.h),
              _buildSearchBar(context),
              SizedBox(height: 2.h),
              _buildTypeFilters(context),
            ],
          ),
        ),
        Expanded(
          child: filteredDocuments.isEmpty
              ? _buildEmptyState(context)
              : ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  itemCount: filteredDocuments.length,
                  separatorBuilder: (context, index) => SizedBox(height: 2.h),
                  itemBuilder: (context, index) {
                    final document = filteredDocuments[index];
                    return _buildDocumentCard(context, document);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Rechercher par numéro, date ou montant...',
        prefixIcon: Padding(
          padding: EdgeInsets.all(3.w),
          child: CustomIconWidget(
            iconName: 'search',
            color: theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
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
                  setState(() {});
                },
              )
            : null,
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildTypeFilters(BuildContext context) {
    final theme = Theme.of(context);

    final filters = [
      {'value': 'all', 'label': 'Tous', 'icon': 'description'},
      {'value': 'invoice', 'label': 'Factures', 'icon': 'receipt_long'},
      {
        'value': 'delivery',
        'label': 'Bons de livraison',
        'icon': 'local_shipping'
      },
      {'value': 'statement', 'label': 'Relevés', 'icon': 'account_balance'},
    ];

    return SizedBox(
      height: 5.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => SizedBox(width: 2.w),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter['value'];

          return FilterChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName: filter['icon'] as String,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  size: 16,
                ),
                SizedBox(width: 2.w),
                Text(
                  filter['label'] as String,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _selectedFilter = filter['value'] as String;
              });
            },
            backgroundColor: theme.colorScheme.surface,
            selectedColor: theme.colorScheme.primary,
            side: BorderSide(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDocumentCard(
      BuildContext context, Map<String, dynamic> document) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: () => _showDocumentPreview(context, document),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2.5.w),
                    decoration: BoxDecoration(
                      color: _getDocumentTypeColor(document['type'])
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: _getDocumentTypeIcon(document['type']),
                      color: _getDocumentTypeColor(document['type']),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          document['id'],
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          document['typeLabel'],
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(
                      context, document['status'], document['statusLabel']),
                ],
              ),
              SizedBox(height: 2.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        _formatDate(document['date']),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Montant',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        document['amount'],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (document['orderId'] != null) ...[
                SizedBox(height: 1.5.h),
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'link',
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 14,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      'Commande: ${document['orderId']}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 2.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _downloadDocument(document),
                      icon: CustomIconWidget(
                        iconName: 'download',
                        color: theme.colorScheme.primary,
                        size: 18,
                      ),
                      label: const Text('Télécharger'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _shareDocument(document),
                      icon: CustomIconWidget(
                        iconName: 'share',
                        color: theme.colorScheme.onPrimary,
                        size: 18,
                      ),
                      label: const Text('Partager'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status, String label) {
    final theme = Theme.of(context);

    Color backgroundColor;
    Color textColor;

    switch (status) {
      case 'paid':
        backgroundColor = AppTheme.successLight.withValues(alpha: 0.1);
        textColor = AppTheme.successLight;
        break;
      case 'pending':
        backgroundColor = AppTheme.warningLight.withValues(alpha: 0.1);
        textColor = AppTheme.warningLight;
        break;
      case 'overdue':
        backgroundColor = AppTheme.errorLight.withValues(alpha: 0.1);
        textColor = AppTheme.errorLight;
        break;
      case 'delivered':
        backgroundColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue;
        break;
      case 'available':
        backgroundColor = Colors.purple.withValues(alpha: 0.1);
        textColor = Colors.purple;
        break;
      default:
        backgroundColor = theme.colorScheme.surfaceContainerHighest;
        textColor = theme.colorScheme.onSurface;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'description',
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            size: 64,
          ),
          SizedBox(height: 2.h),
          Text(
            'Aucun document trouvé',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Essayez de modifier vos filtres',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _filterDocuments() {
    var filtered = _documents;

    if (_selectedFilter != 'all') {
      filtered =
          filtered.where((doc) => doc['type'] == _selectedFilter).toList();
    }

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((doc) {
        return (doc['id'] as String).toLowerCase().contains(query) ||
            (doc['amount'] as String).toLowerCase().contains(query) ||
            (doc['typeLabel'] as String).toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  String _getDocumentTypeIcon(String type) {
    switch (type) {
      case 'invoice':
        return 'receipt_long';
      case 'delivery':
        return 'local_shipping';
      case 'statement':
        return 'account_balance';
      default:
        return 'description';
    }
  }

  Color _getDocumentTypeColor(String type) {
    switch (type) {
      case 'invoice':
        return AppTheme.primaryLight;
      case 'delivery':
        return AppTheme.warningLight;
      case 'statement':
        return Colors.purple;
      default:
        return AppTheme.secondaryLight;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Août',
      'Sep',
      'Oct',
      'Nov',
      'Déc'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showDocumentPreview(
      BuildContext context, Map<String, dynamic> document) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Aperçu du document',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                document['id'],
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                document['typeLabel'],
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 2.h),
              Container(
                width: double.infinity,
                height: 30.h,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'picture_as_pdf',
                        color: AppTheme.errorLight,
                        size: 48,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Aperçu PDF',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _downloadDocument(document);
              },
              child: const Text('Télécharger'),
            ),
          ],
        );
      },
    );
  }

  void _downloadDocument(Map<String, dynamic> document) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Téléchargement de ${document['id']} en cours...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareDocument(Map<String, dynamic> document) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Partage de ${document['id']} en cours...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
