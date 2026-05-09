import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/security_monitoring_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/assign_investigator_dialog_widget.dart';
import './widgets/create_incident_dialog_widget.dart';
import './widgets/incident_card_widget.dart';
import './widgets/incident_details_dialog_widget.dart';
import './widgets/incident_filters_widget.dart';
import './widgets/status_progression_widget.dart';

class IncidentManagementCenter extends StatefulWidget {
  const IncidentManagementCenter({super.key});

  @override
  State<IncidentManagementCenter> createState() =>
      _IncidentManagementCenterState();
}

class _IncidentManagementCenterState extends State<IncidentManagementCenter> {
  final SecurityMonitoringService _securityService =
      SecurityMonitoringService();

  List<Map<String, dynamic>> _incidents = [];
  bool _isLoading = true;
  String? _selectedSeverity;
  String? _selectedStatus;
  String? _selectedCategory;

  // Real-time subscription channels
  RealtimeChannel? _incidentsChannel;
  RealtimeChannel? _evidenceChannel;
  RealtimeChannel? _escalationChannel;

  // Real-time notification state
  bool _showRealtimeNotification = false;
  String _realtimeNotificationMessage = '';
  Color _realtimeNotificationColor = Colors.blue;

  // Severity filter options
  final List<String> _severityOptions = ['critical', 'high', 'medium', 'low'];

  // Status filter options (workflow progression)
  final List<String> _statusOptions = [
    'pending',
    'reviewing',
    'resolved',
    'false_positive'
  ];

  // Category filter options
  final List<String> _categoryOptions = [
    'transaction',
    'access',
    'inventory',
    'permission',
    'system'
  ];

  @override
  void initState() {
    super.initState();
    _loadIncidents();
    _setupRealtimeSubscriptions();
  }

  @override
  void dispose() {
    _disposeRealtimeSubscriptions();
    super.dispose();
  }

