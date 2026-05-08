import 'package:supabase_flutter/supabase_flutter.dart';

class InventoryService {
  static InventoryService? _instance;
  static InventoryService get instance => _instance ??= InventoryService._();
  InventoryService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getStock({String? warehouseId, String? productId, bool lowStockOnly = false}) async {
    try {
      var query = _client.from('inventory_stock').select('*, products(name, sku, barcode), warehouse_locations(name, code)');
      if (warehouseId != null) query = query.eq('warehouse_id', warehouseId);
      if (productId != null) query = query.eq('product_id', productId);
      if (lowStockOnly) query = query.lte('quantity', 10);
      final response = await query.order('updated_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur lors du chargement du stock: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getWarehouses() async {
    try {
      final response = await _client.from('warehouse_locations').select().order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur lors du chargement des entrepôts: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getStockMovements({String? warehouseId, String? productId, int limit = 50}) async {
    try {
      var query = _client.from('stock_movements').select('*, products(name, sku), warehouse_locations(name)');
      if (warehouseId != null) query = query.eq('warehouse_id', warehouseId);
      if (productId != null) query = query.eq('product_id', productId);
      final response = await query.order('created_at', ascending: false).limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur lors du chargement des mouvements: $e');
    }
  }

  Future<Map<String, dynamic>> createStockMovement({
    required String productId,
    required String warehouseId,
    required int quantity,
    required String movementType,
    String? reference,
    String? notes,
  }) async {
    try {
      final response = await _client.from('stock_movements').insert({
        'product_id': productId,
        'warehouse_id': warehouseId,
        'quantity': quantity,
        'movement_type': movementType,
        'performed_by': _client.auth.currentUser?.id,
        if (reference != null) 'reference': reference,
        if (notes != null) 'notes': notes,
      }).select().single();
      return response;
    } catch (e) {
      throw Exception('Erreur lors de la création du mouvement: $e');
    }
  }

  Future<Map<String, dynamic>> getStockSummary() async {
    try {
      final stock = await _client.from('inventory_stock').select('quantity, products(unit_price)');
      int totalItems = 0;
      double totalValue = 0;
      int lowStockCount = 0;
      for (final item in stock) {
        final qty = item['quantity'] as int? ?? 0;
        totalItems += qty;
        if (qty <= 10) lowStockCount++;
        final price = (item['products']?['unit_price'] as num?)?.toDouble() ?? 0;
        totalValue += qty * price;
      }
      return {
        'total_items': totalItems,
        'total_value': totalValue,
        'low_stock_count': lowStockCount,
        'total_products': stock.length,
      };
    } catch (e) {
      throw Exception('Erreur lors du calcul du résumé: $e');
    }
  }
}
