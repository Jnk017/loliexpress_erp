import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

import '../../../services/investigation_workspace_service.dart';

class TimelineCorrelationsWidget extends StatefulWidget {
  final String incidentId;

  const TimelineCorrelationsWidget({super.key, required this.incidentId});

  @override
  State<TimelineCorrelationsWidget> createState() =>
      _TimelineCorrelationsWidgetState();
}

class _TimelineCorrelationsWidgetState
    extends State<TimelineCorrelationsWidget> {
  final _workspaceService = InvestigationWorkspaceService();
  List<Map<String, dynamic>> _timeline = [];
  String _selectedFilter = 'all';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTimeline();
  }

  Future<void> _loadTimeline() async {
    try {
      final timeline = await _workspaceService.getTimeline(widget.incidentId);
      setState(() {
        _timeline = timeline;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredTimeline() {
    if (_selectedFilter == 'all') return _timeline;
    return _timeline
        .where((e) => e['event_type'].toString().contains(_selectedFilter))
        .toList();
  }

  IconData _getEventIcon(String eventType) {
    if (eventType.contains('task')) return Icons.task_alt;
    if (eventType.contains('evidence')) return Icons.folder_special;
    if (eventType.contains('team')) return Icons.group;
    if (eventType.contains('message')) return Icons.chat;
    return Icons.event;
  }

  Color _getEventColor(String eventType) {
    if (eventType.contains('task')) return Colors.blue[700]!;
    if (eventType.contains('evidence')) return Colors.purple[700]!;
    if (eventType.contains('team')) return Colors.green[700]!;
    if (eventType.contains('message')) return Colors.orange[700]!;
    return Colors.grey[700]!;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredTimeline = _getFilteredTimeline();

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(3.w),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'All Events'),
                _buildFilterChip('task', 'Tasks'),
                _buildFilterChip('evidence', 'Evidence'),
                _buildFilterChip('team', 'Team'),
                _buildFilterChip('message', 'Messages'),
              ],
            ),
          ),
        ),
        Expanded(
          child: filteredTimeline.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timeline, size: 64, color: Colors.grey[400]),
                      SizedBox(height: 2.h),
                      Text(
                        'No timeline events',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(3.w),
                  itemCount: filteredTimeline.length,
                  itemBuilder: (context, index) {
                    final event = filteredTimeline[index];
                    final actor = event['actor'] as Map<String, dynamic>?;
                    final eventType = event['event_type'] as String;

                    return Padding(
                      padding: EdgeInsets.only(bottom: 2.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color:
                                      _getEventColor(eventType).withAlpha(26),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _getEventColor(eventType),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  _getEventIcon(eventType),
                                  color: _getEventColor(eventType),
                                  size: 20,
                                ),
                              ),
                              if (index < filteredTimeline.length - 1)
                                Container(
                                  width: 2,
                                  height: 60,
                                  color: Colors.grey[300],
                                ),
                            ],
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Container(
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
                                  Text(
                                    event['description'],
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 1.h),
                                  Row(
                                    children: [
                                      if (actor != null) ...[
                                        CircleAvatar(
                                          radius: 10,
                                          backgroundColor: Colors.blue[100],
                                          backgroundImage:
                                              actor['avatar_url'] != null
                                                  ? NetworkImage(
                                                      actor['avatar_url'])
                                                  : null,
                                          child: actor['avatar_url'] == null
                                              ? Text(
                                                  actor['full_name']?[0]
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
                                          actor['full_name'] ?? 'System',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        SizedBox(width: 2.w),
                                      ],
                                      Text(
                                        DateFormat('MMM dd, HH:mm').format(
                                          DateTime.parse(event['created_at']),
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
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String filter, String label) {
    final isSelected = _selectedFilter == filter;
    return Padding(
      padding: EdgeInsets.only(right: 2.w),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = filter;
          });
        },
        selectedColor: Colors.blue[700],
        backgroundColor: Colors.grey[200],
        labelStyle: TextStyle(
          fontSize: 12.sp,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : Colors.grey[700],
        ),
      ),
    );
  }
}
