import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loliexpress_erp/main.dart';

void main() {
  testWidgets('App builds MaterialApp with correct title',
      (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    expect(find.byType(MaterialApp), findsOneWidget);

    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.title, equals('loliexpress_erp'));
  });

  testWidgets('App has light and dark themes configured',
      (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());

    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.theme, isNotNull);
    expect(app.darkTheme, isNotNull);
  });
}
