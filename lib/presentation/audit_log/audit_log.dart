import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/audit_log_service.dart';
import './widgets/analytics_dashboard_widget.dart';
import './widgets/anomaly_correlation_widget.dart';
import './widgets/audit_log_card_widget.dart';
import './widgets/date_range_selector_widget.dart';
import './widgets/device_fingerprinting_widget.dart';
import './widgets/filter_panel_widget.dart';
import './widgets/forensic_timeline_widget.dart';
import './widgets/ip_geolocation_map_widget.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen>
    with WidgetsBindingObserver {
  final AuditLogService _auditService = AuditLogService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<AuditLogEntry> _auditLogs = [];
  List<AuditLogEntry> _filteredLogs = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 0;
  final int _pageSize = 20;

  // Real-time updates
  StreamSubscription<AuditLogEntry>? _realtimeSubscription;
  int _newActivityCount = 0;
  bool _showNewActivityBadge = false;

  // Filter states
  DateTimeRange? _selectedDateRange;
  String? _selectedUser;
  String? _selectedModule;
  String? _selectedActionType;
  List<String> _availableUsers = [];
  List<String> _availableModules = [];

  // Action type options
  final List<String> _actionTypes = [
    'All Actions',
    'CREATE',
    'UPDATE',
    'DELETE',
    'LOGIN',
    'LOGOUT',
    'EXPORT',
    'IMPORT'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAuditLogs();
    _loadFilterOptions();
    _setupRealtimeSubscription();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _scrollController.dispose();
    _realtimeSubscription?.cancel();
    _auditService.unsubscribeFromAuditLogs();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reconnect when app comes to foreground
      _setupRealtimeSubscription();
    } else if (state == AppLifecycleState.paused) {
      // Clean up when app goes to background
      _realtimeSubscription?.cancel();
    }
  }

  void _setupRealtimeSubscription() {
    final stream = _auditService.subscribeToAuditLogs();
    if (stream != null) {
      _realtimeSubscription = stream.listen(
        (newEntry) {
          setState(() {
            // Add new entry to the beginning of the list
            _auditLogs.insert(0, newEntry);
            _newActivityCount++;
            _showNewActivityBadge = true;
          });

          // Show toast for critical actions
          if (newEntry.isCriticalAction) {
            _showCriticalActionToast(newEntry);
          }

          // Auto-apply filters to include new entry if it matches
          _applyFilters();
        },
        onError: (error) {
          // Silent fail - connection issues shouldn't break the UI
        },
      );
    }
  }

  void _showCriticalActionToast(AuditLogEntry entry) {
    if (!mounted) return;

    final snackBar = SnackBar(
      content: Row(
        children: [
          Container(
            width: 4.w,
            height: 4.w,
            decoration: BoxDecoration(
              color: entry.actionColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getActionIcon(entry.actionType),
              color: Colors.white,
              size: 2.w,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${entry.actionDisplay} - ${entry.moduleDisplay}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                  ),
                ),
                Text(
                  entry.getChangeDescription(),
                  style: TextStyle(fontSize: 10.sp),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: Colors.grey[900],
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        label: 'VIEW',
        textColor: entry.actionColor,
        onPressed: () {
          // Scroll to top to see the new entry
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  IconData _getActionIcon(String actionType) {
    switch (actionType.toLowerCase()) {
      case 'insert':
        return Icons.add_circle_outline;
      case 'update':
        return Icons.edit_outlined;
      case 'delete':
        return Icons.delete_outline;
      default:
        return Icons.info_outline;
    }
  }

  void _clearNewActivityBadge() {
    setState(() {
      _newActivityCount = 0;
      _showNewActivityBadge = false;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoadingMore && _hasMoreData) {
        _loadMoreLogs();
      }
    }

    // Clear badge when user scrolls to top
    if (_scrollController.position.pixels == 0 && _showNewActivityBadge) {
      _clearNewActivityBadge();
    }
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  Future<void> _loadAuditLogs() async {
    setState(() => _isLoading = true);

    try {
      final logs = await _auditService.getAuditLogs(
        limit: _pageSize,
        offset: 0,
      );

      setState(() {
        _auditLogs = logs;
        _filteredLogs = logs;
        _isLoading = false;
        _currentPage = 0;
        _hasMoreData = logs.length >= _pageSize;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de terminer l’opération. Réessayez.')),
        );
      }
    }
  }

  Future<void> _loadMoreLogs() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() => _isLoadingMore = true);

    try {
      final newLogs = await _auditService.getAuditLogs(
        limit: _pageSize,
        offset: (_currentPage + 1) * _pageSize,
      );

      setState(() {
        _auditLogs.addAll(newLogs);
        _currentPage++;
        _hasMoreData = newLogs.length >= _pageSize;
        _isLoadingMore = false;
      });

      _applyFilters();
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _loadFilterOptions() async {
    try {
      final users = await _auditService.getDistinctUsers();
      final modules = await _auditService.getDistinctModules();

      setState(() {
        _availableUsers = ['All Users', ...users];
        _availableModules = ['All Modules', ...modules];
      });
    } catch (e) {
      // Silent fail for filter options
    }
  }

  void _applyFilters() {
    List<AuditLogEntry> filtered = List.from(_auditLogs);

    // Search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((log) {
        return log.userName.toLowerCase().contains(query) ||
            log.tableName.toLowerCase().contains(query) ||
            (log.oldValues?.toString().toLowerCase().contains(query) ??
                false) ||
            (log.newValues?.toString().toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Date range filter
    if (_selectedDateRange != null) {
      filtered = filtered.where((log) {
        return log.createdAt.isAfter(_selectedDateRange!.start) &&
            log.createdAt
                .isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // User filter
    if (_selectedUser != null && _selectedUser != 'All Users') {
      filtered =
          filtered.where((log) => log.userName == _selectedUser).toList();
    }

    // Module filter
    if (_selectedModule != null && _selectedModule != 'All Modules') {
      filtered =
          filtered.where((log) => log.tableName == _selectedModule).toList();
    }

    // Action type filter
    if (_selectedActionType != null && _selectedActionType != 'All Actions') {
      filtered = filtered
          .where((log) => log.actionType.toUpperCase() == _selectedActionType)
          .toList();
    }

    setState(() => _filteredLogs = filtered);
  }

  void _showFilterPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterPanelWidget(
        selectedUser: _selectedUser,
        selectedModule: _selectedModule,
        selectedActionType: _selectedActionType,
        availableUsers: _availableUsers,
        availableModules: _availableModules,
        actionTypes: _actionTypes,
        onUserChanged: (value) {
          setState(() => _selectedUser = value);
          _applyFilters();
        },
        onModuleChanged: (value) {
          setState(() => _selectedModule = value);
          _applyFilters();
        },
        onActionTypeChanged: (value) {
          setState(() => _selectedActionType = value);
          _applyFilters();
        },
        onReset: () {
          setState(() {
            _selectedUser = null;
            _selectedModule = null;
            _selectedActionType = null;
            _selectedDateRange = null;
          });
          _applyFilters();
        },
        resultCount: _filteredLogs.length,
      ),
    );
  }

  Future<void> _exportLogs() async {
    try {
      await _auditService.exportAuditLogs(_filteredLogs);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audit logs exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de terminer l’opération. Réessayez.')),
        );
      }
    }
  }

  void _showUserAnalytics() async {
    final currentUser = _auditService.getCurrentUserId();
    if (currentUser == null) return;

    final userProfile = await _auditService.getUserProfile(currentUser);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: 90.h,
        child: AnalyticsDashboardWidget(
          userId: currentUser,
          userName: userProfile['full_name'] ?? 'Unknown User',
          userRole: userProfile['role'] ?? 'user',
        ),
      ),
    );
  }

  void _showForensicAnalysis() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: 90.h,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(4.w),
              topRight: Radius.circular(4.w),
            ),
          ),
          child: DefaultTabController(
            length: 4,
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: EdgeInsets.only(top: 1.h, bottom: 2.h),
                  width: 12.w,
                  height: 0.5.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),

                // Title
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Row(
                    children: [
                      Icon(Icons.science,
                          color: Theme.of(context).primaryColor, size: 6.w),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Advanced Forensic Analysis',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Incident investigation tools',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Tabs
                TabBar(
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Theme.of(context).primaryColor,
                  tabs: const [
                    Tab(icon: Icon(Icons.timeline), text: 'Timeline'),
                    Tab(icon: Icon(Icons.map), text: 'Map'),
                    Tab(icon: Icon(Icons.fingerprint), text: 'Devices'),
                    Tab(icon: Icon(Icons.hub), text: 'Patterns'),
                  ],
                ),

                // Tab views
                Expanded(
                  child: TabBarView(
                    children: [
                      ForensicTimelineWidget(
                        userId: _auditService.getCurrentUserId() ?? '',
                        startTime:
                            DateTime.now().subtract(const Duration(days: 7)),
                        endTime: DateTime.now(),
                      ),
                      const IpGeolocationMapWidget(),
                      const DeviceFingerprintingWidget(),
                      AnomalyCorrelationWidget(
                          userId: _auditService.getCurrentUserId()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Audit Log'),
            if (_showNewActivityBadge) ...[
              SizedBox(width: 2.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fiber_manual_record,
                        size: 2.w, color: Colors.white),
                    SizedBox(width: 1.w),
                    Text(
                      '$_newActivityCount new',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          // Real-time indicator
          Padding(
            padding: EdgeInsets.only(right: 2.w),
            child: Center(
              child: Row(
                children: [
                  Container(
                    width: 2.w,
                    height: 2.w,
                    decoration: BoxDecoration(
                      color: _realtimeSubscription != null
                          ? Colors.green
                          : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    _realtimeSubscription != null ? 'Live' : 'Offline',
                    style: TextStyle(fontSize: 10.sp),
                  ),
                ],
              ),
            ),
          ),
          // Analytics button
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: _showUserAnalytics,
            tooltip: 'User Analytics',
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: _filteredLogs.isEmpty ? null : _exportLogs,
            tooltip: 'Export Logs',
          ),
          // Add forensic analysis button
          IconButton(
            icon: const Icon(Icons.science_outlined),
            onPressed: _showForensicAnalysis,
            tooltip: 'Forensic Analysis',
          ),
        ],
      ),
      body: Column(
        children: [
          // New activity banner
          if (_showNewActivityBadge)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 3.w),
              color: Colors.blue[50],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '$_newActivityCount new audit ${_newActivityCount == 1 ? 'entry' : 'entries'} available',
                      style: TextStyle(
                        color: Colors.blue[900],
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      _scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                      _clearNewActivityBadge();
                    },
                    icon: const Icon(Icons.arrow_upward, size: 16),
                    label: const Text('View'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue[900],
                    ),
                  ),
                ],
              ),
            ),

          // Date range selector header
          DateRangeSelectorWidget(
            selectedDateRange: _selectedDateRange,
            onDateRangeChanged: (range) {
              setState(() => _selectedDateRange = range);
              _applyFilters();
            },
          ),

          // Search and filter bar
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText:
                          'Rechercher par utilisateur, module ou modifications...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 1.5.h,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.filter_list, color: Colors.white),
                    onPressed: _showFilterPanel,
                    tooltip: 'Advanced Filters',
                  ),
                ),
              ],
            ),
          ),

          // Results count
          if (_filteredLogs.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              child: Text(
                '${_filteredLogs.length} audit entries found',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12.sp,
                ),
              ),
            ),

          SizedBox(height: 1.h),

          // Audit logs list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredLogs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_outlined,
                              size: 15.w,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'No audit logs found',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (_searchController.text.isNotEmpty ||
                                _selectedDateRange != null ||
                                _selectedUser != null ||
                                _selectedModule != null ||
                                _selectedActionType != null)
                              Padding(
                                padding: EdgeInsets.only(top: 1.h),
                                child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _selectedDateRange = null;
                                      _selectedUser = null;
                                      _selectedModule = null;
                                      _selectedActionType = null;
                                    });
                                    _applyFilters();
                                  },
                                  child: const Text('Clear Filters'),
                                ),
                              ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAuditLogs,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.all(3.w),
                          itemCount:
                              _filteredLogs.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _filteredLogs.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final log = _filteredLogs[index];
                            final isNewEntry = index < _newActivityCount;

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                color: isNewEntry
                                    ? Colors.blue[50]
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: AuditLogCardWidget(
                                auditLog: log,
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
