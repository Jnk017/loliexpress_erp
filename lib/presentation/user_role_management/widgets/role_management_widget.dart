import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/user_management_service.dart';

class RoleManagementWidget extends StatefulWidget {
  final VoidCallback onRefresh;

  const RoleManagementWidget({
    Key? key,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<RoleManagementWidget> createState() => _RoleManagementWidgetState();
}

class _RoleManagementWidgetState extends State<RoleManagementWidget> {
  final UserManagementService _userService = UserManagementService();
  Map<String, List<Map<String, dynamic>>> _roleUsers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoleData();
  }

  Future<void> _loadRoleData() async {
    setState(() => _isLoading = true);
    try {
      final users = await _userService.getAllUsers();
      final roleMap = <String, List<Map<String, dynamic>>>{
        'admin': [],
        'sales': [],
        'warehouse': [],
      };

      for (var user in users) {
        final role = _normalizeRole(user['role'].toString());
        if (roleMap.containsKey(role)) {
          roleMap[role]!.add(user);
        }
      }

      setState(() {
        _roleUsers = roleMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading role data: $e')),
        );
      }
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'sales':
        return Colors.blue;
      case 'warehouse':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getRoleTitle(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrators';
      case 'sales':
        return 'Sales';
      case 'warehouse':
        return 'Warehouse Staff';
      default:
        return role.toUpperCase();
    }
  }

  String _getRoleDescription(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Full system access with user and configuration management';
      case 'sales':
        return 'Manage sales orders, customers, and assigned client accounts';
      case 'warehouse':
        return 'Handle inventory, stock movements, and deliveries';
      default:
        return '';
    }
  }

  List<String> _getRolePermissions(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return [
          'User Management',
          'System Configuration',
          'Financial Reports',
          'All Module Access',
          'Data Export',
        ];
      case 'sales':
        return [
          'Create Sales Orders',
          'Manage Customers',
          'View Assigned Accounts',
          'Generate Invoices',
          'Sales Reports',
        ];
      case 'warehouse':
        return [
          'Inventory Management',
          'Stock Movements',
          'Delivery Tracking',
          'Barcode Scanning',
          'Stock Reports',
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadRoleData,
            child: ListView(
              padding: EdgeInsets.all(3.w),
              children: [
                _buildRoleCard('admin'),
                SizedBox(height: 2.h),
                _buildRoleCard('sales'),
                SizedBox(height: 2.h),
                _buildRoleCard('warehouse'),
              ],
            ),
          );
  }

  Widget _buildRoleCard(String role) {
    final users = _roleUsers[role] ?? [];
    final color = _getRoleColor(role);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(
            _getRoleIcon(role),
            color: color,
            size: 24.0,
          ),
        ),
        title: Text(
          _getRoleTitle(role),
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          '${users.length} user${users.length != 1 ? 's' : ''}',
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getRoleDescription(role),
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Permissions:',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 1.h),
                ..._getRolePermissions(role).map(
                  (permission) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 0.5.h),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 16.0, color: color),
                        SizedBox(width: 2.w),
                        Text(
                          permission,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (users.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(
                    'Users with this role:',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  ...users.map(
                    (user) => ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 18.0,
                        backgroundColor: color.withAlpha(51),
                        child: Icon(Icons.person, size: 20.0, color: color),
                      ),
                      title: Text(
                        user['full_name'],
                        style: TextStyle(fontSize: 13.sp),
                      ),
                      subtitle: Text(
                        user['email'],
                        style: TextStyle(fontSize: 11.sp),
                      ),
                      trailing: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: user['is_active'] ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          user['is_active'] ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'sales':
        return Icons.business_center;
      case 'warehouse':
        return Icons.warehouse;
      default:
        return Icons.person;
    }
  }

  String _normalizeRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
      case 'comptable':
      case 'acheteur':
        return 'admin';
      case 'warehouse':
      case 'warehouse_staff':
        return 'warehouse';
      case 'sales':
      case 'sales_rep':
      case 'b2b_customer':
      default:
        return 'sales';
    }
  }
}
