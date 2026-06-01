import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../services/product_service.dart';

class AddProductDialogWidget extends StatefulWidget {
  final Map<String, dynamic>? existingProduct;

  const AddProductDialogWidget({
    super.key,
    this.existingProduct,
  });

  @override
  State<AddProductDialogWidget> createState() => _AddProductDialogWidgetState();
}

class _AddProductDialogWidgetState extends State<AddProductDialogWidget> {
  final _formKey = GlobalKey<FormState>();
  final _productService = ProductService.instance;

  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _minStockController = TextEditingController();
  final _imageUrlController = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId;
  String _selectedUnit = 'pièce';
  bool _isLoading = false;
  bool _isSaving = false;
  bool _autoGenerateSku = true;

  bool get _isEditMode => widget.existingProduct != null;

  static const List<String> _units = [
    'pièce',
    'kg',
    'litre',
    'mètre',
    'carton',
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (_isEditMode) {
      _populateFields();
    }
  }

  void _populateFields() {
    final product = widget.existingProduct!;
    _nameController.text = product['name'] ?? '';
    _skuController.text = product['sku'] ?? '';
    _barcodeController.text = product['barcode'] ?? '';
    _priceController.text =
        (product['unit_price'] ?? product['price'] ?? '').toString();
    _descriptionController.text = product['description'] ?? '';
    _minStockController.text = (product['min_stock_level'] ?? 0).toString();
    _imageUrlController.text = product['image_url'] ?? '';
    _selectedCategoryId = product['category_id'];
    _selectedUnit = product['unit_of_measure'] ?? 'pièce';
    _autoGenerateSku = false;
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final categories = await _productService.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des catégories: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  String _generateSku() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return '';
    final prefix =
        name.substring(0, name.length >= 3 ? 3 : name.length).toUpperCase();
    final timestamp =
        DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    return '$prefix-$timestamp';
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final sku = _autoGenerateSku && !_isEditMode
          ? _generateSku()
          : _skuController.text.trim();

      final productData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'sku': sku,
        'unit_price': double.tryParse(_priceController.text.trim()) ?? 0,
        'unit_of_measure': _selectedUnit,
        'min_stock_level': int.tryParse(_minStockController.text.trim()) ?? 0,
      };

      if (_barcodeController.text.trim().isNotEmpty) {
        productData['barcode'] = _barcodeController.text.trim();
      }
      if (_descriptionController.text.trim().isNotEmpty) {
        productData['description'] = _descriptionController.text.trim();
      }
      if (_imageUrlController.text.trim().isNotEmpty) {
        productData['image_url'] = _imageUrlController.text.trim();
      }
      if (_selectedCategoryId != null) {
        productData['category_id'] = _selectedCategoryId;
      }

