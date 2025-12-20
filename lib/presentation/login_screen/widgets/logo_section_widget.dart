import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';


/// Logo section widget for login screen
/// Displays official Loliexpress logo with brand colors
class LogoSectionWidget extends StatelessWidget {
  const LogoSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Official Loliexpress Logo
        Image.asset(
          'assets/images/1-1764550821958.png',
          width: 35.w,
          height: 35.w,
          fit: BoxFit.contain,
        ),
        SizedBox(height: 2.h),
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
