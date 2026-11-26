import 'package:flutter/material.dart';

class ScreenStateView extends StatelessWidget {
  const ScreenStateView({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.isError = false,
  });

  const ScreenStateView.error({
    super.key,
    required this.message,
    required this.onAction,
  }) : icon = Icons.error_outline,
       actionLabel = 'Réessayer',
       isError = true;

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: isError ? colors.error : colors.onSurfaceVariant),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 12),
              FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
