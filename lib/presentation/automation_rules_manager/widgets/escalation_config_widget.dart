import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/automation_rules_service.dart';

class EscalationConfigWidget extends StatefulWidget {
  const EscalationConfigWidget({super.key});

  @override
  State<EscalationConfigWidget> createState() => _EscalationConfigWidgetState();
}

class _EscalationConfigWidgetState extends State<EscalationConfigWidget> {
  final _rulesService = AutomationRulesService();
  List<Map<String, dynamic>> _configurations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfigurations();
  }

  Future<void> _loadConfigurations() async {
    setState(() => _isLoading = true);
    try {
      final configs = await _rulesService.getEscalationConfigurations();
      setState(() {
        _configurations = configs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_configurations.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadConfigurations,
      child: ListView.builder(
        padding: EdgeInsets.all(2.w),
        itemCount: _configurations.length,
        itemBuilder: (context, index) =>
            _buildConfigCard(_configurations[index]),
      ),
    );
  }

  Widget _buildConfigCard(Map<String, dynamic> config) {
    final escalationName = config['escalation_name'] ?? 'Unnamed Config';
    final severityLevel = config['severity_level'] ?? 'low';
    final delayMinutes = config['escalation_delay_minutes'] ?? 30;
    final primaryAdmin =
        config['primary_admin']?['full_name'] ?? 'Not assigned';
    final primaryEmail = config['primary_admin']?['email'] ?? '';
    final channels = (config['notification_channels'] as List<dynamic>?) ?? [];
    final externalEmail = config['external_support_email'] as String?;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildSeverityIcon(severityLevel),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        escalationName,
                        style: TextStyle(
                            fontSize: 15.sp, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Severity: ${severityLevel.toUpperCase()}',
                        style: TextStyle(
                            fontSize: 12.sp,
                            color: _getSeverityColor(severityLevel)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
                Icons.schedule, 'Escalation Delay', '$delayMinutes minutes'),
            _buildInfoRow(Icons.person, 'Primary Admin', primaryAdmin),
            if (primaryEmail.isNotEmpty)
              _buildInfoRow(Icons.email, 'Admin Email', primaryEmail),
            if (externalEmail != null && externalEmail.isNotEmpty)
              _buildInfoRow(
                  Icons.support_agent, 'External Support', externalEmail),
            if (channels.isNotEmpty) ...[
              SizedBox(height: 1.h),
              Row(
                children: [
                  Icon(Icons.notifications, size: 18, color: Colors.grey[600]),
                  SizedBox(width: 2.w),
                  Text(
                    'Channels: ',
                    style:
                        TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
                  ),
                  ...channels.map((channel) => Padding(
                        padding: EdgeInsets.only(right: 1.w),
                        child: Chip(
                          label: Text(
                            channel.toString().toUpperCase(),
                            style: TextStyle(fontSize: 10.sp),
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      )),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          SizedBox(width: 2.w),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityIcon(String severity) {
    final icons = {
      'low': Icons.info_outline,
      'medium': Icons.warning_amber,
      'high': Icons.error_outline,
      'critical': Icons.dangerous,
    };

    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: _getSeverityColor(severity).withAlpha(51),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icons[severity] ?? Icons.info,
        color: _getSeverityColor(severity),
        size: 32,
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings_suggest, size: 80, color: Colors.grey[300]),
          SizedBox(height: 2.h),
          Text(
            'No Escalation Configs',
            style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600]),
          ),
          SizedBox(height: 1.h),
          Text(
            'Escalation configurations will appear here',
            style: TextStyle(fontSize: 13.sp, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
