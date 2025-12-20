import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/automation_rules_service.dart';

class RulesListWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onEditRule;

  const RulesListWidget({super.key, required this.onEditRule});

  @override
  State<RulesListWidget> createState() => _RulesListWidgetState();
}

class _RulesListWidgetState extends State<RulesListWidget> {
  final _rulesService = AutomationRulesService();
  List<Map<String, dynamic>> _rules = [];
  bool _isLoading = true;
  String? _filterTriggerType;

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  Future<void> _loadRules() async {
    setState(() => _isLoading = true);
    try {
      final rules = await _rulesService.getAutomationRules(
        triggerType: _filterTriggerType,
      );
      setState(() {
        _rules = rules;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleRuleStatus(String ruleId, bool currentStatus) async {
    try {
      await _rulesService.toggleRuleStatus(ruleId, !currentStatus);
      _loadRules();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to toggle rule: $e')),
        );
      }
    }
  }

  Future<void> _deleteRule(String ruleId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Rule'),
        content:
            const Text('Are you sure you want to delete this automation rule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _rulesService.deleteAutomationRule(ruleId);
        _loadRules();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete rule: $e')),
          );
        }
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
              : _rules.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadRules,
                      child: ListView.builder(
                        padding: EdgeInsets.all(2.w),
                        itemCount: _rules.length,
                        itemBuilder: (context, index) =>
                            _buildRuleCard(_rules[index]),
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
          Text('Filter by:', style: TextStyle(fontSize: 13.sp)),
          SizedBox(width: 2.w),
          Expanded(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _filterTriggerType,
              hint: const Text('All Trigger Types'),
              items: [
                const DropdownMenuItem(
                    value: null, child: Text('All Trigger Types')),
                const DropdownMenuItem(
                    value: 'anomaly_detected', child: Text('Anomaly Detected')),
                const DropdownMenuItem(
                    value: 'failed_login_threshold',
                    child: Text('Failed Login')),
                const DropdownMenuItem(
                    value: 'risk_score_exceeded', child: Text('Risk Score')),
                const DropdownMenuItem(
                    value: 'repeated_violation',
                    child: Text('Repeated Violation')),
              ],
              onChanged: (value) {
                setState(() => _filterTriggerType = value);
                _loadRules();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleCard(Map<String, dynamic> rule) {
    final isActive = rule['is_active'] == true;
    final triggerType = rule['trigger_type'] ?? 'unknown';
    final priority = rule['priority'] ?? 0;
    final createdBy = rule['created_by']?['full_name'] ?? 'Unknown';

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.green.withAlpha(26)
                  : Colors.grey.withAlpha(26),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? Icons.check_circle : Icons.pause_circle,
                  color: isActive ? Colors.green : Colors.grey,
                  size: 28,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rule['rule_name'] ?? 'Unnamed Rule',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Priority: $priority | By: $createdBy',
                        style:
                            TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isActive,
                  onChanged: (value) => _toggleRuleStatus(rule['id'], isActive),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule['description'] ?? 'No description',
                  style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 1.h),
                _buildTriggerTypeBadge(triggerType),
                SizedBox(height: 1.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => widget.onEditRule(rule),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                    ),
                    TextButton.icon(
                      onPressed: () => _deleteRule(rule['id']),
                      icon:
                          const Icon(Icons.delete, size: 18, color: Colors.red),
                      label: const Text('Delete',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTriggerTypeBadge(String triggerType) {
    final badges = {
      'anomaly_detected': {'label': 'Anomaly', 'color': Colors.orange},
      'failed_login_threshold': {'label': 'Failed Login', 'color': Colors.red},
      'risk_score_exceeded': {'label': 'Risk Score', 'color': Colors.purple},
      'repeated_violation': {'label': 'Violation', 'color': Colors.pink},
      'time_based': {'label': 'Time-Based', 'color': Colors.blue},
    };

    final badgeData =
        badges[triggerType] ?? {'label': triggerType, 'color': Colors.grey};

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: (badgeData['color'] as Color).withAlpha(51),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Trigger: ${badgeData['label']}',
        style: TextStyle(
          fontSize: 11.sp,
          color: badgeData['color'] as Color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rule_outlined, size: 80, color: Colors.grey[300]),
          SizedBox(height: 2.h),
          Text(
            'No Automation Rules',
            style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600]),
          ),
          SizedBox(height: 1.h),
          Text(
            'Create your first rule to automate security responses',
            style: TextStyle(fontSize: 13.sp, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
