import 'package:supabase_flutter/supabase_flutter.dart';

class OrderService {
  static OrderService? _instance;
  static OrderService get instance => _instance ??= OrderService._();
  OrderService._() : _injectedClient = null;
  OrderService({SupabaseClient? client}) : _injectedClient = client;

  final SupabaseClient? _injectedClient;
  SupabaseClient get _client => _injectedClient ?? Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getOrders(
      {String? status,
      String? customerId,
      int limit = 50,
      int offset = 0}) async {
    try {
      var query = _client
          .from('sales_orders')
          .select('*, customers(company_name, contact_person)');
      if (status != null) query = query.eq('order_status', status);
      if (customerId != null) query = query.eq('customer_id', customerId);
      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Erreur lors du chargement des commandes: $e');
    }
  }

  Future<Map<String, dynamic>?> getOrderById(String id) async {
    try {
      return await _client
          .from('sales_orders')
          .select(
              '*, customers(company_name, contact_person), order_items(*, products(name, sku, unit_price))')
          .eq('id', id)
          .maybeSingle();
    } catch (e) {
      throw Exception('Erreur lors du chargement de la commande: $e');
    }
  }

  Future<double> getOrderUnitPrice({
    required String customerId,
    required String productId,
    String currency = 'CDF',
  }) async {
    final result = await _client.rpc('order_unit_price', params: {
      'p_customer_id': customerId,
      'p_product_id': productId,
      'p_currency': currency,
    });
    if (result is! num) {
      throw const FormatException('Tarif client invalide');
    }
    return result.toDouble();
  }

  Future<Map<String, dynamic>> issueInvoice({
    required String orderId,
    required DateTime dueDate,
    required bool homeDelivery,
    required double deliveryFee,
  }) async {
    final result = await _client.rpc('issue_order_invoice', params: {
      'p_order_id': orderId,
      'p_due_date': dueDate.toUtc().toIso8601String(),
      'p_home_delivery': homeDelivery,
      'p_delivery_fee': deliveryFee,
    });
    if (result is! Map) {
      throw const FormatException('Réponse de facturation invalide');
    }
    return Map<String, dynamic>.from(result);
  }

  Future<Map<String, dynamic>> createOrder({
    required String customerId,
    required List<Map<String, dynamic>> items,
    String? notes,
    double? discount,
    String currency = 'CDF',
    double? exchangeRate,
    String paymentType = 'cash',
  }) async {
    if (items.isEmpty) {
      throw ArgumentError.value(
        items,
        'items',
        'Une commande doit contenir au moins un article',
      );
    }

    try {
      final response = await _client.rpc(
        'create_order_with_items',
        params: {
          'p_customer_id': customerId,
          'p_items': items
              .map((item) => {
                    'product_id': item['product_id'],
                    'quantity': item['quantity'],
                    if (item['unit_price'] != null)
                      'unit_price': item['unit_price'],
                  })
              .toList(),
          'p_notes': notes,
          'p_currency': currency,
          'p_exchange_rate': exchangeRate,
          'p_payment_type': paymentType,
          'p_discount': discount ?? 0,
        },
      );
      if (response is! Map) {
        throw const FormatException('Réponse RPC de commande invalide');
      }
      return Map<String, dynamic>.from(response);
    } catch (e) {
      throw Exception('Erreur lors de la création de la commande: $e');
    }
  }

  Future<Map<String, dynamic>> updateOrderStatus(
      String orderId, String newStatus) async {
    try {
      final response = await _client.rpc(
        'transition_order_status',
        params: {
          'p_order_id': orderId,
          'p_new_status': newStatus,
        },
      );
      if (response is! Map) {
        throw const FormatException('Réponse RPC de statut invalide');
      }
      return Map<String, dynamic>.from(response);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du statut: $e');
    }
  }

  Future<Map<String, dynamic>> getOrderStats() async {
    try {
      final orders = await _client
          .from('sales_orders')
          .select('order_status, total_amount');
      int total = orders.length;
      int pending = 0, confirmed = 0, delivered = 0;
      double totalRevenue = 0;
      for (final o in orders) {
        switch (o['order_status']) {
          case 'pending':
            pending++;
            break;
          case 'confirmed':
            confirmed++;
            break;
          case 'delivered':
            delivered++;
            break;
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
