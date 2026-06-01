import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loliexpress_erp/presentation/login_screen/login_screen.dart';
import 'package:sizer/sizer.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('forgot password opens OTP dialog', (tester) async {
    await tester.pumpWidget(
      Sizer(
        builder: (context, orientation, screenType) {
          return const MaterialApp(home: LoginScreen());
        },
      ),
    );

    await tester.tap(find.text('Mot de passe oublié ? Réinitialiser par OTP'));
    await tester.pumpAndSettle();

    expect(find.text('Réinitialisation par OTP'), findsOneWidget);
    expect(
      find.text('Entrez votre email pour recevoir un code OTP à 6 chiffres.'),
      findsOneWidget,
    );
    expect(find.text('Envoyer le code'), findsOneWidget);
  });
}
