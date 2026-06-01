import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/order.dart';
import '../services/order_service.dart';

class OrderRepository {
  OrderRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Order>> fetchOrders({String? status}) async {
    var query = _client.from('sales_orders').select();
    if (status != null) query = query.eq('order_status', status);
    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response)
        .map(Order.fromJson)
        .toList();
  }

  Future<Order> createOrder({
    required String customerId,
    required List<OrderItem> items,
    String? notes,
  }) async {
    final created = await OrderService.instance.createOrder(
      customerId: customerId,
      items: items
          .map((item) => {
                'product_id': item.productId,
                'quantity': item.quantity,
                'unit_price': item.unitPrice,
              })
          .toList(),
      notes: notes,
    );
    return Order.fromJson(created);
  }
}
