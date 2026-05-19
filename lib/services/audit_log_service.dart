import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AuditLogEntry {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String recordId;
  final String tableName;
  final String actionType;
  final DateTime createdAt;
  final String? ipAddress;
  final String? userAgent;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;

  AuditLogEntry({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.recordId,
    required this.tableName,
    required this.actionType,
    required this.createdAt,
    this.ipAddress,
    this.userAgent,
    this.oldValues,
    this.newValues,
  });

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    final userProfile = json['user_profiles'] as Map<String, dynamic>?;

    return AuditLogEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      userName: userProfile?['full_name'] as String? ?? 'Unknown User',
      userEmail: userProfile?['email'] as String? ?? '',
      recordId: json['record_id'] as String,
      tableName: json['table_name'] as String,
      actionType: json['action_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      oldValues: json['old_values'] as Map<String, dynamic>?,
      newValues: json['new_values'] as Map<String, dynamic>?,
    );
  }

  String get moduleDisplay {
    // Convert table_name to human-readable module name
    final parts = tableName.split('_');
    return parts
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  Color get actionColor {
    switch (actionType.toLowerCase()) {
      case 'insert':
        return const Color(0xFF4CAF50); // Green
      case 'update':
        return const Color(0xFF2196F3); // Blue
      case 'delete':
        return const Color(0xFFF44336); // Red
      case 'login':
      case 'logout':
        return const Color(0xFF9C27B0); // Purple
      case 'export':
      case 'import':
        return const Color(0xFFFF9800); // Orange
      default:
        return const Color(0xFF757575); // Gray
    }
  }

  String get actionDisplay {
    return actionType.toUpperCase();
  }

  List<String> getChangedFields() {
    if (oldValues == null || newValues == null) return [];

    final List<String> changed = [];
    newValues!.forEach((key, value) {
      if (oldValues![key] != value) {
        changed.add(key);
      }
    });

    return changed;
  }

  String getChangeDescription() {
    if (actionType.toLowerCase() == 'insert') {
      return 'Created new ${moduleDisplay.toLowerCase()} record';
    } else if (actionType.toLowerCase() == 'delete') {
      return 'Deleted ${moduleDisplay.toLowerCase()} record';
    } else if (actionType.toLowerCase() == 'update') {
      final fields = getChangedFields();
      if (fields.isEmpty) return 'No changes detected';
      return 'Modified ${fields.join(', ')}';
    } else {
      return actionDisplay;
    }
  }

  bool get isCriticalAction {
    // Define which actions should show toast notifications
    return actionType.toLowerCase() == 'delete' ||
        (actionType.toLowerCase() == 'update' &&
            (tableName == 'payments' ||
                tableName == 'invoices' ||
                tableName == 'sales_orders'));
  }
}

class AuditLogService {
  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _realtimeChannel;

  // Stream controller for real-time updates
  Stream<AuditLogEntry>? subscribeToAuditLogs() {
    try {
      final streamController = StreamController<AuditLogEntry>();

      _realtimeChannel = _supabase
          .channel('audit_logs_realtime')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'audit_logs',
            callback: (payload) async {
              final newLog = payload.newRecord;
              if (newLog.isEmpty) return;

              // Fetch user profile data separately for the new entry
              final userId = newLog['user_id'] as String;
              final userProfile = await _supabase
                  .from('user_profiles')
                  .select('full_name, email')
                  .eq('id', userId)
                  .maybeSingle();

              newLog['user_profiles'] = userProfile;

              // Add to stream
              streamController.add(AuditLogEntry.fromJson(newLog));
            },
          )
          .subscribe();

      return streamController.stream;
    } catch (e) {
      return null;
    }
  }

  void unsubscribeFromAuditLogs() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
  }

  Future<List<AuditLogEntry>> getAuditLogs({
    int limit = 20,
    int offset = 0,
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
    String? tableName,
    String? actionType,
  }) async {
    try {
      var query = _supabase
          .from('audit_logs')
          .select('*, user_profiles!inner(full_name, email)');

      // Apply all filters BEFORE ordering and range
      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      if (tableName != null) {
        query = query.eq('table_name', tableName);
      }

      if (actionType != null && actionType != 'All Actions') {
        query = query.eq('action_type', actionType.toLowerCase());
      }

      // Apply ordering and range in a single chain without reassignment
      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => AuditLogEntry.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load audit logs: $e');
    }
  }

  Future<List<String>> getDistinctUsers() async {
    try {
      final response = await _supabase
          .from('audit_logs')
          .select('user_profiles!inner(full_name)')
          .order('user_profiles(full_name)');

      final users = <String>{};
      for (final item in response as List) {
        final profile = item['user_profiles'];
        if (profile != null && profile['full_name'] != null) {
          users.add(profile['full_name'] as String);
        }
      }

      return users.toList()..sort();
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> getDistinctModules() async {
    try {
      final response = await _supabase
          .from('audit_logs')
          .select('table_name')
          .order('table_name');

      final modules = <String>{};
      for (final item in response as List) {
        if (item['table_name'] != null) {
          modules.add(item['table_name'] as String);
        }
      }

      return modules.toList()..sort();
    } catch (e) {
      return [];
    }
  }

  // Helper method to get current user ID
  String? getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }

  // Get user profile information
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('full_name, role, email')
          .eq('id', userId)
          .single();

      return response;
    } catch (e) {
      return {
        'full_name': 'Unknown User',
        'role': 'user',
        'email': '',
      };
    }
  }

  Future<void> exportAuditLogs(List<AuditLogEntry> logs) async {
    try {
      // Generate CSV content
      final buffer = StringBuffer();

      // Header
      buffer.writeln(
        'Timestamp,User,Email,Module,Action,Record ID,IP Address,Changes',
      );

      // Data rows
      for (final log in logs) {
        final timestamp = DateFormat(
          'yyyy-MM-dd HH:mm:ss',
        ).format(log.createdAt);
        final changes = log.getChangeDescription();

        buffer.writeln(
          '"$timestamp","${log.userName}","${log.userEmail}","${log.moduleDisplay}",'
          '"${log.actionDisplay}","${log.recordId}","${log.ipAddress ?? 'N/A'}","$changes"',
        );
      }

      // In a real app, use file_saver package to download
      // For now, just print success
      debugPrint('CSV Export Ready: ${buffer.toString().length} bytes');
    } catch (e) {
      throw Exception('Failed to export audit logs: $e');
    }
  }

  Future<AuditLogEntry?> getAuditLogDetails(String id) async {
    try {
      final response = await _supabase
          .from('audit_logs')
          .select('*, user_profiles!inner(full_name, email)')
          .eq('id', id)
          .single();

      return AuditLogEntry.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}
