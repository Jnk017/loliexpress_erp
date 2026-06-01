import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/security_monitoring_service.dart';
import '../../theme/app_theme.dart';
import './widgets/alert_action_buttons_widget.dart';
import './widgets/alert_configuration_dialog_widget.dart';
import './widgets/alert_severity_filter_widget.dart';
import './widgets/security_alert_card_widget.dart';
import './widgets/time_range_selector_widget.dart';

class SecurityAlertCenter extends StatefulWidget {
  const SecurityAlertCenter({super.key});

  @override
  State<SecurityAlertCenter> createState() => _SecurityAlertCenterState();
}

class _SecurityAlertCenterState extends State<SecurityAlertCenter> {
  final SecurityMonitoringService _securityService =
      SecurityMonitoringService();

  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;
  String? _error;

  String _selectedSeverity = 'all';
  String _selectedTimeRange = '24h';

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      DateTime? startDate;
      if (_selectedTimeRange == '24h') {
        startDate = DateTime.now().subtract(const Duration(hours: 24));
      } else if (_selectedTimeRange == '7d') {
        startDate = DateTime.now().subtract(const Duration(days: 7));
      } else if (_selectedTimeRange == '30d') {
        startDate = DateTime.now().subtract(const Duration(days: 30));
      }

      final alerts = await _securityService.getSecurityAnomalies(
        severity: _selectedSeverity == 'all' ? null : _selectedSeverity,
        startDate: startDate,
        limit: 100,
      );

