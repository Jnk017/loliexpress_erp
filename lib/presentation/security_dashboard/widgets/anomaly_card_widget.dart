import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

class AnomalyCardWidget extends StatelessWidget {
  final Map<String, dynamic> anomaly;
  final Function(String status, String? notes)? onStatusUpdate;

  const AnomalyCardWidget({
    super.key,
    required this.anomaly,
    this.onStatusUpdate,
  });

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'transaction':
        return Icons.payment;
      case 'access':
        return Icons.lock_open;
      case 'inventory':
        return Icons.inventory_2;
      case 'permission':
        return Icons.admin_panel_settings;
      default:
        return Icons.security;
    }
  }

  void _showDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(anomaly['title'] ?? 'Security Anomaly'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Description:',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(anomaly['description'] ?? 'No description'),
              SizedBox(height: 2.h),
              Text('Severity:',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(anomaly['severity'] ?? 'Unknown'),
              SizedBox(height: 2.h),
              Text('Risk Score:',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('${anomaly['risk_score'] ?? 0}/100'),
              SizedBox(height: 2.h),
              Text('Detected At:',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(DateFormat('MMM dd, yyyy HH:mm')
                  .format(DateTime.parse(anomaly['detected_at']))),
              if (anomaly['metadata'] != null) ...[
                SizedBox(height: 2.h),
                Text('Additional Details:',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(anomaly['metadata'].toString()),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          if (onStatusUpdate != null && anomaly['alert_status'] == 'pending')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showResolveDialog(context);
              },
              child: const Text('Resolve'),
            ),
        ],
      ),
    );
  }

  void _showResolveDialog(BuildContext context) {
    final notesController = TextEditingController();
    String selectedStatus = 'resolved';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Anomaly'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedStatus,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                DropdownMenuItem(
                    value: 'false_positive', child: Text('False Positive')),
              ],
              onChanged: (value) => selectedStatus = value ?? 'resolved',
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Resolution Notes',
                hintText: 'Enter resolution details...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              onStatusUpdate?.call(selectedStatus, notesController.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final severity = anomaly['severity'] ?? 'unknown';
    final category = anomaly['category'] ?? 'system';
    final status = anomaly['alert_status'] ?? 'pending';
    final severityColor = _getSeverityColor(severity);

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: severityColor.withAlpha(77), width: 2),
      ),
      child: InkWell(
        onTap: () => _showDetailsDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: severityColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(category),
                      color: severityColor,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          anomaly['title'] ?? 'Security Alert',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          category.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: severityColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      severity.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Text(
                anomaly['description'] ?? 'No description available',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 1.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 14.sp, color: Colors.grey),
                      SizedBox(width: 1.w),
                      Text(
                        anomaly['user']?['full_name'] ?? 'Unknown User',
                        style:
                            TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  Text(
                    DateFormat('MMM dd, HH:mm')
                        .format(DateTime.parse(anomaly['detected_at'])),
                    style: TextStyle(fontSize: 10.sp, color: Colors.grey[500]),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield_outlined,
                          size: 14.sp, color: Colors.grey),
                      SizedBox(width: 1.w),
                      Text(
                        'Risk Score: ${anomaly['risk_score'] ?? 0}/100',
                        style: TextStyle(
                            fontSize: 11.sp, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: status == 'pending'
                          ? Colors.orange.withAlpha(26)
                          : Colors.green.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            status == 'pending' ? Colors.orange : Colors.green,
                      ),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9.sp,
                        color:
                            status == 'pending' ? Colors.orange : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
