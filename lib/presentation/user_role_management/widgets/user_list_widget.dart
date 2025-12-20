import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/user_management_service.dart';
import './create_user_dialog.dart';
import './edit_user_dialog.dart';
import './user_card_widget.dart';

class UserListWidget extends StatefulWidget {
  final VoidCallback onRefresh;

  const UserListWidget({
    Key? key,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<UserListWidget> createState() => _UserListWidgetState();
}

class _UserListWidgetState extends State<UserListWidget> {
  final UserManagementService _userService = UserManagementService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  String _selectedRole = 'All';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _userService.getAllUsers();
      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _filteredUsers = _users.where((user) {
        final matchesSearch = user['full_name']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            user['email']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase());
        final matchesRole = _selectedRole == 'All' ||
            user['role'].toString().toUpperCase() ==
                _selectedRole.toUpperCase();
        return matchesSearch && matchesRole;
      }).toList();
    });
  }

  void _filterByRole(String role) {
    setState(() {
      _selectedRole = role;
      _filterUsers(_searchController.text);
    });
  }

  Future<void> _createUser() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const CreateUserDialog(),
    );
    if (result == true) {
      await _loadUsers();
      widget.onRefresh();
    }
  }

  Future<void> _editUser(Map<String, dynamic> user) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditUserDialog(user: user),
    );
    if (result == true) {
      await _loadUsers();
      widget.onRefresh();
    }
  }

  Future<void> _toggleUserStatus(Map<String, dynamic> user) async {
    try {
      await _userService.updateUserStatus(
        user['id'],
        !user['is_active'],
      );
      await _loadUsers();
      widget.onRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'User ${user['is_active'] ? 'deactivated' : 'activated'} successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating user: $e')),
        );
      }
    }
  }

  Future<void> _resetPassword(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text(
          'Send password reset email to ${user['email']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _userService.sendPasswordResetEmail(user['email']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset email sent successfully'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sending email: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(3.w),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: _filterUsers,
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFF1976D2)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: Color(0xFF1976D2)),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 1.5.h,
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildRoleChip('All'),
                    SizedBox(width: 2.w),
                    _buildRoleChip('ADMIN'),
                    SizedBox(width: 2.w),
                    _buildRoleChip('SALES_REP'),
                    SizedBox(width: 2.w),
                    _buildRoleChip('WAREHOUSE_STAFF'),
                    SizedBox(width: 2.w),
                    _buildRoleChip('B2B_CUSTOMER'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline,
                              size: 80.0, color: Colors.grey[400]),
                          SizedBox(height: 2.h),
                          Text(
                            'No users found',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadUsers,
                      child: ListView.builder(
                        padding: EdgeInsets.all(3.w),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return UserCardWidget(
                            user: user,
                            onEdit: () => _editUser(user),
                            onToggleStatus: () => _toggleUserStatus(user),
                            onResetPassword: () => _resetPassword(user),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildRoleChip(String role) {
    final isSelected = _selectedRole == role;
    return FilterChip(
      label: Text(
        role.replaceAll('_', ' '),
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF1976D2),
          fontSize: 12.sp,
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF1976D2),
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFF1976D2)),
      onSelected: (_) => _filterByRole(role),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
