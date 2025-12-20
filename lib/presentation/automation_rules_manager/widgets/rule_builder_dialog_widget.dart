import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/automation_rules_service.dart';

class RuleBuilderDialogWidget extends StatefulWidget {
  final Map<String, dynamic>? existingRule;
  final VoidCallback onRuleSaved;

  const RuleBuilderDialogWidget({
    super.key,
    this.existingRule,
    required this.onRuleSaved,
  });

  @override
  State<RuleBuilderDialogWidget> createState() =>
      _RuleBuilderDialogWidgetState();
}

class _RuleBuilderDialogWidgetState extends State<RuleBuilderDialogWidget> {
  final _formKey = GlobalKey<FormState>();
  final _rulesService = AutomationRulesService();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priorityController;

  String _selectedTriggerType = 'anomaly_detected';
  List<Map<String, dynamic>> _conditions = [];
  List<Map<String, dynamic>> _actions = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.existingRule?['rule_name'] ?? '');
    _descriptionController =
        TextEditingController(text: widget.existingRule?['description'] ?? '');
    _priorityController = TextEditingController(
        text: widget.existingRule?['priority']?.toString() ?? '50');

    if (widget.existingRule != null) {
      _selectedTriggerType =
          widget.existingRule!['trigger_type'] ?? 'anomaly_detected';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priorityController.dispose();
    super.dispose();
  }

  Future<void> _saveRule() async {
    if (!_formKey.currentState!.validate()) return;
    if (_conditions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one condition')),
      );
      return;
    }
    if (_actions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one action')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _rulesService.createAutomationRule(
        ruleName: _nameController.text,
        description: _descriptionController.text,
        triggerType: _selectedTriggerType,
        conditions: _conditions,
        actions: _actions,
        priority: int.tryParse(_priorityController.text) ?? 50,
      );
      widget.onRuleSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save rule: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _addCondition() {
    setState(() {
      _conditions.add({
        'condition_field': 'severity',
        'condition_operator': 'equals',
        'condition_value': 'high',
        'logical_operator': 'AND',
      });
    });
  }

  void _removeCondition(int index) {
    setState(() => _conditions.removeAt(index));
  }

  void _addAction() {
    setState(() {
      _actions.add({
        'action_type': 'send_notification',
        'action_parameters': {},
        'execution_order': _actions.length,
      });
    });
  }

  void _removeAction(int index) {
    setState(() => _actions.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.all(4.w),
      child: Container(
        constraints: BoxConstraints(maxHeight: 80.h, maxWidth: 95.w),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.all(4.w),
                  children: [
                    _buildBasicInfoSection(),
                    SizedBox(height: 2.h),
                    _buildConditionsSection(),
                    SizedBox(height: 2.h),
                    _buildActionsSection(),
                  ],
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.rule, color: Colors.white),
          SizedBox(width: 2.w),
          Text(
            widget.existingRule != null ? 'Edit Rule' : 'Create New Rule',
            style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Basic Information',
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 1.h),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Rule Name',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value?.isEmpty == true ? 'Required' : null,
        ),
        SizedBox(height: 1.h),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        SizedBox(height: 1.h),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedTriggerType,
                decoration: const InputDecoration(
                  labelText: 'Trigger Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'anomaly_detected',
                      child: Text('Anomaly Detected')),
                  DropdownMenuItem(
                      value: 'failed_login_threshold',
                      child: Text('Failed Login Threshold')),
                  DropdownMenuItem(
                      value: 'risk_score_exceeded',
                      child: Text('Risk Score Exceeded')),
                  DropdownMenuItem(
                      value: 'repeated_violation',
                      child: Text('Repeated Violation')),
                  DropdownMenuItem(
                      value: 'time_based', child: Text('Time-Based')),
                ],
                onChanged: (value) {
                  if (value != null)
                    setState(() => _selectedTriggerType = value);
                },
              ),
            ),
            SizedBox(width: 2.w),
            SizedBox(
              width: 20.w,
              child: TextFormField(
                controller: _priorityController,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConditionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Conditions (IF)',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: _addCondition,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        if (_conditions.isEmpty)
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('No conditions added'),
          )
        else
          ..._conditions.asMap().entries.map((entry) {
            final index = entry.key;
            final condition = entry.value;
            return Card(
              margin: EdgeInsets.only(bottom: 1.h),
              child: Padding(
                padding: EdgeInsets.all(2.w),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: condition['condition_field'],
                            decoration: const InputDecoration(
                                labelText: 'Field', isDense: true),
                            items: const [
                              DropdownMenuItem(
                                  value: 'severity', child: Text('Severity')),
                              DropdownMenuItem(
                                  value: 'category', child: Text('Category')),
                              DropdownMenuItem(
                                  value: 'risk_score',
                                  child: Text('Risk Score')),
                              DropdownMenuItem(
                                  value: 'failed_attempts',
                                  child: Text('Failed Attempts')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _conditions[index]
                                    ['condition_field'] = value);
                              }
                            },
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: condition['condition_operator'],
                            decoration: const InputDecoration(
                                labelText: 'Operator', isDense: true),
                            items: const [
                              DropdownMenuItem(
                                  value: 'equals', child: Text('Equals')),
                              DropdownMenuItem(
                                  value: 'greater_than',
                                  child: Text('Greater Than')),
                              DropdownMenuItem(
                                  value: 'less_than', child: Text('Less Than')),
                              DropdownMenuItem(
                                  value: 'contains', child: Text('Contains')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _conditions[index]
                                    ['condition_operator'] = value);
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeCondition(index),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    TextFormField(
                      initialValue: condition['condition_value'],
                      decoration: const InputDecoration(
                          labelText: 'Value', isDense: true),
                      onChanged: (value) {
                        _conditions[index]['condition_value'] = value;
                      },
                    ),
                    if (index < _conditions.length - 1)
                      DropdownButtonFormField<String>(
                        initialValue: condition['logical_operator'],
                        decoration: const InputDecoration(
                            labelText: 'Logic', isDense: true),
                        items: const [
                          DropdownMenuItem(value: 'AND', child: Text('AND')),
                          DropdownMenuItem(value: 'OR', child: Text('OR')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() =>
                                _conditions[index]['logical_operator'] = value);
                          }
                        },
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Actions (THEN)',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: _addAction,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        if (_actions.isEmpty)
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('No actions added'),
          )
        else
          ..._actions.asMap().entries.map((entry) {
            final index = entry.key;
            final action = entry.value;
            return Card(
              margin: EdgeInsets.only(bottom: 1.h),
              child: Padding(
                padding: EdgeInsets.all(2.w),
                child: Row(
                  children: [
                    Text('${index + 1}.',
                        style: TextStyle(
                            fontSize: 14.sp, fontWeight: FontWeight.bold)),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: action['action_type'],
                        decoration: const InputDecoration(
                            labelText: 'Action Type', isDense: true),
                        items: const [
                          DropdownMenuItem(
                              value: 'send_notification',
                              child: Text('Send Notification')),
                          DropdownMenuItem(
                              value: 'block_user_temporary',
                              child: Text('Block User (Temporary)')),
                          DropdownMenuItem(
                              value: 'block_user_permanent',
                              child: Text('Block User (Permanent)')),
                          DropdownMenuItem(
                              value: 'escalate_to_admin',
                              child: Text('Escalate to Admin')),
                          DropdownMenuItem(
                              value: 'generate_report',
                              child: Text('Generate Report')),
                          DropdownMenuItem(
                              value: 'lock_module', child: Text('Lock Module')),
                          DropdownMenuItem(
                              value: 'enable_detailed_logging',
                              child: Text('Enable Detailed Logging')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(
                                () => _actions[index]['action_type'] = value);
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeAction(index),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          SizedBox(width: 2.w),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveRule,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save Rule'),
          ),
        ],
      ),
    );
  }
}
