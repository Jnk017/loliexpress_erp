import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loliexpress_erp/presentation/force_password_change/force_password_change_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('first-login gate requires matching passwords', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ForcePasswordChangeScreen()),
    );

    expect(find.text('Définissez votre mot de passe'), findsOneWidget);
    expect(find.text('Enregistrer et continuer'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nouveau mot de passe'),
      'long-password',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirmer le mot de passe'),
      'different-password',
    );
    await tester.tap(find.text('Enregistrer et continuer'));
    await tester.pump();

    expect(find.text('Les mots de passe ne correspondent pas.'), findsOneWidget);
  });
}
