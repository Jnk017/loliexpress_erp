import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/automation_rules_service.dart';

class BlockedUsersWidget extends StatefulWidget {
  const BlockedUsersWidget({super.key});

  @override
  State<BlockedUsersWidget> createState() => _BlockedUsersWidgetState();
}

class _BlockedUsersWidgetState extends State<BlockedUsersWidget> {
  final _rulesService = AutomationRulesService();
  List<Map<String, dynamic>> _blockedUsers = [];
  bool _isLoading = true;
  String _filterStatus = 'active';

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _rulesService.getBlockedUsers(status: _filterStatus);
      setState(() {
        _blockedUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _unblockUser(String blockingRecordId) async {
    try {
      await _rulesService.unblockUser(blockingRecordId);
      _loadBlockedUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User unblocked successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de terminer l’opération. Réessayez.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _blockedUsers.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadBlockedUsers,
                      child: ListView.builder(
                        padding: EdgeInsets.all(2.w),
                        itemCount: _blockedUsers.length,
                        itemBuilder: (context, index) =>
                            _buildBlockedUserCard(_blockedUsers[index]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      color: Colors.grey[100],
      child: Row(
        children: [
          Text('Status:', style: TextStyle(fontSize: 13.sp)),
          SizedBox(width: 2.w),
          Expanded(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _filterStatus,
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Active Blocks')),
                DropdownMenuItem(
                    value: 'expired', child: Text('Expired Blocks')),
                DropdownMenuItem(
                    value: 'manually_removed', child: Text('Manually Removed')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _filterStatus = value);
                  _loadBlockedUsers();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedUserCard(Map<String, dynamic> record) {
    final user = record['user'] ?? {};
    final userName = user['full_name'] ?? 'Unknown User';
    final userEmail = user['email'] ?? '';
    final avatarUrl = user['avatar_url'] as String?;
    final blockingReason = record['blocking_reason'] ?? 'unknown';
    final blockedAt = DateTime.parse(
        record['blocked_at'] ?? DateTime.now().toIso8601String());
    final unblockAt = record['unblock_at'] != null
        ? DateTime.parse(record['unblock_at'])
        : null;
    final status = record['blocking_status'] ?? 'active';
    final notes = record['notes'] ?? '';
    final rule = record['rule']?['rule_name'];

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: TextStyle(
                            fontSize: 15.sp, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        userEmail,
                        style:
                            TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
                Icons.warning_amber, 'Reason', _formatReason(blockingReason)),
            if (rule != null) _buildInfoRow(Icons.rule, 'Rule', rule),
            _buildInfoRow(
                Icons.access_time, 'Blocked', _formatDateTime(blockedAt)),
            if (unblockAt != null)
              _buildInfoRow(
                Icons.schedule,
                'Auto-Unblock',
                _formatDateTime(unblockAt),
              ),
            if (notes.isNotEmpty) ...[
              SizedBox(height: 1.h),
              Text('Notes:',
                  style:
                      TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600)),
              Text(notes,
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[700])),
            ],
            if (status == 'active') ...[
              SizedBox(height: 2.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _unblockUser(record['id']),
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Unblock User'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          SizedBox(width: 2.w),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final colors = {
      'active': Colors.red,
      'expired': Colors.orange,
      'manually_removed': Colors.green,
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: (colors[status] ?? Colors.grey).withAlpha(51),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase().replaceAll('_', ' '),
        style: TextStyle(
          fontSize: 10.sp,
          color: colors[status] ?? Colors.grey,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatReason(String reason) {
    return reason
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.isEmpty ? word : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.block, size: 80, color: Colors.grey[300]),
          SizedBox(height: 2.h),
          Text(
            _filterStatus == 'active' ? 'No Active Blocks' : 'No Blocked Users',
            style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600]),
          ),
          SizedBox(height: 1.h),
          Text(
            'User blocking records will appear here',
            style: TextStyle(fontSize: 13.sp, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
