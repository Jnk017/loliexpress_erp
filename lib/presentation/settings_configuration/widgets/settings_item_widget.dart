import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SettingsItemWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const SettingsItemWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: colors.onPrimaryContainer, size: 20.sp),
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 11.sp, color: colors.onSurfaceVariant),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