      setState(() {
        _alerts = alerts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load security alerts';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleInvestigate(Map<String, dynamic> alert) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _AlertInvestigationScreen(alert: alert),
      ),
    );
    _loadAlerts();
  }

  Future<void> _handleResolve(Map<String, dynamic> alert) async {
    final notes = await _showResolutionDialog();
    if (notes != null) {
      try {
        await _securityService.updateAnomalyStatus(
          anomalyId: alert['id'],
          status: 'resolved',
          resolutionNotes: notes,
        );
        _loadAlerts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Alert marked as resolved')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to resolve alert: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleEscalate(Map<String, dynamic> alert) async {
    try {
      await _securityService.updateAnomalyStatus(
        anomalyId: alert['id'],
        status: 'reviewing',
        resolutionNotes: 'Escalated to security team',
      );
      _loadAlerts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alert escalated to security team')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to escalate alert: $e')),
        );
      }
    }
  }

  Future<void> _handleBlockUser(Map<String, dynamic> alert) async {
    final confirm = await _showBlockUserConfirmation();
    if (confirm == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('User access blocked - Feature coming soon')),
        );
      }
    }
  }

  Future<void> _handleFalsePositive(Map<String, dynamic> alert) async {
    try {
      await _securityService.updateAnomalyStatus(
        anomalyId: alert['id'],
        status: 'false_positive',
        resolutionNotes: 'Marked as false positive',
      );
      _loadAlerts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alert marked as false positive')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update alert: $e')),
        );
      }
    }
  }

  Future<String?> _showResolutionDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolution Notes'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter resolution details...',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showBlockUserConfirmation() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User Access'),
        content: const Text(
          'This will immediately suspend the user\'s account. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Block User'),
          ),
        ],
      ),
    );
  }

  void _showAlertConfiguration() {
    showDialog(
      context: context,
      builder: (context) => const AlertConfigurationDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Security Alert Center'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAlerts,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            color: Colors.white,
            child: Column(
              children: [
                AlertSeverityFilterWidget(
                  selectedSeverity: _selectedSeverity,
                  onSeverityChanged: (severity) {
                    setState(() => _selectedSeverity = severity);
                    _loadAlerts();
                  },
                ),
                SizedBox(height: 2.h),
                TimeRangeSelectorWidget(
                  selectedRange: _selectedTimeRange,
                  onRangeChanged: (range) {
                    setState(() => _selectedTimeRange = range);
                    _loadAlerts();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _alerts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shield_outlined,
                                    size: 80, color: Colors.grey[400]),
                                SizedBox(height: 2.h),
                                Text(
                                  'No security alerts found',
                                  style: TextStyle(
                                      fontSize: 16.sp, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadAlerts,
                            child: ListView.builder(
                              padding: EdgeInsets.all(3.w),
                              itemCount: _alerts.length,
                              itemBuilder: (context, index) {
                                final alert = _alerts[index];
                                return Dismissible(
                                  key: Key(alert['id']),
                                  direction: DismissDirection.horizontal,
                                  background: AlertActionButtons(
                                    alignment: Alignment.centerLeft,
                                    actions: [
                                      AlertAction(
                                        icon: Icons.search,
                                        label: 'Investigate',
                                        color: Colors.blue,
                                        onTap: () => _handleInvestigate(alert),
                                      ),
                                      AlertAction(
                                        icon: Icons.check,
                                        label: 'Acknowledge',
                                        color: Colors.green,
                                        onTap: () => _handleResolve(alert),
                                      ),
                                      AlertAction(
                                        icon: Icons.arrow_upward,
                                        label: 'Escalate',
                                        color: Colors.orange,
                                        onTap: () => _handleEscalate(alert),
                                      ),
                                      AlertAction(
                                        icon: Icons.block,
                                        label: 'Block User',
                                        color: Colors.red,
                                        onTap: () => _handleBlockUser(alert),
                                      ),
                                    ],
                                  ),
                                  secondaryBackground: AlertActionButtons(
                                    alignment: Alignment.centerRight,
                                    actions: [
                                      AlertAction(
                                        icon: Icons.archive,
                                        label: 'Archive',
                                        color: Colors.grey,
                                        onTap: () =>
                                            _handleFalsePositive(alert),
                                      ),
                                      AlertAction(
                                        icon: Icons.report_off,
                                        label: 'False Positive',
                                        color: Colors.amber,
                                        onTap: () =>
                                            _handleFalsePositive(alert),
                                      ),
                                    ],
                                  ),
                                  confirmDismiss: (direction) async => false,
                                  child: SecurityAlertCard(
                                    alert: alert,
                                    onTap: () => _handleInvestigate(alert),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAlertConfiguration,
        child: const Icon(Icons.settings),
      ),
    );
  }
}

class _AlertInvestigationScreen extends StatelessWidget {
  final Map<String, dynamic> alert;

  const _AlertInvestigationScreen({required this.alert});

  @override
  Widget build(BuildContext context) {
    final metadata = alert['metadata'] as Map<String, dynamic>? ?? {};
    final user = alert['user'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert Investigation'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert['title'] ?? 'No Title',
                      style: TextStyle(
                          fontSize: 18.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 1.h),
                    _buildInfoRow(
                        'Severity',
                        alert['severity']?.toString().toUpperCase() ??
                            'UNKNOWN'),
                    _buildInfoRow(
                        'Category',
                        alert['category']?.toString().toUpperCase() ??
                            'UNKNOWN'),
                    _buildInfoRow(
                        'Status',
                        alert['alert_status']?.toString().toUpperCase() ??
                            'UNKNOWN'),
                    _buildInfoRow(
                        'Risk Score', alert['risk_score']?.toString() ?? '0'),
                    _buildInfoRow(
                        'Detected', _formatTimestamp(alert['detected_at'])),
                  ],
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Card(
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Description',
                        style: TextStyle(
                            fontSize: 16.sp, fontWeight: FontWeight.bold)),
                    SizedBox(height: 1.h),
                    Text(alert['description'] ?? 'No description available'),
                  ],
                ),
              ),
            ),
            if (user.isNotEmpty) ...[
              SizedBox(height: 2.h),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('User Information',
                          style: TextStyle(
                              fontSize: 16.sp, fontWeight: FontWeight.bold)),
                      SizedBox(height: 1.h),
                      _buildInfoRow('Name', user['full_name'] ?? 'Unknown'),
                      _buildInfoRow('Email', user['email'] ?? 'Unknown'),
                      _buildInfoRow('Role',
                          user['role']?.toString().toUpperCase() ?? 'UNKNOWN'),
                    ],
                  ),
                ),
              ),
            ],
            if (metadata.isNotEmpty) ...[
              SizedBox(height: 2.h),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Additional Details',
                          style: TextStyle(
                              fontSize: 16.sp, fontWeight: FontWeight.bold)),
                      SizedBox(height: 1.h),
                      ...metadata.entries.map((entry) => _buildInfoRow(
                            entry.key,
                            entry.value?.toString() ?? 'N/A',
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30.w,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final dt = DateTime.parse(timestamp.toString());
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp.toString();
    }
  }
}
