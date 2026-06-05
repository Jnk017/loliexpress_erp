import 'package:flutter_test/flutter_test.dart';
import 'package:loliexpress_erp/services/delivery_service.dart';

void main() {
  test('rejects delivery status writes that bypass confirm_delivery', () async {
    await expectLater(
      DeliveryService().updateDeliveryStatus('delivery', 'in_transit'),
      throwsArgumentError,
    );
  });
}
