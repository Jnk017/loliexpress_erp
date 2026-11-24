import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loliexpress_erp/presentation/settings_configuration/widgets/settings_item_widget.dart';
import 'package:loliexpress_erp/presentation/settings_configuration/widgets/settings_section_widget.dart';
import 'package:loliexpress_erp/theme/app_theme.dart';
import 'package:sizer/sizer.dart';

double _contrast(Color foreground, Color background) {
  final a = foreground.computeLuminance();
  final b = background.computeLuminance();
  return (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final brightness in Brightness.values) {
    testWidgets('settings text contrast in ${brightness.name}', (tester) async {
      final theme = brightness == Brightness.dark
          ? AppTheme.darkTheme
          : AppTheme.lightTheme;
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, screenType) => MaterialApp(
            theme: theme,
            home: const Scaffold(
              body: SettingsSectionWidget(
                title: 'Préférences',
                children: [
                  SettingsItemWidget(
                    icon: Icons.dark_mode,
                    title: 'Mode sombre',
                    subtitle: 'Changer de thème',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      final section = tester.widget<Text>(find.text('Préférences'));
      final subtitle = tester.widget<Text>(find.text('Changer de thème'));
      expect(_contrast(section.style!.color!, theme.scaffoldBackgroundColor),
          greaterThanOrEqualTo(4.5));
      expect(_contrast(subtitle.style!.color!, theme.cardColor),
          greaterThanOrEqualTo(4.5));
    });
  }
}
