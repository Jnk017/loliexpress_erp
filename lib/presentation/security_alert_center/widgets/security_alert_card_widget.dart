import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SecurityAlertCard extends StatelessWidget {
  final Map<String, dynamic> alert;
  final VoidCallback onTap;

  const SecurityAlertCard({
    super.key,
    required this.alert,
    required this.onTap,
  });

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow[700]!;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'transaction':
        return Icons.attach_money;
      case 'access':
        return Icons.lock;
      case 'inventory':
        return Icons.inventory;
      case 'permission':
        return Icons.security;
      case 'system':
        return Icons.computer;
      default:
        return Icons.warning;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final dt = DateTime.parse(timestamp.toString());
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h ago';
      } else {
        return '${diff.inDays}d ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final severity = alert['severity'] ?? 'unknown';
    final category = alert['category'] ?? 'unknown';
    final severityColor = _getSeverityColor(severity);
    final user = alert['user'] as Map<String, dynamic>? ?? {};

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: severityColor, width: 4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: severityColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Icon(
                      _getCategoryIcon(category),
                      color: severityColor,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert['title'] ?? 'No Title',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.5.h),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 2.w, vertical: 0.3.h),
                              decoration: BoxDecoration(
                                color: severityColor,
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Text(
                                severity.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              category.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatTimestamp(alert['detected_at']),
                        style:
                            TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 0.5.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 2.w, vertical: 0.3.h),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.trending_up,
                                size: 12, color: Colors.red),
                            SizedBox(width: 1.w),
                            Text(
                              '${alert['risk_score'] ?? 0}',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              Text(
                alert['description'] ?? 'No description available',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (user.isNotEmpty) ...[
                SizedBox(height: 1.h),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 1.w),
                    Text(
                      user['full_name'] ?? user['email'] ?? 'Unknown User',
                      style:
                          TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 2.w, vertical: 0.3.h),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        (user['role'] ?? 'unknown').toString().toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 1.h),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.grey[500]),
                  SizedBox(width: 1.w),
                  Text(
                    'Swipe for actions',
                    style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
