import 'package:flutter_test/flutter_test.dart';
import 'package:loliexpress_erp/services/product_service.dart';

void main() {
  group('ProductService', () {
    test('instance returns singleton', () {
      final a = ProductService.instance;
      final b = ProductService.instance;
      expect(identical(a, b), isTrue);
    });
  });
}
