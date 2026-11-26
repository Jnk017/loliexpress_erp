import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

class IncidentDetailsDialogWidget extends StatefulWidget {
  final Map<String, dynamic> incident;
  final Function(String, String?) onStatusUpdate;
  final Function(Map<String, dynamic>) onAddEvidence;

  const IncidentDetailsDialogWidget({
    super.key,
    required this.incident,
    required this.onStatusUpdate,
    required this.onAddEvidence,
  });

  @override
  State<IncidentDetailsDialogWidget> createState() =>
      _IncidentDetailsDialogWidgetState();
}

class _IncidentDetailsDialogWidgetState
    extends State<IncidentDetailsDialogWidget> {
  final TextEditingController _notesController = TextEditingController();
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.incident['alert_status'];
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final incident = widget.incident;
    final severity = incident['severity'] ?? 'low';
    final category = incident['category'] ?? 'system';
    final title = incident['title'] ?? 'Unknown Incident';
    final description = incident['description'] ?? '';
    final detectedAt = incident['detected_at'] != null
        ? DateTime.parse(incident['detected_at'])
        : DateTime.now();
    final user = incident['user'] as Map<String, dynamic>?;
    final metadata = incident['metadata'] as Map<String, dynamic>?;
    final riskScore = (incident['risk_score'] ?? 0).toDouble();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Container(
        constraints: BoxConstraints(maxHeight: 80.h, maxWidth: 90.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: _getSeverityColor(severity),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16.0),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Incident Details',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          'Severity: ${severity.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.white,
                          ),
                        ),
                      ],
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
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 1.h),

                    // Description
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 2.h),

                    // Info Grid
                    _buildInfoRow('Category', category.toUpperCase()),
                    _buildInfoRow('Risk Score', riskScore.toInt().toString()),
                    _buildInfoRow(
                      'Detected',
                      DateFormat('MMM dd, yyyy HH:mm').format(detectedAt),
                    ),
                    if (user != null)
                      _buildInfoRow(
                        'User',
                        user['full_name'] ?? user['email'] ?? 'Unknown',
                      ),
                    SizedBox(height: 2.h),

                    // Metadata
                    if (metadata != null && metadata.isNotEmpty) ...[
                      Text(
                        'Additional Details',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: metadata.entries.map((entry) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: 0.5.h),
                              child: Text(
                                '${entry.key}: ${entry.value}',
                                style: TextStyle(fontSize: 12.sp),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      SizedBox(height: 2.h),
                    ],

                    // Status Update Section
                    Text(
                      'Update Status',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedStatus,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 3.w,
                          vertical: 1.h,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'pending', child: Text('Pending')),
                        DropdownMenuItem(
                            value: 'reviewing', child: Text('Reviewing')),
                        DropdownMenuItem(
                            value: 'resolved', child: Text('Resolved')),
                        DropdownMenuItem(
                            value: 'false_positive',
                            child: Text('False Positive')),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedStatus = value);
                      },
                    ),
                    SizedBox(height: 2.h),

                    // Resolution Notes
                    Text(
                      'Resolution Notes',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    TextField(
                      controller: _notesController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Enter resolution notes...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),

                    // Add Evidence Button
                    OutlinedButton.icon(
                      onPressed: () {
                        // Handle evidence upload
                        widget.onAddEvidence({
                          'type': 'document',
                          'timestamp': DateTime.now().toIso8601String(),
                        });
                      },
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Add Evidence'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(double.infinity, 5.h),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16.0),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onStatusUpdate(
                          _selectedStatus!,
                          _notesController.text.isEmpty
                              ? null
                              : _notesController.text,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                      ),
                      child: const Text('Update'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 25.w,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

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
}
