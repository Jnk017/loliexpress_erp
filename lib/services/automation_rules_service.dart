import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

class AutomationRulesService {
  final _supabase = SupabaseService.instance.client;

  // ===========================
  // AUTOMATION RULES MANAGEMENT
  // ===========================

  Future<List<Map<String, dynamic>>> getAutomationRules({
    bool? isActive,
    String? triggerType,
  }) async {
    try {
      var query = _supabase.from('automation_rules').select('''
        *,
        created_by:user_profiles!automation_rules_created_by_fkey(full_name, email)
      ''');

      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      if (triggerType != null) {
        query = query.eq('trigger_type', triggerType);
      }

      final response = await query.order('priority', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch automation rules: $e');
    }
  }

  Future<Map<String, dynamic>> getRuleDetails(String ruleId) async {
    try {
      final response = await _supabase.from('automation_rules').select('''
            *,
            conditions:rule_conditions(*),
            actions:rule_actions(*),
            created_by:user_profiles!automation_rules_created_by_fkey(full_name, email)
          ''').eq('id', ruleId).single();

      return response;
    } catch (e) {
      throw Exception('Failed to fetch rule details: $e');
    }
  }

  Future<void> createAutomationRule({
    required String ruleName,
    required String description,
    required String triggerType,
    required List<Map<String, dynamic>> conditions,
    required List<Map<String, dynamic>> actions,
    int priority = 0,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final ruleResponse = await _supabase
          .from('automation_rules')
          .insert({
            'rule_name': ruleName,
            'description': description,
            'trigger_type': triggerType,
            'priority': priority,
            'created_by': userId,
          })
          .select('id')
          .single();

      final ruleId = ruleResponse['id'];

      if (conditions.isNotEmpty) {
        await _supabase.from('rule_conditions').insert(
              conditions.map((c) => {...c, 'rule_id': ruleId}).toList(),
            );
      }

      if (actions.isNotEmpty) {
        await _supabase.from('rule_actions').insert(
              actions.map((a) => {...a, 'rule_id': ruleId}).toList(),
            );
      }
    } catch (e) {
      throw Exception('Failed to create automation rule: $e');
    }
  }

  Future<void> updateAutomationRule({
    required String ruleId,
    String? ruleName,
    String? description,
    bool? isActive,
    int? priority,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (ruleName != null) updates['rule_name'] = ruleName;
      if (description != null) updates['description'] = description;
      if (isActive != null) updates['is_active'] = isActive;
      if (priority != null) updates['priority'] = priority;
      updates['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.from('automation_rules').update(updates).eq('id', ruleId);
    } catch (e) {
      throw Exception('Failed to update automation rule: $e');
    }
  }

  Future<void> deleteAutomationRule(String ruleId) async {
    try {
      await _supabase.from('automation_rules').delete().eq('id', ruleId);
    } catch (e) {
      throw Exception('Failed to delete automation rule: $e');
    }
  }

  Future<void> toggleRuleStatus(String ruleId, bool isActive) async {
    try {
      await _supabase.from('automation_rules').update({
        'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String()
      }).eq('id', ruleId);
    } catch (e) {
      throw Exception('Failed to toggle rule status: $e');
    }
  }

  // ===========================
  // RULE CONDITIONS & ACTIONS
  // ===========================

  Future<void> updateRuleConditions(
    String ruleId,
    List<Map<String, dynamic>> conditions,
  ) async {
    try {
      await _supabase.from('rule_conditions').delete().eq('rule_id', ruleId);

      if (conditions.isNotEmpty) {
        await _supabase.from('rule_conditions').insert(
              conditions.map((c) => {...c, 'rule_id': ruleId}).toList(),
            );
      }
    } catch (e) {
      throw Exception('Failed to update rule conditions: $e');
    }
  }

  Future<void> updateRuleActions(
    String ruleId,
    List<Map<String, dynamic>> actions,
  ) async {
    try {
      await _supabase.from('rule_actions').delete().eq('rule_id', ruleId);

      if (actions.isNotEmpty) {
        await _supabase.from('rule_actions').insert(
              actions.map((a) => {...a, 'rule_id': ruleId}).toList(),
            );
      }
    } catch (e) {
      throw Exception('Failed to update rule actions: $e');
    }
  }

  // ===========================
  // RULE EXECUTION HISTORY
  // ===========================

  Future<List<Map<String, dynamic>>> getRuleExecutionHistory({
    String? ruleId,
    String? userId,
    int limit = 50,
  }) async {
    try {
      var query = _supabase.from('rule_execution_history').select('''
            *,
            rule:automation_rules(rule_name),
            user:user_profiles!rule_execution_history_affected_user_id_fkey(full_name, email)
          ''');

      if (ruleId != null) {
        query = query.eq('rule_id', ruleId);
      }

      if (userId != null) {
        query = query.eq('affected_user_id', userId);
      }

      final response =
          await query.order('executed_at', ascending: false).limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch rule execution history: $e');
    }
  }

  // ===========================
  // USER BLOCKING MANAGEMENT
  // ===========================

  Future<List<Map<String, dynamic>>> getBlockedUsers({
    String? status,
  }) async {
    try {
      var query = _supabase.from('user_blocking_records').select('''
        *,
        user:user_profiles!user_blocking_records_user_id_fkey(full_name, email, avatar_url),
        blocked_by_user:user_profiles!user_blocking_records_blocked_by_fkey(full_name),
        rule:automation_rules(rule_name)
      ''');

      if (status != null) {
        query = query.eq('blocking_status', status);
      }

      final response = await query.order('blocked_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch blocked users: $e');
    }
  }

  Future<void> blockUser({
    required String userId,
    required String blockingReason,
    DateTime? unblockAt,
    String? notes,
  }) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;

      await _supabase.from('user_blocking_records').insert({
        'user_id': userId,
        'blocking_reason': blockingReason,
        'unblock_at': unblockAt?.toIso8601String(),
        'blocked_by': currentUserId,
        'notes': notes,
      });
    } catch (e) {
      throw Exception('Failed to block user: $e');
    }
  }

