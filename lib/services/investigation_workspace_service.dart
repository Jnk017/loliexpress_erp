import './supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InvestigationWorkspaceService {
  final _supabase = SupabaseService.instance.client;

  // Team Management
  Future<List<Map<String, dynamic>>> getTeamMembers(String incidentId) async {
    try {
      final response = await _supabase
          .from('investigation_team_members')
          .select('*, user_profiles(*)')
          .eq('incident_id', incidentId)
          .eq('is_active', true)
          .order('assigned_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to fetch team members: $error');
    }
  }

  Future<void> addTeamMember({
    required String incidentId,
    required String userId,
    required String role,
    required String assignedBy,
  }) async {
    try {
      await _supabase.from('investigation_team_members').insert({
        'incident_id': incidentId,
        'user_id': userId,
        'role': role,
        'assigned_by': assignedBy,
      });
    } catch (error) {
      throw Exception('Failed to add team member: $error');
    }
  }

  Future<void> removeTeamMember(String teamMemberId) async {
    try {
      await _supabase
          .from('investigation_team_members')
          .update({'is_active': false}).eq('id', teamMemberId);
    } catch (error) {
      throw Exception('Failed to remove team member: $error');
    }
  }

  // Task Management
  Future<List<Map<String, dynamic>>> getTasks(String incidentId) async {
    try {
      final response = await _supabase
          .from('investigation_tasks')
          .select(
              '*, assigned_to:user_profiles!assigned_to(*), created_by:user_profiles!created_by(*)')
          .eq('incident_id', incidentId)
          .order('sort_order', ascending: true)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to fetch tasks: $error');
    }
  }

  Future<void> createTask({
    required String incidentId,
    required String title,
    String? description,
    String? assignedTo,
    required String createdBy,
    int priority = 0,
    DateTime? dueDate,
  }) async {
    try {
      await _supabase.from('investigation_tasks').insert({
        'incident_id': incidentId,
        'title': title,
        'description': description,
        'assigned_to': assignedTo,
        'created_by': createdBy,
        'priority': priority,
        'due_date': dueDate?.toIso8601String(),
      });
    } catch (error) {
      throw Exception('Failed to create task: $error');
    }
  }

  Future<void> updateTaskStatus(String taskId, String status) async {
    try {
      await _supabase.from('investigation_tasks').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
        if (status == 'complete')
          'completed_at': DateTime.now().toIso8601String(),
      }).eq('id', taskId);
    } catch (error) {
      throw Exception('Failed to update task status: $error');
    }
  }

  Future<void> updateTaskOrder(String taskId, int newOrder) async {
    try {
      await _supabase
          .from('investigation_tasks')
          .update({'sort_order': newOrder}).eq('id', taskId);
    } catch (error) {
      throw Exception('Failed to update task order: $error');
    }
  }

  Future<void> assignTask(String taskId, String userId) async {
    try {
      await _supabase
          .from('investigation_tasks')
          .update({'assigned_to': userId}).eq('id', taskId);
    } catch (error) {
      throw Exception('Failed to assign task: $error');
    }
  }

  // Evidence Management
  Future<List<Map<String, dynamic>>> getEvidence(String incidentId) async {
    try {
      final response = await _supabase
          .from('investigation_evidence')
          .select('*, collected_by:user_profiles(*)')
          .eq('incident_id', incidentId)
          .order('is_critical', ascending: false)
          .order('collected_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to fetch evidence: $error');
    }
  }

  Future<void> addEvidence({
    required String incidentId,
    required String category,
    required String title,
    String? description,
    String? filePath,
    int? fileSize,
    String? mimeType,
    Map<String, dynamic>? metadata,
    bool isCritical = false,
    required String collectedBy,
  }) async {
    try {
      await _supabase.from('investigation_evidence').insert({
        'incident_id': incidentId,
        'category': category,
        'title': title,
        'description': description,
        'file_path': filePath,
        'file_size': fileSize,
        'mime_type': mimeType,
        'metadata': metadata,
        'is_critical': isCritical,
        'collected_by': collectedBy,
      });
    } catch (error) {
      throw Exception('Failed to add evidence: $error');
    }
  }

  Future<void> markEvidenceCritical(String evidenceId, bool isCritical) async {
    try {
      await _supabase
          .from('investigation_evidence')
          .update({'is_critical': isCritical}).eq('id', evidenceId);
    } catch (error) {
      throw Exception('Failed to mark evidence critical: $error');
    }
  }

  // Messaging
  Future<List<Map<String, dynamic>>> getMessages(String incidentId) async {
    try {
      final response = await _supabase
          .from('investigation_messages')
          .select('*, sender:user_profiles(*)')
          .eq('incident_id', incidentId)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to fetch messages: $error');
    }
  }

  Future<void> sendMessage({
    required String incidentId,
    required String senderId,
    required String message,
    List<String>? mentions,
    Map<String, dynamic>? attachments,
    bool isDecision = false,
  }) async {
    try {
      await _supabase.from('investigation_messages').insert({
        'incident_id': incidentId,
        'sender_id': senderId,
        'message': message,
        'mentions': mentions,
        'attachments': attachments,
        'is_decision': isDecision,
      });
    } catch (error) {
      throw Exception('Failed to send message: $error');
    }
  }

  // Timeline
  Future<List<Map<String, dynamic>>> getTimeline(String incidentId) async {
    try {
      final response = await _supabase
          .from('investigation_timeline')
          .select('*, actor:user_profiles(*)')
          .eq('incident_id', incidentId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to fetch timeline: $error');
    }
  }

  // Real-time Subscriptions
  RealtimeChannel subscribeToWorkspace(
      String incidentId, Function(dynamic) onUpdate) {
    return _supabase
        .channel('investigation_workspace_$incidentId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'investigation_tasks',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'incident_id',
            value: incidentId,
          ),
          callback: onUpdate,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'investigation_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'incident_id',
            value: incidentId,
          ),
          callback: onUpdate,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'investigation_evidence',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'incident_id',
            value: incidentId,
          ),
          callback: onUpdate,
        )
        .subscribe();
  }

  void unsubscribeFromWorkspace(RealtimeChannel channel) {
    _supabase.removeChannel(channel);
  }
}