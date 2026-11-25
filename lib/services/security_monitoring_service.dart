import 'package:supabase_flutter/supabase_flutter.dart';

class SecurityMonitoringService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================================
  // ANOMALY DETECTION
  // ============================================================================

  /// Trigger all security detection functions
  Future<void> runSecurityChecks() async {
    try {
      await _supabase.rpc('detect_suspicious_transactions');
      await _supabase.rpc('detect_unauthorized_access');
      await _supabase.rpc('detect_inventory_anomalies');
      await _supabase.rpc('calculate_user_risk_scores');
    } catch (e) {
      throw Exception('Failed to run security checks: $e');
    }
  }

  /// Get all security anomalies with optional filters
  Future<List<Map<String, dynamic>>> getSecurityAnomalies({
    String? category,
    String? severity,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? limit = 50,
  }) async {
    try {
      var query = _supabase.from('security_anomalies').select('''
            *,
            user:user_id(id, full_name, email, role),
            resolver:resolved_by(id, full_name, email)
          ''');

      if (category != null) {
        query = query.eq('category', category);
      }
      if (severity != null) {
        query = query.eq('severity', severity);
      }
      if (status != null) {
        query = query.eq('alert_status', status);
      }
      if (startDate != null) {
        query = query.gte('detected_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('detected_at', endDate.toIso8601String());
      }

      final response =
          await query.order('detected_at', ascending: false).limit(limit ?? 50);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch security anomalies: $e');
    }
  }

  /// Get pending anomalies count
  Future<int> getPendingAnomaliesCount() async {
    try {
      final response = await _supabase
          .from('security_anomalies')
          .select('id')
          .eq('alert_status', 'pending')
          .count();

      return response.count;
    } catch (e) {
      throw Exception('Failed to fetch pending anomalies count: $e');
    }
  }

  /// Get anomalies by severity distribution
  Future<Map<String, int>> getAnomaliesBySeverity() async {
    try {
      final response =
          await _supabase.from('security_anomalies').select('severity');

      final distribution = <String, int>{
        'low': 0,
        'medium': 0,
        'high': 0,
        'critical': 0,
      };

      for (var anomaly in response) {
        final severity = anomaly['severity'] as String;
        distribution[severity] = (distribution[severity] ?? 0) + 1;
      }

      return distribution;
    } catch (e) {
      throw Exception('Failed to fetch severity distribution: $e');
    }
  }

  /// Update anomaly status
  Future<void> updateAnomalyStatus({
    required String anomalyId,
    required String status,
    String? resolutionNotes,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      final updates = <String, dynamic>{
        'alert_status': status,
      };

      if (status == 'resolved' || status == 'false_positive') {
        updates['resolved_at'] = DateTime.now().toIso8601String();
        updates['resolved_by'] = userId;
        if (resolutionNotes != null) {
          updates['resolution_notes'] = resolutionNotes;
        }
      }

      await _supabase
          .from('security_anomalies')
          .update(updates)
          .eq('id', anomalyId);
    } catch (e) {
      throw Exception('Failed to update anomaly status: $e');
    }
  }

  // ============================================================================
  // USER RISK SCORES
  // ============================================================================

  /// Get user risk scores
  Future<List<Map<String, dynamic>>> getUserRiskScores({
    double? minScore,
    int? limit = 20,
  }) async {
    try {
      // Build query with proper chaining to avoid type conflicts
      final baseQuery = _supabase.from('user_risk_scores').select('''
            *,
            user:user_id(id, full_name, email, role)
          ''');

      // Apply optional filters
      final filteredQuery = minScore != null
          ? baseQuery.gte('overall_score', minScore)
          : baseQuery;

      // Apply ordering and limit
      final response = await filteredQuery
          .order('overall_score', ascending: false)
          .limit(limit ?? 20);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch user risk scores: $e');
    }
  }

  /// Get risk score for specific user
  Future<Map<String, dynamic>?> getUserRiskScore(String userId) async {
    try {
      final response = await _supabase
          .from('user_risk_scores')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to fetch user risk score: $e');
    }
  }

  // ============================================================================
  // FAILED LOGIN ATTEMPTS
  // ============================================================================

  /// Get failed login attempts
  Future<List<Map<String, dynamic>>> getFailedLoginAttempts({
    String? email,
    DateTime? startDate,
    int? limit = 50,
  }) async {
    try {
      // Build query with proper chaining to avoid type conflicts
      final baseQuery = _supabase.from('failed_login_attempts').select('*');

      // Apply optional filters
      var filteredQuery = baseQuery;
      if (email != null) {
        filteredQuery = filteredQuery.eq('email', email);
      }
      if (startDate != null) {
        filteredQuery =
            filteredQuery.gte('attempt_time', startDate.toIso8601String());
      }

      // Apply ordering and limit
      final response = await filteredQuery
          .order('attempt_time', ascending: false)
          .limit(limit ?? 50);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch failed login attempts: $e');
    }
  }

  /// Record failed login attempt
  Future<void> recordFailedLogin({
    required String email,
    String? ipAddress,
    String? userAgent,
    String? failureReason,
  }) async {
    try {
      await _supabase.from('failed_login_attempts').insert({
        'email': email,
        'ip_address': ipAddress,
        'user_agent': userAgent,
        'failure_reason': failureReason,
      });
    } catch (e) {
      throw Exception('Failed to record failed login: $e');
    }
  }

  // ============================================================================
  // SECURITY THRESHOLDS
  // ============================================================================

  /// Get security thresholds
  Future<List<Map<String, dynamic>>> getSecurityThresholds({
    String? category,
  }) async {
    try {
      var query = _supabase
          .from('security_thresholds')
          .select('*')
          .eq('is_active', true);

      if (category != null) {
        query = query.eq('category', category);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch security thresholds: $e');
    }
  }

  /// Update security threshold
  Future<void> updateSecurityThreshold({
    required String thresholdId,
    required double value,
  }) async {
    try {
      await _supabase.from('security_thresholds').update({
        'threshold_value': value,
        'updated_at': DateTime.now().toIso8601String()
      }).eq('id', thresholdId);
    } catch (e) {
      throw Exception('Failed to update threshold: $e');
    }
  }

  // ============================================================================
  // REAL-TIME SUBSCRIPTIONS
  // ============================================================================

  /// Subscribe to new security anomalies
  RealtimeChannel subscribeToAnomalies({
    required Function(Map<String, dynamic>) onInsert,
    required Function(Map<String, dynamic>) onUpdate,
  }) {
    return _supabase
        .channel('security-anomalies')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'security_anomalies',
          callback: (payload) => onInsert(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'security_anomalies',
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .subscribe();
  }

  /// Subscribe to evidence additions for specific incident
  RealtimeChannel subscribeToIncidentEvidence({
    required String incidentId,
    required Function(Map<String, dynamic>) onEvidenceAdded,
  }) {
    return _supabase
        .channel('incident-evidence-$incidentId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'document_attachments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'entity_id',
            value: incidentId,
          ),
          callback: (payload) => onEvidenceAdded(payload.newRecord),
        )
        .subscribe();
  }

  /// Subscribe to investigator assignments for specific incident
  RealtimeChannel subscribeToIncidentAssignments({
    required String incidentId,
    required Function(Map<String, dynamic>) onAssignment,
    required Function(Map<String, dynamic>) onUpdate,
  }) {
    return _supabase
        .channel('incident-assignments-$incidentId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'escalation_history',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'anomaly_id',
            value: incidentId,
          ),
          callback: (payload) => onAssignment(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'escalation_history',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'anomaly_id',
            value: incidentId,
          ),
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .subscribe();
  }

  /// Subscribe to all evidence additions (for team-wide monitoring)
  RealtimeChannel subscribeToAllEvidence({
    required Function(Map<String, dynamic>) onEvidenceAdded,
  }) {
    return _supabase
        .channel('all-incident-evidence')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'document_attachments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'entity_type',
            value: 'security_anomaly',
          ),
          callback: (payload) => onEvidenceAdded(payload.newRecord),
        )
        .subscribe();
  }

  /// Subscribe to all investigator assignments (for team-wide monitoring)
  RealtimeChannel subscribeToAllAssignments({
    required Function(Map<String, dynamic>) onAssignment,
    required Function(Map<String, dynamic>) onUpdate,
  }) {
    return _supabase
        .channel('all-incident-assignments')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'escalation_history',
          callback: (payload) => onAssignment(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'escalation_history',
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .subscribe();
  }

  /// Subscribe to incident status changes with custom filters
  RealtimeChannel subscribeToIncidentStatusChanges({
    String? severity,
    String? category,
    required Function(Map<String, dynamic>) onStatusChange,
  }) {
    final channel = _supabase.channel('incident-status-changes');

    var changeBuilder = channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'security_anomalies',
      callback: (payload) {
        final incident = payload.newRecord;
        final oldIncident = payload.oldRecord;

        // Check if status actually changed
        if (incident['alert_status'] != oldIncident['alert_status']) {
          onStatusChange(incident);
        }
      },
    );

    return changeBuilder.subscribe();
  }

  // ============================================================================
  // INCIDENT MANAGEMENT EXTENSIONS
  // ============================================================================

  /// Get incidents with investigator assignments
  Future<List<Map<String, dynamic>>> getIncidentsWithInvestigators({
    String? severity,
    String? status,
    int? limit = 50,
  }) async {
    try {
      var query = _supabase.from('security_anomalies').select('''
            *,
            user:user_id(id, full_name, email, role),
            resolver:resolved_by(id, full_name, email),
            investigation_reports:forensic_investigation_reports!forensic_investigation_reports_user_id_fkey(
              id,
              investigator:investigator_id(id, full_name, email),
              status,
              severity
            )
          ''');

      if (severity != null) {
        query = query.eq('severity', severity);
      }
      if (status != null) {
        query = query.eq('alert_status', status);
      }

      final response =
          await query.order('detected_at', ascending: false).limit(limit ?? 50);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch incidents with investigators: $e');
    }
  }

  /// Get incident timeline
  Future<List<Map<String, dynamic>>> getIncidentTimeline(
      String incidentId) async {
    try {
      final response = await _supabase
          .from('audit_logs')
          .select('*')
          .eq('table_name', 'security_anomalies')
          .eq('record_id', incidentId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch incident timeline: $e');
    }
  }

  /// Escalate incident
  Future<void> escalateIncident({
    required String incidentId,
    required String escalationReason,
  }) async {
    try {
      // Get incident details
      final incident = await _supabase
          .from('security_anomalies')
          .select('*')
          .eq('id', incidentId)
          .single();

      // Find appropriate escalation configuration
      final escalationConfigs = await _supabase
          .from('escalation_configurations')
          .select('*, primary_admin:primary_admin_id(id, email, full_name)')
          .eq('is_active', true)
          .eq('severity_level', incident['severity']);

      if (escalationConfigs.isEmpty) {
        throw Exception('No escalation configuration found');
      }

      final config = escalationConfigs.first;

      final primaryAdmin = config['primary_admin'] as Map<String, dynamic>?;
      final recipientEmail = (primaryAdmin?['email'] as String?)?.trim();
      if (recipientEmail == null || recipientEmail.isEmpty) {
        throw StateError('Adresse e-mail d’escalade indisponible');
      }

      // Create escalation record
      await _supabase.from('escalation_history').insert({
        'anomaly_id': incidentId,
        'escalation_config_id': config['id'],
        'escalated_to': config['primary_admin_id'],
        'escalation_level_reached': incident['severity'],
        'response_action': escalationReason,
      });

      // Send notification
      await _supabase.from('notification_queue').insert({
        'recipient_id': config['primary_admin_id'],
        'recipient_email': recipientEmail,
        'notification_type': 'new_order',
        'subject': 'Incident Escalated: ${incident['title']}',
        'message': escalationReason,
        'related_entity_type': 'security_anomaly',
        'related_entity_id': incidentId,
        'channel': 'email',
        'status': 'pending',
      });
    } catch (e) {
      throw Exception('Failed to escalate incident: $e');
    }
  }

  /// Get incident statistics for reporting
  Future<Map<String, dynamic>> getIncidentStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase.from('security_anomalies').select('*');

      if (startDate != null) {
        query = query.gte('detected_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('detected_at', endDate.toIso8601String());
      }

      final incidents = await query;

      // Calculate statistics
      final totalIncidents = incidents.length;
      final statusCounts = <String, int>{};
      final severityCounts = <String, int>{};
      final categoryCounts = <String, int>{};
      int resolvedCount = 0;
      int avgResolutionTimeHours = 0;

      for (var incident in incidents) {
        final status = incident['alert_status'] as String;
        final severity = incident['severity'] as String;
        final category = incident['category'] as String;

        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
        severityCounts[severity] = (severityCounts[severity] ?? 0) + 1;
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;

        if (status == 'resolved' && incident['resolved_at'] != null) {
          resolvedCount++;
          final detectedAt = DateTime.parse(incident['detected_at']);
          final resolvedAt = DateTime.parse(incident['resolved_at']);
          final resolutionTime = resolvedAt.difference(detectedAt).inHours;
          avgResolutionTimeHours += resolutionTime;
        }
      }

      if (resolvedCount > 0) {
        avgResolutionTimeHours =
            (avgResolutionTimeHours / resolvedCount).round();
      }

      return {
        'total_incidents': totalIncidents,
        'status_distribution': statusCounts,
        'severity_distribution': severityCounts,
        'category_distribution': categoryCounts,
        'resolution_rate': totalIncidents > 0
            ? (resolvedCount / totalIncidents * 100).toInt()
            : 0,
        'avg_resolution_time_hours': avgResolutionTimeHours,
      };
    } catch (e) {
      throw Exception('Failed to fetch incident statistics: $e');
    }
  }

  /// Export incident report
  Future<Map<String, dynamic>> generateIncidentReport({
    required String incidentId,
    String format = 'pdf',
  }) async {
    try {
      final incident = await _supabase.from('security_anomalies').select('''
            *,
            user:user_id(id, full_name, email, role),
            resolver:resolved_by(id, full_name, email)
          ''').eq('id', incidentId).single();

      final timeline = await getIncidentTimeline(incidentId);

      final userId = _supabase.auth.currentUser?.id;

      // Create export record
      final exportRecord = await _supabase
          .from('forensic_export_history')
          .insert({
            'exported_by': userId,
            'format': format,
            'export_name':
                'incident_report_${incident['title']}_${DateTime.now().millisecondsSinceEpoch}',
            'status': 'completed',
            'filter_start_date': incident['detected_at'],
            'filter_end_date':
                incident['resolved_at'] ?? DateTime.now().toIso8601String(),
            'record_count': timeline.length,
          })
          .select()
          .single();

      return {
        'export_id': exportRecord['id'],
        'incident': incident,
        'timeline': timeline,
        'format': format,
      };
    } catch (e) {
      throw Exception('Failed to generate incident report: $e');
    }
  }

  // ============================================================================
  // ANALYTICS & REPORTS
  // ============================================================================

  /// Get security dashboard summary
  Future<Map<String, dynamic>> getSecurityDashboardSummary() async {
    try {
      // Get counts
      final pendingCount = await getPendingAnomaliesCount();
      final severityDist = await getAnomaliesBySeverity();

      // Get high-risk users count
      final highRiskUsers = await _supabase
          .from('user_risk_scores')
          .select('id')
          .gte('overall_score', 60)
          .count();

      // Get recent failed logins
      final recentFailedLogins = await _supabase
          .from('failed_login_attempts')
          .select('id')
          .gte(
              'attempt_time',
              DateTime.now()
                  .subtract(const Duration(hours: 24))
                  .toIso8601String())
          .count();

      return {
        'pending_anomalies': pendingCount,
        'severity_distribution': severityDist,
        'high_risk_users': highRiskUsers.count,
        'failed_logins_24h': recentFailedLogins.count,
      };
    } catch (e) {
      throw Exception('Failed to fetch dashboard summary: $e');
    }
  }

  /// Get anomaly trends (last 30 days)
  Future<List<Map<String, dynamic>>> getAnomalyTrends() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final response = await _supabase
          .from('security_anomalies')
          .select('detected_at, severity, category')
          .gte('detected_at', thirtyDaysAgo.toIso8601String())
          .order('detected_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch anomaly trends: $e');
    }
  }
}
