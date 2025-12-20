import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../services/audit_log_service.dart';
import './audit_log_details_dialog.dart';

class AuditLogCardWidget extends StatelessWidget {
  final AuditLogEntry auditLog;

  const AuditLogCardWidget({
    super.key,
    required this.auditLog,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: () => _showDetails(context),
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with timestamp and action badge
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 4.w,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          DateFormat('MMM dd, yyyy HH:mm')
                              .format(auditLog.createdAt),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: auditLog.actionColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(
                        color: auditLog.actionColor,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      auditLog.actionDisplay,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: auditLog.actionColor,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 1.5.h),

              // User info
              Row(
                children: [
                  CircleAvatar(
                    radius: 5.w,
                    backgroundColor:
                        Theme.of(context).primaryColor.withAlpha(26),
                    child: Text(
                      auditLog.userName.isNotEmpty
                          ? auditLog.userName[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auditLog.userName,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          auditLog.userEmail,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 1.5.h),

              // Module and change description
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.folder_outlined,
                          size: 4.w,
                          color: Theme.of(context).primaryColor,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          auditLog.moduleDisplay,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      auditLog.getChangeDescription(),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),

              // Footer with IP address and device info
              if (auditLog.ipAddress != null || auditLog.userAgent != null)
                Padding(
                  padding: EdgeInsets.only(top: 1.5.h),
                  child: Row(
                    children: [
                      if (auditLog.ipAddress != null) ...[
                        Icon(
                          Icons.computer_outlined,
                          size: 3.5.w,
                          color: Colors.grey[500],
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          auditLog.ipAddress!,
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(width: 3.w),
                      ],
                      if (auditLog.userAgent != null)
                        Expanded(
                          child: Text(
                            _getBrowserInfo(auditLog.userAgent!),
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getBrowserInfo(String userAgent) {
    if (userAgent.contains('Chrome')) return 'Chrome';
    if (userAgent.contains('Firefox')) return 'Firefox';
    if (userAgent.contains('Safari')) return 'Safari';
    if (userAgent.contains('Edge')) return 'Edge';
    return 'Unknown Browser';
  }

  void _showDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AuditLogDetailsDialog(auditLog: auditLog),
    );
  }
}
