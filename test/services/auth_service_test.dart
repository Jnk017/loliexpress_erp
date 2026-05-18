import 'package:flutter_test/flutter_test.dart';
import 'package:loliexpress_erp/services/auth_service.dart';

void main() {
  group('AuthService', () {
    test('instance returns singleton', () {
      final a = AuthService.instance;
      final b = AuthService.instance;
      expect(identical(a, b), isTrue);
    });
  });
}
