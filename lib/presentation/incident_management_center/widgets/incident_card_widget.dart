import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

class IncidentCardWidget extends StatelessWidget {
  final Map<String, dynamic> incident;
  final VoidCallback onTap;
  final VoidCallback onAssignInvestigator;
  final Function(String) onChangeStatus;
  final VoidCallback onEscalate;

  const IncidentCardWidget({
    super.key,
    required this.incident,
    required this.onTap,
    required this.onAssignInvestigator,
    required this.onChangeStatus,
    required this.onEscalate,
  });

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red.shade700;
      case 'high':
        return Colors.orange.shade700;
      case 'medium':
        return Colors.yellow.shade700;
      case 'low':
        return Colors.blue.shade700;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'reviewing':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'false_positive':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'transaction':
        return Icons.account_balance_wallet;
      case 'access':
        return Icons.lock_open;
      case 'inventory':
        return Icons.inventory;
      case 'permission':
        return Icons.admin_panel_settings;
      case 'system':
        return Icons.settings;
      default:
        return Icons.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final severity = incident['severity'] ?? 'low';
    final status = incident['alert_status'] ?? 'pending';
    final category = incident['category'] ?? 'system';
    final title = incident['title'] ?? 'Unknown Incident';
    final description = incident['description'] ?? '';
    final detectedAt = incident['detected_at'] != null
        ? DateTime.parse(incident['detected_at'])
        : DateTime.now();
    final user = incident['user'] as Map<String, dynamic>?;
    final riskScore = (incident['risk_score'] ?? 0).toDouble();

    return Dismissible(
      key: Key(incident['id']),
      direction: DismissDirection.horizontal,
      background: Container(
        color: Colors.blue,
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: const Icon(Icons.assignment_ind, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: const Icon(Icons.priority_high, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right - Assign Investigator
          onAssignInvestigator();
          return false;
        } else {
          // Swipe left - Escalate
          onEscalate();
          return false;
        }
      },
      child: Card(
        margin: EdgeInsets.only(bottom: 2.h),
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(
            color: _getSeverityColor(severity),
            width: 2.0,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // Severity Badge
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 2.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: _getSeverityColor(severity),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        severity.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    // Status Badge
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 2.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withAlpha(51),
                        border: Border.all(color: _getStatusColor(status)),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Risk Score
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 2.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: riskScore > 60
                            ? Colors.red.shade50
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.speed,
                            size: 14.sp,
                            color: riskScore > 60 ? Colors.red : Colors.green,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            '${riskScore.toInt()}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: riskScore > 60 ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),

                // Title Row with Category Icon
                Row(
                  children: [
                    Icon(
                      _getCategoryIcon(category),
                      size: 18.sp,
                      color: Colors.grey[700],
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),

                // Description
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 1.5.h),

                // Info Row
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14.sp, color: Colors.grey),
                    SizedBox(width: 1.w),
                    Text(
                      DateFormat('MMM dd, yyyy HH:mm').format(detectedAt),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (user != null) ...[
                      SizedBox(width: 3.w),
                      Icon(Icons.person, size: 14.sp, color: Colors.grey),
                      SizedBox(width: 1.w),
                      Expanded(
                        child: Text(
                          user['full_name'] ?? user['email'] ?? 'Unknown User',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 1.5.h),

                // Quick Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onAssignInvestigator,
                        icon: const Icon(Icons.assignment_ind, size: 16.0),
                        label: const Text('Assign'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 1.h),
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showStatusMenu(context),
                        icon: const Icon(Icons.sync_alt, size: 16.0),
                        label: const Text('Status'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 1.h),
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEscalate,
                        icon: const Icon(Icons.arrow_upward, size: 16.0),
                        label: const Text('Escalate'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 1.h),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStatusMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Change Status',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            ListTile(
              leading: Icon(Icons.pending, color: Colors.orange),
              title: const Text('Pending'),
              onTap: () {
                Navigator.pop(context);
                onChangeStatus('pending');
              },
            ),
            ListTile(
              leading: Icon(Icons.rate_review, color: Colors.blue),
              title: const Text('Reviewing'),
              onTap: () {
                Navigator.pop(context);
                onChangeStatus('reviewing');
              },
            ),
            ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Resolved'),
              onTap: () {
                Navigator.pop(context);
                onChangeStatus('resolved');
              },
            ),
            ListTile(
              leading: Icon(Icons.cancel, color: Colors.grey),
              title: const Text('False Positive'),
              onTap: () {
                Navigator.pop(context);
                onChangeStatus('false_positive');
              },
            ),
          ],
        ),
      ),
    );
  }
}