  /// Setup real-time subscriptions for incidents, evidence, and escalations
  void _setupRealtimeSubscriptions() {
    // Subscribe to incident status changes and new incidents
    _incidentsChannel = _securityService.subscribeToAnomalies(
      onInsert: (incident) {
        _handleNewIncident(incident);
      },
      onUpdate: (incident) {
        _handleIncidentUpdate(incident);
      },
    );

    // Subscribe to evidence additions (document attachments)
    _evidenceChannel = Supabase.instance.client
        .channel('incident-evidence')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'document_attachments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'entity_type',
            value: 'security_anomaly',
          ),
          callback: (payload) => _handleNewEvidence(payload.newRecord),
        )
        .subscribe();

    // Subscribe to investigator assignments (escalation history)
    _escalationChannel = Supabase.instance.client
        .channel('incident-escalations')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'escalation_history',
          callback: (payload) => _handleNewEscalation(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'escalation_history',
          callback: (payload) => _handleEscalationUpdate(payload.newRecord),
        )
        .subscribe();
  }

  /// Dispose real-time subscriptions
  void _disposeRealtimeSubscriptions() {
    _incidentsChannel?.unsubscribe();
    _evidenceChannel?.unsubscribe();
    _escalationChannel?.unsubscribe();
  }

  /// Handle new incident creation in real-time
  void _handleNewIncident(Map<String, dynamic> incident) {
    if (!mounted) return;

    setState(() {
      _incidents.insert(0, incident);
      _showRealtimeNotification = true;
      _realtimeNotificationMessage =
          '🚨 New ${incident['severity']} incident detected: ${incident['title']}';
      _realtimeNotificationColor = _getSeverityColor(incident['severity']);
    });

    // Auto-hide notification after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _showRealtimeNotification = false);
      }
    });

    // Play notification sound or vibration (optional)
    _playNotificationAlert();
  }

  /// Handle incident status updates in real-time
  void _handleIncidentUpdate(Map<String, dynamic> updatedIncident) {
    if (!mounted) return;

    setState(() {
      final index =
          _incidents.indexWhere((inc) => inc['id'] == updatedIncident['id']);
      if (index != -1) {
        final oldStatus = _incidents[index]['alert_status'];
        final newStatus = updatedIncident['alert_status'];

        _incidents[index] = updatedIncident;

        if (oldStatus != newStatus) {
          _showRealtimeNotification = true;
          _realtimeNotificationMessage =
              '📝 Incident "${updatedIncident['title']}" status changed: $oldStatus → $newStatus';
          _realtimeNotificationColor = Colors.blue;
        }
      }
    });

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _showRealtimeNotification = false);
      }
    });
  }

  /// Handle new evidence additions in real-time
  void _handleNewEvidence(Map<String, dynamic> evidence) {
    if (!mounted) return;

    final incidentId = evidence['entity_id'];
    final incident = _incidents.firstWhere((inc) => inc['id'] == incidentId,
        orElse: () => {});

    if (incident.isNotEmpty) {
      setState(() {
        _showRealtimeNotification = true;
        _realtimeNotificationMessage =
            '📎 New evidence added to incident: ${incident['title']}';
        _realtimeNotificationColor = Colors.green;
      });

      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() => _showRealtimeNotification = false);
        }
      });
    }
  }

  /// Handle new investigator assignments in real-time
  void _handleNewEscalation(Map<String, dynamic> escalation) {
    if (!mounted) return;

    final incidentId = escalation['anomaly_id'];
    final incident = _incidents.firstWhere((inc) => inc['id'] == incidentId,
        orElse: () => {});

    if (incident.isNotEmpty) {
      setState(() {
        _showRealtimeNotification = true;
        _realtimeNotificationMessage =
            '👤 Incident "${incident['title']}" has been escalated to investigator';
        _realtimeNotificationColor = Colors.orange;
      });

      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() => _showRealtimeNotification = false);
        }
      });

      _loadIncidents();
    }
  }

  /// Handle escalation updates in real-time
  void _handleEscalationUpdate(Map<String, dynamic> escalation) {
    if (!mounted) return;

    if (escalation['response_received_at'] != null) {
      final incidentId = escalation['anomaly_id'];
      final incident = _incidents.firstWhere(
        (inc) => inc['id'] == incidentId,
        orElse: () => {},
      );

      if (incident.isNotEmpty) {
        setState(() {
          _showRealtimeNotification = true;
          _realtimeNotificationMessage =
              '✅ Investigator responded to incident: ${incident['title']}';
          _realtimeNotificationColor = Colors.teal;
        });

        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() => _showRealtimeNotification = false);
          }
        });
      }
    }
  }

  /// Play notification alert (vibration/sound)
  void _playNotificationAlert() {
    // Optional: Implement vibration or sound notification
    // This would require additional packages like vibration or audioplayers
  }

  Future<void> _loadIncidents() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final incidents = await _securityService.getSecurityAnomalies(
        severity: _selectedSeverity,
        status: _selectedStatus,
        category: _selectedCategory,
        limit: 100,
      );

      if (!mounted) return;
      setState(() {
        _incidents = incidents;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load incidents: $e')),
      );
    }
  }

  Future<void> _updateIncidentStatus(
    String incidentId,
    String newStatus,
    String? notes,
  ) async {
    try {
      await _securityService.updateAnomalyStatus(
        anomalyId: incidentId,
        status: newStatus,
        resolutionNotes: notes,
      );

      await _loadIncidents();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incident status updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  void _showIncidentDetails(Map<String, dynamic> incident) {
    showDialog(
      context: context,
      builder: (context) => IncidentDetailsDialogWidget(
        incident: incident,
        onStatusUpdate: (newStatus, notes) {
          Navigator.pop(context);
          _updateIncidentStatus(incident['id'], newStatus, notes);
        },
        onAddEvidence: (evidence) async {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Evidence added successfully')),
          );
        },
      ),
    );
  }

  void _showCreateIncidentDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateIncidentDialogWidget(
        onIncidentCreated: () {
          Navigator.pop(context);
          _loadIncidents();
        },
      ),
    );
  }

  void _showAssignInvestigatorDialog(Map<String, dynamic> incident) {
    showDialog(
      context: context,
      builder: (context) => AssignInvestigatorDialogWidget(
        incident: incident,
        onAssigned: () {
          Navigator.pop(context);
          _loadIncidents();
        },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(
        title: 'Incident Management Center',
        actions: [
          // Real-time connection indicator
          Padding(
            padding: EdgeInsets.only(right: 2.w),
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(51),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 2.w,
                      height: 2.w,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      'Live',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => IncidentFiltersWidget(
                  selectedSeverity: _selectedSeverity,
                  selectedStatus: _selectedStatus,
                  selectedCategory: _selectedCategory,
                  severityOptions: _severityOptions,
                  statusOptions: _statusOptions,
                  categoryOptions: _categoryOptions,
                  onFiltersApplied: (severity, status, category) {
                    setState(() {
                      _selectedSeverity = severity;
                      _selectedStatus = status;
                      _selectedCategory = category;
                    });
                    _loadIncidents();
                  },
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadIncidents,
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _incidents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.security,
                            size: 20.w,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'No incidents detected',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            'Your system is secure',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Status Progression Overview
                        Container(
                          margin: EdgeInsets.all(2.w),
                          child: StatusProgressionWidget(
                            incidents: _incidents,
                          ),
                        ),

                        // Active Filters Display
                        if (_selectedSeverity != null ||
                            _selectedStatus != null ||
                            _selectedCategory != null)
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 3.w, vertical: 1.h),
                            color: Colors.blue.shade50,
                            child: Row(
                              children: [
                                Text(
                                  'Active Filters:',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 2.w),
                                Expanded(
                                  child: Wrap(
                                    spacing: 2.w,
                                    children: [
                                      if (_selectedSeverity != null)
                                        Chip(
                                          label: Text(_selectedSeverity!),
                                          backgroundColor: _getSeverityColor(
                                              _selectedSeverity!),
                                          labelStyle: const TextStyle(
                                              color: Colors.white),
                                          deleteIcon: const Icon(Icons.close,
                                              color: Colors.white),
                                          onDeleted: () {
                                            setState(
                                                () => _selectedSeverity = null);
                                            _loadIncidents();
                                          },
                                        ),
                                      if (_selectedStatus != null)
                                        Chip(
                                          label: Text(_selectedStatus!),
                                          onDeleted: () {
                                            setState(
                                                () => _selectedStatus = null);
                                            _loadIncidents();
                                          },
                                        ),
                                      if (_selectedCategory != null)
                                        Chip(
                                          label: Text(_selectedCategory!),
                                          onDeleted: () {
                                            setState(
                                                () => _selectedCategory = null);
                                            _loadIncidents();
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Incidents List
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _loadIncidents,
                            child: ListView.builder(
                              padding: EdgeInsets.all(2.w),
                              itemCount: _incidents.length,
                              itemBuilder: (context, index) {
                                final incident = _incidents[index];
                                return IncidentCardWidget(
                                  incident: incident,
                                  onTap: () => _showIncidentDetails(incident),
                                  onAssignInvestigator: () =>
                                      _showAssignInvestigatorDialog(incident),
                                  onChangeStatus: (newStatus) =>
                                      _updateIncidentStatus(
                                    incident['id'],
                                    newStatus,
                                    null,
                                  ),
                                  onEscalate: () async {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Incident escalated to admin')),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),

          // Real-time notification banner
          if (_showRealtimeNotification)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                elevation: 4.0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: EdgeInsets.all(3.w),
                  color: _realtimeNotificationColor.withAlpha(26),
                  child: Row(
                    children: [
                      Icon(
                        Icons.notifications_active,
                        color: _realtimeNotificationColor,
                        size: 6.w,
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Text(
                          _realtimeNotificationMessage,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: _realtimeNotificationColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        color: _realtimeNotificationColor,
                        onPressed: () {
                          setState(() => _showRealtimeNotification = false);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateIncidentDialog,
        icon: const Icon(Icons.add),
        label: const Text('Create Incident'),
        backgroundColor: Colors.blue.shade700,
      ),
    );
  }
}
