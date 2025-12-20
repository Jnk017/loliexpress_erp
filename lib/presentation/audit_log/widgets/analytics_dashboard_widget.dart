import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/user_analytics_service.dart';

class AnalyticsDashboardWidget extends StatefulWidget {
  final String userId;
  final String userName;
  final String userRole;

  const AnalyticsDashboardWidget({
    super.key,
    required this.userId,
    required this.userName,
    required this.userRole,
  });

  @override
  State<AnalyticsDashboardWidget> createState() =>
      _AnalyticsDashboardWidgetState();
}

class _AnalyticsDashboardWidgetState extends State<AnalyticsDashboardWidget>
    with SingleTickerProviderStateMixin {
  final UserAnalyticsService _analyticsService = UserAnalyticsService();
  late TabController _tabController;

  bool _isLoading = true;
  Map<String, dynamic> _analyticsData = {};
  int _selectedDays = 30;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final data = await _analyticsService.getAllUserAnalytics(
        userId: widget.userId,
        daysBack: _selectedDays,
      );

      setState(() {
        _analyticsData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User Analytics',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        '${widget.userName} (${widget.userRole})',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                DropdownButton<int>(
                  value: _selectedDays,
                  dropdownColor: Theme.of(context).primaryColor,
                  style: TextStyle(color: Colors.white, fontSize: 12.sp),
                  underline: Container(),
                  items: [
                    DropdownMenuItem(value: 7, child: Text('Last 7 days')),
                    DropdownMenuItem(value: 30, child: Text('Last 30 days')),
                    DropdownMenuItem(value: 90, child: Text('Last 90 days')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedDays = value);
                      _loadAnalytics();
                    }
                  },
                ),
              ],
            ),
          ),

          // Tab bar
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
            labelStyle: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Login Patterns'),
              Tab(text: 'Features'),
              Tab(text: 'Navigation'),
            ],
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildLoginPatternsTab(),
                      _buildFeatureUsageTab(),
                      _buildNavigationTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final productivity =
        _analyticsData['productivity_metrics'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Productivity score card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withAlpha(179),
                ],
              ),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              children: [
                Text(
                  'Productivity Score',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${productivity['productivity_score'] ?? '0'}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'out of 100',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 3.h),

          // Key metrics grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            mainAxisSpacing: 2.w,
            crossAxisSpacing: 2.w,
            children: [
              _buildMetricCard(
                'Total Sessions',
                '${productivity['total_sessions'] ?? 0}',
                Icons.login,
                Colors.blue,
              ),
              _buildMetricCard(
                'Avg Session',
                '${productivity['avg_session_duration_minutes'] ?? 0} min',
                Icons.timer,
                Colors.green,
              ),
              _buildMetricCard(
                'Screens Visited',
                '${productivity['total_screens_visited'] ?? 0}',
                Icons.screen_share,
                Colors.orange,
              ),
              _buildMetricCard(
                'Unique Screens',
                '${productivity['unique_screens_count'] ?? 0}',
                Icons.apps,
                Colors.purple,
              ),
            ],
          ),

          SizedBox(height: 3.h),

          // Most used feature and screen
          _buildInfoCard(
            'Most Used Feature',
            productivity['most_used_feature'] ?? 'N/A',
            Icons.star,
            Colors.amber,
          ),
          SizedBox(height: 2.h),
          _buildInfoCard(
            'Most Visited Screen',
            productivity['most_visited_screen'] ?? 'N/A',
            Icons.screen_share,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPatternsTab() {
    final loginPatterns =
        _analyticsData['login_patterns'] as Map<String, dynamic>? ?? {};
    final peakHours = loginPatterns['peak_login_hours'] as List<dynamic>? ?? [];
    final deviceBreakdown =
        loginPatterns['device_breakdown'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Login Statistics',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Logins',
                  '${loginPatterns['total_sessions'] ?? 0}',
                  Icons.login,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildMetricCard(
                  'Avg Duration',
                  '${loginPatterns['avg_duration_minutes'] ?? 0} min',
                  Icons.timer,
                  Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Text(
            'Peak Login Hours',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          if (peakHours.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Text(
                  'No login data available',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            )
          else
            ...peakHours.map((hour) {
              return Container(
                margin: EdgeInsets.only(bottom: 1.h),
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.blue, size: 5.w),
                    SizedBox(width: 3.w),
                    Text(
                      hour.toString(),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          SizedBox(height: 3.h),
          Text(
            'Device Breakdown',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          if (deviceBreakdown.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Text(
                  'No device data available',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            )
          else
            ...deviceBreakdown.entries.map((entry) {
              final percentage = (loginPatterns['total_sessions'] ?? 0) > 0
                  ? (entry.value / loginPatterns['total_sessions'] * 100)
                      .toStringAsFixed(1)
                  : '0';

              return Container(
                margin: EdgeInsets.only(bottom: 1.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$percentage% (${entry.value} sessions)',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    LinearProgressIndicator(
                      value: double.parse(percentage) / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.blue[400]!),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildFeatureUsageTab() {
    final featureUsage =
        _analyticsData['feature_usage'] as Map<String, dynamic>? ?? {};
    final topFeatures = featureUsage['top_features'] as List<dynamic>? ?? [];
    final moduleBreakdown =
        featureUsage['module_breakdown'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Feature Usage Statistics',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              children: [
                Text(
                  'Total Feature Usage',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  '${featureUsage['total_feature_usage'] ?? 0}',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[700],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'Top Features',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          if (topFeatures.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Text(
                  'No feature usage data available',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            )
          else
            ...topFeatures.take(5).map((feature) {
              return Container(
                margin: EdgeInsets.only(bottom: 1.h),
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: Colors.purple[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.star,
                        color: Colors.purple,
                        size: 5.w,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            feature['feature_name'],
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${feature['module_name']} • ${feature['action_type']}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${feature['usage_count']} uses',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple[700],
                          ),
                        ),
                        if (feature['average_time_seconds'] != null)
                          Text(
                            'Avg: ${(feature['average_time_seconds'] as num).toStringAsFixed(1)}s',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          SizedBox(height: 3.h),
          Text(
            'Module Breakdown',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          if (moduleBreakdown.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Text(
                  'No module data available',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            )
          else
            ...moduleBreakdown.entries.map((entry) {
              final percentage = (featureUsage['total_feature_usage'] ?? 0) > 0
                  ? (entry.value / featureUsage['total_feature_usage'] * 100)
                      .toStringAsFixed(1)
                  : '0';

              return Container(
                margin: EdgeInsets.only(bottom: 1.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$percentage% (${entry.value} uses)',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    LinearProgressIndicator(
                      value: double.parse(percentage) / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.purple[400]!),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildNavigationTab() {
    final screenNav =
        _analyticsData['screen_navigation'] as Map<String, dynamic>? ?? {};
    final mostVisited =
        screenNav['most_visited_screens'] as List<dynamic>? ?? [];
    final categoryBreakdown =
        screenNav['category_breakdown'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Screen Navigation Analytics',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Views',
                  '${screenNav['total_screen_views'] ?? 0}',
                  Icons.visibility,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildMetricCard(
                  'Unique Screens',
                  '${screenNav['unique_screens_visited'] ?? 0}',
                  Icons.apps,
                  Colors.green,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Text(
            'Most Visited Screens',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          if (mostVisited.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Text(
                  'No navigation data available',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            )
          else
            ...mostVisited.map((screen) {
              return Container(
                margin: EdgeInsets.only(bottom: 1.h),
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.screen_share,
                        color: Colors.orange,
                        size: 5.w,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            screen['screen'],
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Avg time: ${screen['avg_time']}s',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${screen['visits']} visits',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              );
            }),
          SizedBox(height: 3.h),
          Text(
            'Category Breakdown',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          if (categoryBreakdown.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Text(
                  'No category data available',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            )
          else
            ...categoryBreakdown.map((category) {
              final percentage = (screenNav['total_screen_views'] ?? 0) > 0
                  ? (category['visits'] / screenNav['total_screen_views'] * 100)
                      .toStringAsFixed(1)
                  : '0';

              return Container(
                margin: EdgeInsets.only(bottom: 1.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          category['category'],
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$percentage% (${category['visits']} views)',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    LinearProgressIndicator(
                      value: double.parse(percentage) / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.orange[400]!),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 8.w),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 6.w),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
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
