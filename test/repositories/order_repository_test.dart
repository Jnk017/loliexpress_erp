import 'package:flutter_test/flutter_test.dart';
import 'package:loliexpress_erp/models/order.dart';
import 'package:loliexpress_erp/repositories/order_repository.dart';
import 'package:loliexpress_erp/services/order_service.dart';

class FakeOrderService extends OrderService {
  Map<String, dynamic>? receivedItem;

  @override
  Future<Map<String, dynamic>> createOrder({
    required String customerId,
    required List<Map<String, dynamic>> items,
    String? notes,
    double? discount,
    String currency = 'CDF',
    double exchangeRate = 1,
    String paymentType = 'cash',
  }) async {
    receivedItem = items.single;
    return {
      'id': 'order-id',
      'order_number': 'ORD-2026-00001',
      'customer_id': customerId,
      'order_status': 'pending',
      'payment_status': 'pending',
      'subtotal': 25,
      'total_amount': 25,
      'currency': currency,
      'created_at': '2026-06-05T00:00:00Z',
    };
  }
}

void main() {
  test(
    'repository delegates order creation to the transactional service',
    () async {
      final service = FakeOrderService();
      final repository = OrderRepository(orderService: service);

      final order = await repository.createOrder(
        customerId: 'customer-id',
        items: const [
          OrderItem(
            productId: 'product-id',
            quantity: 2,
            unitPrice: 12.5,
            lineTotal: 25,
          ),
        ],
      );

      expect(order.orderNumber, 'ORD-2026-00001');
      expect(service.receivedItem, {
        'product_id': 'product-id',
        'quantity': 2,
        'unit_price': 12.5,
      });
    },
  );
}
