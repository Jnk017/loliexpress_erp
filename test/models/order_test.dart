import 'package:flutter_test/flutter_test.dart';
import 'package:loliexpress_erp/models/order.dart';

void main() {
  group('Order model', () {
    test('maps database JSON into typed model', () {
      final order = Order.fromJson({
        'id': 'order-id',
        'order_number': 'ORD-2026-00001',
        'customer_id': 'customer-id',
        'order_status': 'pending',
        'payment_status': 'pending',
        'subtotal': 1000,
        'total_amount': 950,
        'currency': 'CDF',
        'created_at': '2026-05-31T00:00:00.000Z',
      });

      expect(order.orderNumber, 'ORD-2026-00001');
      expect(order.subtotal, 1000);
      expect(order.totalAmount, 950);
      expect(order.currency, 'CDF');
    });

    test('serializes order item with line_total column', () {
      const item = OrderItem(
        productId: 'product-id',
        quantity: 2,
        unitPrice: 500,
        lineTotal: 1000,
      );

      expect(item.toInsertJson('order-id'), {
        'order_id': 'order-id',
        'product_id': 'product-id',
        'quantity': 2,
        'unit_price': 500.0,
        'line_total': 1000.0,
      });
    });
  });
}
