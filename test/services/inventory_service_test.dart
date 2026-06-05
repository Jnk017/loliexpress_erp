import 'package:flutter_test/flutter_test.dart';
import 'package:loliexpress_erp/services/inventory_service.dart';

void main() {
  test('rejects unknown stock movement types before calling Supabase', () async {
    await expectLater(
      InventoryService().createStockMovement(
        productId: 'product',
        warehouseId: 'warehouse',
        quantity: 1,
        movementType: 'invalid',
      ),
      throwsArgumentError,
    );
  });
}
