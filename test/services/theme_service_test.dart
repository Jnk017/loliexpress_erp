import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loliexpress_erp/services/theme_service.dart';

void main() {
  group('ThemeService', () {
    test('instance returns singleton', () {
      final a = ThemeService.instance;
      final b = ThemeService.instance;
      expect(identical(a, b), isTrue);
    });

    test('default theme mode is light', () {
      expect(ThemeService.instance.themeMode, equals(ThemeMode.light));
    });

    test('isDarkMode returns false by default', () {
      expect(ThemeService.instance.isDarkMode, isFalse);
    });
  });
}
