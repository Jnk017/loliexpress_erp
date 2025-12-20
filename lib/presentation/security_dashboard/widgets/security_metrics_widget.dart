import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SecurityMetricsWidget extends StatelessWidget {
  final Map<String, dynamic> summary;

  const SecurityMetricsWidget({
    super.key,
    required this.summary,
  });

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24.sp),
            SizedBox(height: 1.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              label,
              style: TextStyle(fontSize: 10.sp, color: Colors.grey[700]),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingAnomalies = summary['pending_anomalies'] ?? 0;
    final highRiskUsers = summary['high_risk_users'] ?? 0;
    final failedLogins = summary['failed_logins_24h'] ?? 0;
    final severityDist =
        summary['severity_distribution'] as Map<String, dynamic>? ?? {};
    final criticalCount = severityDist['critical'] ?? 0;

    return Container(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Security Overview',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              _buildMetricCard(
                label: 'Pending Alerts',
                value: pendingAnomalies.toString(),
                icon: Icons.notification_important,
                color: Colors.orange,
              ),
              SizedBox(width: 2.w),
              _buildMetricCard(
                label: 'Critical Issues',
                value: criticalCount.toString(),
                icon: Icons.error,
                color: Colors.red,
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              _buildMetricCard(
                label: 'High Risk Users',
                value: highRiskUsers.toString(),
                icon: Icons.person_off,
                color: Colors.purple,
              ),
              SizedBox(width: 2.w),
              _buildMetricCard(
                label: 'Failed Logins (24h)',
                value: failedLogins.toString(),
                icon: Icons.lock_clock,
                color: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
