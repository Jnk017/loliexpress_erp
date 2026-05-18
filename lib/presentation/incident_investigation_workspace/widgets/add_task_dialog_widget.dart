import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../services/investigation_workspace_service.dart';
import '../../../services/supabase_service.dart';

class AddTaskDialogWidget extends StatefulWidget {
  final String incidentId;
  final VoidCallback onTaskAdded;

  const AddTaskDialogWidget({
    super.key,
    required this.incidentId,
    required this.onTaskAdded,
  });

  @override
  State<AddTaskDialogWidget> createState() => _AddTaskDialogWidgetState();
}

class _AddTaskDialogWidgetState extends State<AddTaskDialogWidget> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _workspaceService = InvestigationWorkspaceService();

  List<Map<String, dynamic>> _teamMembers = [];
  String? _selectedAssignee;
  int _priority = 0;
  DateTime? _dueDate;
  bool _isLoading = false;
  bool _isLoadingMembers = true;

  @override
  void initState() {
    super.initState();
    _loadTeamMembers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadTeamMembers() async {
    try {
      final members = await _workspaceService.getTeamMembers(widget.incidentId);
      setState(() {
        _teamMembers = members;
        _isLoadingMembers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMembers = false;
      });
    }
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      setState(() {
        _dueDate = date;
      });
    }
  }

  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUserId = SupabaseService.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _workspaceService.createTask(
        incidentId: widget.incidentId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        assignedTo: _selectedAssignee,
        createdBy: currentUserId,
        priority: _priority,
        dueDate: _dueDate,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onTaskAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add task: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Investigation Task'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Task title is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 2.h),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 2.h),
              if (!_isLoadingMembers)
                DropdownButtonFormField<String>(
                  value: _selectedAssignee,
                  decoration: const InputDecoration(
                    labelText: 'Assign To',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Unassigned'),
                    ),
                    ..._teamMembers.map((member) {
                      final profile =
                          member['user_profiles'] as Map<String, dynamic>?;
                      return DropdownMenuItem(
                        value: member['user_id'],
                        child: Text(profile?['full_name'] ?? 'Unknown'),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedAssignee = value;
                    });
                  },
                ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Priority',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        DropdownButtonFormField<int>(
                          value: _priority,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(
                                value: 0, child: Text('Normal')),
                            const DropdownMenuItem(
                                value: 1, child: Text('High')),
                            const DropdownMenuItem(
                                value: 2, child: Text('Urgent')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _priority = value ?? 0;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Due Date',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        OutlinedButton.icon(
                          onPressed: _selectDueDate,
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            _dueDate != null
                                ? DateFormat('MMM dd, yyyy').format(_dueDate!)
                                : 'Select',
                            style: TextStyle(fontSize: 12.sp),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitTask,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add Task'),
        ),
      ],
    );
  }
}