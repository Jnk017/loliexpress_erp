import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../services/investigation_workspace_service.dart';

class TasksKanbanWidget extends StatefulWidget {
  final String incidentId;

  const TasksKanbanWidget({super.key, required this.incidentId});

  @override
  State<TasksKanbanWidget> createState() => _TasksKanbanWidgetState();
}

class _TasksKanbanWidgetState extends State<TasksKanbanWidget> {
  final _workspaceService = InvestigationWorkspaceService();
  Map<String, List<Map<String, dynamic>>> _tasksByStatus = {
    'assigned': [],
    'in_progress': [],
    'review': [],
    'complete': [],
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await _workspaceService.getTasks(widget.incidentId);
      final grouped = <String, List<Map<String, dynamic>>>{
        'assigned': [],
        'in_progress': [],
        'review': [],
        'complete': [],
      };

      for (final task in tasks) {
        final status = task['status'] as String;
        grouped[status]?.add(task);
      }

      setState(() {
        _tasksByStatus = grouped;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getColumnTitle(String status) {
    switch (status) {
      case 'assigned':
        return 'Assigned';
      case 'in_progress':
        return 'In Progress';
      case 'review':
        return 'Review';
      case 'complete':
        return 'Complete';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'assigned':
        return Colors.grey[700]!;
      case 'in_progress':
        return Colors.blue[700]!;
      case 'review':
        return Colors.amber[700]!;
      case 'complete':
        return Colors.green[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.all(3.w),
      itemCount: _tasksByStatus.keys.length,
      itemBuilder: (context, index) {
        final status = _tasksByStatus.keys.elementAt(index);
        final tasks = _tasksByStatus[status]!;

        return Container(
          width: 80.w,
          margin: EdgeInsets.only(right: 3.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getColumnTitle(status),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(status),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${tasks.length}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2.h),
              Expanded(
                child: ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, taskIndex) {
                    final task = tasks[taskIndex];
                    final assignedTo =
                        task['assigned_to'] as Map<String, dynamic>?;

                    return Container(
                      margin: EdgeInsets.only(bottom: 2.h),
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withAlpha(26),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (task['priority'] != null && task['priority'] > 0)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 2.w,
                                vertical: 0.5.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Priority ${task['priority']}',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                              ),
                            ),
                          SizedBox(height: 1.h),
                          Text(
                            task['title'],
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (task['description'] != null) ...[
                            SizedBox(height: 1.h),
                            Text(
                              task['description'],
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          SizedBox(height: 2.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (assignedTo != null)
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.blue[100],
                                      backgroundImage:
                                          assignedTo['avatar_url'] != null
                                              ? NetworkImage(
                                                  assignedTo['avatar_url'])
                                              : null,
                                      child: assignedTo['avatar_url'] == null
                                          ? Text(
                                              assignedTo['full_name']?[0]
                                                      ?.toUpperCase() ??
                                                  'U',
                                              style: TextStyle(
                                                fontSize: 10.sp,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue[700],
                                              ),
                                            )
                                          : null,
                                    ),
                                    SizedBox(width: 2.w),
                                    Text(
                                      assignedTo['full_name'] ?? 'Unknown',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: Colors.grey[600],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              if (task['due_date'] != null)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 12.sp,
                                      color: Colors.grey[600],
                                    ),
                                    SizedBox(width: 1.w),
                                    Text(
                                      DateFormat('MMM dd').format(
                                        DateTime.parse(task['due_date']),
                                      ),
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
