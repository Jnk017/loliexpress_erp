import 'package:supabase_flutter/supabase_flutter.dart';

class DeliveryService {
  static DeliveryService? _instance;
  static DeliveryService get instance => _instance ??= DeliveryService._();
  DeliveryService._();

  SupabaseClient get _client => Supabase.instance.client;

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

  Future<void> updateDeliveryStatus(String deliveryId, String status) async {
    try {
      final updates = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (status == 'delivered') {
        updates['actual_delivery_time'] = DateTime.now().toIso8601String();
      }
      await _client.from('deliveries').update(updates).eq('id', deliveryId);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la livraison: $e');
    }
  }
}
