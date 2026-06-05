import 'package:flutter_test/flutter_test.dart';
import 'package:loliexpress_erp/services/order_service.dart';

void main() {
  test(
    'createOrder rejects an empty item list before contacting Supabase',
    () async {
      await expectLater(
        OrderService().createOrder(customerId: 'customer', items: const []),
        throwsArgumentError,
      );
    },
  );
}
