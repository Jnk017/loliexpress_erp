import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/investigation_workspace_service.dart';

class WorkspaceHeaderWidget extends StatefulWidget {
  final String incidentId;
  final String incidentTitle;
  final String severity;
  final bool hasUpdate;

  const WorkspaceHeaderWidget({
    super.key,
    required this.incidentId,
    required this.incidentTitle,
    required this.severity,
    required this.hasUpdate,
  });

  @override
  State<WorkspaceHeaderWidget> createState() => _WorkspaceHeaderWidgetState();
}

class _WorkspaceHeaderWidgetState extends State<WorkspaceHeaderWidget> {
  final _workspaceService = InvestigationWorkspaceService();
  List<Map<String, dynamic>> _teamMembers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeamMembers();
  }

  Future<void> _loadTeamMembers() async {
    try {
      final members = await _workspaceService.getTeamMembers(widget.incidentId);
      setState(() {
        _teamMembers = members;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getSeverityColor() {
    switch (widget.severity.toLowerCase()) {
      case 'critical':
        return Colors.red[700]!;
      case 'high':
        return Colors.orange[700]!;
      case 'medium':
        return Colors.amber[700]!;
      default:
        return Colors.blue[700]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'INC-${widget.incidentId.substring(0, 8)}',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 1.h,
                            ),
                            decoration: BoxDecoration(
                              color: _getSeverityColor().withAlpha(26),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.severity.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: _getSeverityColor(),
                              ),
                            ),
                          ),
                          if (widget.hasUpdate) ...[
                            SizedBox(width: 2.w),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        widget.incidentTitle,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!_isLoading && _teamMembers.isNotEmpty) ...[
              SizedBox(height: 2.h),
              Row(
                children: [
                  Text(
                    'Investigation Team:',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _teamMembers.length.clamp(0, 5),
                        itemBuilder: (context, index) {
                          final member = _teamMembers[index];
                          final profile =
                              member['user_profiles'] as Map<String, dynamic>?;
                          return Padding(
                            padding: EdgeInsets.only(right: 1.w),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.blue[100],
                              backgroundImage: profile?['avatar_url'] != null
                                  ? NetworkImage(profile!['avatar_url'])
                                  : null,
                              child: profile?['avatar_url'] == null
                                  ? Text(
                                      profile?['full_name']?[0]
                                              ?.toUpperCase() ??
                                          'U',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[700],
                                      ),
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  if (_teamMembers.length > 5)
                    Text(
                      '+${_teamMembers.length - 5}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
