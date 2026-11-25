import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class UserCardWidget extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onResetPassword;

  const UserCardWidget({
    super.key,
    required this.user,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onResetPassword,
  });

  Color _getRoleColor(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return Colors.red;
      case 'SALES_REP':
        return Colors.blue;
      case 'WAREHOUSE_STAFF':
        return Colors.orange;
      case 'B2B_CUSTOMER':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatRole(String role) {
    return role.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = user['is_active'] ?? true;
    final roleColor = _getRoleColor(user['role'] ?? '');

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 25.0,
                    backgroundColor: roleColor.withAlpha(51),
                    child: user['avatar_url'] != null
                        ? ClipOval(
                            child: Image.network(
                              user['avatar_url'],
                              width: 50.0,
                              height: 50.0,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.person,
                                      size: 30.0, color: roleColor),
                            ),
                          )
                        : Icon(Icons.person, size: 30.0, color: roleColor),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['full_name'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          user['email'] ?? '',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Icon(Icons.badge_outlined,
                      size: 16.0, color: Colors.grey[600]),
                  SizedBox(width: 1.w),
                  Text(
                    _formatRole(user['role'] ?? ''),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: roleColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (user['phone'] != null) ...[
                    SizedBox(width: 4.w),
                    Icon(Icons.phone_outlined,
                        size: 16.0, color: Colors.grey[600]),
                    SizedBox(width: 1.w),
                    Expanded(
                      child: Text(
                        user['phone'],
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[700],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              if (user['company_name'] != null) ...[
                SizedBox(height: 1.h),
                Row(
                  children: [
                    Icon(Icons.business_outlined,
                        size: 16.0, color: Colors.grey[600]),
                    SizedBox(width: 1.w),
                    Expanded(
                      child: Text(
                        user['company_name'],
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[700],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 2.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 16.0),
                      label: const Text('Modifier'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1976D2),
                        side: const BorderSide(color: Color(0xFF1976D2)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 1.h),
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onResetPassword,
                      icon: const Icon(Icons.lock_reset, size: 16.0),
                      label: const Text('Réinitialiser'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 1.h),
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onToggleStatus,
                      icon: Icon(
                        isActive ? Icons.block : Icons.check_circle_outline,
                        size: 16.0,
                      ),
                      label: Text(isActive ? 'Disable' : 'Enable'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActive ? Colors.red : Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 1.h),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
