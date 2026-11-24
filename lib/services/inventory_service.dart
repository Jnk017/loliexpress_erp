import 'package:supabase_flutter/supabase_flutter.dart';

class InventoryService {
  static InventoryService? _instance;
  static InventoryService get instance => _instance ??= InventoryService._();
  InventoryService._() : _injectedClient = null;
  InventoryService({SupabaseClient? client}) : _injectedClient = client;

  final SupabaseClient? _injectedClient;
  SupabaseClient get _client => _injectedClient ?? Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getStock(
      {String? warehouseId,
      String? productId,
      bool lowStockOnly = false}) async {
    try {
      var query = _client
          .from('inventory_stock')
          .select('*, products(name, sku, barcode), warehouse_locations(name)');
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
      final response =
          await _client.from('warehouse_locations').select().order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur lors du chargement des entrepôts: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getStockMovements(
      {String? warehouseId, String? productId, int limit = 50}) async {
    try {
      var query = _client
          .from('stock_movements')
          .select('*, products(name, sku), warehouse_locations(name)');
      if (warehouseId != null) query = query.eq('warehouse_id', warehouseId);
      if (productId != null) query = query.eq('product_id', productId);
      final response =
          await query.order('created_at', ascending: false).limit(limit);
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
    final quantityDelta = switch (movementType) {
      'in' || 'return' => quantity.abs(),
      'out' => -quantity.abs(),
      'adjustment' => quantity,
      _ => throw ArgumentError.value(
          movementType,
          'movementType',
          'Type de mouvement non pris en charge',
        ),
    };
    final reason = notes?.trim().isNotEmpty == true
        ? notes!.trim()
        : 'Mouvement $movementType';

    try {
      final response = await _client.rpc(
        'adjust_stock',
        params: {
          'p_product_id': productId,
          'p_warehouse_id': warehouseId,
          'p_quantity_delta': quantityDelta,
          'p_reason': reason,
          'p_reference_type': reference ?? movementType,
        },
      );
      if (response is! Map) {
        throw const FormatException('Réponse RPC de stock invalide');
      }
      return Map<String, dynamic>.from(response);
    } catch (e) {
      throw Exception('Erreur lors de la création du mouvement: $e');
    }
  }

  Future<void> transferStock({
    required String productId,
    required String sourceId,
    required String destinationId,
    required int quantity,
    required String reason,
  }) async {
    await _client.rpc('transfer_stock', params: {
      'p_product_id': productId,
      'p_source_id': sourceId,
      'p_destination_id': destinationId,
      'p_quantity': quantity,
      'p_reason': reason,
    });
  }

  Future<void> recordPhysicalCount({
    required String productId,
    required String warehouseId,
    required int expectedQuantity,
    required int countedQuantity,
    required String reason,
  }) async {
    await _client.rpc('record_physical_stock_count', params: {
      'p_product_id': productId,
      'p_warehouse_id': warehouseId,
      'p_expected_quantity': expectedQuantity,
      'p_counted_quantity': countedQuantity,
      'p_reason': reason,
    });
  }

  Future<Map<String, dynamic>> updateStock({
    required String productId,
    required String warehouseId,
    required int quantityDelta,
    String? notes,
  }) {
    return createStockMovement(
      productId: productId,
      warehouseId: warehouseId,
      quantity: quantityDelta,
      movementType: 'adjustment',
      notes: notes,
    );
  }

  Future<Map<String, dynamic>> getStockSummary() async {
    try {
      final stock = await _client
          .from('inventory_stock')
          .select('quantity, products(unit_price)');
      int totalItems = 0;
      double totalValue = 0;
      int lowStockCount = 0;
      for (final item in stock) {
        final qty = item['quantity'] as int? ?? 0;
        totalItems += qty;
        if (qty <= 10) lowStockCount++;
        final price =
            (item['products']?['unit_price'] as num?)?.toDouble() ?? 0;
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
