import 'package:supabase_flutter/supabase_flutter.dart';

class DeliveryService {
  static DeliveryService? _instance;
  static DeliveryService get instance => _instance ??= DeliveryService._();
  DeliveryService._() : _injectedClient = null;
  DeliveryService({SupabaseClient? client}) : _injectedClient = client;

  final SupabaseClient? _injectedClient;
  SupabaseClient get _client => _injectedClient ?? Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getDeliveries({
    String? status,
    String? routeId,
    int limit = 100,
  }) async {
    try {
      var query = _client.from('deliveries').select('''
            *,
            sales_orders(order_number, total_amount, payment_status, customers(company_name, phone)),
            delivery_routes(route_name, route_date, driver_id)
          ''');
      if (status != null) query = query.eq('status', status);
      if (routeId != null) query = query.eq('route_id', routeId);
      final response =
          await query.order('created_at', ascending: false).limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur lors du chargement des livraisons: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getRoutes() async {
    try {
      final response = await _client
          .from('delivery_routes')
          .select('*')
          .order('route_date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur lors du chargement des tournées: $e');
    }
  }

  Future<void> assignDeliveryWarehouse(String deliveryId, String warehouseId) async {
    await _client.rpc('assign_delivery_warehouse', params: {
      'p_delivery_id': deliveryId,
      'p_warehouse_id': warehouseId,
    });
  }

  Future<bool> canAssignDeliveryWarehouse() async {
    final role = await getActiveRole();
    return const ['admin', 'warehouse_staff'].contains(role);
  }

  Future<String?> getActiveRole() async {
    final id = _client.auth.currentUser?.id;
    if (id == null) return null;
    final profile = await _client.from('user_profiles')
        .select('role,is_active,must_change_password')
        .eq('id', id)
        .maybeSingle();
    if (profile == null || profile['is_active'] != true ||
        profile['must_change_password'] != false) {
      return null;
    }
    return profile['role'] as String?;
  }

  Future<List<Map<String, dynamic>>> getActiveWarehouses() async {
    return await _client.from('warehouse_locations')
        .select('id,name')
        .eq('is_active', true)
        .order('name');
  }

  Future<List<Map<String, dynamic>>> getReturnLines(String orderNumber) async {
    final result = await _client.rpc('get_customer_return_lines', params: {
      'p_order_number': orderNumber,
    });
    return List<Map<String, dynamic>>.from(result as List);
  }

  Future<void> inspectCustomerReturn({
    required String orderItemId,
    required int returnedQuantity,
    required int sellableQuantity,
    required String inspectionNote,
    required String requestId,
  }) async {
    await _client.rpc('inspect_customer_return', params: {
      'p_order_item_id': orderItemId,
      'p_returned_quantity': returnedQuantity,
      'p_sellable_quantity': sellableQuantity,
      'p_inspection_note': inspectionNote,
      'p_request_id': requestId,
    });
  }

  Future<void> updateDeliveryStatus(String deliveryId, String status) async {
    if (status != 'delivered') {
      throw ArgumentError.value(
        status,
        'status',
        'Seule la confirmation de livraison est disponible via ce service',
      );
    }
    try {
      final result = await _client.rpc(
        'confirm_delivery',
        params: {'p_delivery_id': deliveryId},
      );
      if (result is! Map || result['success'] != true) {
        throw StateError(result is Map
            ? result['error']?.toString() ?? 'Remise refusée'
            : 'Réponse de remise invalide');
      }
    } catch (e) {
      throw Exception('Erreur lors de la confirmation de la livraison: $e');
    }
  }
}
