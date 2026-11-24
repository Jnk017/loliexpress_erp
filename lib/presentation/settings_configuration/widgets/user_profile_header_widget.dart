import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class UserProfileHeaderWidget extends StatelessWidget {
  final String name;
  final String email;
  final String role;
  final VoidCallback onEditProfile;

  const UserProfileHeaderWidget({
    super.key,
    required this.name,
    required this.email,
    required this.role,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30.sp,
              backgroundColor: colors.primaryContainer,
              foregroundColor: colors.onPrimaryContainer,
              child: const Icon(Icons.person_outline),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    email,
                    style: TextStyle(fontSize: 12.sp, color: colors.onSurfaceVariant),
                  ),
                  SizedBox(height: 0.5.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      role,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit, color: colors.onSurface),
              onPressed: onEditProfile,
            ),
          ],
        ),
      ),
    );
  }
}
