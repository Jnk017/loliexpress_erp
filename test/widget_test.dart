import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:loliexpress_erp/main.dart';

void main() {
  testWidgets('App should build without errors', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
