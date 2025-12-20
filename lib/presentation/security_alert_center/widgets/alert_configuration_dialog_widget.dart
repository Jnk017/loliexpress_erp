import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/security_monitoring_service.dart';

class AlertConfigurationDialog extends StatefulWidget {
  const AlertConfigurationDialog({super.key});

  @override
  State<AlertConfigurationDialog> createState() =>
      _AlertConfigurationDialogState();
}

class _AlertConfigurationDialogState extends State<AlertConfigurationDialog> {
  final SecurityMonitoringService _securityService =
      SecurityMonitoringService();
  List<Map<String, dynamic>> _thresholds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThresholds();
  }

  Future<void> _loadThresholds() async {
    try {
      final thresholds = await _securityService.getSecurityThresholds();
      setState(() {
        _thresholds = thresholds;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateThreshold(String id, double value) async {
    try {
      await _securityService.updateSecurityThreshold(
        thresholdId: id,
        value: value,
      );
      _loadThresholds();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Threshold updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update threshold: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: EdgeInsets.all(4.w),
        constraints: BoxConstraints(maxHeight: 70.h, maxWidth: 90.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, size: 28),
                SizedBox(width: 2.w),
                Text(
                  'Alert Configuration',
                  style:
                      TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _thresholds.isEmpty
                      ? const Center(child: Text('No thresholds configured'))
                      : ListView(
                          children: [
                            _buildSection('Detection Thresholds', Icons.shield),
                            ..._thresholds.map(
                                (threshold) => _buildThresholdTile(threshold)),
                            SizedBox(height: 2.h),
                            _buildSection('Notification Preferences',
                                Icons.notifications),
                            _buildSwitchTile('Email Notifications', true),
                            _buildSwitchTile('Push Notifications', true),
                            _buildSwitchTile(
                                'SMS Alerts (Critical Only)', false),
                            SizedBox(height: 2.h),
                            _buildSection(
                                'Automated Response', Icons.auto_fix_high),
                            _buildSwitchTile(
                                'Auto-escalate Critical Alerts', true),
                            _buildSwitchTile(
                                'Auto-block Suspicious IPs', false),
                            _buildSwitchTile('Real-time Monitoring', true),
                          ],
                        ),
            ),
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          SizedBox(width: 2.w),
          Text(
            title,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdTile(Map<String, dynamic> threshold) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 0.5.h),
      child: ListTile(
        title: Text(
          threshold['threshold_name'] ?? 'Unknown',
          style: TextStyle(fontSize: 13.sp),
        ),
        subtitle: Text(
          threshold['description'] ?? '',
          style: TextStyle(fontSize: 11.sp),
        ),
        trailing: SizedBox(
          width: 20.w,
          child: TextFormField(
            initialValue: threshold['threshold_value']?.toString() ?? '0',
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              isDense: true,
            ),
            onFieldSubmitted: (value) {
              final numValue = double.tryParse(value);
              if (numValue != null) {
                _updateThreshold(threshold['id'], numValue);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool initialValue) {
    return SwitchListTile(
      title: Text(title, style: TextStyle(fontSize: 13.sp)),
      value: initialValue,
      onChanged: (value) {
        // Update notification preference
      },
    );
  }
}
