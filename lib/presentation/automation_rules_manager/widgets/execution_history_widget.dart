import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/automation_rules_service.dart';

class ExecutionHistoryWidget extends StatefulWidget {
  const ExecutionHistoryWidget({super.key});

  @override
  State<ExecutionHistoryWidget> createState() => _ExecutionHistoryWidgetState();
}

class _ExecutionHistoryWidgetState extends State<ExecutionHistoryWidget> {
  final _rulesService = AutomationRulesService();
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final history = await _rulesService.getRuleExecutionHistory(limit: 100);
      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_history.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: EdgeInsets.all(2.w),
        itemCount: _history.length,
        itemBuilder: (context, index) => _buildHistoryCard(_history[index]),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> record) {
    final ruleName = record['rule']?['rule_name'] ?? 'Unknown Rule';
    final executedAt = DateTime.parse(
        record['executed_at'] ?? DateTime.now().toIso8601String());
    final status = record['execution_status'] ?? 'success';
    final errorMessage = record['error_message'] as String?;
    final actionsExecuted = record['actions_executed'] as List<dynamic>? ?? [];
    final user = record['user'];
    final userName = user?['full_name'] ?? 'Unknown User';

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  status == 'success' ? Icons.check_circle : Icons.error,
                  color: status == 'success' ? Colors.green : Colors.red,
                  size: 24,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ruleName,
                        style: TextStyle(
                            fontSize: 14.sp, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _formatDateTime(executedAt),
                        style:
                            TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            _buildInfoRow(Icons.person, 'Affected User', userName),
            _buildInfoRow(Icons.play_arrow, 'Actions',
                '${actionsExecuted.length} executed'),
            if (status != 'success' && errorMessage != null) ...[
              SizedBox(height: 1.h),
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 18),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        errorMessage,
                        style:
                            TextStyle(fontSize: 12.sp, color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (actionsExecuted.isNotEmpty) ...[
              SizedBox(height: 1.h),
              ExpansionTile(
                title: Text(
                  'View Actions',
                  style:
                      TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
                ),
                children: actionsExecuted.map((action) {
                  final actionType = action['action_type'] ?? 'unknown';
                  final executedAt = action['executed_at'] ?? '';
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.arrow_right, size: 18),
                    title: Text(
                      _formatActionType(actionType),
                      style: TextStyle(fontSize: 12.sp),
                    ),
                    subtitle: Text(
                      executedAt,
                      style:
                          TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.5.h),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
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

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatActionType(String type) {
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.isEmpty ? word : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[300]),
          SizedBox(height: 2.h),
          Text(
            'No Execution History',
            style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600]),
          ),
          SizedBox(height: 1.h),
          Text(
            'Rule execution records will appear here',
            style: TextStyle(fontSize: 13.sp, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
