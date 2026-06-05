import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loliexpress_erp/presentation/user_role_management/widgets/create_user_dialog.dart';
import 'package:sizer/sizer.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('admin user creation uses an invitation instead of a password', (
    tester,
  ) async {
    await tester.pumpWidget(
      Sizer(
        builder: (context, orientation, screenType) {
          return const MaterialApp(home: Scaffold(body: CreateUserDialog()));
        },
      ),
    );

    expect(find.textContaining('lien sécurisé d’invitation'), findsOneWidget);
    expect(find.text('Password *'), findsNothing);
    expect(find.byIcon(Icons.lock_outline), findsNothing);
  });
}
