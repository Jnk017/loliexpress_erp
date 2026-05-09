import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/security_monitoring_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/anomaly_card_widget.dart';
import './widgets/failed_login_list_widget.dart';
import './widgets/risk_score_card_widget.dart';
import './widgets/security_metrics_widget.dart';

class SecurityDashboard extends StatefulWidget {
  const SecurityDashboard({super.key});

  @override
  State<SecurityDashboard> createState() => _SecurityDashboardState();
}

class _SecurityDashboardState extends State<SecurityDashboard>
    with SingleTickerProviderStateMixin {
  final SecurityMonitoringService _securityService =
      SecurityMonitoringService();

  Map<String, dynamic>? _dashboardSummary;
  List<Map<String, dynamic>> _recentAnomalies = [];
  List<Map<String, dynamic>> _highRiskUsers = [];
  List<Map<String, dynamic>> _failedLogins = [];

  bool _isLoading = true;
  String? _errorMessage;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSecurityData();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSecurityData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final summary = await _securityService.getSecurityDashboardSummary();
      final anomalies = await _securityService.getSecurityAnomalies(limit: 10);
      final riskUsers =
          await _securityService.getUserRiskScores(minScore: 60, limit: 10);
      final failedLogins = await _securityService.getFailedLoginAttempts(
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        limit: 20,
      );

      setState(() {
        _dashboardSummary = summary;
        _recentAnomalies = anomalies;
        _highRiskUsers = riskUsers;
        _failedLogins = failedLogins;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _setupRealtimeSubscription() {
    _securityService.subscribeToAnomalies(
      onInsert: (anomaly) {
        setState(() {
          _recentAnomalies.insert(0, anomaly);
          if (_recentAnomalies.length > 10) {
            _recentAnomalies.removeLast();
          }
        });

        // Show notification for critical anomalies
        if (anomaly['severity'] == 'critical') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Critical Security Alert: ${anomaly['title']}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      },
      onUpdate: (anomaly) {
        setState(() {
          final index =
              _recentAnomalies.indexWhere((a) => a['id'] == anomaly['id']);
          if (index != -1) {
            _recentAnomalies[index] = anomaly;
          }
        });
      },
    );
  }

  Future<void> _runSecurityChecks() async {
    try {
      await _securityService.runSecurityChecks();
      await _loadSecurityData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Security checks completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to run security checks: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Security Dashboard',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSecurityData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.security),
            onPressed: _runSecurityChecks,
            tooltip: 'Run Security Checks',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      SizedBox(height: 2.h),
                      Text(_errorMessage!, textAlign: TextAlign.center),
                      SizedBox(height: 2.h),
                      ElevatedButton(
                        onPressed: _loadSecurityData,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Security Metrics Overview
                    if (_dashboardSummary != null)
                      SecurityMetricsWidget(summary: _dashboardSummary!),

                    // Tab Bar
                    Container(
                      color: Theme.of(context).primaryColor.withAlpha(26),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Theme.of(context).primaryColor,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Theme.of(context).primaryColor,
                        tabs: const [
                          Tab(
                              text: 'Anomalies',
                              icon: Icon(Icons.warning_amber)),
                          Tab(
                              text: 'Risk Scores',
                              icon: Icon(Icons.person_outline)),
                          Tab(
                              text: 'Failed Logins',
                              icon: Icon(Icons.lock_outline)),
                          Tab(
                              text: 'Analytics',
                              icon: Icon(Icons.analytics_outlined)),
                        ],
                      ),
                    ),

                    // Tab Content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Anomalies Tab
                          RefreshIndicator(
                            onRefresh: _loadSecurityData,
                            child: _recentAnomalies.isEmpty
                                ? const Center(
                                    child: Text('No anomalies detected'))
                                : ListView.builder(
                                    padding: EdgeInsets.all(2.w),
                                    itemCount: _recentAnomalies.length,
                                    itemBuilder: (context, index) {
                                      return AnomalyCardWidget(
                                        anomaly: _recentAnomalies[index],
                                        onStatusUpdate: (status, notes) async {
                                          await _securityService
                                              .updateAnomalyStatus(
                                            anomalyId: _recentAnomalies[index]
                                                ['id'],
                                            status: status,
                                            resolutionNotes: notes,
                                          );
                                          await _loadSecurityData();
                                        },
                                      );
                                    },
                                  ),
                          ),

                          // Risk Scores Tab
                          RefreshIndicator(
                            onRefresh: _loadSecurityData,
                            child: _highRiskUsers.isEmpty
                                ? const Center(
                                    child: Text('No high-risk users found'))
                                : ListView.builder(
                                    padding: EdgeInsets.all(2.w),
                                    itemCount: _highRiskUsers.length,
                                    itemBuilder: (context, index) {
                                      return RiskScoreCardWidget(
                                        userRisk: _highRiskUsers[index],
                                      );
                                    },
                                  ),
                          ),

                          // Failed Logins Tab
                          RefreshIndicator(
                            onRefresh: _loadSecurityData,
                            child: FailedLoginListWidget(
                              failedLogins: _failedLogins,
                            ),
                          ),

                          // Analytics Tab
                          RefreshIndicator(
                            onRefresh: _loadSecurityData,
                            child: SingleChildScrollView(
                              padding: EdgeInsets.all(2.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Security Analytics',
                                    style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 2.h),
                                  const Text(
                                      'Analytics dashboard coming soon with trend charts and detailed reports.'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
