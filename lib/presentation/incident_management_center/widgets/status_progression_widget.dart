import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class StatusProgressionWidget extends StatelessWidget {
  final List<Map<String, dynamic>> incidents;

  const StatusProgressionWidget({
    super.key,
    required this.incidents,
  });

  Map<String, int> _getStatusCounts() {
    final counts = {
      'pending': 0,
      'reviewing': 0,
      'resolved': 0,
      'false_positive': 0,
    };

    for (var incident in incidents) {
      final status = incident['alert_status'] ?? 'pending';
      counts[status] = (counts[status] ?? 0) + 1;
    }

    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final statusCounts = _getStatusCounts();
    final total = incidents.length;

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workflow Status Overview',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.5.h),
            Row(
              children: [
                Expanded(
                  child: _buildStatusCard(
                    'Detection',
                    statusCounts['pending'] ?? 0,
                    total,
                    Colors.orange,
                    Icons.report_problem,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildStatusCard(
                    'Investigation',
                    statusCounts['reviewing'] ?? 0,
                    total,
                    Colors.blue,
                    Icons.search,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.w),
            Row(
              children: [
                Expanded(
                  child: _buildStatusCard(
                    'Resolution',
                    statusCounts['resolved'] ?? 0,
                    total,
                    Colors.green,
                    Icons.check_circle,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildStatusCard(
                    'Closure',
                    statusCounts['false_positive'] ?? 0,
                    total,
                    Colors.grey,
                    Icons.cancel,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    String label,
    int count,
    int total,
    Color color,
    IconData icon,
  ) {
    final percentage = total > 0 ? (count / total * 100).toInt() : 0;

    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18.sp),
          SizedBox(height: 0.5.h),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