  Future<void> unblockUser(String blockingRecordId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;

      await _supabase.from('user_blocking_records').update({
        'blocking_status': 'manually_removed',
        'unblocked_by': currentUserId,
        'unblocked_at': DateTime.now().toIso8601String(),
      }).eq('id', blockingRecordId);
    } catch (e) {
      throw Exception('Failed to unblock user: $e');
    }
  }

  // ===========================
  // ESCALATION MANAGEMENT
  // ===========================

  Future<List<Map<String, dynamic>>> getEscalationConfigurations() async {
    try {
      final response =
          await _supabase.from('escalation_configurations').select('''
            *,
            primary_admin:user_profiles!escalation_configurations_primary_admin_id_fkey(full_name, email)
          ''').eq('is_active', true).order('severity_level', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch escalation configurations: $e');
    }
  }

  Future<void> createEscalationConfig({
    required String escalationName,
    required String severityLevel,
    required int escalationDelayMinutes,
    required String primaryAdminId,
    List<String>? secondaryAdminIds,
    String? externalSupportEmail,
    List<String>? notificationChannels,
  }) async {
    try {
      await _supabase.from('escalation_configurations').insert({
        'escalation_name': escalationName,
        'severity_level': severityLevel,
        'escalation_delay_minutes': escalationDelayMinutes,
        'primary_admin_id': primaryAdminId,
        'secondary_admin_ids': secondaryAdminIds,
        'external_support_email': externalSupportEmail,
        'notification_channels': notificationChannels ?? ['email'],
      });
    } catch (e) {
      throw Exception('Failed to create escalation configuration: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getEscalationHistory({
    String? anomalyId,
    int limit = 50,
  }) async {
    try {
      var query = _supabase.from('escalation_history').select('''
            *,
            config:escalation_configurations(escalation_name, severity_level),
            anomaly:security_anomalies(title, severity),
            escalated_to_user:user_profiles!escalation_history_escalated_to_fkey(full_name, email)
          ''');

      if (anomalyId != null) {
        query = query.eq('anomaly_id', anomalyId);
      }

      final response =
          await query.order('escalated_at', ascending: false).limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch escalation history: $e');
    }
  }

  // ===========================
  // STATISTICS & ANALYTICS
  // ===========================

  Future<Map<String, dynamic>> getRulesStatistics() async {
    try {
      final totalRulesResponse = await _supabase
          .from('automation_rules')
          .select('id')
          .count(CountOption.exact);

      final activeRulesResponse = await _supabase
          .from('automation_rules')
          .select('id')
          .eq('is_active', true)
          .count(CountOption.exact);

      final executionsTodayResponse = await _supabase
          .from('rule_execution_history')
          .select('id')
          .gte(
              'executed_at',
              DateTime.now()
                  .subtract(const Duration(days: 1))
                  .toIso8601String())
          .count(CountOption.exact);

      final blockedUsersResponse = await _supabase
          .from('user_blocking_records')
          .select('id')
          .eq('blocking_status', 'active')
          .count(CountOption.exact);

      return {
        'total_rules': totalRulesResponse.count,
        'active_rules': activeRulesResponse.count,
        'executions_today': executionsTodayResponse.count,
        'currently_blocked_users': blockedUsersResponse.count,
      };
    } catch (e) {
      throw Exception('Failed to fetch rules statistics: $e');
    }
  }

  // ===========================
  // REAL-TIME SUBSCRIPTIONS
  // ===========================

  RealtimeChannel subscribeToRuleExecutions(
    Function(Map<String, dynamic>) onExecutionCreated,
  ) {
    return _supabase
        .channel('rule-executions')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'rule_execution_history',
          callback: (payload) => onExecutionCreated(payload.newRecord),
        )
        .subscribe();
  }

  RealtimeChannel subscribeToBlockingRecords(
    Function(Map<String, dynamic>) onBlockingUpdate,
  ) {
    return _supabase
        .channel('blocking-records')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_blocking_records',
          callback: (payload) => onBlockingUpdate(payload.newRecord),
        )
        .subscribe();
  }
}
