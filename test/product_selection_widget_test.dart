import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loliexpress_erp/presentation/sales_order_processing/widgets/product_selection_section.dart';
import 'package:sizer/sizer.dart';

void main() {
  testWidgets('renders catalogue products without legacy discount data',
      (tester) async {
    Map<String, dynamic> product(String name, int? stock) => {
          'name': name,
          'code': name,
          'price': 10.0,
          'currency': 'CDF',
          'stock': stock,
          'image': 'assets/images/logo_loliexpress.png',
          'semanticLabel': name,
        };

    await tester.pumpWidget(Sizer(
      builder: (context, orientation, screenType) => MaterialApp(
        home: Scaffold(
          body: ProductSelectionSection(
            products: [product('Produit A', 3), product('Produit B', null)],
            onProductAdd: (_) {},
            onBarcodeScan: () {},
          ),
        ),
      ),
    ));

    expect(find.text('Catalogue 10.00 CDF'), findsNWidgets(2));
    expect(find.text('3 en stock'), findsOneWidget);
    expect(find.text('Stock non communiqué'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
