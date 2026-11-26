import 'package:supabase_flutter/supabase_flutter.dart';

class ProductService {
  static const _productSelection = '''
    id, sku, name, description, category_id, unit_price, image_url,
    barcode, is_active, created_at, updated_at, currency,
    product_categories(name)
  ''';
  static ProductService? _instance;
  static ProductService get instance => _instance ??= ProductService._();
  ProductService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getProducts(
      {String? categoryId,
      String? search,
      int limit = 50,
      int offset = 0,
      bool includeStock = false}) async {
    try {
      final selection = includeStock
          ? '$_productSelection, inventory_stock(quantity)'
          : _productSelection;
      var query = _client.from('products').select(selection);
      if (categoryId != null) query = query.eq('category_id', categoryId);
      if (search != null && search.isNotEmpty) {
        query = query.or(
            'name.ilike.%$search%,sku.ilike.%$search%,barcode.ilike.%$search%');
      }
      final response =
          await query.order('name').range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur lors du chargement des produits: $e');
    }
  }

  Future<Map<String, dynamic>?> getProductById(String id) async {
    try {
      return await _client
          .from('products')
          .select(_productSelection)
          .eq('id', id)
          .maybeSingle();
    } catch (e) {
      throw Exception('Erreur lors du chargement du produit: $e');
    }
  }

  Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    try {
      return await _client
          .from('products')
          .select(_productSelection)
          .eq('barcode', barcode)
          .maybeSingle();
    } catch (e) {
      throw Exception('Produit non trouvé pour ce code-barres: $e');
    }
  }

  Future<Map<String, dynamic>> createProduct(
      Map<String, dynamic> productData) async {
    try {
      final response = await _client
          .from('products')
          .insert(productData)
          .select(_productSelection)
          .single();
      return response;
    } catch (e) {
      throw Exception('Erreur lors de la création du produit: $e');
    }
  }

  Future<Map<String, dynamic>> updateProduct(
      String id, Map<String, dynamic> productData) async {
    try {
      final response = await _client
          .from('products')
          .update(productData)
          .eq('id', id)
          .select(_productSelection)
          .single();
      return response;
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du produit: $e');
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _client.from('products').delete().eq('id', id);
    } catch (e) {
      throw Exception('Erreur lors de la suppression du produit: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response =
          await _client.from('product_categories').select().order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur lors du chargement des catégories: $e');
    }
  }

  Future<Map<String, dynamic>> createCategory(String name,
      {String? description}) async {
    try {
      final response = await _client
          .from('product_categories')
          .insert({
            'name': name,
            if (description != null) 'description': description,
          })
          .select()
          .single();
      return response;
    } catch (e) {
      throw Exception('Erreur lors de la création de la catégorie: $e');
    }
  }

  Future<void> recordBarcodeScan(String barcode,
      {String? productId, String? scanType}) async {
    try {
      var resolvedProductId = productId;
      if (resolvedProductId == null) {
        final product = await getProductByBarcode(barcode);
        resolvedProductId = product?['id'] as String?;
      }
      if (resolvedProductId == null) return;

      await _client.from('barcode_scans').insert({
        'scanned_by': _client.auth.currentUser?.id,
        'product_id': resolvedProductId,
        'scan_type': scanType ?? 'lookup',
      });
    } catch (e) {
      // Non-critical, don't throw
    }
  }
}
