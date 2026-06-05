import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/order.dart';
import '../services/order_service.dart';

class OrderRepository {
  OrderRepository({SupabaseClient? client, OrderService? orderService})
      : _injectedClient = client,
        _orderService = orderService ?? OrderService(client: client);

  final SupabaseClient? _injectedClient;
  SupabaseClient get _client => _injectedClient ?? Supabase.instance.client;
  final OrderService _orderService;

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
    final created = await _orderService.createOrder(
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
