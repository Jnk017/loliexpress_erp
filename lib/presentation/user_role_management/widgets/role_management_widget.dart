import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/user_management_service.dart';

class RoleManagementWidget extends StatefulWidget {
  final VoidCallback onRefresh;

  const RoleManagementWidget({
    super.key,
    required this.onRefresh,
  });

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
        'commercial_staff': [],
        'warehouse_staff': [],
        'comptable': [],
        'acheteur': [],
        'delivery_agent': [],
        'client_b2b': [],
      };

      for (var user in users) {
        final role = user['role'].toString().toLowerCase();
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
      case 'commercial_staff':
        return Colors.blue;
      case 'warehouse_staff':
        return Colors.orange;
      case 'comptable':
        return Colors.purple;
      case 'acheteur':
        return Colors.teal;
      case 'delivery_agent':
        return Colors.indigo;
      case 'client_b2b':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getRoleTitle(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrators';
      case 'commercial_staff':
        return 'Sales Representatives';
      case 'warehouse_staff':
        return 'Warehouse Staff';
      case 'comptable':
        return 'Comptables';
      case 'acheteur':
        return 'Acheteurs';
      case 'delivery_agent':
        return 'Agents de livraison';
      case 'client_b2b':
        return 'B2B Customers';
      default:
        return role.toUpperCase();
    }
  }

  String _getRoleDescription(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Full system access with user and configuration management';
      case 'commercial_staff':
        return 'Manage sales orders, customers, and assigned client accounts';
      case 'warehouse_staff':
        return 'Handle inventory, stock movements, and deliveries';
      case 'comptable':
        return 'Finance management: expenses, payments, and financial reports';
      case 'acheteur':
        return 'Purchasing: supplier management and purchase orders';
      case 'delivery_agent':
        return 'Access assigned routes and confirm deliveries';
      case 'client_b2b':
        return 'View orders, track deliveries, and access portal features';
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
      case 'commercial_staff':
        return [
          'Create Sales Orders',
          'Manage Customers',
          'View Assigned Accounts',
          'Generate Invoices',
          'Sales Reports',
        ];
      case 'warehouse_staff':
        return [
          'Inventory Management',
          'Stock Movements',
          'Delivery Tracking',
          'Barcode Scanning',
          'Stock Reports',
        ];
      case 'comptable':
        return [
          'View Financial Dashboard',
          'Approve/Reject Expenses',
          'Process Payments',
          'Financial Reports',
          'View Receivables',
        ];
      case 'acheteur':
        return [
          'Manage Suppliers',
          'Create Purchase Orders',
          'View Inventory Levels',
          'Purchase Reports',
          'Supplier Invoices',
        ];
      case 'delivery_agent':
        return [
          'View Assigned Routes',
          'View Assigned Deliveries',
          'Confirm Deliveries',
          'Access Delivery Documents',
        ];
      case 'client_b2b':
        return [
          'View Own Orders',
          'Track Deliveries',
          'Access Documents',
          'Submit Support Tickets',
          'View Account Info',
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
                _buildRoleCard('commercial_staff'),
                SizedBox(height: 2.h),
                _buildRoleCard('warehouse_staff'),
                SizedBox(height: 2.h),
                _buildRoleCard('comptable'),
                SizedBox(height: 2.h),
                _buildRoleCard('acheteur'),
                SizedBox(height: 2.h),
                _buildRoleCard('delivery_agent'),
                SizedBox(height: 2.h),
                _buildRoleCard('client_b2b'),
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
      case 'commercial_staff':
        return Icons.business_center;
      case 'warehouse_staff':
        return Icons.warehouse;
      case 'comptable':
        return Icons.account_balance;
      case 'acheteur':
        return Icons.shopping_cart;
      case 'delivery_agent':
        return Icons.local_shipping;
      case 'client_b2b':
        return Icons.shopping_bag;
      default:
        return Icons.person;
    }
  }
}
