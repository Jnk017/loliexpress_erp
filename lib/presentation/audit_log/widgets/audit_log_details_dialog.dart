import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../services/audit_log_service.dart';

class AuditLogDetailsDialog extends StatelessWidget {
  final AuditLogEntry auditLog;

  const AuditLogDetailsDialog({
    super.key,
    required this.auditLog,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Container(
        constraints: BoxConstraints(maxHeight: 80.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Audit Log Details',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoSection(
                      context,
                      'General Information',
                      [
                        _InfoRow('Action Type', auditLog.actionDisplay,
                            color: auditLog.actionColor),
                        _InfoRow('Module', auditLog.moduleDisplay),
                        _InfoRow(
                            'Timestamp',
                            DateFormat('MMM dd, yyyy HH:mm:ss')
                                .format(auditLog.createdAt)),
                        _InfoRow('Record ID', auditLog.recordId),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    _buildInfoSection(
                      context,
                      'User Information',
                      [
                        _InfoRow('Name', auditLog.userName),
                        _InfoRow('Email', auditLog.userEmail),
                        _InfoRow('User ID', auditLog.userId),
                      ],
                    ),
                    if (auditLog.ipAddress != null ||
                        auditLog.userAgent != null) ...[
                      SizedBox(height: 2.h),
                      _buildInfoSection(
                        context,
                        'Session Information',
                        [
                          if (auditLog.ipAddress != null)
                            _InfoRow('IP Address', auditLog.ipAddress!),
                          if (auditLog.userAgent != null)
                            _InfoRow('User Agent', auditLog.userAgent!,
                                maxLines: 3),
                        ],
                      ),
                    ],
                    if (auditLog.actionType.toLowerCase() == 'update') ...[
                      SizedBox(height: 2.h),
                      _buildChangesSection(context),
                    ],
                    if (auditLog.actionType.toLowerCase() == 'insert' &&
                        auditLog.newValues != null) ...[
                      SizedBox(height: 2.h),
                      _buildDataSection(
                          context, 'New Values', auditLog.newValues!),
                    ],
                    if (auditLog.actionType.toLowerCase() == 'delete' &&
                        auditLog.oldValues != null) ...[
                      SizedBox(height: 2.h),
                      _buildDataSection(
                          context, 'Deleted Values', auditLog.oldValues!),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(
      BuildContext context, String title, List<_InfoRow> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            children: rows.map((row) => _buildInfoRow(row)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(_InfoRow row) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30.w,
            child: Text(
              '${row.label}:',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              row.value,
              style: TextStyle(
                fontSize: 12.sp,
                color: row.color ?? Colors.grey[800],
                fontWeight:
                    row.color != null ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: row.maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangesSection(BuildContext context) {
    final changedFields = auditLog.getChangedFields();

    if (changedFields.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Changes Details',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        SizedBox(height: 1.h),
        ...changedFields.map((field) => _buildChangeCard(field)),
      ],
    );
  }

  Widget _buildChangeCard(String field) {
    final oldValue = auditLog.oldValues?[field];
    final newValue = auditLog.newValues?[field];

    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Old Value',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        _formatValue(oldValue),
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.red[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 2.w),
                child: const Icon(Icons.arrow_forward, size: 16),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New Value',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        _formatValue(newValue),
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.green[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataSection(
      BuildContext context, String title, Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        SizedBox(height: 1.h),
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Text(
            const JsonEncoder.withIndent('  ').convert(data),
            style: TextStyle(
              fontSize: 11.sp,
              fontFamily: 'monospace',
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return value;
    if (value is num) return value.toString();
    if (value is bool) return value.toString();
    return value.toString();
  }

}

class _InfoRow {
  final String label;
  final String value;
  final Color? color;
  final int maxLines;

  _InfoRow(
    this.label,
    this.value, {
    this.color,
    this.maxLines = 1,
  });
}
