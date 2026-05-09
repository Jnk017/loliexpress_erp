import 'package:supabase_flutter/supabase_flutter.dart';

class OrderService {
  static OrderService? _instance;
  static OrderService get instance => _instance ??= OrderService._();
  OrderService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getOrders({String? status, String? customerId, int limit = 50, int offset = 0}) async {
    try {
      var query = _client.from('sales_orders').select('*, customers(company_name, contact_person)');
      if (status != null) query = query.eq('order_status', status);
      if (customerId != null) query = query.eq('customer_id', customerId);
      final response = await query.order('created_at', ascending: false).range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur lors du chargement des commandes: $e');
    }
  }

  Future<Map<String, dynamic>?> getOrderById(String id) async {
    try {
      return await _client.from('sales_orders').select('*, customers(company_name, contact_person), order_items(*, products(name, sku, unit_price))').eq('id', id).maybeSingle();
    } catch (e) {
      throw Exception('Erreur lors du chargement de la commande: $e');
    }
  }

  Future<Map<String, dynamic>> createOrder({
    required String customerId,
    required List<Map<String, dynamic>> items,
    String? notes,
    double? discount,
  }) async {
    try {
      double totalAmount = 0;
      for (final item in items) {
        totalAmount += (item['quantity'] as num) * (item['unit_price'] as num);
      }
      if (discount != null) totalAmount -= discount;

      final order = await _client.from('sales_orders').insert({
        'customer_id': customerId,
        'total_amount': totalAmount,
        'order_status': 'pending',
        'payment_status': 'pending',
        'sales_rep_id': _client.auth.currentUser?.id,
        if (notes != null) 'notes': notes,
        if (discount != null) 'discount_amount': discount,
      }).select().single();

      for (final item in items) {
        await _client.from('order_items').insert({
          'order_id': order['id'],
          'product_id': item['product_id'],
          'quantity': item['quantity'],
          'unit_price': item['unit_price'],
          'total_price': (item['quantity'] as num) * (item['unit_price'] as num),
        });
      }

      return order;
    } catch (e) {
      throw Exception('Erreur lors de la création de la commande: $e');
    }
  }

  Future<Map<String, dynamic>> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final response = await _client.from('sales_orders').update({
        'order_status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId).select().single();
      return response;
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du statut: $e');
    }
  }

  Future<Map<String, dynamic>> getOrderStats() async {
    try {
      final orders = await _client.from('sales_orders').select('order_status, total_amount');
      int total = orders.length;
      int pending = 0, confirmed = 0, delivered = 0;
      double totalRevenue = 0;
      for (final o in orders) {
        switch (o['order_status']) {
          case 'pending': pending++; break;
          case 'confirmed': confirmed++; break;
          case 'delivered': delivered++; break;
        }
        totalRevenue += (o['total_amount'] as num?)?.toDouble() ?? 0;
      }
      return {
        'total': total,
        'pending': pending,
        'confirmed': confirmed,
        'delivered': delivered,
        'total_revenue': totalRevenue,
      };
    } catch (e) {
      throw Exception('Erreur lors du calcul des statistiques: $e');
    }
  }
}
