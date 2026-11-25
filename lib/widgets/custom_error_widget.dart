import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import 'screen_state_view.dart';

class CustomErrorWidget extends StatelessWidget {
  const CustomErrorWidget({
    super.key,
    this.errorDetails,
    this.errorMessage,
  });

  final FlutterErrorDetails? errorDetails;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ScreenStateView(
        icon: Icons.error_outline,
        message: 'Une erreur est survenue. Revenez à l’écran précédent.',
        actionLabel: 'Retour',
        isError: true,
        onAction: () {
          final navigator = Navigator.of(context);
          if (navigator.canPop()) {
            navigator.pop();
          } else {
            navigator.pushNamed(AppRoutes.initial);
          }
        },
      ),
    ),
  );
}
