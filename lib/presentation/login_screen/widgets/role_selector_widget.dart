import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Role selector widget for login screen
/// Allows users to select their access level
class RoleSelectorWidget extends StatelessWidget {
  final String? selectedRole;
  final ValueChanged<String?> onRoleChanged;
  final String? errorText;

  const RoleSelectorWidget({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
    this.errorText,
  });

  static const List<Map<String, dynamic>> roles = [
    {
      'value': 'admin',
      'label': 'Administrateur',
      'icon': 'admin_panel_settings',
    },
    {
      'value': 'sales',
      'label': 'Représentant Commercial',
      'icon': 'person',
    },
    {
      'value': 'warehouse',
      'label': 'Personnel Entrepôt',
      'icon': 'warehouse',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rôle',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: errorText != null
                  ? theme.colorScheme.error
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedRole,
              isExpanded: true,
              hint: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'person_outline',
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    'Sélectionnez votre rôle',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              icon: Padding(
                padding: EdgeInsets.only(right: 3.w),
                child: CustomIconWidget(
                  iconName: 'arrow_drop_down',
                  size: 24,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              borderRadius: BorderRadius.circular(8),
              items: roles.map((role) {
                return DropdownMenuItem<String>(
                  value: role['value'] as String,
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: role['icon'] as String,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Text(
                          role['label'] as String,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onRoleChanged,
            ),
          ),
        ),
        if (errorText != null) ...[
          SizedBox(height: 0.5.h),
          Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: Text(
              errorText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