      if (_isEditMode) {
        await _productService.updateProduct(
          widget.existingProduct!['id'],
          productData,
        );
      } else {
        await _productService.createProduct(productData);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Erreur lors de la mise à jour: $e'
                : 'Erreur lors de la création: $e',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _minStockController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Modifier le produit' : 'Ajouter un produit',
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProduct,
            child: _isSaving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  )
                : Text(
                    'Enregistrer',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(theme, 'Informations générales'),
                    SizedBox(height: 1.h),
                    _buildNameField(theme),
                    SizedBox(height: 2.h),
                    _buildSkuField(theme),
                    SizedBox(height: 2.h),
                    _buildBarcodeField(theme),
                    SizedBox(height: 2.h),
                    _buildCategoryDropdown(theme, colorScheme),
                    SizedBox(height: 3.h),
                    _buildSectionTitle(theme, 'Tarification et unités'),
                    SizedBox(height: 1.h),
                    _buildPriceField(theme),
                    SizedBox(height: 2.h),
                    _buildUnitDropdown(theme, colorScheme),
                    SizedBox(height: 2.h),
                    _buildMinStockField(theme),
                    SizedBox(height: 3.h),
                    _buildSectionTitle(theme, 'Détails supplémentaires'),
                    SizedBox(height: 1.h),
                    _buildDescriptionField(theme),
                    SizedBox(height: 2.h),
                    _buildImageUrlField(theme),
                    SizedBox(height: 4.h),
                    _buildSaveButton(theme, colorScheme),
                    SizedBox(height: 2.h),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildNameField(ThemeData theme) {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Nom du produit *',
        hintText: 'Ex: Coca-Cola 1.5L',
        prefixIcon: Icon(Icons.inventory_2_outlined),
      ),
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Le nom du produit est requis';
        }
        return null;
      },
    );
  }

  Widget _buildSkuField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_isEditMode)
          Row(
            children: [
              Checkbox(
                value: _autoGenerateSku,
                onChanged: (value) {
                  setState(() => _autoGenerateSku = value ?? true);
                },
              ),
              Text(
                'Générer le SKU automatiquement',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        if (!_autoGenerateSku || _isEditMode)
          TextFormField(
            controller: _skuController,
            decoration: const InputDecoration(
              labelText: 'SKU',
              hintText: 'Ex: CC-1500-001',
              prefixIcon: Icon(Icons.qr_code),
            ),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (!_autoGenerateSku &&
                  (value == null || value.trim().isEmpty)) {
                return 'Le SKU est requis si non auto-généré';
              }
              return null;
            },
          ),
      ],
    );
  }

  Widget _buildBarcodeField(ThemeData theme) {
    return TextFormField(
      controller: _barcodeController,
      decoration: const InputDecoration(
        labelText: 'Code-barres (optionnel)',
        hintText: 'Ex: 5449000000996',
        prefixIcon: Icon(Icons.barcode_reader),
      ),
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    );
  }

  Widget _buildCategoryDropdown(ThemeData theme, ColorScheme colorScheme) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategoryId,
      decoration: const InputDecoration(
        labelText: 'Catégorie',
        prefixIcon: Icon(Icons.category_outlined),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('Aucune catégorie'),
        ),
        ..._categories.map((cat) => DropdownMenuItem<String>(
              value: cat['id'].toString(),
              child: Text(cat['name'] ?? ''),
            )),
      ],
      onChanged: (value) => setState(() => _selectedCategoryId = value),
    );
  }

  Widget _buildPriceField(ThemeData theme) {
    return TextFormField(
      controller: _priceController,
      decoration: const InputDecoration(
        labelText: 'Prix unitaire (FC) *',
        hintText: 'Ex: 750',
        prefixIcon: Icon(Icons.attach_money),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Le prix unitaire est requis';
        }
        final price = double.tryParse(value.trim());
        if (price == null || price < 0) {
          return 'Veuillez entrer un prix valide';
        }
        return null;
      },
    );
  }

  Widget _buildUnitDropdown(ThemeData theme, ColorScheme colorScheme) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedUnit,
      decoration: const InputDecoration(
        labelText: 'Unité de mesure',
        prefixIcon: Icon(Icons.straighten),
      ),
      items: _units
          .map((unit) => DropdownMenuItem<String>(
                value: unit,
                child: Text(unit),
              ))
          .toList(),
      onChanged: (value) {
        if (value != null) setState(() => _selectedUnit = value);
      },
    );
  }

  Widget _buildMinStockField(ThemeData theme) {
    return TextFormField(
      controller: _minStockController,
      decoration: const InputDecoration(
        labelText: 'Niveau de stock minimum',
        hintText: 'Ex: 10',
        prefixIcon: Icon(Icons.warning_amber_outlined),
      ),
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    );
  }

  Widget _buildDescriptionField(ThemeData theme) {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Description (optionnel)',
        hintText: 'Décrivez le produit...',
        prefixIcon: Icon(Icons.description_outlined),
        alignLabelWithHint: true,
      ),
      maxLines: 4,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildImageUrlField(ThemeData theme) {
    return TextFormField(
      controller: _imageUrlController,
      decoration: const InputDecoration(
        labelText: 'URL de l\'image (optionnel)',
        hintText: 'https://example.com/image.jpg',
        prefixIcon: Icon(Icons.image_outlined),
      ),
      keyboardType: TextInputType.url,
      textInputAction: TextInputAction.done,
    );
  }

  Widget _buildSaveButton(ThemeData theme, ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _saveProduct,
        icon: _isSaving
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.onPrimary,
                ),
              )
            : Icon(
                _isEditMode ? Icons.save : Icons.add,
                color: colorScheme.onPrimary,
              ),
        label: Text(
          _isSaving
              ? 'Enregistrement...'
              : _isEditMode
                  ? 'Mettre à jour le produit'
                  : 'Créer le produit',
          style: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.onPrimary,
          ),
        ),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 2.h),
        ),
      ),
    );
  }
}
