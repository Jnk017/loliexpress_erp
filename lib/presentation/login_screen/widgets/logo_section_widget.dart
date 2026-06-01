import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Logo section widget for login screen
/// Displays official Loliexpress logo with brand colors
class LogoSectionWidget extends StatelessWidget {
  const LogoSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    final logoSize = (shortestSide * 0.22).clamp(88.0, 132.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Official Loliexpress Logo
        Image.asset(
          'assets/images/logo_loliexpress.png',
          width: logoSize,
          height: logoSize,
          fit: BoxFit.contain,
        ),
        SizedBox(height: 1.2.h),
        // Tagline
        Text(
          'GRANDIR ENSEMBLE',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
